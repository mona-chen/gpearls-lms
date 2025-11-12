class UserPaymentMethod < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :payment_gateway
  has_many :payments, dependent: :restrict_with_error

  # Validations
  validates :user, presence: true
  validates :payment_gateway, presence: true
  validates :method_type, presence: true, inclusion: { in: %w[paystack stripe razorpay paypal flutterwave] }
  validates :status, presence: true, inclusion: { in: %w[active inactive expired revoked] }
  validates :customer_code, presence: true, if: -> { method_type == 'paystack' }
  validates :customer_id, presence: true, if: -> { %w[stripe razorpay].include?(method_type) }
  validates :authorization_code, presence: true, if: -> { method_type == 'paystack' && last4.present? }
  validates :last4, presence: true, if: -> { authorization_code.present? }
  validates :exp_month, :exp_year, presence: true, if: -> { last4.present? && method_type != 'paypal' }
  validate :validate_expiration_date, if: -> { exp_month.present? && exp_year.present? }
  validate :ensure_single_default_method

  # Callbacks
  before_validation :set_defaults
  before_save :update_gateway_data
  after_update :update_default_method, if: :saved_change_to_is_default?

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :expired, -> { where(status: 'expired') }
  scope :default, -> { where(is_default: true) }
  scope :by_type, ->(type) { where(method_type: type) }
  scope :by_gateway, ->(gateway) { where(payment_gateway: gateway) }
  scope :cards, -> { where.not(last4: nil) }
  scope :bank_accounts, -> { where.not(account_number_last4: nil) }

  # Class methods
  def self.for_user(user)
    where(user: user).includes(:payment_gateway)
  end

  def self.default_for_user(user)
    for_user(user).active.default.first
  end

  def self.active_for_user(user)
    for_user(user).active
  end

  def self.expiring_soon(days = 30)
    where('exp_month <= ? AND exp_year <= ?', Date.current.month + (days / 30), Date.current.year)
  end

  # Instance methods
  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def expired?
    status == 'expired' || card_expired?
  end

  def default?
    is_default
  end

  def card?
    last4.present? && method_type != 'paypal'
  end

  def bank_account?
    account_number_last4.present?
  end

  def card_type_display
    return 'Card' unless card?

    case card_type&.downcase
    when 'visa'
      'Visa'
    when 'mastercard'
      'Mastercard'
    when 'amex'
      'American Express'
    when 'discover'
      'Discover'
    when 'diners'
      'Diners Club'
    when 'jcb'
      'JCB'
    when 'unionpay'
      'UnionPay'
    else
      card_type&.titleize || 'Card'
    end
  end

  def masked_number
    return nil unless last4.present?

    case method_type
    when 'paypal'
      '****'
    else
      "**** **** **** #{last4}"
    end
  end

  def expiry_display
    return nil unless exp_month.present? && exp_year.present?

    "#{exp_month.to_s.rjust(2, '0')}/#{exp_year.to_s.last(2)}"
  end

  def card_expired?
    return false unless exp_month.present? && exp_year.present?

    expiry_date = Date.new(exp_year.to_i, exp_month.to_i).end_of_month
    expiry_date < Date.current
  end

  def expires_soon?(days = 30)
    return false unless exp_month.present? && exp_year.present?

    expiry_date = Date.new(exp_year.to_i, exp_month.to_i).end_of_month
    expiry_date <= Date.current + days
  end

  def can_be_used?
    active? && !expired?
  end

  def mark_as_default!
    transaction do
      user.user_payment_methods.where.not(id: id).update_all(is_default: false)
      update!(is_default: true)
    end
  end

  def deactivate!
    update!(status: 'inactive', is_default: false)
  end

  def expire!
    update!(status: 'expired', is_default: false)
  end

  def revoke!
    update!(status: 'revoked', is_default: false)
  end

  def refresh_gateway_data!
    case method_type
    when 'paystack'
      refresh_paystack_data
    when 'stripe'
      refresh_stripe_data
    when 'razorpay'
      refresh_razorpay_data
    end
  rescue => e
    Rails.logger.error "Failed to refresh gateway data for payment method #{id}: #{e.message}"
  end

  def charge(amount, description = nil)
    return { success: false, error: 'Payment method cannot be used' } unless can_be_used?

    payment = Payment.create!(
      user: user,
      amount: amount,
      currency: payment_gateway.supported_currencies.first,
      payment_method: method_type,
      payment_status: 'Pending',
      description: description
    )

    begin
      service = get_gateway_service
      result = case method_type
              when 'paystack'
                service.charge_authorization(payment, authorization_code)
              when 'stripe'
                service.charge_customer(payment, customer_id)
              when 'razorpay'
                service.charge_customer(payment, customer_id)
              else
                raise Payments::Error::UnsupportedGatewayError, "Method #{method_type} not supported"
              end

      {
        success: true,
        payment: payment,
        result: result
      }
    rescue => e
      payment.mark_failed!(error: e.message)

      {
        success: false,
        error: e.message,
        payment: payment
      }
    end
  end

  def to_frappe_format
    {
      name: id,
      user: user.email,
      payment_gateway: payment_gateway.name,
      method_type: method_type,
      status: status,
      is_default: is_default,
      card_type: card_type_display,
      last4: last4,
      expiry_month: exp_month,
      expiry_year: exp_year,
      masked_number: masked_number,
      expiry_display: expiry_display,
      bank_name: bank_name,
      account_name: account_name,
      account_number_last4: account_number_last4,
      created_at: created_at&.strftime('%Y-%m-%d %H:%M:%S'),
      modified_at: updated_at&.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.is_default ||= false
  end

  def update_gateway_data
    return unless gateway_data_changed?

    gateway_data_will_change!
    self.gateway_data = gateway_data.merge(updated_at: Time.current) if gateway_data.present?
  end

  def update_default_method
    return unless is_default? && saved_change_to_is_default?

    user.user_payment_methods.where.not(id: id).update_all(is_default: false)
  end

  def ensure_single_default_method
    if is_default? && user.user_payment_methods.where(is_default: true).where.not(id: id).exists?
      errors.add(:is_default, 'Only one payment method can be set as default')
    end
  end

  def validate_expiration_date
    return unless exp_month.present? && exp_year.present?

    begin
      expiry_date = Date.new(exp_year.to_i, exp_month.to_i)

      if expiry_date.year < Date.current.year ||
         (expiry_date.year == Date.current.year && expiry_date.month < Date.current.month)
        errors.add(:exp_year, 'Card has expired')
      end

      if expiry_date > Date.current + 10.years
        errors.add(:exp_year, 'Expiry year is too far in the future')
      end
    rescue ArgumentError
      errors.add(:exp_month, 'Invalid expiry date')
    end
  end

  def get_gateway_service
    case method_type
    when 'paystack'
      Paystack::PaystackService.new(payment_gateway)
    when 'stripe'
      Stripe::StripeService.new(payment_gateway)
    when 'razorpay'
      Razorpay::RazorpayService.new(payment_gateway)
    else
      raise Payments::Error::UnsupportedGatewayError, "Method #{method_type} not supported"
    end
  end

  def refresh_paystack_data
    service = Paystack::PaystackService.new(payment_gateway)
    customer = service.get_customer(customer_code)

    if customer.present?
      update!(
        gateway_data: gateway_data.merge(
          customer: customer,
          refreshed_at: Time.current
        )
      )
    end
  end

  def refresh_stripe_data
    service = Stripe::StripeService.new(payment_gateway)
    customer = service.get_customer(customer_id)

    if customer.present?
      update!(
        gateway_data: gateway_data.merge(
          customer: customer,
          refreshed_at: Time.current
        )
      )
    end
  end

  def refresh_razorpay_data
    service = Razorpay::RazorpayService.new(payment_gateway)
    customer = service.get_customer(customer_id)

    if customer.present?
      update!(
        gateway_data: gateway_data.merge(
          customer: customer,
          refreshed_at: Time.current
        )
      )
    end
  end
end
