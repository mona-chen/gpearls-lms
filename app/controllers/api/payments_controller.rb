class Api::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :authenticate_user!
  before_action :set_payment, only: [:show, :verify, :refund]
  before_action :set_payment_gateway

  # POST /api/payments/initialize
  def initialize_payment
    @payment = build_payment
    @payment.save!

    begin
      gateway_service = get_gateway_service(@payment.payment_method)
      payment_data = @payment.initialize_payment(gateway_service)

      render json: {
        success: true,
        payment: @payment,
        payment_url: payment_data[:authorization_url],
        reference: payment_data[:reference],
        access_code: payment_data[:access_code]
      }
    rescue => e
      @payment.mark_failed!(error: e.message)
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # GET /api/payments/:id
  def show
    render json: {
      success: true,
      payment: @payment
    }
  end

  # POST /api/payments/:id/verify
  def verify
    begin
      gateway_service = get_gateway_service(@payment.payment_method)
      result = @payment.verify_payment(gateway_service, params[:reference])

      render json: {
        success: true,
        payment: result[:payment],
        status: result[:status]
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # POST /api/payments/callback/paystack
  def paystack_callback
    signature = request.headers['X-Paystack-Signature']
    payload = request.raw_post

    begin
      paystack_service = Paystack::PaystackService.new
      unless paystack_service.validate_webhook_signature(payload, signature)
        return render json: { error: 'Invalid signature' }, status: :unauthorized
      end

      webhook_data = JSON.parse(payload)
      paystack_service.process_webhook(webhook_data)

      render json: { status: 'success' }
    rescue => e
      Rails.logger.error "Paystack webhook error: #{e.message}"
      render json: { error: 'Webhook processing failed' }, status: :unprocessable_entity
    end
  end

  # POST /api/payments/:id/refund
  def refund
    unless @payment.can_be_refunded?
      return render json: {
        success: false,
        error: 'Payment cannot be refunded'
      }, status: :unprocessable_entity
    end

    refund_amount = params[:amount]&.to_f || @payment.amount

    begin
      gateway_service = get_gateway_service(@payment.payment_method)
      refund_data = @payment.process_refund(gateway_service, refund_amount)

      render json: {
        success: true,
        refund: refund_data
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # GET /api/payments
  def index
    payments = current_user.payments
                     .includes(:course, :batch, :program)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(params[:per_page] || 20)

    render json: {
      success: true,
      payments: payments.map(&:to_frappe_format),
      pagination: {
        current_page: payments.current_page,
        total_pages: payments.total_pages,
        total_count: payments.total_count
      }
    }
  end

  # GET /api/payments/gateways
  def gateways
    active_gateways = PaymentGateway.active
                           .where("settings->>'supported_currencies' LIKE ?", "%#{params[:currency] || 'USD'}%")

    render json: {
      success: true,
      gateways: active_gateways.map do |gateway|
        {
          id: gateway.id,
          name: gateway.name,
          type: gateway.gateway_type,
          supported_currencies: gateway.supported_currencies,
          fee_structure: gateway.fee_structure
        }
      end
    }
  end

  # POST /api/payments/methods
  def add_payment_method
    method_type = params[:method_type]
    gateway = PaymentGateway.active_for_type(method_type)

    unless gateway
      return render json: {
        success: false,
        error: 'Payment gateway not available'
      }, status: :unprocessable_entity
    end

    begin
      case method_type
      when 'paystack'
        result = add_paystack_method(gateway)
      when 'stripe'
        result = add_stripe_method(gateway)
      else
        return render json: {
          success: false,
          error: 'Unsupported payment method'
        }, status: :unprocessable_entity
      end

      PaymentMailer.payment_method_added(current_user, result[:method]).deliver_later

      render json: {
        success: true,
        payment_method: result[:method]
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # GET /api/payments/methods
  def payment_methods
    methods = current_user.payment_methods.active

    render json: {
      success: true,
      payment_methods: methods.map(&:to_frappe_format)
    }
  end

  # DELETE /api/payments/methods/:id
  def remove_payment_method
    method = current_user.payment_methods.find(params[:id])
    method.update!(status: 'inactive')

    render json: {
      success: true,
      message: 'Payment method removed successfully'
    }
  end

  private

  def set_payment
    @payment = current_user.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Payment not found'
    }, status: :not_found
  end

  def set_payment_gateway
    @gateway = PaymentGateway.active_for_type(params[:payment_method] || 'paystack')
    unless @gateway&.active?
      render json: {
        success: false,
        error: 'Payment gateway not available'
      }, status: :unprocessable_entity
    end
  end

  def build_payment
    payment_params = params.require(:payment).permit(
      :item_type, :item_id, :amount, :currency, :payment_method
    )

    case payment_params[:item_type]
    when 'course'
      course = Course.find(payment_params[:item_id])
      Payment.create_for_course(current_user, course, payment_params[:payment_method])
    when 'batch'
      batch = Batch.find(payment_params[:item_id])
      Payment.create_for_batch(current_user, batch, payment_params[:payment_method])
    when 'program'
      program = LmsProgram.find(payment_params[:item_id])
      Payment.create_for_program(current_user, program, payment_params[:payment_method])
    else
      raise ArgumentError, 'Invalid item type'
    end
  end

  def get_gateway_service(method_type)
    case method_type
    when 'paystack'
      Paystack::PaystackService.new
    when 'razorpay'
      Razorpay::RazorpayService.new
    when 'stripe'
      Stripe::StripeService.new
    else
      raise Error::UnsupportedGatewayError, "Gateway #{method_type} not supported"
    end
  end

  def add_paystack_method(gateway)
    service = Paystack::PaystackService.new(gateway)
    customer_data = service.create_customer(current_user)

    # Save payment method to database
    payment_method = current_user.payment_methods.create!(
      method_type: 'paystack',
      gateway: gateway,
      customer_code: customer_data[:customer_code],
      status: 'active'
    )

    { method: payment_method, customer: customer_data }
  end

  def add_stripe_method(gateway)
    service = Stripe::StripeService.new(gateway)
    customer_data = service.create_customer(current_user)

    payment_method = current_user.payment_methods.create!(
      method_type: 'stripe',
      gateway: gateway,
      customer_id: customer_data[:customer_id],
      status: 'active'
    )

    { method: payment_method, customer: customer_data }
  end
end
