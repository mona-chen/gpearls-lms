FactoryBot.define do
  factory :payment do
    sequence(:name) { |n| "payment_#{n}" }
    user
    amount { 1000 }
    currency { 'NGN' }
    payment_method { 'paystack' }
    payment_status { 'Pending' }
  end
end
