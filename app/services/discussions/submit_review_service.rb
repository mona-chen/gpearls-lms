module Discussions
  class SubmitReviewService
    def self.call(params, user)
      new(params, user).call
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def call
      # Validate required parameters
      return error_response("User not found") unless @user
      return error_response("Course is required") unless @params[:course]
      return error_response("Review content is required") unless @params[:content].present?

      course = Course.find_by(id: @params[:course])
      return error_response("Course not found") unless course

      # Check if user is enrolled in the course
      enrollment = Enrollment.find_by(user: @user, course: course)
      return error_response("User is not enrolled in this course") unless enrollment

      # Check if user has completed the course
      return error_response("Course not completed") unless enrollment.completed?

      # Check if review already exists
      existing_review = Message.find_by(
        discussion: nil,
        user: @user,
        message_type: "review"
      )
      if existing_review
        return error_response("Review already submitted for this course")
      end

      # Create review message (not attached to a discussion)
      review = Message.new(
        discussion: nil, # Reviews are not part of discussions
        user: @user,
        content: @params[:content],
        message_type: "review"
      )

      # Add review-specific attributes if provided
      review.rating = @params[:rating] if @params[:rating].present?

      if review.save
        # Create or update course review
        course_review = CourseReview.find_or_initialize_by(
          user: @user,
          course: course
        )
        course_review.rating = @params[:rating] if @params[:rating].present?
        course_review.review = @params[:content]
        course_review.save

        success_response(review, "Review submitted successfully")
      else
        error_response(review.errors.full_messages.join(", "))
      end
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    end

    private

    def success_response(data, message = "Success")
      {
        success: true,
        data: data,
        message: message
      }
    end

    def error_response(message)
      {
        success: false,
        error: message,
        message: message
      }
    end
  end
end
