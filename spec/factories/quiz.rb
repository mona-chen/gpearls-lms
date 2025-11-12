FactoryBot.define do
  factory :quiz do
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    instructions { Faker::Lorem.paragraph }
    passing_score { 70 }
    max_attempts { 3 }
    time_limit { rand(1800..3600) } # 30 minutes to 1 hour
    published { false }

    association :course
    association :lesson, optional: true

    trait :published do
      published { true }
    end

    trait :with_questions do
      after(:create) do |quiz|
        create_list(:quiz_question, 5, quiz: quiz)
      end
    end

    trait :with_submissions do
      after(:create) do |quiz|
        create_list(:quiz_submission, 3, quiz: quiz, user: quiz.course.instructor)
      end
    end
  end
end
