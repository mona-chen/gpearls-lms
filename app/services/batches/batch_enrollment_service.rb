module Batches
  class BatchEnrollmentService
    def self.enroll_in_batch(batch_name, user)
      new(batch_name, user).enroll
    end

    def initialize(batch_name, user)
      @batch_name = batch_name
      @user = user
    end

    def enroll
      # Find batch by name (parameterized title), title, or id
      batch = Batch.find_by(title: @batch_name) ||
              Batch.find_by(id: @batch_name) ||
              Batch.where("title LIKE ?", @batch_name.tr("_", " ")).first
      return error_response("Batch not found") unless batch
      return error_response("User not found") unless @user

      # Check if already enrolled
      existing_enrollment = BatchEnrollment.find_by(batch: batch, user: @user)
      return success_response(existing_enrollment, "Already enrolled in this batch") if existing_enrollment

      # Validate enrollment
      validation_errors = validate_enrollment(batch)
      return error_response(validation_errors.join(", ")) if validation_errors.any?

      # Create enrollment
      enrollment = BatchEnrollment.new(
        batch: batch,
        user: @user
      )

      if enrollment.save
        # Create course enrollments for batch courses
        create_course_enrollments(batch, @user)

        # Send confirmation email
        BatchEnrollmentMailer.confirmation_email(enrollment).deliver_later

        success_response(enrollment, "Successfully enrolled in batch")
      else
        error_response(enrollment.errors.full_messages.join(", "))
      end
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    end

    private

    def validate_enrollment(batch)
      errors = []

      # Check if batch allows self-enrollment
      unless batch.allow_self_enrollment
        errors << "Batch does not allow self-enrollment"
      end

      # Check if batch is published
      unless batch.published
        errors << "Batch is not published"
      end

      # Check if batch is accepting enrollments
      unless batch.accept_enrollments?
        errors << "Batch is not accepting enrollments"
      end

      # Check capacity
      if batch.full?
        errors << "Batch is full"
      end

      # Check for time conflicts with existing enrollments
      if has_time_conflicts?(batch)
        errors << "Time conflicts with existing enrollments"
      end

      # Check for course conflicts
      if has_course_conflicts?(batch)
        errors << "Already enrolled in same courses through another batch"
      end

      errors
    end

    def has_time_conflicts?(batch)
      return false unless batch.start_date && batch.end_date

      user_enrollments = @user.batch_enrollments.joins(:batch)
                               .where(batches: { end_date: batch.start_date.. })
                               .where.not(batches: { id: batch.id })

      user_enrollments.any? do |enrollment|
        other_batch = enrollment.batch
        dates_overlap = batch.start_date <= other_batch.end_date && batch.end_date >= other_batch.start_date
        times_overlap = if batch.start_time && other_batch.start_time
                         batch.start_time < other_batch.end_time && batch.end_time > other_batch.start_time
        else
                          false
        end

        dates_overlap && times_overlap
      end
    end

    def has_course_conflicts?(batch)
      batch_courses = batch.courses
      return false if batch_courses.empty?

      user_active_batches = @user.batch_enrollments.joins(:batch)
                                       .where(batches: { end_date: Date.current.. })

      user_active_batches.any? do |enrollment|
        other_batch = enrollment.batch
        common_courses = batch_courses & other_batch.courses
        common_courses.any?
      end
    end

    def create_course_enrollments(batch, user)
      batch.batch_courses.includes(:course).find_each do |batch_course|
        next unless batch_course.course

        enrollment = Enrollment.find_or_initialize_by(
          user: user,
          course: batch_course.course
        )

        enrollment.member_type = "Student"
        enrollment.role = "Member"
        enrollment.batch = batch
        enrollment.cohort = nil # Clear cohort if any
        enrollment.save if enrollment.new_record? || enrollment.changed?
      end
    end

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
