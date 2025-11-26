FactoryBot.define do
  factory :live_class do
    name { "Live Class #{Faker::Number.number(digits: 6)}" }
    title { Faker::Educator.subject }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    date { Date.today + rand(1..14).days }
    time { Time.parse("#{rand(9..18)}:00") }
    duration { "#{rand(1..3)} hours" }
    attendees { [] }
    start_url { Faker::Internet.url }
    join_url { Faker::Internet.url }
    owner { Faker::Internet.email }

    association :batch
    association :course
    association :instructor, factory: [ :user, :instructor ]

    trait :upcoming do
      date { Date.today + rand(1..30).days }
    end

    trait :today do
      date { Date.today }
    end

    trait :past do
      date { Date.today - rand(1..30).days }
    end

    trait :with_attendees do
      after(:build) do |live_class|
        live_class.attendees = Array.new(rand(1..10)) { Faker::Internet.email }
      end
    end

    trait :for_student do
      association :instructor, factory: [ :user, :student ]
    end

    trait :with_zoom do
      start_url { "https://zoom.us/j/#{SecureRandom.hex(8)}" }
      join_url { "https://zoom.us/j/#{SecureRandom.hex(8)}" }
    end

    trait :short_duration do
      duration { "1 hour" }
    end

    trait :long_duration do
      duration { "3 hours" }
    end

    trait :morning_time do
      time { Time.parse("#{rand(9..12)}:00") }
    end

    trait :afternoon_time do
      time { Time.parse("#{rand(13..17)}:00") }
    end

    trait :evening_time do
      time { Time.parse("#{rand(18..21)}:00") }
    end
  end
end
