FactoryBot.define do
  factory :user do
    username { Faker::Internet.username(specifier: 6..20) }
    email { Faker::Internet.email }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    full_name { Faker::Name.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    profile_image { Faker::Internet.url }
    role { "LMS Student" }

    trait :instructor do
      role { "Course Creator" }
    end

    trait :moderator do
      role { "Moderator" }
    end

    trait :evaluator do
      role { "Batch Evaluator" }
    end
  end
end
