module Razorpay
  class RazorpayService
    def initialize(gateway = nil)
      @gateway = gateway || PaymentGateway.active_for_type("razorpay")
      raise Payments::Error::GatewayNotConfiguredError, "Razorpay gateway not configured" unless @gateway&.active?

      @key_id = @gateway.credentials[:key_id]
      @key_secret = @gateway.credentials[:key_secret]
    end

    # Create a payment order
    def create_order(payment)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      order = Razorpay::Order.create(
        amount: (payment.amount * 100).to_i,
        currency: payment_currency(payment.currency),
        receipt: payment.name,
        notes: {
          payment_id: payment.id,
          payment_description: payment.payment_description
        }
      )

      payment.update!(transaction_id: order.id)

      {
        order_id: order.id,
        amount: order.amount,
        currency: order.currency
      }
    end

    # Capture a payment
    def capture_payment(payment_id, amount)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      payment = Razorpay::Payment.capture(payment_id, amount)
      payment_record = Payment.find_by(transaction_id: payment.order_id)

      if payment.status == "captured"
        payment_record.mark_completed!(payment.to_json)
        process_payment_completion(payment_record, payment.to_json)
      else
        payment_record.mark_failed!(payment.to_json)
      end

      {
        status: payment.status,
        payment: payment_record
      }
    end

    # Create a customer
    def create_customer(user)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      customer = Razorpay::Customer.create(
        email: user.email,
        name: user.full_name,
        contact: user.phone_number,
        notes: {
          user_id: user.id
        }
      )

      {
        customer_id: customer.id,
        email: customer.email
      }
    end

    # Create payment for customer
    def create_customer_payment(payment, customer_id)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      razorpay_payment = Razorpay::Payment.create(
        amount: (payment.amount * 100).to_i,
        currency: payment_currency(payment.currency),
        email: payment.user.email,
        contact: payment.user.phone_number,
        customer_id: customer_id,
        notes: {
          payment_id: payment.id,
          payment_description: payment.payment_description
        }
      )

      payment.update!(transaction_id: razorpay_payment.id)

      {
        payment_id: razorpay_payment.id,
        amount: razorpay_payment.amount,
        currency: razorpay_payment.currency
      }
    end

    # Process refund
    def process_refund(payment, amount = nil)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      refund_data = {
        payment_id: payment.transaction_id
      }
      refund_data[:amount] = (amount * 100).to_i if amount

      refund = Razorpay::Refund.create(refund_data)
      payment.mark_refunded!(refund.to_json)

      {
        refund_id: refund.id,
        amount: refund.amount / 100.0,
        status: refund.status
      }
    end

    # Get customer
    def get_customer(customer_id)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      Razorpay::Customer.retrieve(customer_id)
    end

    # Verify webhook signature
    def validate_webhook_signature(payload, signature)
      require "razorpay"
      Razorpay.setup(@key_id, @key_secret)

      Razorpay::Utility.verify_webhook_signature(
        payload,
        signature,
        @gateway.credentials[:webhook_secret]
      )
    end

    # Process webhook events
    def process_webhook(payload)
      event = payload["event"]
      data = payload["payload"]

      case event
      when "payment.captured"
        handle_successful_payment(data)
      when "payment.failed"
        handle_failed_payment(data)
      when "refund.processed"
        handle_refund_processed(data)
      else
        Rails.logger.info "Unhandled Razorpay webhook event: #{event}"
      end

      { status: "processed", event: event }
    end

    private

    def payment_currency(currency)
      case currency.upcase
      when "USD"
        "USD"
      when "INR"
        "INR"
      else
        "INR" # Default to INR for Razorpay
      end
    end

    def process_payment_completion(payment, gateway_data)
      # Handle different payment types
      if payment.course.present?
        enrollment = Enrollment.find_or_create_by!(user: payment.user, course: payment.course)
        enrollment.update!(status: "Active", enrollment_date: Time.current)
      elsif payment.batch.present?
        batch_enrollment = BatchEnrollment.find_or_create_by!(user: payment.user, batch: payment.batch)
        batch_enrollment.update!(status: "Active", enrollment_date: Time.current)
      elsif payment.program.present?
        program_enrollment = LmsProgramEnrollment.find_or_create_by!(user: payment.user, program: payment.program)
        program_enrollment.update!(status: "Active", enrollment_date: Time.current)
      end

      # Send notifications
      PaymentMailer.payment_confirmation(payment).deliver_later
    end

    def handle_successful_payment(data)
      payment = Payment.find_by(transaction_id: data["order_id"])
      return unless payment

      payment.mark_completed!(data)
      process_payment_completion(payment, data)
    end

    def handle_failed_payment(data)
      payment = Payment.find_by(transaction_id: data["order_id"])
      return unless payment

      payment.mark_failed!(data)
      PaymentMailer.payment_failure(payment).deliver_later
    end

    def handle_refund_processed(data)
      payment = Payment.find_by(transaction_id: data["payment_id"])
      return unless payment

      payment.mark_refunded!(data)
      PaymentMailer.refund_confirmation(payment).deliver_later
    end
  end
end
