class BatchMailer < ApplicationMailer
  default from: Rails.application.credentials.dig(:email, :from) || "noreply@lms.test"

  def batch_published(batch)
    @batch = batch
    @subject = "New Batch Available: #{@batch.title}"

    # Send to users who might be interested
    interested_users = get_interested_users(batch)

    mail(
      to: interested_users.pluck(:email),
      subject: @subject,
      template_name: "batch_published"
    )
  end

  def batch_started(batch)
    @batch = batch
    @subject = "Batch Started: #{@batch.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "batch_started"
    )
  end

  def batch_completed(batch)
    @batch = batch
    @subject = "Batch Completed: #{@batch.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "batch_completed"
    )
  end

  def batch_cancelled(batch, reason = nil)
    @batch = batch
    @reason = reason
    @subject = "Batch Cancelled: #{@batch.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "batch_cancelled"
    )
  end

  def batch_updated(batch, changes = {})
    @batch = batch
    @changes = changes
    @subject = "Batch Updated: #{@batch.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "batch_updated"
    )
  end

  def new_enrollment(batch_enrollment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @subject = "New Enrollment in #{@batch.title}"

    # Send to instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "new_enrollment"
    )
  end

  def enrollment_cancelled(batch_enrollment, reason = nil)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @reason = reason
    @subject = "Enrollment Cancelled: #{@batch.title}"

    # Send to instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "enrollment_cancelled"
    )
  end

  def payment_reminder(batch_enrollment, payment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @payment = payment
    @subject = "Payment Reminder for #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "payment_reminder"
    )
  end

  def assessment_created(batch, assessment)
    @batch = batch
    @assessment = assessment
    @subject = "New Assessment: #{@assessment.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "assessment_created"
    )
  end

  def live_class_scheduled(batch, live_class)
    @batch = batch
    @live_class = live_class
    @subject = "Live Class Scheduled: #{@live_class.title}"

    # Send to all enrolled students
    student_emails = batch.batch_enrollments.joins(:user).pluck("users.email")

    mail(
      to: student_emails,
      subject: @subject,
      template_name: "live_class_scheduled"
    )
  end

  def batch_full(batch)
    @batch = batch
    @subject = "Batch Full: #{@batch.title}"

    # Send to instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "batch_full"
    )
  end

  def batch_almost_full(batch, seats_left = 5)
    @batch = batch
    @seats_left = seats_left
    @subject = "Batch Almost Full: #{@batch.title}"

    # Send to instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "batch_almost_full"
    )
  end

  def batch_statistics(batch, stats)
    @batch = batch
    @stats = stats
    @subject = "Batch Statistics: #{@batch.title}"

    # Send to instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "batch_statistics"
    )
  end

  private

  def get_interested_users(batch)
    # Get users who might be interested in this batch
    # Based on course preferences, past enrollments, etc.
    User.joins(:enrollments)
       .where(enrollments: { course: batch.courses })
       .where.not(id: batch.batch_enrollments.select(:user_id))
       .distinct
  end
end
