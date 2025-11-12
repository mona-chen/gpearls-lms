FactoryBot.define do
  factory :batch_course do
    title { Faker::Lorem.words(number: 3).join(" ").titleize }
    position { rand(1..10) }

    association :batch
    association :course
    association :evaluator, factory: [:user, :evaluator], optional: true

    trait :with_position do
      position { 1 }
    end

    trait :with_evaluator do
      association :evaluator, factory: [:user, :evaluator]
    end
  end
end
