FactoryBot.define do
  factory :course do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    short_introduction { Faker::Lorem.sentence }
    video_link { Faker::Internet.url }
    tags { Faker::Lorem.words(number: 3).join(', ') }
    category { Faker::Educator.subject }
    published { false }
    featured { false }

    association :instructor, factory: [ :user, :instructor ]

    trait :published do
      published { true }
    end

    trait :featured do
      featured { true }
      published { true }
    end

    trait :with_chapters do
      after(:create) do |course|
        create_list(:chapter, 3, course: course)
      end
    end

    trait :with_lessons do
      after(:create) do |course|
        create_list(:lesson, 5, course: course)
      end
    end
  end
end
