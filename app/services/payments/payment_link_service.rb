module Payments
  class PaymentLinkService
    def self.call(params, user)
      new(params, user).call
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def call
      # Validate required parameters
      return error_response("User not found") unless @user
      return error_response("Item type is required") unless @params[:item_type]
      return error_response("Item ID is required") unless @params[:item_id]

      # Find the item to purchase
      item = find_item
      return error_response("Item not found") unless item

      # Check if user already has access
      return error_response("You already have access to this item") if user_has_access?(item)

      # Check if payment already exists and is pending
      existing_payment = find_existing_payment(item)
      if existing_payment&.pending?
        return success_response(existing_payment, "Existing payment found")
      end

      # Create new payment
      payment = create_payment(item)
      return error_response("Failed to create payment") unless payment

      # Initialize payment with gateway
      gateway_service = get_gateway_service(payment)
      payment_link = initialize_payment_link(payment, gateway_service)

      if payment_link[:success]
        success_response(payment, "Payment link generated successfully", payment_link[:data])
      else
        error_response(payment_link[:error] || "Failed to generate payment link")
      end
    end

    private

    def find_item
      case @params[:item_type]
      when "course"
        Course.find_by(id: @params[:item_id])
      when "batch"
        Batch.find_by(id: @params[:item_id])
      when "program"
        LmsProgram.find_by(id: @params[:item_id])
      else
        nil
      end
    end

    def user_has_access?(item)
      case item.class.name
      when "Course"
        Enrollment.exists?(user: @user, course: item)
      when "Batch"
        BatchEnrollment.exists?(user: @user, batch: item)
      when "LmsProgram"
        LmsProgramMember.exists?(user: @user, lms_program: item)
      else
        false
      end
    end

    def find_existing_payment(item)
      case item.class.name
      when "Course"
        Payment.find_by(user: @user, course: item, payment_status: "Pending")
      when "Batch"
        Payment.find_by(user: @user, batch: item, payment_status: "Pending")
      when "LmsProgram"
        Payment.find_by(user: @user, program: item, payment_status: "Pending")
      else
        nil
      end
    end

    def create_payment(item)
      gateway = @params[:gateway] || PaymentGateway.primary_gateway&.gateway_type || "paystack"

      case item.class.name
      when "Course"
        Payment.create_for_course(@user, item, gateway)
      when "Batch"
        Payment.create_for_batch(@user, item, gateway)
      when "LmsProgram"
        Payment.create_for_program(@user, item, gateway)
      else
        nil
      end
    rescue => e
      Rails.logger.error "Failed to create payment: #{e.message}"
      nil
    end

    def get_gateway_service(payment)
      case payment.payment_method
      when "paystack", "paystack_ussd", "paystack_bank_transfer", "paystack_mobile_money"
        Paystack::PaystackService.new
      when "razorpay"
        Razorpay::RazorpayService.new
      when "stripe"
        Stripe::StripeService.new
      else
        nil
      end
    end

    def initialize_payment_link(payment, gateway_service)
      return { success: false, error: "Gateway service not available" } unless gateway_service

      begin
        result = payment.initialize_payment(gateway_service)

        case payment.payment_method
        when "paystack"
          {
            success: true,
            data: {
              payment_url: result["authorization_url"],
              reference: result["reference"],
              access_code: result["access_code"],
              payment_method: "card"
            }
          }
        when "paystack_ussd"
          {
            success: true,
            data: {
              ussd_code: result["ussd_code"],
              reference: result["reference"],
              payment_method: "ussd"
            }
          }
        when "paystack_bank_transfer"
          {
            success: true,
            data: {
              bank_details: result["bank_details"],
              reference: result["reference"],
              payment_method: "bank_transfer"
            }
          }
        when "paystack_mobile_money"
          {
            success: true,
            data: {
              payment_url: result["authorization_url"],
              reference: result["reference"],
              payment_method: "mobile_money",
              provider: result["provider"]
            }
          }
        when "razorpay"
          {
            success: true,
            data: {
              order_id: result["id"],
              payment_url: "https://checkout.razorpay.com/v1/checkout.js?order_id=#{result['id']}",
              key_id: gateway_service.credentials[:key_id]
            }
          }
        when "stripe"
          {
            success: true,
            data: {
              client_secret: result.client_secret,
              payment_intent_id: result.id
            }
          }
        else
          { success: false, error: "Unsupported payment method" }
        end
      rescue => e
        Rails.logger.error "Payment initialization failed: #{e.message}"
        { success: false, error: e.message }
      end
    end

    def success_response(payment, message, payment_data = nil)
      {
        success: true,
        data: {
          payment: payment.to_frappe_format,
          payment_link: payment_data,
          message: message
        }
      }
    end

    def error_response(message)
      {
        success: false,
        error: message
      }
    end
  end
end
