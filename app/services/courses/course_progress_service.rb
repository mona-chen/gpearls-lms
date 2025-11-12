module Courses
  class CourseProgressService
    def self.update_progress(user, course, lesson, completed = true)
      new(user, course, lesson).update_progress(completed)
    end

    def self.get_progress(user, course)
      new(user, course, nil).get_course_progress
    end

    def self.save_current_lesson(user, course, lesson)
      new(user, course, lesson).save_current_lesson
    end

    def initialize(user, course, lesson)
      @user = user
      @course = course
      @lesson = lesson
    end

    def update_progress(completed = true)
      return progress_error("User not authenticated") unless @user
      return progress_error("Course not found") unless @course
      return progress_error("Lesson not found") unless @lesson

      # Check if user is enrolled in the course
      enrollment = Enrollment.find_by(user: @user, course: @course)
      return progress_error("Not enrolled in this course") unless enrollment

      begin
        puts "Finding progress record for member: #{@user.email}, course: #{@course.name}, lesson: #{@lesson.name}"
        progress_record = CourseProgress.where(
          member: @user.email,
          course: @course.name,
          lesson: @lesson.name
        ).first_or_initialize
        puts "Progress record: #{progress_record.inspect}"

        progress_record.status = completed ? "Complete" : "Incomplete"
        puts "Saving progress record..."
        progress_record.save!
        puts "Progress record saved successfully"

        # Update enrollment progress
        update_enrollment_progress(enrollment)

        {
          success: true,
          progress: progress_record.status,
          course_progress: calculate_course_progress,
          message: "Lesson #{completed ? 'completed' : 'marked incomplete'}"
        }
      rescue => e
        puts "Error: #{e.message}"
        puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
        progress_error("Failed to update lesson progress: #{e.message}")
      end
    end

    def get_course_progress
      return progress_error("User not authenticated") unless @user
      return progress_error("Course not found") unless @course

      total_lessons = CourseLesson.where(course: @course.id.to_s).count
      completed_lessons = CourseProgress
        .where(member: @user.email)
        .where(course: @course.name)
        .where(status: "Complete")
        .count

      progress_percentage = total_lessons > 0 ? ((completed_lessons.to_f / total_lessons) * 100).round(2) : 0

      {
        success: true,
        course: @course.name,
        total_lessons: total_lessons,
        completed_lessons: completed_lessons,
        progress: progress_percentage,
        status: progress_status(progress_percentage)
      }
    end

    def save_current_lesson
      return progress_error("User not authenticated") unless @user
      return progress_error("Course not found") unless @course
      return progress_error("Lesson not found") unless @lesson

      # This could be used to track the last accessed lesson
      # For now, we'll just return success
      {
        success: true,
        message: "Current lesson saved"
      }
    end

    private

    def calculate_course_progress
      total_lessons = CourseLesson.where(course: @course.id.to_s).count
      return 0 if total_lessons == 0

      completed_lessons = CourseProgress
        .where(member: @user.email)
        .where(course: @course.name)
        .where(status: "Complete")
        .count

      ((completed_lessons.to_f / total_lessons) * 100).round(2)
    end

    def update_enrollment_progress(enrollment)
      progress_percentage = calculate_course_progress
      enrollment.update(progress_percentage: progress_percentage)

      # Mark enrollment as completed if progress is 100%
      if progress_percentage >= 100
        enrollment.update(status: "Completed", completion_date: Time.current)
      end
    end

    def progress_status(progress_percentage)
      if progress_percentage >= 100
        "Completed"
      elsif progress_percentage > 0
        "In Progress"
      else
        "Not Started"
      end
    end

    def progress_error(message)
      {
        success: false,
        error: message
      }
    end
  end
end
