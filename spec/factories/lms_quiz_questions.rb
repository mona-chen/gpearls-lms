FactoryBot.define do
  factory :lms_quiz_question do
    association :lms_quiz
    marks { 10 }
  end
end
