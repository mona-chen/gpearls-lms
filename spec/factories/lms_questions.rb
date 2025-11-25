FactoryBot.define do
  factory :lms_question do
    question { Faker::Lorem.question }
    type { "Choices" }

    # Choice options
    option_1 { "Option 1" }
    option_2 { "Option 2" }
    option_3 { "Option 3" }
    option_4 { "Option 4" }
    is_correct_1 { true }
    is_correct_2 { false }
    is_correct_3 { false }
    is_correct_4 { false }

    transient do
      quiz { nil }
      marks { 10 }
      question_type { nil }
    end

    after(:build) do |question, evaluator|
      question.quiz = evaluator.quiz
      question.marks = evaluator.marks

      if evaluator.question_type == 'User Input' || question.type == 'User Input'
        question.type = 'User Input'
        question.possibility_1 = 'Answer 1'
        question.possibility_2 = 'Answer 2'
        # Clear choice options
        question.option_1 = nil
        question.option_2 = nil
        question.option_3 = nil
        question.option_4 = nil
        question.is_correct_1 = nil
        question.is_correct_2 = nil
        question.is_correct_3 = nil
        question.is_correct_4 = nil
      end
    end

    trait :multiple_choice do
      is_correct_1 { true }
      is_correct_2 { true }
      is_correct_3 { false }
      is_correct_4 { false }
      multiple { true }
    end

    trait :user_input do
      type { "User Input" }
      possibility_1 { "Answer 1" }
      possibility_2 { "Answer 2" }
      option_1 { nil }
      option_2 { nil }
      option_3 { nil }
      option_4 { nil }
      is_correct_1 { nil }
      is_correct_2 { nil }
      is_correct_3 { nil }
      is_correct_4 { nil }
    end

    trait :open_ended do
      type { "Open Ended" }
      option_1 { nil }
      option_2 { nil }
      option_3 { nil }
      option_4 { nil }
      is_correct_1 { nil }
      is_correct_2 { nil }
      is_correct_3 { nil }
      is_correct_4 { nil }
    end
  end
end
