module Payments
  module Error
    class PaymentError < StandardError; end

    class GatewayNotConfiguredError < PaymentError; end
    class UnsupportedGatewayError < PaymentError; end
    class InvalidPaymentError < PaymentError; end
    class PaymentFailedError < PaymentError; end
    class RefundFailedError < PaymentError; end
    class WebhookValidationError < PaymentError; end
    class InsufficientFundsError < PaymentError; end
    class CardDeclinedError < PaymentError; end
    class ExpiryDateError < PaymentError; end
    class CvcError < PaymentError; end
    class ProcessingError < PaymentError; end
    class TimeoutError < PaymentError; end

    # Paystack specific errors
    class PaystackError < PaymentError; end
    class PaystackConnectionError < PaystackError; end
    class PaystackAuthenticationError < PaystackError; end

    # Stripe specific errors
    class StripeError < PaymentError; end
    class StripeConnectionError < StripeError; end
    class StripeAuthenticationError < StripeError; end

    # Razorpay specific errors
    class RazorpayError < PaymentError; end
    class RazorpayConnectionError < RazorpayError; end
    class RazorpayAuthenticationError < RazorpayError; end
  end
end
