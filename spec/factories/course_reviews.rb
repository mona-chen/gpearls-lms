FactoryBot.define do
  factory :course_review do
    name { SecureRandom.uuid }
    association :course
    association :user

    rating { Faker::Number.between(from: 1, to: 5) }
    review { Faker::Lorem.paragraph(sentence_count: 2) }
    owner { user.email }
    modified_by { user.email }
    docstatus { "0" } # Published by default

    trait :draft do
      docstatus { "1" }
    end

    trait :cancelled do
      docstatus { "2" }
    end

    trait :with_high_rating do
      rating { 5 }
    end

    trait :with_low_rating do
      rating { 1 }
    end

    trait :without_review_text do
      review { nil }
    end
  end
end
