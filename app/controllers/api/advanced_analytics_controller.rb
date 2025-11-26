class Api::AdvancedAnalyticsController < Api::BaseController
  before_action :authenticate_user!
  before_action :require_analytics_permission
  before_action :find_course, except: [ :system_analytics, :user_analytics ]

  # GET /api/advanced-analytics/learning-heatmap/:course_id
  def learning_heatmap
    date_range = parse_date_range(params[:date_range])

    heatmap_data = Analytics::AdvancedAnalyticsService.generate_learning_heatmap(@course, date_range)

    render json: {
      course_id: @course.id,
      course_title: @course.title,
      date_range: {
        start: date_range.begin,
        end: date_range.end
      },
      heatmap: heatmap_data,
      generated_at: Time.current
    }
  end

  # GET /api/advanced-analytics/engagement/:course_id
  def engagement_analytics
    timeframe = params[:timeframe] || "week"

    engagement_data = Analytics::AdvancedAnalyticsService.get_engagement_analytics(@course, timeframe)

    render json: engagement_data
  end

  # GET /api/advanced-analytics/progress-distribution/:course_id
  def progress_distribution
    distribution_data = Analytics::AdvancedAnalyticsService.get_progress_distribution_detailed(@course)

    render json: distribution_data
  end

  # GET /api/advanced-analytics/dashboard/:course_id
  def analytics_dashboard
    dashboard_data = Analytics::AdvancedAnalyticsService.generate_learning_analytics_dashboard(@course)

    render json: dashboard_data
  end

  # GET /api/advanced-analytics/predictive/:course_id
  def predictive_analytics
    # Get predictive insights for course performance
    at_risk_students = Analytics::AdvancedAnalyticsService.identify_at_risk_students(@course)
    success_predictors = analyze_success_predictors(@course)
    completion_predictions = generate_completion_predictions(@course)

    render json: {
      course_id: @course.id,
      at_risk_students: at_risk_students,
      success_predictors: success_predictors,
      completion_predictions: completion_predictions,
      recommendations: generate_predictive_recommendations(@course, at_risk_students),
      generated_at: Time.current
    }
  end

  # GET /api/advanced-analytics/learning-patterns/:course_id
  def learning_patterns
    # Analyze learning patterns and behaviors
    patterns = analyze_learning_patterns(@course)

    render json: {
      course_id: @course.id,
      learning_patterns: patterns,
      insights: generate_pattern_insights(patterns),
      generated_at: Time.current
    }
  end

  # GET /api/advanced-analytics/content-effectiveness/:course_id
  def content_effectiveness
    # Analyze which content is most/least effective
    effectiveness_data = analyze_content_effectiveness(@course)

    render json: {
      course_id: @course.id,
      content_analysis: effectiveness_data,
      recommendations: generate_content_recommendations(effectiveness_data),
      generated_at: Time.current
    }
  end

  # GET /api/advanced-analytics/system-analytics
  def system_analytics
    unless current_user.admin? || current_user.has_role?(:system_admin)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    system_data = {
      total_users: User.count,
      total_courses: Course.count,
      total_enrollments: Enrollment.count,
      active_users_today: get_active_users_count(Date.current),
      active_users_week: get_active_users_count(1.week.ago..Time.current),
      popular_courses: get_popular_courses,
      system_performance: get_system_performance_metrics,
      growth_metrics: get_growth_metrics,
      engagement_trends: get_system_engagement_trends
    }

    render json: system_data
  end

  # GET /api/advanced-analytics/user-journey/:course_id
  def user_journey_analysis
    # Analyze how users move through the course
    journey_data = analyze_user_journeys(@course)

    render json: {
      course_id: @course.id,
      journey_analysis: journey_data,
      common_paths: identify_common_learning_paths(@course),
      drop_off_points: identify_drop_off_points(@course),
      optimization_suggestions: suggest_journey_optimizations(journey_data),
      generated_at: Time.current
    }
  end

  # GET /api/advanced-analytics/real-time/:course_id
  def real_time_analytics
    # Real-time course activity
    real_time_data = {
      active_users_now: get_currently_active_users(@course),
      recent_activities: get_recent_course_activities(@course),
      live_sessions: get_live_sessions(@course),
      current_engagement_score: calculate_current_engagement(@course)
    }

    render json: real_time_data
  end

  # POST /api/advanced-analytics/custom-report
  def generate_custom_report
    report_params = params[:report_config] || {}

    begin
      custom_report = generate_custom_analytics_report(@course, report_params)

      render json: {
        report_id: SecureRandom.uuid,
        course_id: @course.id,
        report_data: custom_report,
        generated_at: Time.current,
        expires_at: 24.hours.from_now
      }
    rescue => e
      Rails.logger.error "Custom report generation error: #{e.message}"
      render json: { error: "Failed to generate custom report" }, status: :internal_server_error
    end
  end

  # GET /api/advanced-analytics/export/:course_id
  def export_analytics
    format = params[:format] || "json"

    case format.downcase
    when "csv"
      csv_data = generate_analytics_csv(@course)
      send_data csv_data, filename: "course_#{@course.id}_analytics.csv", type: "text/csv"
    when "xlsx"
      xlsx_data = generate_analytics_xlsx(@course)
      send_data xlsx_data, filename: "course_#{@course.id}_analytics.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else
      dashboard_data = Analytics::AdvancedAnalyticsService.generate_learning_analytics_dashboard(@course)
      render json: dashboard_data
    end
  end

  private

  def require_analytics_permission
    unless current_user.admin? || current_user.has_role?(:analytics_viewer) || can_view_course_analytics?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def can_view_course_analytics?
    return false unless @course

    @course.instructors.include?(current_user) ||
    @course.course_evaluators.exists?(user: current_user)
  end

  def find_course
    @course = Course.find(params[:course_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Course not found" }, status: :not_found
  end

  def parse_date_range(date_range_param)
    case date_range_param
    when "week"
      1.week.ago..Time.current
    when "month"
      1.month.ago..Time.current
    when "quarter"
      3.months.ago..Time.current
    when "year"
      1.year.ago..Time.current
    else
      30.days.ago..Time.current
    end
  end

  def analyze_success_predictors(course)
    # Analyze what factors correlate with course success
    successful_students = course.enrollments.joins(:lesson_progresses)
                               .where(lesson_progresses: { status: "Complete" })
                               .group(:user_id)
                               .having("COUNT(lesson_progresses.id) >= ?", course.course_lessons.count * 0.8)
                               .pluck(:user_id)

    all_students = course.enrolled_users.pluck(:id)

    # Analyze patterns in successful vs unsuccessful students
    success_factors = {
      early_engagement: analyze_early_engagement_correlation(successful_students, all_students),
      consistency: analyze_consistency_correlation(successful_students, all_students),
      video_completion: analyze_video_completion_correlation(successful_students, all_students, course),
      quiz_performance: analyze_quiz_performance_correlation(successful_students, all_students, course)
    }

    success_factors
  end

  def generate_completion_predictions(course)
    # Predict likely completion based on current progress patterns
    enrollments = course.enrollments.includes(:user, :lesson_progresses)

    predictions = enrollments.map do |enrollment|
      user = enrollment.user
      current_progress = calculate_user_progress_percentage(user, course)
      engagement_score = calculate_user_engagement_score_for_course(user, course)

      # Simple prediction model (in practice, you'd use ML models)
      completion_probability = predict_completion_probability(current_progress, engagement_score, enrollment)

      {
        user_id: user.id,
        user_email: user.email,
        current_progress: current_progress,
        completion_probability: completion_probability,
        predicted_completion_date: predict_completion_date(enrollment, current_progress),
        risk_level: categorize_risk_level(completion_probability)
      }
    end

    predictions.sort_by { |p| -p[:completion_probability] }
  end

  def analyze_learning_patterns(course)
    # Analyze how students learn - when, what order, what works best
    patterns = {
      temporal_patterns: analyze_temporal_learning_patterns(course),
      sequence_patterns: analyze_learning_sequence_patterns(course),
      content_preferences: analyze_content_preference_patterns(course),
      difficulty_progression: analyze_difficulty_progression_patterns(course)
    }

    patterns
  end

  def analyze_content_effectiveness(course)
    lessons = course.course_lessons.includes(:lesson_progresses, :video_watch_durations)

    effectiveness_data = lessons.map do |lesson|
      completion_rate = calculate_lesson_completion_rate(lesson)
      engagement_score = calculate_lesson_engagement_score(lesson)
      difficulty_score = calculate_lesson_difficulty_score(lesson)

      {
        lesson_id: lesson.id,
        lesson_title: lesson.title,
        completion_rate: completion_rate,
        engagement_score: engagement_score,
        difficulty_score: difficulty_score,
        effectiveness_rating: calculate_overall_effectiveness(completion_rate, engagement_score, difficulty_score),
        improvement_suggestions: suggest_lesson_improvements(lesson, completion_rate, engagement_score)
      }
    end

    effectiveness_data.sort_by { |data| -data[:effectiveness_rating] }
  end

  def analyze_user_journeys(course)
    # Track common paths users take through the course
    enrollments = course.enrollments.includes(:lesson_progresses)

    journeys = enrollments.map do |enrollment|
      user_path = enrollment.lesson_progresses
                            .joins(:lesson)
                            .order(:created_at)
                            .pluck("course_lessons.title", :created_at, :status)

      {
        user_id: enrollment.user_id,
        path: user_path,
        completion_time: calculate_journey_completion_time(user_path),
        stuck_points: identify_user_stuck_points(user_path),
        success_rate: calculate_journey_success_rate(user_path)
      }
    end

    journeys
  end

  def get_currently_active_users(course)
    # Users active in the last 5 minutes
    active_threshold = 5.minutes.ago

    course.enrolled_users
          .joins("LEFT JOIN lesson_progresses ON lesson_progresses.user_id = users.id")
          .joins("LEFT JOIN video_watch_durations ON video_watch_durations.user_id = users.id")
          .where("lesson_progresses.updated_at > ? OR video_watch_durations.updated_at > ?",
                 active_threshold, active_threshold)
          .distinct
          .count
  end

  def get_recent_course_activities(course)
    # Get recent activities in the course
    recent_activities = []

    # Recent lesson completions
    recent_lessons = LessonProgress.joins(lesson: :course)
                                  .where(courses: { id: course.id })
                                  .where(created_at: 1.hour.ago..Time.current)
                                  .includes(:user, :lesson)
                                  .order(created_at: :desc)
                                  .limit(10)

    recent_lessons.each do |progress|
      recent_activities << {
        type: "lesson_completion",
        user_email: progress.user.email,
        lesson_title: progress.lesson.title,
        timestamp: progress.created_at
      }
    end

    # Recent quiz submissions
    recent_quizzes = QuizSubmission.joins(quiz: { course_lessons: :course })
                                  .where(courses: { id: course.id })
                                  .where(created_at: 1.hour.ago..Time.current)
                                  .includes(:user, :quiz)
                                  .order(created_at: :desc)
                                  .limit(10)

    recent_quizzes.each do |submission|
      recent_activities << {
        type: "quiz_submission",
        user_email: submission.user.email,
        quiz_title: submission.quiz.title,
        score: submission.score,
        timestamp: submission.created_at
      }
    end

    recent_activities.sort_by { |activity| -activity[:timestamp].to_i }.first(20)
  end

  def generate_analytics_csv(course)
    require "csv"

    CSV.generate do |csv|
      csv << [ "User Email", "Progress %", "Lessons Completed", "Quizzes Completed", "Last Activity" ]

      course.enrollments.includes(:user, :lesson_progresses).each do |enrollment|
        user = enrollment.user
        progress = calculate_user_progress_percentage(user, course)
        lessons_completed = enrollment.lesson_progresses.where(status: "Complete").count
        quizzes_completed = get_completed_quizzes_count(user, course)
        last_activity = get_last_activity_date(user, course)

        csv << [ user.email, progress, lessons_completed, quizzes_completed, last_activity ]
      end
    end
  end

  # Additional helper methods would continue here...
end
