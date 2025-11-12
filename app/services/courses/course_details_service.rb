module Courses
  class CourseDetailsService
    def self.call(course_id, user = nil)
      new(course_id, user).call
    end

    def initialize(course_id, user = nil)
      @course_id = course_id
      @user = user
    end

    def call
      course = find_course
      return course_not_found unless course

      course_data = course.to_frappe_format

      # Add user-specific data if user is provided
      if @user
        course_data["membership"] = course.membership_for(@user)
        course_data["current_lesson"] = course.current_lesson_for(@user)
      end

      # Add additional computed fields
      course_data["enrollment_count"] = course.enrollment_count
      course_data["enrollment_count_formatted"] = course.enrollment_count_formatted
      course_data["total_reviews"] = course.total_reviews
      course_data["rating_distribution"] = course.rating_distribution

      course_data
    end

    private

    def find_course
      Course.includes(:instructor).find_by(id: @course_id)
    end

    def course_not_found
      { "error" => "Course not found", "status" => 404 }
    end
  end
end
