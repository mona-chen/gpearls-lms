module Stripe
  class StripeService
    def initialize(gateway = nil)
      @gateway = gateway || PaymentGateway.active_for_type("stripe")
      raise Payments::Error::GatewayNotConfiguredError, "Stripe gateway not configured" unless @gateway&.active?

      @secret_key = @gateway.credentials[:secret_key]
      @publishable_key = @gateway.credentials[:publishable_key]
    end

    # Initialize a payment intent
    def create_payment_intent(payment)
      require "stripe"
      Stripe.api_key = @secret_key

      intent = Stripe::PaymentIntent.create({
        amount: (payment.amount * 100).to_i,
        currency: payment.currency.downcase,
        metadata: {
          payment_id: payment.id,
          payment_description: payment.payment_description
        },
        confirmation_method: "manual",
        confirm: false
      })

      payment.update!(transaction_id: intent.id)

      {
        client_secret: intent.client_secret,
        payment_intent_id: intent.id
      }
    end

    # Confirm a payment
    def confirm_payment(payment_intent_id)
      require "stripe"
      Stripe.api_key = @secret_key

      intent = Stripe::PaymentIntent.confirm(payment_intent_id)
      payment = Payment.find_by(transaction_id: payment_intent_id)

      if intent.status == "succeeded"
        payment.mark_completed!(intent.to_json)
        process_payment_completion(payment, intent.to_json)
      else
        payment.mark_failed!(intent.to_json)
      end

      {
        status: intent.status,
        payment: payment
      }
    end

    # Create a customer
    def create_customer(user)
      require "stripe"
      Stripe.api_key = @secret_key

      customer = Stripe::Customer.create({
        email: user.email,
        name: user.full_name,
        metadata: {
          user_id: user.id
        }
      })

      {
        customer_id: customer.id,
        email: customer.email
      }
    end

    # Charge a customer
    def charge_customer(payment, customer_id)
      require "stripe"
      Stripe.api_key = @secret_key

      charge = Stripe::Charge.create({
        amount: (payment.amount * 100).to_i,
        currency: payment.currency.downcase,
        customer: customer_id,
        description: payment.payment_description,
        metadata: {
          payment_id: payment.id
        }
      })

      if charge.status == "succeeded"
        payment.mark_completed!(charge.to_json)
        process_payment_completion(payment, charge.to_json)
      else
        payment.mark_failed!(charge.to_json)
      end

      {
        charge: charge,
        payment: payment
      }
    end

    # Process refund
    def process_refund(payment, amount = nil)
      require "stripe"
      Stripe.api_key = @secret_key

      refund = Stripe::Refund.create({
        charge: payment.transaction_id,
        amount: amount ? (amount * 100).to_i : nil
      })

      payment.mark_refunded!(refund.to_json)

      {
        refund_id: refund.id,
        amount: refund.amount / 100.0,
        status: refund.status
      }
    end

    # Get customer
    def get_customer(customer_id)
      require "stripe"
      Stripe.api_key = @secret_key

      Stripe::Customer.retrieve(customer_id)
    end

    private

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
  end
end
