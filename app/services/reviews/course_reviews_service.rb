module Reviews
  class CourseReviewsService
    def self.call(course_id)
      new(course_id).call
    end

    def initialize(course_id)
      @course_id = course_id
    end

    def call
      course = Course.find_by(id: @course_id)
      return [] unless course

      # For now, return empty array since we don't have a reviews table
      # In the future, this should query a real reviews table
      []
    end
  end
end
