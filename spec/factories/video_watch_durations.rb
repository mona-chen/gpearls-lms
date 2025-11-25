FactoryBot.define do
  factory :video_watch_duration do
    video_url { 'https://example.com/video.mp4' }
    duration_watched { rand(60..300) } # 1 to 5 minutes
    video_length { 600 } # 10 minutes
    last_watched_at { Time.current }

    association :user
    association :course_lesson
  end
end