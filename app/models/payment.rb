class Payment < ApplicationRecord
  attr_accessor :name

  # Associations
  belongs_to :user, class_name: "User", foreign_key: :user_id
  alias_attribute :payment_status, :status
  belongs_to :payable, polymorphic: true, optional: true
  belongs_to :payment_gateway, optional: true
  belongs_to :coupon, optional: true, class_name: "LmsCoupon"
  belongs_to :address, optional: true

  # Aliases for backward compatibility
  def course
    payable if payable_type == "Course"
  end

  def batch
    payable if payable_type == "Batch"
  end

  def program
    payable if payable_type == "LmsProgram"
  end

  # Validations
  validates :name, presence: true
  validates :user, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD NGN EUR GBP GHS KES ZAR] }
  validates :payment_status, presence: true, inclusion: { in: %w[Pending Completed Failed Refunded Cancelled] }
  validates :transaction_id, uniqueness: { allow_blank: true }
   validates :payment_method, inclusion: { in: %w[paystack paystack_ussd paystack_bank_transfer paystack_mobile_money razorpay stripe paypal flutterwave], allow_blank: true }

  # Callbacks
  before_validation :set_defaults, on: :create
  before_create :generate_name
  after_update :update_enrollment_status, if: :saved_change_to_payment_status?

  # Scopes
  scope :completed, -> { where(payment_status: "Completed") }
  scope :pending, -> { where(payment_status: "Pending") }
  scope :failed, -> { where(payment_status: "Failed") }
  scope :refunded, -> { where(payment_status: "Refunded") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_gateway, ->(gateway) { where(payment_method: gateway) }
  scope :for_course, ->(course) { where(payable: course) }
  scope :for_batch, ->(batch) { where(payable: batch) }

  # Class methods
  def self.create_for_course(user, course, gateway = "paystack")
    create!(
      user: user,
      payable: course,
      amount: course.course_price || 0,
      currency: course.currency || "USD",
      payment_method: gateway,
      payment_status: "Pending"
    )
  end

  def self.create_for_batch(user, batch, gateway = "paystack")
    create!(
      user: user,
      batch: batch,
      amount: batch.price || 0,
      currency: batch.currency || "USD",
      payment_method: gateway,
      payment_status: "Pending"
    )
  end

  def self.create_for_program(user, program, gateway = "paystack")
    create!(
      user: user,
      program: program,
      amount: program.price || 0,
      currency: program.currency || "USD",
      payment_method: gateway,
      payment_status: "Pending"
    )
  end

  # Instance methods
  def completed?
    payment_status == "Completed"
  end

  def pending?
    payment_status == "Pending"
  end

  def failed?
    payment_status == "Failed"
  end

  def refunded?
    payment_status == "Refunded"
  end

  def can_be_refunded?
    completed? && !refunded? && refundable_period_active?
  end

  def mark_completed!(gateway_response = nil)
    update!(
      payment_status: "Completed",
      payment_date: Time.current,
      gateway_response: gateway_response
    )
  end

  def mark_failed!(gateway_response = nil)
    update!(
      payment_status: "Failed",
      gateway_response: gateway_response
    )
  end

  def mark_refunded!(refund_amount = nil)
    update!(
      payment_status: "Refunded",
      gateway_response: (gateway_response || {}).merge(refunded_at: Time.current)
    )
  end

  def initialize_payment(gateway_service)
    case payment_method
    when "paystack"
      gateway_service.initialize_transaction(self)
    when "paystack_ussd"
      gateway_service.initialize_ussd_payment(self)
    when "paystack_bank_transfer"
      gateway_service.initialize_bank_transfer(self)
    when "paystack_mobile_money"
      gateway_service.initialize_mobile_money_payment(self)
    when "razorpay"
      gateway_service.create_order(self)
    when "stripe"
      gateway_service.create_payment_intent(self)
    else
      raise Error::UnsupportedGatewayError, "Gateway #{payment_method} not supported"
    end
  end

  def verify_payment(gateway_service, reference = nil)
    case payment_method
    when "paystack"
      gateway_service.verify_transaction(reference || transaction_id)
    when "razorpay"
      gateway_service.verify_payment(reference || transaction_id)
    when "stripe"
      gateway_service.confirm_payment(reference || transaction_id)
    else
      raise Error::UnsupportedGatewayError, "Gateway #{payment_method} not supported"
    end
  end

  def calculate_fees
    return 0 unless payment_gateway

    gateway_config = payment_gateway.settings
    base_fee = gateway_config.dig("fees", "base") || 0
    percentage_fee = gateway_config.dig("fees", "percentage") || 0

    total_fees = base_fee + (amount * percentage_fee / 100)
    total_fees.round(2)
  end

  def net_amount
    amount - calculate_fees
  end

  def payment_description
    if course.present?
      "Payment for course: #{course.title}"
    elsif batch.present?
      "Payment for batch: #{batch.title}"
    elsif program.present?
      "Payment for program: #{program.title}"
    else
      "Payment transaction"
    end
  end

  def to_frappe_format
    {
      "name" => name,
      "member" => member&.email,
      "billing_name" => billing_name,
      "source" => source,
      "payment_for_document_type" => payment_for_document_type,
      "payment_for_document" => payment_for_document,
      "payment_received" => payment_received || false,
      "payment_for_certificate" => payment_for_certificate || false,
      "original_amount" => original_amount,
      "discount_amount" => discount_amount,
      "amount" => amount,
      "amount_with_gst" => amount_with_gst,
      "currency" => currency,
      "coupon" => coupon&.name,
      "coupon_code" => coupon_code,
      "address" => address&.name,
      "payment_id" => payment_id,
      "order_id" => order_id,
      "gstin" => gstin,
      "pan" => pan,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Webhook handling
  def process_webhook_payload(payload, gateway)
    case gateway
    when "paystack"
      process_paystack_webhook(payload)
    when "razorpay"
      process_razorpay_webhook(payload)
    when "stripe"
      process_stripe_webhook(payload)
    end
  end

  private

  def set_defaults
    self.currency ||= "USD"
    self.payment_status ||= "Pending"
  end

  def generate_name
    self.name = "PAY-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
   end
end

  def update_enrollment_status
    return unless completed?

    if payable_type == "Course"
      enrollment = Enrollment.find_or_create_by!(user: user, course: payable)
      enrollment.update!(status: "Active", enrollment_date: Time.current)
    elsif payable_type == "Batch"
      # Handle batch enrollment
    elsif payable_type == "LmsProgram"
      # Handle program enrollment
    end

    # Send notifications
    PaymentMailer.payment_confirmation(self).deliver_later
  end

  def refundable_period_active?
    # Typically 30 days for digital goods
    completed? && (Time.current - payment_date) <= 30.days
  end

  # Polling functionality
  def start_polling!
    return unless pending? && auto_verification_enabled?

    # Enqueue Sidekiq job for automatic polling
    Payments::TransactionPollingService.perform_async(id)
    update!(last_polled_at: Time.current, polling_expires_at: 30.minutes.from_now)
  end

  def stop_polling!
    update!(auto_verification_enabled: false)
  end

  def polling_active?
    pending? && auto_verification_enabled? &&
    (polling_expires_at.blank? || polling_expires_at > Time.current)
  end

  def polling_expired?
    polling_expires_at.present? && polling_expires_at < Time.current
  end

  def should_poll?
    pending? && auto_verification_enabled? && !polling_expired?
  end

  # Gateway-specific webhook processors
  def process_paystack_webhook(payload)
    event = payload["event"]
    data = payload["data"]

    case event
    when "charge.success"
      mark_completed!(data) if pending?
    when "charge.failed"
      mark_failed!(data) if pending?
    when "refund.processed"
      mark_refunded!(data) if completed?
    end
  end

  def process_razorpay_webhook(payload)
    event = payload["event"]

    case event
    when "payment.captured"
      mark_completed!(payload) if pending?
    when "payment.failed"
      mark_failed!(payload) if pending?
    when "refund.processed"
      mark_refunded!(payload) if completed?
    end
  end

  def process_stripe_webhook(payload)
    event_type = payload["type"]

    case event_type
    when "payment_intent.succeeded"
      mark_completed!(payload) if pending?
    when "payment_intent.payment_failed"
      mark_failed!(payload) if pending?
    when "charge.dispute.created"
      # Handle disputes
    end
   end
