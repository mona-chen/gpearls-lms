class ZoomSetting < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  # Validations
  validates :account_name, presence: true, uniqueness: true
  validates :api_key, presence: true
  validates :api_secret, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :recording_option, inclusion: { in: %w[local cloud none] }
  validates :password_type, inclusion: { in: %w[numeric alphanumeric] }
  validates :password_length, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_account, ->(account_name) { where(account_name: account_name) }

  # Callbacks
  before_save :encrypt_sensitive_data
  before_create :set_defaults

  # Instance methods
  def active?
    enabled? && sync_status != "error"
  end

  def credentials
    @credentials ||= begin
      {
        api_key: decrypt(api_key),
        api_secret: decrypt(api_secret),
        account_id: account_id,
        user_id: user_id
      }
    end
  end

  def meeting_settings
    super || {}
  end

  def security_settings
    super || {}
  end

  def recording_settings
    super || {}
  end

  def branding_settings
    super || {}
  end

  def virtual_background_settings
    super || {}
  end

  def webhook_events
    super || []
  end

  def test_meeting_settings
    super || {}
  end

  def can_create_meetings?
    active? && api_key.present? && api_secret.present?
  end

  def sync_status_color
    case sync_status
    when "success" then "green"
    when "error" then "red"
    when "pending" then "yellow"
    else "gray"
    end
  end

  def to_frappe_format
    {
      name: account_name,
      account_name: account_name,
      api_key: api_key,
      api_secret: api_secret,
      account_id: account_id,
      user_id: user_id,
      user_email: user_email,
      enabled: enabled,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def encrypt_sensitive_data
    self.api_key = encrypt(api_key) if api_key_changed?
    self.api_secret = encrypt(api_secret) if api_secret_changed?
    self.webhook_secret = encrypt(webhook_secret) if webhook_secret_changed?
  end

  def set_defaults
    self.meeting_settings ||= {}
    self.security_settings ||= {}
    self.recording_settings ||= {}
    self.branding_settings ||= {}
    self.virtual_background_settings ||= {}
    self.webhook_events ||= []
    self.test_meeting_settings ||= {}
  end

  def encrypt(value)
    return nil if value.blank?
    Rails.application.message_verifier("zoom_settings").generate(value)
  end

  def decrypt(encrypted_value)
    return nil if encrypted_value.blank?
    Rails.application.message_verifier("zoom_settings").verify(encrypted_value)
  rescue => e
    Rails.logger.error "Failed to decrypt Zoom setting: #{e.message}"
    nil
  end
end
