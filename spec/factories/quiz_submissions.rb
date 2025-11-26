FactoryBot.define do
  factory :quiz_submission, class: 'LmsQuizSubmission' do
    submission_code { "SUB#{rand(10000..99999)}" }
    attempt_number { 1 }
    percentage { rand(0..100) }
    total_marks { 100 }

    association :member, factory: :user
    association :quiz

  trait :passed do
    percentage { rand(70..100) }
  end

  trait :failed do
    percentage { rand(0..69) }
  end

  trait :perfect_score do
    percentage { 100.0 }
  end

  trait :high_score do
    percentage { rand(90..99) }
  end

  trait :low_score do
    percentage { rand(0..30) }
  end

    trait :with_course do
      association :course, :published
    end

    trait :recent do
      created_at { Time.current - rand(1..7).days }
    end

    trait :old do
      created_at { Time.current - rand(30..90).days }
    end

    trait :for_student do
      association :user, factory: [ :user, :student ]
    end

    trait :graded do
      after(:build) do |submission|
        submission.quiz_title = "#{submission.quiz&.title || 'Quiz'} - #{submission.created_at.strftime('%B %d, %Y')}"
      end
    end
  end
end
