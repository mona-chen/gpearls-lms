FactoryBot.define do
  factory :scorm_package do
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    manifest_file { 'imsmanifest.xml' }
    launch_file { 'index.html' }
    version { 'SCORM 2004' }

    association :course_lesson
    association :uploaded_by, factory: :user
  end
end