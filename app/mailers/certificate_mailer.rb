class CertificateMailer < ApplicationMailer
  def certificate_request_notification(certificate_request)
    @member_name = certificate_request.user.full_name || certificate_request.user.email
    @course = certificate_request.course.title
    @date = certificate_request.evaluation_date
    @start_time = certificate_request.evaluation_time
    @timezone = certificate_request.timezone || 'UTC'
    @evaluator = certificate_request.evaluator&.full_name || 'TBD'
    
    mail(
      to: certificate_request.user.email,
      subject: "Certificate Evaluation Scheduled - #{@course}"
    )
  end
  
  def certificate_generated(certificate)
    @member_name = certificate.user.full_name || certificate.user.email
    @course_title = certificate.course.title
    @certificate_url = Rails.application.routes.url_helpers.certificate_url(certificate)
    @issue_date = certificate.created_at
    
    mail(
      to: certificate.user.email,
      subject: "🎉 Your Certificate is Ready! - #{@course_title}"
    )
  end
  
  def certification_reminder(certification_request)
    @student_name = certification_request.user.full_name || certification_request.user.email
    @course_title = certification_request.course.title
    @evaluation_date = certification_request.evaluation_date
    @course_url = Rails.application.routes.url_helpers.course_url(certification_request.course)
    
    mail(
      to: certification_request.user.email,
      subject: "Certification Reminder - #{@course_title}"
    )
  end
end