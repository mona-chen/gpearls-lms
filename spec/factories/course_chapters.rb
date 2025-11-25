FactoryBot.define do
  factory :course_chapter do
    name { SecureRandom.uuid }
    owner { 'test@example.com' }
    creation { Time.current }
    modified { Time.current }
    modified_by { owner }
    title { Faker::Lorem.words(number: 2).join(' ').titleize }
    idx { 1 }

    association :course
  end
end