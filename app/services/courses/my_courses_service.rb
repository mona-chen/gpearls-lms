module Courses
  class MyCoursesService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return [] unless @user

      # Get enrolled courses first (like Frappe's get_my_latest_courses)
      enrolled_course_ids = @user.enrollments
                                 .order(updated_at: :desc)
                                 .limit(3)
                                 .pluck(:course_id)

      courses = if enrolled_course_ids.any?
                  # Return enrolled courses with full details
                  Course.where(id: enrolled_course_ids)
                        .includes(:instructor)
                        .order(created_at: :desc) # SQLite doesn't support FIELD(), use alternative ordering
      else
                  # If no enrolled courses, return featured courses (like Frappe)
                  Course.published
                        .featured
                        .includes(:instructor)
                        .order(published_at: :desc)
                        .limit(3)
      end

      courses.map do |course|
        enrollment = @user.enrollments.find_by(course: course)
        progress = enrollment ? calculate_course_progress(@user, course) : 0

        course_details(course, enrollment, progress)
      end
    end

    private

    def course_details(course, enrollment, progress)
      # Use the same format as CoursesService for consistency
      course_data = Courses::CoursesService.new({}).send(:format_course_for_listing, course)

      # Add enrollment-specific data if enrolled
      if enrollment
        course_data.merge!(
          progress: progress,
          status: enrollment_status(enrollment, progress),
          enrollment_date: enrollment.enrollment_date&.strftime("%Y-%m-%d"),
          completion_date: enrollment.completed? ? enrollment.updated_at.strftime("%Y-%m-%d") : nil,
          membership: enrollment_membership_data(enrollment, progress)
        )
      end

      course_data
    end

    def calculate_course_progress(user, course)
      total_lessons = course.lessons.count
      return 0 if total_lessons == 0

      lesson_names = course.lessons.pluck(:name)
      completed_lessons = CourseProgress.where(member: user, course: course, lesson: lesson_names, status: "Complete").count

      ((completed_lessons.to_f / total_lessons) * 100).round(2)
    end

    def enrollment_status(enrollment, progress)
      if enrollment.completed?
        "Completed"
      elsif progress > 0
        "In Progress"
      else
        "Approved" # Course is approved/enrolled but not started
      end
    end

    def enrollment_membership_data(enrollment, progress)
      {
        enrollment_date: enrollment.enrollment_date&.strftime("%Y-%m-%d"),
        progress: progress,
        completed: enrollment.completed?,
        completion_date: enrollment.completed? ? enrollment.updated_at.strftime("%Y-%m-%d") : nil
      }
    end
  end
end
