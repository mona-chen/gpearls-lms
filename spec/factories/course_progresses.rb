FactoryBot.define do
  factory :course_progress do
    status { 'Incomplete' }

    association :user
    association :course
    association :lesson

    trait :complete do
      status { 'Complete' }
    end

    trait :incomplete do
      status { 'Incomplete' }
    end

    trait :for_student do
      association :user, factory: [ :user, :student ]
    end

    trait :for_instructor do
      association :user, factory: [ :user, :instructor ]
    end
  end
end
