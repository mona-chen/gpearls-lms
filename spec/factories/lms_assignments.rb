FactoryBot.define do
  factory :lms_assignment do
    title { Faker::Lorem.sentence }
    course
    description { Faker::Lorem.paragraph }
    total_marks { 100.0 }
    passing_percentage { 70.0 }
    status { 'Published' }
    assignment_type { 'Submission' }
    due_date { 1.week.from_now }
  end
end
