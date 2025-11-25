module Payments
  class PaymentService
    def self.initialize_payment(user, item_type, item_id, payment_method = "paystack")
      new(user, item_type, item_id, payment_method).initialize_payment
    end

    def self.verify_payment(payment_id, reference = nil)
      payment = Payment.find(payment_id)
      new(payment.user, nil, nil, payment.payment_method).verify_payment(payment, reference)
    end

    def self.process_refund(payment_id, amount = nil)
      payment = Payment.find(payment_id)
      new(payment.user, nil, nil, payment.payment_method).process_refund(payment, amount)
    end

    def initialize(user, item_type = nil, item_id = nil, payment_method = "paystack")
      @user = user
      @item_type = item_type
      @item_id = item_id
      @payment_method = payment_method
      @gateway = PaymentGateway.active_for_type(payment_method)
      @gateway_service = get_gateway_service
    end

    def initialize_payment
      validate_payment_setup
      payment = create_payment_record

      begin
        result = payment.initialize_payment(@gateway_service)

        log_payment_event(payment, "payment_initialized", "success", {
          gateway_type: @payment_method,
          authorization_url: result[:authorization_url]
        })

        {
          success: true,
          payment: payment,
          payment_url: result[:authorization_url],
          reference: result[:reference],
          access_code: result[:access_code]
        }
      rescue => e
        payment.mark_failed!(error: e.message)
        log_payment_event(payment, "payment_initialization_failed", "error", { error: e.message })

        {
          success: false,
          error: e.message,
          payment: payment
        }
      end
    end

    def verify_payment(payment, reference = nil)
      validate_payment(payment)

      begin
        result = payment.verify_payment(@gateway_service, reference)

        if result[:status] == "success"
          log_payment_event(payment, "payment_verified", "success", result[:gateway_response])
        else
          log_payment_event(payment, "payment_verification_failed", "error", result[:gateway_response])
        end

        result
      rescue => e
        log_payment_event(payment, "payment_verification_error", "error", { error: e.message })

        {
          success: false,
          error: e.message,
          payment: payment
        }
      end
    end

    def process_refund(payment, amount = nil)
      validate_refund(payment)

      begin
        result = @gateway_service.process_refund(payment, amount)

        log_payment_event(payment, "refund_processed", "success", {
          refund_amount: result[:amount],
          refund_id: result[:refund_id]
        })

        {
          success: true,
          refund: result,
          payment: payment
        }
      rescue => e
        log_payment_event(payment, "refund_failed", "error", { error: e.message })

        {
          success: false,
          error: e.message,
          payment: payment
        }
      end
    end

    def get_user_payment_methods
      @user.payment_methods.active.includes(:payment_gateway)
    end

    def add_payment_method(gateway_type, payment_details)
      gateway = PaymentGateway.active_for_type(gateway_type)
      raise Error::GatewayNotConfiguredError, "Gateway #{gateway_type} not configured" unless gateway

      begin
        case gateway_type
        when "paystack"
          add_paystack_method(gateway, payment_details)
        when "stripe"
          add_stripe_method(gateway, payment_details)
        when "razorpay"
          add_razorpay_method(gateway, payment_details)
        else
          raise Error::UnsupportedGatewayError, "Gateway #{gateway_type} not supported"
        end
      rescue => e
        {
          success: false,
          error: e.message
        }
      end
    end

    def remove_payment_method(method_id)
      payment_method = @user.payment_methods.find(method_id)
      payment_method.update!(status: "inactive")

      {
        success: true,
        message: "Payment method removed successfully"
      }
    end

    def get_payment_history(options = {})
      payments = @user.payments
                        .includes(:course, :batch, :program)
                        .order(created_at: :desc)
                        .page(options[:page] || 1)
                        .per(options[:per_page] || 20)

      {
        payments: payments.map(&:to_frappe_format),
        pagination: {
          current_page: payments.current_page,
          total_pages: payments.total_pages,
          total_count: payments.total_count
        }
      }
    end

    def get_available_gateways(currency = "USD")
      active_gateways = PaymentGateway.active
                             .where("settings->>'supported_currencies' LIKE ?", "%#{currency}%")
                             .order(is_primary: :desc)

      active_gateways.map do |gateway|
        {
          id: gateway.id,
          name: gateway.name,
          type: gateway.gateway_type,
          is_primary: gateway.is_primary,
          supported_currencies: gateway.supported_currencies,
          fee_structure: gateway.fee_structure,
          fees: {
            base: gateway.base_fee,
            percentage: gateway.percentage_fee
          }
        }
      end
    end

    def calculate_fees(amount, gateway_type)
      gateway = PaymentGateway.active_for_type(gateway_type)
      return 0 unless gateway

      gateway.calculate_fees(amount)
    end

    def charge_saved_payment_method(payment_method_id, amount, description = nil)
      payment_method = @user.payment_methods.find(payment_method_id)

      payment = Payment.create!(
        user: @user,
        amount: amount,
        currency: payment_method.payment_gateway.supported_currencies.first,
        payment_method: payment_method.method_type,
        payment_status: "Pending",
        description: description
      )

      begin
        case payment_method.method_type
        when "paystack"
          result = charge_paystack_method(payment_method, payment)
        when "stripe"
          result = charge_stripe_method(payment_method, payment)
        else
          raise Error::UnsupportedGatewayError, "Method #{payment_method.method_type} not supported"
        end

        log_payment_event(payment, "saved_method_charged", "success", {
          payment_method_id: payment_method_id,
          result: result
        })

        {
          success: true,
          payment: payment,
          result: result
        }
      rescue => e
        payment.mark_failed!(error: e.message)
        log_payment_event(payment, "saved_method_charge_failed", "error", { error: e.message })

        {
          success: false,
          error: e.message,
          payment: payment
        }
      end
    end

    private

    def validate_payment_setup
      raise Error::GatewayNotConfiguredError, "Payment gateway not configured" unless @gateway&.active?
      raise Error::InvalidPaymentError, "User not provided" unless @user
      raise Error::InvalidPaymentError, "Item type not provided" unless @item_type
      raise Error::InvalidPaymentError, "Item ID not provided" unless @item_id

      validate_item_exists
    end

    def validate_item_exists
      case @item_type
      when "course"
        @item = Course.find(@item_id)
      when "batch"
        @item = Batch.find(@item_id)
      when "program"
        @item = LmsProgram.find(@item_id)
      else
        raise Error::InvalidPaymentError, "Invalid item type: #{@item_type}"
      end
    rescue ActiveRecord::RecordNotFound
      raise Error::InvalidPaymentError, "#{@item_type.titleize} not found"
    end

    def validate_payment(payment)
      raise Error::InvalidPaymentError, "Payment not found" unless payment
      raise Error::InvalidPaymentError, "Payment does not belong to user" unless payment.user == @user
    end

    def validate_refund(payment)
      validate_payment(payment)
      raise Error::RefundFailedError, "Payment cannot be refunded" unless payment.can_be_refunded?
    end

    def create_payment_record
      case @item_type
      when "course"
        Payment.create_for_course(@user, @item, @payment_method)
      when "batch"
        Payment.create_for_batch(@user, @item, @payment_method)
      when "program"
        Payment.create_for_program(@user, @item, @payment_method)
      end
    end

    def get_gateway_service
      case @payment_method
      when "paystack"
        PaystackIntegration::PaystackService.new(@gateway)
      when "razorpay"
        Razorpay::RazorpayService.new(@gateway)
      when "stripe"
        Stripe::StripeService.new(@gateway)
      else
        raise Error::UnsupportedGatewayError, "Gateway #{@payment_method} not supported"
      end
    end

    def add_paystack_method(gateway, details)
      service = PaystackIntegration::PaystackService.new(gateway)
      customer_data = service.create_customer(@user)

      payment_method = @user.payment_methods.create!(
        payment_gateway: gateway,
        method_type: "paystack",
        customer_code: customer_data[:customer_code],
        status: "active",
        gateway_data: customer_data
      )

      {
        success: true,
        payment_method: payment_method,
        customer: customer_data
      }
    end

    def add_stripe_method(gateway, details)
      service = Stripe::StripeService.new(gateway)
      customer_data = service.create_customer(@user)

      payment_method = @user.payment_methods.create!(
        payment_gateway: gateway,
        method_type: "stripe",
        customer_id: customer_data[:customer_id],
        status: "active",
        gateway_data: customer_data
      )

      {
        success: true,
        payment_method: payment_method,
        customer: customer_data
      }
    end

    def add_razorpay_method(gateway, details)
      service = Razorpay::RazorpayService.new(gateway)
      customer_data = service.create_customer(@user)

      payment_method = @user.payment_methods.create!(
        payment_gateway: gateway,
        method_type: "razorpay",
        customer_id: customer_data[:customer_id],
        status: "active",
        gateway_data: customer_data
      )

      {
        success: true,
        payment_method: payment_method,
        customer: customer_data
      }
    end

    def charge_paystack_method(payment_method, payment)
      service = PaystackIntegration::PaystackService.new(payment_method.payment_gateway)
      service.charge_authorization(payment, payment_method.gateway_data["authorization_code"])
    end

    def charge_stripe_method(payment_method, payment)
      service = Stripe::StripeService.new(payment_method.payment_gateway)
      service.charge_customer(payment, payment_method.customer_id)
    end

    def log_payment_event(payment, event_type, status, data = {})
      PaymentLog.create!(
        payment: payment,
        event_type: event_type,
        status: status,
        gateway_response: data,
        gateway_type: @payment_method,
        ip_address: Current.current_request&.remote_ip,
        user_agent: Current.current_request&.user_agent,
        processed_at: Time.current
      )
    rescue => e
      Rails.logger.error "Failed to log payment event: #{e.message}"
    end
  end
end
