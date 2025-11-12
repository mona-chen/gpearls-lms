module Payments
  class OrderSummaryService
    def self.call(order_id, user)
      new(order_id, user).call
    end

    def initialize(order_id, user)
      @order_id = order_id
      @user = user
    end

    def call
      payment = find_payment
      return error_response("Payment not found") unless payment
      return error_response("Access denied") unless can_access_payment?(payment)

      order_summary = build_order_summary(payment)
      success_response(order_summary)
    end

    private

    def find_payment
      Payment.find_by(name: @order_id) || Payment.find_by(id: @order_id)
    end

    def can_access_payment?(payment)
      return false unless @user
      payment.user_id == @user.id
    end

    def build_order_summary(payment)
      {
        order_id: payment.name,
        payment_id: payment.id,
        user: payment.user&.full_name,
        user_email: payment.user&.email,
        item_type: determine_item_type(payment),
        item_name: determine_item_name(payment),
        item_id: determine_item_id(payment),
        amount: payment.amount,
        currency: payment.currency,
        payment_method: payment.payment_method,
        payment_status: payment.payment_status,
        transaction_id: payment.transaction_id,
        payment_date: payment.payment_date&.strftime("%Y-%m-%d %H:%M:%S"),
        gateway_fees: payment.calculate_fees,
        net_amount: payment.net_amount,
        gateway_response: payment.gateway_response,
        billing_address: payment.billing_address,
        created_at: payment.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
        updated_at: payment.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
        payment_logs: payment.payment_logs.recent.limit(10).map(&:to_frappe_format)
      }
    end

    def determine_item_type(payment)
      return "course" if payment.course.present?
      return "batch" if payment.batch.present?
      return "program" if payment.program.present?
      "unknown"
    end

    def determine_item_name(payment)
      return payment.course.title if payment.course.present?
      return payment.batch.title if payment.batch.present?
      return payment.program.title if payment.program.present?
      "Unknown Item"
    end

    def determine_item_id(payment)
      return payment.course.id if payment.course.present?
      return payment.batch.id if payment.batch.present?
      return payment.program.id if payment.program.present?
      nil
    end

    def success_response(data)
      {
        success: true,
        data: data
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
