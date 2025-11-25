FactoryBot.define do
  factory :enrollment do
    progress_percentage { 0 }
    status { 'Active' }
    role { 'Member' }

    association :course
    association :user

    trait :completed do
      progress_percentage { 100 }
      status { 'Completed' }
    end

    trait :in_progress do
      progress_percentage { rand(1..99) }
    end
  end
end
