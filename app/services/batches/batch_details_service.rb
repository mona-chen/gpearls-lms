module Batches
  class BatchDetailsService
    def self.call(batch_name, user = nil)
      new(batch_name, user).call
    end

    def initialize(batch_name, user = nil)
      @batch_name = batch_name
      @user = user
    end

    def call
      batch = Batch.find_by(title: @batch_name) || Batch.find_by(id: @batch_name)
      return { error: "Batch not found" } unless batch

      # Check if user has access to this batch
      unless batch.published? || (@user && (batch.instructor == @user || @user.moderator?))
        return { error: "Access denied" }
      end

      # Get enrollment info if user is provided
      enrollment = @user ? BatchEnrollment.find_by(user: @user, batch: batch) : nil

      {
        name: batch.name,
        title: batch.title,
        batch_id: batch.id,
        course_id: batch.courses.first&.id,
        course_title: batch.courses.first&.title,
        start_date: batch.start_date&.strftime("%Y-%m-%d"),
        end_date: batch.end_date&.strftime("%Y-%m-%d"),
        start_time: batch.start_time,
        end_time: batch.end_time,
        timezone: batch.timezone,
        description: batch.description,
        batch_details: batch.additional_info,
        published: batch.published,
        allow_self_enrollment: batch.allow_self_enrollment,
        certification: batch.certification,
        seat_count: batch.seat_count,
        evaluation_end_date: batch.evaluation_end_date&.strftime("%Y-%m-%d"),
        medium: batch.medium,
        category: batch.category,
        confirmation_email_template: batch.confirmation_email_template,
        instructors: batch.instructors_list,
        zoom_account: batch.zoom_account,
        paid_batch: batch.paid_batch,
        amount: batch.amount,
        currency: batch.currency,
        amount_usd: batch.amount_usd,
        show_live_class: batch.show_live_class,
        allow_future: batch.allow_future,
        status: batch.status,
        current_seats: batch.current_seats,
        seats_left: batch.seats_left,
        full: batch.full?,
        accept_enrollments: batch.accept_enrollments?,
        courses: batch.batch_courses.map(&:to_frappe_format),
        enrolled: enrollment.present?,
        enrollment_date: enrollment&.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
        creation: batch.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
        modified: batch.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
        owner: batch.instructor&.email
      }
    end
  end
end
