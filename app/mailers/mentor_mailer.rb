class MentorMailer < ApplicationMailer
  def mentor_request_creation(mentor_request)
    @member_name = mentor_request.user.full_name || mentor_request.user.email
    @course = mentor_request.course.title
    @course_url = Rails.application.routes.url_helpers.course_url(mentor_request.course)

    mail(
      to: mentor_request.user.email,
      subject: "Request for Mentorship"
    )
  end

  def mentor_request_status_update(mentor_request)
    @member_name = mentor_request.user.full_name || mentor_request.user.email
    @course_title = mentor_request.course.title
    @status = mentor_request.status
    @course_url = Rails.application.routes.url_helpers.course_url(mentor_request.course)

    subject_text = case @status
    when "accepted"
      "Congratulations! Your mentor application has been accepted"
    when "rejected"
      "Update on your mentor application"
    else
      "The status of your application has changed"
    end

    mail(
      to: mentor_request.user.email,
      subject: subject_text
    )
  end
end
