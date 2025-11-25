FactoryBot.define do
  factory :code_revision do
    code { 'print("Hello World")' }
    section_id { "exercise_1" }
    section_type { 'LmsProgrammingExercise' }

    association :user
  end
end
