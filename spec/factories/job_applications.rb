FactoryBot.define do
  factory :job_application do
    job_opportunity { nil }
    user { nil }
    status { "MyString" }
  end
end
