FactoryBot.define do
  factory :lesson, class: 'CourseLesson' do
    name { SecureRandom.uuid }
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    content { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    instructor_notes { Faker::Lorem.sentence }
    instructor_content { Faker::Lorem.paragraph }
    youtube { Faker::Internet.url }
    question { Faker::Lorem.sentence }
    file_type { 'Document' }
    include_in_preview { true }
    idx { 1 }
    owner { chapter&.course&.instructor&.email || 'test@example.com' }
    creation { Time.current }
    modified { Time.current }
    modified_by { owner }

    association :course
    association :chapter

    trait :with_quiz do
      quiz_id { create(:quiz).id }
    end

    trait :with_progress do
      after(:create) do |lesson|
        create(:course_progress, lesson: lesson, user: lesson.course.instructor, status: 'Complete')
      end
    end

    trait :not_previewable do
      include_in_preview { false }
    end

    trait :scorm_lesson do
      file_type { 'scorm' }
      content { nil }
    end
  end
end
