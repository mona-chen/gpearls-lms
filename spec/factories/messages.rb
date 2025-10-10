FactoryBot.define do
  factory :message do
    user { nil }
    discussion { nil }
    content { "MyText" }
    message_type { "MyString" }
  end
end
