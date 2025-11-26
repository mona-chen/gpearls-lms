FactoryBot.define do
  factory :course_lesson do
    name { SecureRandom.uuid }
    owner { 'test@example.com' }
    creation { Time.current }
    modified { Time.current }
    modified_by { owner }
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    body { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    content { Faker::Lorem.paragraph }
    idx { 1 }
    include_in_preview { true }

    association :course
    association :chapter, factory: :course_chapter
  end
end
