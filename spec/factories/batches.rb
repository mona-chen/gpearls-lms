FactoryBot.define do
  factory :batch do
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    additional_info { Faker::Lorem.sentence }
    start_date { 1.week.from_now }
    end_date { 8.weeks.from_now }
    start_time { Time.parse('09:00') }
    end_time { Time.parse('17:00') }
    max_students { rand(20..50) }
    published { false }

    allow_self_enrollment { true }
    category { Faker::Educator.subject }

    association :course
    association :instructor, factory: [:user, :instructor]

    trait :active do
      start_date { 1.week.ago }
      end_date { 6.weeks.from_now }
      published { true }
    end

    trait :completed do
      start_date { 10.weeks.ago }
      end_date { 2.weeks.ago }
      published { true }
    end

    trait :published do
      published { true }
    end

    trait :paid do
      price { rand(99..999) }
    end

    trait :with_enrollments do
      after(:create) do |batch|
        create_list(:batch_enrollment, 5, batch: batch)
      end
    end

    trait :with_courses do
      after(:create) do |batch|
        create_list(:batch_course, 3, batch: batch)
      end
    end
  end
end
