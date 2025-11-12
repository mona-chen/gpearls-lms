class PaymentGateway < ApplicationRecord
  # Associations
  has_many :payments, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :gateway_type, presence: true, inclusion: { in: %w[paystack razorpay stripe paypal flutterwave] }
  validates :status, presence: true, inclusion: { in: %w[active inactive sandbox] }
  validates :settings, presence: true
  validate :validate_settings_structure
  validate :validate_required_credentials

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :sandbox, -> { where(status: 'sandbox') }
  scope :by_type, ->(type) { where(gateway_type: type) }
  scope :primary, -> { where(is_primary: true) }

  # Callbacks
  before_save :encrypt_sensitive_data
  after_save :clear_cache

  # Class methods
  def self.active_for_type(gateway_type)
    active.by_type(gateway_type).first
  end

  def self.primary_gateway
    active.primary.first || active.first
  end

  def self.for_currency(currency)
    active.find_by("settings->>'supported_currencies' LIKE ?", "%#{currency}%")
  end

  # Instance methods
  def active?
    status == 'active'
  end

  def sandbox?
    status == 'sandbox'
  end

  def supports_currency?(currency)
    supported_currencies.include?(currency)
  end

  def supported_currencies
    settings['supported_currencies'] || []
  end

  def fee_structure
    settings['fees'] || {}
  end

  def base_fee
    fee_structure['base'] || 0
  end

  def percentage_fee
    fee_structure['percentage'] || 0
  end

  def calculate_fees(amount)
    return 0 unless active?

    total_fees = base_fee + (amount * percentage_fee / 100)
    total_fees.round(2)
  end

  def credentials
    @credentials ||= begin
      creds = settings['credentials'] || {}
      case gateway_type
      when 'paystack'
        {
          public_key: decrypt(creds['public_key']),
          secret_key: decrypt(creds['secret_key']),
          webhook_secret: decrypt(creds['webhook_secret'])
        }
      when 'razorpay'
        {
          key_id: decrypt(creds['key_id']),
          key_secret: decrypt(creds['key_secret']),
          webhook_secret: decrypt(creds['webhook_secret'])
        }
      when 'stripe'
        {
          publishable_key: decrypt(creds['publishable_key']),
          secret_key: decrypt(creds['secret_key']),
          webhook_secret: decrypt(creds['webhook_secret'])
        }
      when 'paypal'
        {
          client_id: decrypt(creds['client_id']),
          client_secret: decrypt(creds['client_secret']),
          webhook_id: decrypt(creds['webhook_id'])
        }
      when 'flutterwave'
        {
          public_key: decrypt(creds['public_key']),
          secret_key: decrypt(creds['secret_key']),
          encryption_key: decrypt(creds['encryption_key'])
        }
      else
        {}
      end
    end
  end

  def update_credentials(new_credentials)
    encrypted_creds = {}
    new_credentials.each do |key, value|
      encrypted_creds[key] = encrypt(value) if value.present?
    end

    current_settings = settings.dup
    current_settings['credentials'] = encrypted_creds
    update!(settings: current_settings)
  end

  def test_connection
    case gateway_type
    when 'paystack'
      test_paystack_connection
    when 'razorpay'
      test_razorpay_connection
    when 'stripe'
      test_stripe_connection
    else
      { success: false, message: "Connection testing not implemented for #{gateway_type}" }
    end
  rescue => e
    { success: false, message: e.message }
  end

  def to_frappe_format
    {
      name: name,
      gateway_type: gateway_type,
      status: status,
      is_primary: is_primary,
      supported_currencies: supported_currencies,
      fee_structure: fee_structure,
      creation: created_at&.strftime('%Y-%m-%d %H:%M:%S'),
      modified: updated_at&.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  private

  def validate_settings_structure
    return unless settings.present?

    required_fields = case gateway_type
                    when 'paystack'
                      %w[credentials supported_currencies fees]
                    when 'razorpay'
                      %w[credentials supported_currencies fees]
                    when 'stripe'
                      %w[credentials supported_currencies fees]
                    else
                      %w[credentials supported_currencies]
                    end

    missing_fields = required_fields - settings.keys
    if missing_fields.any?
      errors.add(:settings, "missing required fields: #{missing_fields.join(', ')}")
    end
  end

  def validate_required_credentials
    return unless settings.present? && settings['credentials'].present?

    required_creds = case gateway_type
                    when 'paystack'
                      %w[public_key secret_key]
                    when 'razorpay'
                      %w[key_id key_secret]
                    when 'stripe'
                      %w[publishable_key secret_key]
                    when 'paypal'
                      %w[client_id client_secret]
                    when 'flutterwave'
                      %w[public_key secret_key encryption_key]
                    else
                      []
                    end

    creds = settings['credentials']
    missing_creds = required_creds - creds.keys
    if missing_creds.any?
      errors.add(:settings, "missing required credentials: #{missing_creds.join(', ')}")
    end
  end

  def encrypt_sensitive_data
    return unless settings.present? && settings['credentials'].present?

    encrypted_settings = settings.dup
    settings['credentials'].each do |key, value|
      encrypted_settings['credentials'][key] = encrypt(value) if value.present?
    end

    self.settings = encrypted_settings
  end

  def encrypt(value)
    # Use Rails encrypted credentials or a custom encryption method
    Rails.application.message_verifier('payment_gateway').generate(value)
  end

  def decrypt(encrypted_value)
    return nil if encrypted_value.blank?

    Rails.application.message_verifier('payment_gateway').verify(encrypted_value)
  rescue => e
    Rails.logger.error "Failed to decrypt payment gateway credential: #{e.message}"
    nil
  end

  def clear_cache
    @credentials = nil
  end

  # Gateway-specific connection tests
  def test_paystack_connection
    require 'net/http'
    require 'uri'
    require 'json'

    uri = URI.parse('https://api.paystack.co/bank')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{credentials[:secret_key]}"

    response = http.request(request)

    if response.code.to_i == 200
      { success: true, message: 'Connection successful' }
    else
      { success: false, message: "HTTP #{response.code}: #{response.message}" }
    end
  end

  def test_razorpay_connection
    # Implement Razorpay connection test
    { success: true, message: 'Razorpay connection test placeholder' }
  end

  def test_stripe_connection
    require 'stripe'
    Stripe.api_key = credentials[:secret_key]

    balance = Stripe::Balance.retrieve
    { success: true, message: 'Connection successful', data: balance }
  rescue Stripe::APIError => e
    { success: false, message: e.message }
  end
end
