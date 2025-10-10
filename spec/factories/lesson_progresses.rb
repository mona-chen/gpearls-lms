FactoryBot.define do
  factory :lesson_progress do
    user { nil }
    lesson { nil }
    progress { 1 }
    completed { false }
    last_accessed_at { "2025-10-09 14:59:24" }
  end
end
