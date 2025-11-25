FactoryBot.define do
  factory :quiz, class: LmsQuiz do
    name { Faker::Lorem.words(number: 2).join('_').downcase }
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    passing_percentage { 70.0 }
    max_attempts { 3 }
    duration_minutes { 60 }
    status { "Draft" }
    quiz_type { "Graded" }
    total_marks { 100.0 }

    association :course
    association :creator, factory: :user

    trait :published do
      status { "Published" }
    end
  end
end
