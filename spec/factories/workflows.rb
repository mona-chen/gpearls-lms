FactoryBot.define do
  factory :workflow do
    name { "MyString" }
    document_type { "MyString" }
    is_active { false }
    states { "MyText" }
    transitions { "MyText" }
  end
end
