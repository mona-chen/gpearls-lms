module Courses
  class CourseEnrollmentService
    def self.enroll(user, course)
      new(user, course).enroll
    end

    def self.unenroll(user, course)
      new(user, course).unenroll
    end

    def self.can_enroll?(user, course)
      new(user, course).can_enroll?
    end

    def initialize(user, course)
      @user = user
      @course = course
    end

    def enroll
      return enrollment_error("User not authenticated") unless @user
      return enrollment_error("Course not found") unless @course

      # Check if already enrolled first
      if already_enrolled?
        return enrollment_error("Already enrolled in this course")
      end

      return enrollment_error("Course not available for enrollment") unless can_enroll?

      begin
        enrollment = Enrollment.create!(
          user: @user,
          course: @course
        )

        {
          success: true,
          enrollment: enrollment.to_frappe_format,
          message: "Successfully enrolled in course"
        }
      rescue ActiveRecord::RecordInvalid => e
        enrollment_error("Validation failed: #{e.message}")
      rescue => e
        enrollment_error("Failed to enroll in course: #{e.message}")
      end
    end

    def unenroll
      return enrollment_error("User not authenticated") unless @user

      enrollment = Enrollment.find_by(user: @user, course: @course)
      return enrollment_error("Not enrolled in this course") unless enrollment

      begin
        enrollment.destroy

        {
          success: true,
          message: "Successfully unenrolled from course"
        }
      rescue => e
        enrollment_error("Failed to unenroll from course")
      end
    end

    def can_enroll?
      return false unless @user && @course
      return false unless @course.published? && !@course.upcoming?
      return false if already_enrolled?

      # Allow enrollment - payment validation can happen separately
      true
    end

    private

    def already_enrolled?
      Enrollment.exists?(user: @user, course: @course)
    end

    def enrollment_error(message)
      {
        success: false,
        error: message
      }
    end
  end
end
