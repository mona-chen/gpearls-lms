class PaymentLog < ApplicationRecord
  # Associations
  belongs_to :payment

  # Validations
  validates :payment, presence: true
  validates :event_type, presence: true, inclusion: { in: %w[
    payment_initialized
    payment_initialization_failed
    payment_verified
    payment_verification_failed
    payment_verification_error
    payment_completed
    payment_failed
    refund_processed
    refund_failed
    saved_method_charged
    saved_method_charge_failed
    webhook_received
    webhook_processed
    webhook_failed
    dispute_created
    chargeback_initiated
    subscription_created
    subscription_renewed
    subscription_cancelled
  ] }
  validates :status, presence: true, inclusion: { in: %w[success error warning info] }

  # Scopes
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "error") }
  scope :warnings, -> { where(status: "warning") }
  scope :by_event_type, ->(event_type) { where(event_type: event_type) }
  scope :by_gateway, ->(gateway_type) { where(gateway_type: gateway_type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :between_dates, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Callbacks
  before_validation :set_defaults

  # Class methods
  def self.log_payment_event(payment, event_type, status, gateway_response = nil, options = {})
    create!(
      payment: payment,
      event_type: event_type,
      status: status,
      gateway_response: gateway_response,
      gateway_type: options[:gateway_type],
      transaction_reference: options[:transaction_reference],
      amount: options[:amount] || payment&.amount,
      currency: options[:currency] || payment&.currency,
      ip_address: options[:ip_address],
      user_agent: options[:user_agent],
      request_data: options[:request_data],
      response_data: options[:response_data],
      error_message: options[:error_message],
      notes: options[:notes],
      processed_at: Time.current
    )
  rescue => e
    Rails.logger.error "Failed to create payment log: #{e.message}"
    nil
  end

  def self.get_payment_timeline(payment_id)
    where(payment_id: payment_id)
      .order(:created_at)
      .select(:event_type, :status, :gateway_response, :error_message, :created_at)
  end

  def self.get_error_summary(start_date = 1.week.ago, end_date = Time.current)
    between_dates(start_date, end_date)
      .where(status: "error")
      .group(:event_type)
      .count
  end

  def self.get_gateway_performance(gateway_type, start_date = 1.week.ago, end_date = Time.current)
    logs = between_dates(start_date, end_date).where(gateway_type: gateway_type)

    {
      total_events: logs.count,
      successful_events: logs.successful.count,
      failed_events: logs.failed.count,
      success_rate: (logs.successful.count.to_f / logs.count * 100).round(2),
      error_breakdown: logs.failed.group(:event_type).count
    }
  end

  # Instance methods
  def successful?
    status == "success"
  end

  def failed?
    status == "error"
  end

  def warning?
    status == "warning"
  end

  def has_gateway_response?
    gateway_response.present?
  end

  def error_details
    return nil unless failed?

    {
      error_message: error_message,
      gateway_response: gateway_response,
      request_data: request_data,
      response_data: response_data
    }
  end

  def retry_count
    super || 0
  end

  def increment_retry_count
    increment!(:retry_count)
  end

  def should_retry?
    failed? && retry_count < 3 && retriable_event?
  end

  def to_frappe_format
    {
      name: id,
      payment: payment&.name,
      event_type: event_type,
      status: status,
      gateway_response: gateway_response,
      error_message: error_message,
      gateway_type: gateway_type,
      transaction_reference: transaction_reference,
      amount: amount,
      currency: currency,
      ip_address: ip_address,
      user_agent: user_agent,
      retry_count: retry_count,
      processed_at: processed_at&.strftime("%Y-%m-%d %H:%M:%S"),
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      notes: notes
    }
  end

  private

  def set_defaults
    self.status ||= "info"
    self.processed_at ||= Time.current
    self.retry_count ||= 0
  end

  def retriable_event?
    retriable_events = %w[
      payment_initialization_failed
      payment_verification_error
      saved_method_charge_failed
      webhook_failed
    ]

    retriable_events.include?(event_type)
  end
end
