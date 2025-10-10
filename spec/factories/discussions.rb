FactoryBot.define do
  factory :discussion do
    user { nil }
    course { nil }
    title { "MyString" }
    content { "MyString" }
    status { "MyString" }
  end
end
