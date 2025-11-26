FactoryBot.define do
  factory :certificate_request do
    status { 'Pending' }
    date { Date.today + 1.week }
    start_time { Time.parse('10:00') }
    end_time { Time.parse('12:00') }
    rating { nil }
    summary { nil }
    batch_name { nil }

    association :user
    association :course
    association :evaluator, factory: [ :user, :evaluator ], optional: true

    trait :pending do
      status { 'Pending' }
    end

    trait :upcoming do
      status { 'Upcoming' }
      date { Date.today + 3.days }
      start_time { Time.parse('14:00') }
      end_time { Time.parse('16:00') }
    end

    trait :completed do
      status { 'Completed' }
      date { Date.today - 1.week }
      rating { rand(3.0..5.0).round(2) }
      summary { Faker::Lorem.paragraph(sentence_count: 3) }
    end

    trait :cancelled do
      status { 'Cancelled' }
      date { Date.today - 2.days }
    end

    trait :with_rating do
      rating { rand(3.0..5.0).round(2) }
      summary { Faker::Lorem.paragraph(sentence_count: 2) }
    end

    trait :for_student do
      association :user, factory: [ :user, :student ]
    end

    trait :with_batch do
      batch_name { "Batch #{Faker::Number.number(digits: 4)}" }
    end

    trait :past_evaluation do
      date { Date.today - 1.month }
      start_time { Time.parse('09:00') }
      end_time { Time.parse('11:00') }
      status { 'Completed' }
      rating { rand(3.0..5.0).round(2) }
      summary { "Evaluation completed successfully. #{Faker::Lorem.sentence}" }
    end
  end
end
