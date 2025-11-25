FactoryBot.define do
  factory :lesson_progress do
    progress { 100 }
    completed { false }
    status { 'Incomplete' }

    association :user
    association :lesson

    trait :completed do
      progress { 100 }
      completed { true }
      status { 'Complete' }
    end
  end
end
