FactoryBot.define do
  factory :lms_programming_exercise do
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    problem_statement { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    language { 'Python' }
    name { SecureRandom.uuid }
  end
end
