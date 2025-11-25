FactoryBot.define do
  factory :payment_gateway do
    gateway_type { 'paystack' }
    name { 'Paystack Gateway' }
    status { 'active' }
    settings do
      {
        credentials: {
          secret_key: 'sk_test_123',
          public_key: 'pk_test_123',
          webhook_secret: 'wh_test_123'
        },
        supported_currencies: [ 'NGN', 'USD' ],
        fees: { base: 0, percentage: 0 }
      }
    end
  end
end
