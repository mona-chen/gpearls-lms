class BatchEnrollmentMailer < ApplicationMailer
  default from: Rails.application.credentials.dig(:email, :from) || "noreply@lms.test"

  def confirmation_email(batch_enrollment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @subject = "Enrollment Confirmation for #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "batch_confirmation"
    )
  end

  def start_reminder(batch_enrollment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @subject = "Your batch #{@batch.title} is starting tomorrow"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "batch_start_reminder"
    )
  end

  def payment_confirmation(batch_enrollment, payment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @payment = payment
    @subject = "Payment Confirmation for #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "batch_payment_confirmation"
    )
  end

  def batch_completed(batch_enrollment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @subject = "Batch Completed: #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "batch_completion"
    )
  end

  def batch_cancelled(batch_enrollment, reason = nil)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @reason = reason
    @subject = "Batch Cancelled: #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "batch_cancellation"
    )
  end

  def seat_available(batch, waitlist_user)
    @batch = batch
    @user = waitlist_user
    @subject = "Seat Available in #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "seat_available"
    )
  end

  def enrollment_reminder(batch_enrollment, days_until_start)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @days_until_start = days_until_start
    @subject = "Reminder: #{@batch.title} starts in #{days_until_start} days"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "enrollment_reminder"
    )
  end

  def instructor_notification(batch_enrollment, action = "enrolled")
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @action = action
    @subject = "Student #{action} in #{@batch.title}"

    # Send to all batch instructors
    instructor_emails = @batch.instructors_list

    mail(
      to: instructor_emails,
      subject: @subject,
      template_name: "instructor_notification"
    )
  end

  def assessment_reminder(batch_enrollment, assessment)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @assessment = assessment
    @subject = "Assessment Reminder: #{@assessment.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "assessment_reminder"
    )
  end

  def live_class_reminder(batch_enrollment, live_class)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @live_class = live_class
    @subject = "Live Class Reminder: #{@live_class.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "live_class_reminder"
    )
  end

  def certificate_issued(batch_enrollment, certificate)
    @batch_enrollment = batch_enrollment
    @batch = batch_enrollment.batch
    @user = batch_enrollment.user
    @certificate = certificate
    @subject = "Certificate Issued: #{@batch.title}"

    mail(
      to: @user.email,
      subject: @subject,
      template_name: "certificate_issued"
    )
  end

  private

  def batch_from_enrollment(enrollment)
    enrollment.batch
  end

  def user_from_enrollment(enrollment)
    enrollment.user
  end
end
