class NotificationMailer < ApplicationMailer
  def notification_email(recipient, subject, message, document = nil)
    @recipient = recipient
    @message = message
    @document = document

    mail(
      to: recipient,
      subject: subject,
      template_path: "notification_mailer",
      template_name: "notification_email"
    )
  end

  def course_approved(course, approver)
    @course = course
    @approver = approver

    mail(
      to: course.instructor.email,
      subject: "Your course '#{course.title}' has been approved",
      template_path: 'notification_mailer',
      template_name: 'course_approved'
    )
  end

  def course_rejected(course, approver, reason = nil)
    @course = course
    @approver = approver
    @reason = reason

    mail(
      to: course.instructor.email,
      subject: "Your course '#{course.title}' requires revisions",
      template_path: 'notification_mailer',
      template_name: 'course_rejected'
    )
  end

  def batch_approved(batch, approver)
    @batch = batch
    @approver = approver

    mail(
      to: batch.instructor.email,
      subject: "Your batch '#{batch.title}' has been approved",
      template_path: 'notification_mailer',
      template_name: 'batch_approved'
    )
  end

  def batch_rejected(batch, approver, reason = nil)
    @batch = batch
    @approver = approver
    @reason = reason

    mail(
      to: batch.instructor.email,
      subject: "Your batch '#{batch.title}' requires revisions",
      template_path: 'notification_mailer',
      template_name: 'batch_rejected'
    )
  end

  def enrollment_confirmation(enrollment)
    @enrollment = enrollment
    @user = enrollment.user
    @course = enrollment.course
    @batch = enrollment.batch

    mail(
      to: @user.email,
      subject: "Welcome to #{@course.title}#{@batch ? " - #{@batch.title}" : ''}",
      template_path: 'notification_mailer',
      template_name: 'enrollment_confirmation'
    )
  end

  def certificate_issued(certificate)
    @certificate = certificate
    @user = certificate.member
    @course = certificate.course
    @batch = certificate.batch

    mail(
      to: @user.email,
      subject: "Congratulations! You've earned a certificate",
      template_path: 'notification_mailer',
      template_name: 'certificate_issued'
    )
  end

  def quiz_submission_graded(submission)
    @submission = submission
    @user = submission.member
    @quiz = submission.quiz
    @course = submission.course

    mail(
      to: @user.email,
      subject: "Your quiz submission has been graded",
      template_path: 'notification_mailer',
      template_name: 'quiz_graded'
    )
  end

  def assignment_graded(submission)
    @submission = submission
    @user = submission.student
    @assignment = submission.assignment
    @course = submission.assignment.course

    mail(
      to: @user.email,
      subject: "Your assignment has been graded",
      template_path: 'notification_mailer',
      template_name: 'assignment_graded'
    )
  end
end
