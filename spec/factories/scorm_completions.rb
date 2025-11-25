FactoryBot.define do
  factory :scorm_completion do
    score_raw { rand(0..100) }
    score_max { 100 }
    score_min { 0 }
    total_time { rand(300..3600) } # 5 minutes to 1 hour
    session_time { rand(60..600) } # 1 to 10 minutes
    completion_status { :incomplete }
    success_status { :unknown }

    association :user
    association :scorm_package
    association :course_lesson
  end
end
