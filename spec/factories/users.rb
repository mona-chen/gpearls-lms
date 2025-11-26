FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    profile_image { Faker::Internet.url }

    password { "Password123!" }
    password_confirmation { "Password123!" }

    after(:build) do |user|
      # Assign default student role immediately for both build and create
      user.has_roles << HasRole.new(role: "LMS Student", user: user)
      user.role = "LMS Student"
    end

    trait :instructor do
      after(:build) do |user|
        # Clear default roles and assign instructor role
        user.has_roles.clear
        user.has_roles << HasRole.new(role: "Course Creator", user: user)
        user.role = "Course Creator"
      end
    end

    trait :moderator do
      after(:build) do |user|
        # Clear default roles and assign moderator role
        user.has_roles.clear
        user.has_roles << HasRole.new(role: "Moderator", user: user)
        user.role = "Moderator"
      end
    end

    trait :evaluator do
      after(:build) do |user|
        # Clear default roles and assign evaluator role
        user.has_roles.clear
        user.has_roles << HasRole.new(role: "Batch Evaluator", user: user)
        user.role = "Batch Evaluator"
      end
    end

    trait :student do
      # Default user is already a student, so no changes needed
    end
  end
end
