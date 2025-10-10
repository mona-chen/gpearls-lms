FactoryBot.define do
  factory :notification do
    user { nil }
    subject { "MyString" }
    email_content { "MyText" }
    document_type { "MyString" }
    document_name { "MyString" }
    read { false }
    link { "MyString" }
    from_user { "MyString" }
  end
end
