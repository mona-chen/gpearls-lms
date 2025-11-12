module Payments
  class PaymentGatewayService
    def self.call
      new.call
    end

    def call
      gateways = PaymentGateway.active.includes(:payments)

      gateway_details = gateways.map do |gateway|
        gateway.to_frappe_format.merge(
          "payment_count" => gateway.payments.count,
          "total_volume" => gateway.payments.completed.sum(:amount),
          "success_rate" => calculate_success_rate(gateway),
          "supported_currencies_list" => gateway.supported_currencies,
          "fee_breakdown" => {
            "base_fee" => gateway.base_fee,
            "percentage_fee" => gateway.percentage_fee
          },
          "last_payment_at" => gateway.payments.maximum(:created_at)&.strftime("%Y-%m-%d %H:%M:%S")
        )
      end

      { "data" => gateway_details }
    end

    private

    def calculate_success_rate(gateway)
      total_payments = gateway.payments.count
      return 0 if total_payments == 0

      successful_payments = gateway.payments.completed.count
      (successful_payments.to_f / total_payments * 100).round(2)
    end
  end
end
