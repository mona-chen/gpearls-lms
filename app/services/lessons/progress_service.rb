# frozen_string_literal: true

class Lessons::ProgressService
  def self.mark(course_id, chapter_id, lesson_id, user)
    return { error: "User not authenticated" } unless user
    return { error: "Lesson not found" } unless lesson_id

    lesson = Lesson.find_by(id: lesson_id)
    return { error: "Lesson not found" } unless lesson

    # Check if user is enrolled in the course
    unless user.enrollments.exists?(course_id: course_id)
      return { error: "User not enrolled in this course" }
    end

    # Find or create lesson progress
    progress = LessonProgress.find_or_initialize_by(
      user: user,
      lesson: lesson
    )

    # Calculate progress based on lesson completion criteria
    new_progress = calculate_lesson_progress(lesson, user)

    progress.update!(
      progress: new_progress,
      completed: new_progress >= 100,
      completed_at: new_progress >= 100 ? Time.current : nil,
      started_at: progress.started_at || Time.current
    )

    # Update course progress
    update_course_progress(user, lesson.course)

    {
      success: true,
      progress: new_progress,
      completed: new_progress >= 100,
      lesson_id: lesson_id,
      message: new_progress >= 100 ? "Lesson completed!" : "Progress updated"
    }
  rescue => e
    {
      error: "Failed to update progress",
      details: e.message
    }
  end

  def self.get_user_progress(user, course_id = nil)
    return { error: "User not authenticated" } unless user

    lessons_query = LessonProgress.includes(:lesson, :user)
    lessons_query = lessons_query.where(user: user)
    lessons_query = lessons_query.joins(:lesson).where(lessons: { course_id: course_id }) if course_id

    progress_data = lessons_query.map do |progress|
      {
        lesson_id: progress.lesson_id,
        lesson_title: progress.lesson&.title,
        chapter_title: progress.lesson&.chapter&.title,
        progress: progress.progress,
        completed: progress.completed?,
        started_at: progress.started_at&.strftime("%Y-%m-%d %H:%M:%S"),
        completed_at: progress.completed_at&.strftime("%Y-%m-%d %H:%M:%S"),
        duration_minutes: progress.lesson&.duration_minutes || 0
      }
    end

    {
      success: true,
      progress: progress_data,
      total_lessons: progress_data.count,
      completed_lessons: progress_data.count { |p| p[:completed] },
      average_progress: progress_data.empty? ? 0 : (progress_data.sum { |p| p[:progress] } / progress_data.count).round(2)
    }
  end

  def self.get_course_progress_summary(course_id, user)
    return { error: "User not authenticated" } unless user

    course = Course.find_by(id: course_id)
    return { error: "Course not found" } unless course

    total_lessons = course.lessons.count
    return { error: "Course has no lessons" } if total_lessons == 0

    user_progress = user.lesson_progresses
                     .joins(:lesson)
                     .where(lessons: { course_id: course_id })

    completed_lessons = user_progress.where(completed: true).count
    in_progress_lessons = user_progress.where("progress > 0 AND completed = false").count
    not_started_lessons = total_lessons - completed_lessons - in_progress_lessons

    overall_progress = total_lessons > 0 ? (completed_lessons.to_f / total_lessons * 100).round(2) : 0

    {
      success: true,
      course_id: course_id,
      course_title: course.title,
      total_lessons: total_lessons,
      completed_lessons: completed_lessons,
      in_progress_lessons: in_progress_lessons,
      not_started_lessons: not_started_lessons,
      overall_progress: overall_progress,
      status: determine_course_status(overall_progress),
      last_activity: user_progress.maximum(:updated_at)&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def self.calculate_lesson_progress(lesson, user)
    # Default progress calculation - can be enhanced based on lesson type
    case lesson&.video_url
    when nil
      # Text-based lesson - mark as complete when accessed
      100
    else
      # Video-based lesson - could track video watch time
      # For now, mark as complete when accessed
      100
    end
  end

  def self.update_course_progress(user, course)
    return unless course

    total_lessons = course.lessons.count
    return if total_lessons == 0

    completed_lessons = user.lesson_progresses
                             .joins(:lesson)
                             .where(lessons: { course: course.id.to_s }, completed: true)
                             .count

    course_progress = user.course_progresses.where(course: course).first_or_create
    new_progress = (completed_lessons.to_f / total_lessons * 100).round(2)

    course_progress.update!(
      progress: new_progress,
      status: new_progress >= 80 ? "Completed" : "In Progress",
      updated_at: Time.current
    )
  end

  def self.determine_course_status(progress)
    case progress
    when 0
      "Not Started"
    when 1..79
      "In Progress"
    when 80..100
      "Completed"
    else
      "Unknown"
    end
  end
end
