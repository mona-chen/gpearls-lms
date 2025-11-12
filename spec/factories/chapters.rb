FactoryBot.define do
  factory :chapter, class: 'CourseChapter' do
    name { SecureRandom.uuid }
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    idx { 1 }
    owner { course.instructor&.email || 'test@example.com' }
    creation { Time.current }
    modified { Time.current }
    modified_by { owner }
    is_scorm_package { false }
    scorm_package_path { nil }
    manifest_file { nil }
    launch_file { nil }

    association :course

    trait :with_lessons do
      after(:create) do |chapter|
        create_list(:lesson, 3, chapter: chapter, course: chapter.course)
      end
    end

    trait :scorm do
      is_scorm_package { true }
      scorm_package_path { '/path/to/scorm' }
      manifest_file { 'imsmanifest.xml' }
      launch_file { 'index.html' }
    end
  end
end
