module Courses
  class CourseReviewService
    def self.get_reviews(course)
      new(course).get_reviews
    end

    def self.add_review(user, course, rating, review = nil)
      new(course).add_review(user, rating, review)
    end

    def self.get_average_rating(course)
      new(course).get_average_rating
    end

    def initialize(course)
      @course = course
    end

    def get_reviews
      return [] unless @course

      reviews = CourseReview.where(course: @course.name)
        .published
        .recent
        .limit(50)

      reviews.map do |review|
        {
          name: review.id.to_s,
          review: review.review,
          rating: review.rating,
          owner: review.owner,
          creation: review.creation&.strftime("%Y-%m-%d %H:%M:%S"),
          modified: review.modified&.strftime("%Y-%m-%d %H:%M:%S"),
          course: @course.name,
          course_title: @course.title
        }
      end
    end

    def add_review(user, rating, review = nil)
      return review_error("User not authenticated") unless user
      return review_error("Course not found") unless @course
      return review_error("Invalid rating") unless valid_rating?(rating)

      # Check if user is enrolled in the course
      enrollment = Enrollment.find_by(user: user, course: @course)
      return review_error("Must be enrolled in course to leave a review") unless enrollment

      # Check if user has already reviewed this course
      existing_review = CourseReview.where(owner: user.email, course: @course.name).first
      if existing_review
        return review_error("You have already reviewed this course")
      end

       begin
         review_record = CourseReview.create!(
           course: @course.name,
           owner: user.email,
           rating: rating,
           review: review,
           name: generate_review_name(user, @course)
         )

         {
           success: true,
           review: review_record.to_frappe_format,
           message: "Review submitted successfully"
         }
       rescue => e
         review_error("Failed to submit review")
       end
    end

    def get_average_rating
      return 0.0 unless @course

      @course.average_rating
    end

    private

    def valid_rating?(rating)
      rating.is_a?(Integer) && rating.between?(1, 5)
    end

    def generate_review_name(user, course)
      "#{user.email}-#{course.id}-#{Time.current.to_i}"
    end

    def review_error(message)
      {
        success: false,
        error: message
      }
    end
  end
end
