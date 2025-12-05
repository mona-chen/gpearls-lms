FactoryBot.define do
  factory :lms_message do
    topic { "MyString" }
    reply { "MyText" }
    author { nil }
    course { nil }
    lesson { nil }
    is_pinned { false }
    is_featured { false }
  end
end
