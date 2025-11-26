class Api::VideoAnalyticsController < Api::BaseController
  before_action :authenticate_user!

  # POST /api/track-video-duration
  def track_duration
    lesson_id = params[:lesson_id]
    video_url = params[:video_url]
    duration_watched = params[:duration_watched].to_i
    video_length = params[:video_length].to_i
    current_position = params[:current_position].to_i

    return render json: { error: "Missing required parameters" }, status: :bad_request unless
      lesson_id && video_url && duration_watched && video_length

    begin
      lesson = CourseLesson.find(lesson_id)

      duration_record = VideoWatchDuration.track_duration(
        current_user,
        lesson,
        video_url,
        duration_watched,
        video_length
      )

      # Also update lesson progress if video is completed
      if duration_record.completed?
        update_lesson_progress(lesson, current_user)
      end

      render json: {
        success: true,
        progress_percentage: duration_record.progress_percentage,
        completed: duration_record.completed?,
        message: "Video progress tracked"
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Lesson not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Video tracking error: #{e.message}"
      render json: { error: "Failed to track video duration" }, status: :internal_server_error
    end
  end

  # GET /api/video-analytics/:lesson_id
  def lesson_analytics
    lesson = CourseLesson.find(params[:lesson_id])

    # Check if user has permission to view analytics
    unless can_view_analytics?(lesson, current_user)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    analytics = VideoWatchDuration.get_analytics_for_lesson(lesson)

    render json: {
      lesson_id: lesson.id,
      lesson_title: lesson.title,
      analytics: analytics,
      detailed_stats: get_detailed_stats(lesson)
    }
  end

  # GET /api/my-video-progress/:lesson_id
  def my_progress
    lesson = CourseLesson.find(params[:lesson_id])

    duration_records = VideoWatchDuration.where(
      user: current_user,
      course_lesson: lesson
    )

    total_duration_watched = duration_records.sum(:duration_watched)
    videos_completed = duration_records.select(&:completed?).count
    total_videos = duration_records.count

    render json: {
      lesson_id: lesson.id,
      total_duration_watched: total_duration_watched,
      videos_completed: videos_completed,
      total_videos: total_videos,
      completion_percentage: total_videos > 0 ? (videos_completed.to_f / total_videos * 100).round(2) : 0,
      video_progress: duration_records.map do |record|
        {
          video_url: record.video_url,
          progress_percentage: record.progress_percentage,
          completed: record.completed?,
          last_position: record.last_position,
          last_watched: record.updated_at
        }
      end
    }
  end

  # GET /api/video-heatmap/:course_id
  def course_video_heatmap
    course = Course.find(params[:course_id])

    unless can_view_analytics?(course, current_user)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    lessons = course.course_lessons.includes(:video_watch_durations)

    heatmap_data = lessons.map do |lesson|
      analytics = VideoWatchDuration.get_analytics_for_lesson(lesson)
      {
        lesson_id: lesson.id,
        lesson_title: lesson.title,
        total_views: analytics[:total_views],
        unique_viewers: analytics[:unique_viewers],
        completion_rate: analytics[:completion_rate],
        average_completion: analytics[:average_completion]
      }
    end

    render json: {
      course_id: course.id,
      course_title: course.title,
      heatmap_data: heatmap_data,
      summary: calculate_course_summary(heatmap_data)
    }
  end

  private

  def update_lesson_progress(lesson, user)
    # Update or create lesson progress
    progress = LessonProgress.find_or_create_by(
      user: user,
      lesson: lesson
    ) do |p|
      p.status = "Complete"
      p.progress = 100
    end

    unless progress.status == "Complete"
      progress.update!(status: "Complete", progress: 100)
    end
  end

  def can_view_analytics?(resource, user)
    # Check if user is instructor, admin, or has analytics permission
    return true if user.admin?

    case resource
    when CourseLesson
      resource.course.instructors.include?(user) || user.has_role?(:analytics_viewer)
    when Course
      resource.instructors.include?(user) || user.has_role?(:analytics_viewer)
    else
      false
    end
  end

  def get_detailed_stats(lesson)
    durations = lesson.video_watch_durations.includes(:user)

    {
      engagement_distribution: calculate_engagement_distribution(durations),
      daily_activity: calculate_daily_activity(durations),
      top_viewers: get_top_viewers(durations)
    }
  end

  def calculate_engagement_distribution(durations)
    total = durations.count
    return {} if total.zero?

    {
      not_started: durations.where(duration_watched: 0).count,
      low_engagement: durations.where("duration_watched > 0 AND duration_watched < video_length * 0.25").count,
      medium_engagement: durations.where("duration_watched >= video_length * 0.25 AND duration_watched < video_length * 0.75").count,
      high_engagement: durations.where("duration_watched >= video_length * 0.75 AND duration_watched < video_length * 0.9").count,
      completed: durations.where("duration_watched >= video_length * 0.9").count
    }
  end

  def calculate_daily_activity(durations)
    durations.group("DATE(updated_at)").count
  end

  def get_top_viewers(durations)
    durations.joins(:user)
             .group("users.id, users.email")
             .order("SUM(duration_watched) DESC")
             .limit(10)
             .sum(:duration_watched)
             .map { |k, v| { user: k[1], total_watched: v } }
  end

  def calculate_course_summary(heatmap_data)
    return {} if heatmap_data.empty?

    {
      total_lessons: heatmap_data.count,
      average_completion_rate: (heatmap_data.sum { |d| d[:completion_rate] } / heatmap_data.count).round(2),
      total_unique_viewers: heatmap_data.sum { |d| d[:unique_viewers] },
      total_views: heatmap_data.sum { |d| d[:total_views] }
    }
  end
end
