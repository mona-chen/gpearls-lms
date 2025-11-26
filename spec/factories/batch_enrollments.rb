FactoryBot.define do
  factory :batch_enrollment do
    created_at { Time.current }

    association :batch
    association :user, factory: [ :user, :student ]

    trait :completed do
      created_at { Time.current }
    end

    trait :dropped do
      created_at { Time.current }
    end

    trait :with_progress do
      after(:create) do |batch_enrollment|
        batch_enrollment.batch.courses.each do |course|
          create(:enrollment, user: batch_enrollment.user, course: course, status: 'In Progress')
        end
      end
    end
  end
end
