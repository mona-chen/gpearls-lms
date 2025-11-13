class Analytics::AdvancedAnalyticsService
  def self.generate_learning_heatmap(course, date_range = nil)
    date_range ||= 30.days.ago..Time.current
    
    # Get all lesson progress data for the course
    lesson_progresses = LessonProgress.joins(lesson: :course)
                                    .where(courses: { id: course.id })
                                    .where(created_at: date_range)
                                    .includes(:user, :lesson)
    
    # Get video watch duration data
    video_durations = VideoWatchDuration.joins(course_lesson: :course)
                                       .where(courses: { id: course.id })
                                       .where(updated_at: date_range)
                                       .includes(:user, :course_lesson)
    
    # Get quiz submission data
    quiz_submissions = QuizSubmission.joins(quiz: { course_lessons: :course })
                                    .where(courses: { id: course.id })
                                    .where(created_at: date_range)
                                    .includes(:user, :quiz)
    
    # Generate activity calendar data
    activity_calendar = generate_activity_calendar(date_range, lesson_progresses, video_durations, quiz_submissions)
    
    # Generate lesson engagement heatmap
    lesson_heatmap = generate_lesson_engagement_heatmap(course, lesson_progresses, video_durations)
    
    # Generate user engagement matrix
    user_engagement = generate_user_engagement_matrix(course, lesson_progresses, video_durations, quiz_submissions)
    
    # Generate time-based activity patterns
    activity_patterns = generate_activity_patterns(lesson_progresses, video_durations, quiz_submissions)
    
    {
      activity_calendar: activity_calendar,
      lesson_heatmap: lesson_heatmap,
      user_engagement: user_engagement,
      activity_patterns: activity_patterns,
      summary: generate_heatmap_summary(activity_calendar, lesson_heatmap, user_engagement)
    }
  end
  
  def self.get_engagement_analytics(course, timeframe = 'week')
    case timeframe
    when 'week'
      date_range = 1.week.ago..Time.current
    when 'month'
      date_range = 1.month.ago..Time.current
    when 'quarter'
      date_range = 3.months.ago..Time.current
    else
      date_range = 1.week.ago..Time.current
    end
    
    enrolled_users = course.enrollments.where(created_at: date_range).count
    active_users = get_active_users_count(course, date_range)
    completion_rate = calculate_course_completion_rate(course, date_range)
    average_progress = calculate_average_progress(course, date_range)
    
    engagement_trends = calculate_engagement_trends(course, date_range)
    lesson_popularity = calculate_lesson_popularity(course, date_range)
    learning_paths = analyze_learning_paths(course, date_range)
    
    {
      timeframe: timeframe,
      date_range: {
        start: date_range.begin,
        end: date_range.end
      },
      metrics: {
        enrolled_users: enrolled_users,
        active_users: active_users,
        engagement_rate: active_users.to_f / [enrolled_users, 1].max * 100,
        completion_rate: completion_rate,
        average_progress: average_progress
      },
      trends: engagement_trends,
      lesson_popularity: lesson_popularity,
      learning_paths: learning_paths,
      recommendations: generate_engagement_recommendations(course, engagement_trends)
    }
  end
  
  def self.get_progress_distribution_detailed(course)
    enrollments = course.enrollments.includes(:user, :lesson_progresses)
    
    # Calculate progress buckets
    progress_buckets = {
      not_started: 0,      # 0%
      just_started: 0,     # 1-10%
      getting_going: 0,    # 11-25%
      making_progress: 0,  # 26-50%
      halfway_there: 0,    # 51-75%
      almost_done: 0,      # 76-90%
      completed: 0         # 91-100%
    }
    
    user_progress_data = []
    
    enrollments.each do |enrollment|
      progress = calculate_user_progress_percentage(enrollment.user, course)
      
      user_data = {
        user_id: enrollment.user.id,
        user_email: enrollment.user.email,
        user_name: enrollment.user.full_name || enrollment.user.email,
        progress_percentage: progress,
        enrollment_date: enrollment.created_at,
        last_activity: get_last_activity_date(enrollment.user, course),
        lessons_completed: enrollment.lesson_progresses.where(status: 'Complete').count,
        total_lessons: course.course_lessons.count,
        quizzes_completed: get_completed_quizzes_count(enrollment.user, course),
        total_quizzes: get_total_quizzes_count(course)
      }
      
      user_progress_data << user_data
      
      # Categorize into buckets
      case progress
      when 0
        progress_buckets[:not_started] += 1
      when 1..10
        progress_buckets[:just_started] += 1
      when 11..25
        progress_buckets[:getting_going] += 1
      when 26..50
        progress_buckets[:making_progress] += 1
      when 51..75
        progress_buckets[:halfway_there] += 1
      when 76..90
        progress_buckets[:almost_done] += 1
      when 91..100
        progress_buckets[:completed] += 1
      end
    end
    
    # Calculate additional metrics
    average_progress = user_progress_data.sum { |u| u[:progress_percentage] } / [user_progress_data.count, 1].max
    median_progress = calculate_median(user_progress_data.map { |u| u[:progress_percentage] })
    
    {
      course_id: course.id,
      course_title: course.title,
      total_enrolled: enrollments.count,
      progress_distribution: progress_buckets,
      detailed_progress: user_progress_data.sort_by { |u| -u[:progress_percentage] },
      statistics: {
        average_progress: average_progress.round(2),
        median_progress: median_progress,
        completion_rate: (progress_buckets[:completed].to_f / [enrollments.count, 1].max * 100).round(2),
        engagement_score: calculate_engagement_score(user_progress_data)
      },
      insights: generate_progress_insights(progress_buckets, user_progress_data)
    }
  end
  
  def self.generate_learning_analytics_dashboard(course)
    # Get comprehensive analytics for the course
    basic_stats = get_basic_course_stats(course)
    engagement_data = get_engagement_analytics(course, 'month')
    progress_data = get_progress_distribution_detailed(course)
    heatmap_data = generate_learning_heatmap(course)
    
    # Performance analytics
    performance_analytics = get_performance_analytics(course)
    
    # Predictive analytics
    at_risk_students = identify_at_risk_students(course)
    success_predictors = analyze_success_predictors(course)
    
    # Recommendations
    content_recommendations = generate_content_recommendations(course)
    teaching_recommendations = generate_teaching_recommendations(course, engagement_data)
    
    {
      course_info: {
        id: course.id,
        title: course.title,
        created_at: course.created_at,
        last_updated: course.updated_at
      },
      basic_stats: basic_stats,
      engagement: engagement_data,
      progress: progress_data,
      heatmap: heatmap_data,
      performance: performance_analytics,
      predictions: {
        at_risk_students: at_risk_students,
        success_predictors: success_predictors
      },
      recommendations: {
        content: content_recommendations,
        teaching: teaching_recommendations
      },
      generated_at: Time.current
    }
  end
  
  private
  
  def self.generate_activity_calendar(date_range, lesson_progresses, video_durations, quiz_submissions)
    calendar_data = {}
    
    date_range.each do |date|
      date_key = date.strftime('%Y-%m-%d')
      
      lesson_activity = lesson_progresses.where(created_at: date.beginning_of_day..date.end_of_day).count
      video_activity = video_durations.where(updated_at: date.beginning_of_day..date.end_of_day).count
      quiz_activity = quiz_submissions.where(created_at: date.beginning_of_day..date.end_of_day).count
      
      total_activity = lesson_activity + video_activity + quiz_activity
      
      calendar_data[date_key] = {
        date: date,
        total_activity: total_activity,
        lesson_activity: lesson_activity,
        video_activity: video_activity,
        quiz_activity: quiz_activity,
        intensity: calculate_intensity_level(total_activity)
      }
    end
    
    calendar_data
  end
  
  def self.generate_lesson_engagement_heatmap(course, lesson_progresses, video_durations)
    lessons = course.course_lessons.includes(:lesson_progresses, :video_watch_durations)
    
    lessons.map do |lesson|
      completion_count = lesson.lesson_progresses.where(status: 'Complete').count
      video_engagement = lesson.video_watch_durations.average(:duration_watched) || 0
      
      {
        lesson_id: lesson.id,
        lesson_title: lesson.title,
        chapter: lesson.course_chapter&.title,
        completion_count: completion_count,
        engagement_score: calculate_lesson_engagement_score(lesson, video_engagement),
        avg_time_spent: video_engagement,
        difficulty_indicator: calculate_difficulty_indicator(lesson)
      }
    end
  end
  
  def self.generate_user_engagement_matrix(course, lesson_progresses, video_durations, quiz_submissions)
    users = course.enrolled_users.includes(:lesson_progresses, :video_watch_durations, :quiz_submissions)
    
    users.map do |user|
      user_lessons = lesson_progresses.where(user: user)
      user_videos = video_durations.where(user: user)
      user_quizzes = quiz_submissions.where(user: user)
      
      {
        user_id: user.id,
        user_email: user.email,
        total_lessons_completed: user_lessons.where(status: 'Complete').count,
        total_video_time: user_videos.sum(:duration_watched),
        total_quiz_attempts: user_quizzes.count,
        engagement_score: calculate_user_engagement_score(user_lessons, user_videos, user_quizzes),
        last_activity: [user_lessons.maximum(:updated_at), user_videos.maximum(:updated_at), user_quizzes.maximum(:created_at)].compact.max,
        consistency_score: calculate_consistency_score(user, course)
      }
    end
  end
  
  def self.generate_activity_patterns(lesson_progresses, video_durations, quiz_submissions)
    # Hourly patterns
    hourly_activity = (0..23).map do |hour|
      lesson_count = lesson_progresses.where("EXTRACT(hour FROM created_at) = ?", hour).count
      video_count = video_durations.where("EXTRACT(hour FROM updated_at) = ?", hour).count
      quiz_count = quiz_submissions.where("EXTRACT(hour FROM created_at) = ?", hour).count
      
      {
        hour: hour,
        total_activity: lesson_count + video_count + quiz_count,
        breakdown: {
          lessons: lesson_count,
          videos: video_count,
          quizzes: quiz_count
        }
      }
    end
    
    # Day of week patterns
    daily_activity = (0..6).map do |day|
      lesson_count = lesson_progresses.where("EXTRACT(dow FROM created_at) = ?", day).count
      video_count = video_durations.where("EXTRACT(dow FROM updated_at) = ?", day).count
      quiz_count = quiz_submissions.where("EXTRACT(dow FROM created_at) = ?", day).count
      
      {
        day: Date::DAYNAMES[day],
        total_activity: lesson_count + video_count + quiz_count,
        breakdown: {
          lessons: lesson_count,
          videos: video_count,
          quizzes: quiz_count
        }
      }
    end
    
    {
      hourly_patterns: hourly_activity,
      daily_patterns: daily_activity,
      peak_hours: hourly_activity.max_by { |h| h[:total_activity] },
      peak_days: daily_activity.max_by { |d| d[:total_activity] }
    }
  end
  
  def self.calculate_intensity_level(activity_count)
    case activity_count
    when 0
      'none'
    when 1..5
      'low'
    when 6..15
      'medium'
    when 16..30
      'high'
    else
      'very_high'
    end
  end
  
  def self.calculate_lesson_engagement_score(lesson, avg_video_time)
    completion_rate = lesson.lesson_progresses.where(status: 'Complete').count.to_f / [lesson.lesson_progresses.count, 1].max
    video_engagement = avg_video_time / [lesson.video_watch_durations.maximum(:video_length) || 1, 1].max
    
    (completion_rate * 0.6 + video_engagement * 0.4) * 100
  end
  
  def self.calculate_user_engagement_score(lessons, videos, quizzes)
    lesson_score = lessons.where(status: 'Complete').count * 10
    video_score = videos.sum(:duration_watched) / 60.0 # minutes
    quiz_score = quizzes.count * 5
    
    [lesson_score + video_score + quiz_score, 100].min
  end
  
  def self.calculate_consistency_score(user, course)
    # Calculate how consistently the user engages with the course
    activities = []
    
    # Get all activity dates
    user.lesson_progresses.where(lesson: course.course_lessons).pluck(:created_at).each { |date| activities << date.to_date }
    user.video_watch_durations.joins(:course_lesson).where(course_lessons: { course: course }).pluck(:updated_at).each { |date| activities << date.to_date }
    
    return 0 if activities.empty?
    
    unique_days = activities.uniq.count
    date_range = (activities.min..activities.max).count
    
    return 100 if date_range <= 1
    
    (unique_days.to_f / date_range * 100).round(2)
  end
  
  def self.calculate_median(numbers)
    return 0 if numbers.empty?
    
    sorted = numbers.sort
    len = sorted.length
    
    if len.odd?
      sorted[len / 2]
    else
      (sorted[len / 2 - 1] + sorted[len / 2]) / 2.0
    end
  end
  
  def self.get_basic_course_stats(course)
    {
      total_enrollments: course.enrollments.count,
      total_lessons: course.course_lessons.count,
      total_quizzes: course.quizzes.count,
      average_rating: course.course_reviews.average(:rating) || 0,
      total_reviews: course.course_reviews.count
    }
  end
  
  def self.identify_at_risk_students(course)
    # Students who haven't engaged recently or are falling behind
    enrollments = course.enrollments.includes(:user, :lesson_progresses)
    
    at_risk = []
    
    enrollments.each do |enrollment|
      user = enrollment.user
      progress = calculate_user_progress_percentage(user, course)
      last_activity = get_last_activity_date(user, course)
      
      # Risk factors
      low_progress = progress < 25
      inactive = last_activity.nil? || last_activity < 1.week.ago
      behind_schedule = calculate_behind_schedule(enrollment, course)
      
      if low_progress || inactive || behind_schedule
        risk_score = calculate_risk_score(progress, last_activity, behind_schedule)
        
        at_risk << {
          user_id: user.id,
          user_email: user.email,
          progress_percentage: progress,
          last_activity: last_activity,
          risk_score: risk_score,
          risk_factors: {
            low_progress: low_progress,
            inactive: inactive,
            behind_schedule: behind_schedule
          },
          recommended_actions: generate_intervention_recommendations(risk_score, low_progress, inactive)
        }
      end
    end
    
    at_risk.sort_by { |student| -student[:risk_score] }
  end
  
  def self.generate_progress_insights(progress_buckets, user_progress_data)
    insights = []
    
    total_users = user_progress_data.count
    return insights if total_users.zero?
    
    # Completion insights
    completion_rate = (progress_buckets[:completed].to_f / total_users * 100).round(2)
    
    if completion_rate < 20
      insights << {
        type: 'warning',
        title: 'Low Completion Rate',
        message: "Only #{completion_rate}% of students have completed the course. Consider reviewing course difficulty or providing additional support.",
        priority: 'high'
      }
    elsif completion_rate > 80
      insights << {
        type: 'success',
        title: 'Excellent Completion Rate',
        message: "#{completion_rate}% completion rate indicates well-structured content and good student engagement.",
        priority: 'info'
      }
    end
    
    # Progress distribution insights
    stuck_students = progress_buckets[:just_started] + progress_buckets[:getting_going]
    if stuck_students.to_f / total_users > 0.4
      insights << {
        type: 'warning',
        title: 'Many Students Struggling Early',
        message: "#{(stuck_students.to_f / total_users * 100).round}% of students seem to be stuck in early stages. Consider improving onboarding or early content.",
        priority: 'medium'
      }
    end
    
    insights
  end
  
  # Additional helper methods would continue here...
  # (Methods for performance analytics, predictive analytics, recommendations, etc.)
end