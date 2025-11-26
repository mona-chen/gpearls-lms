class LiveClassMailer < ApplicationMailer
  def live_class_reminder(live_class, user)
    @student_name = user.full_name || user.email
    @class_title = live_class.title
    @course_title = live_class.course&.title || live_class.batch&.course&.title
    @start_time = live_class.start_time
    @instructor = live_class.instructor&.full_name
    @meeting_url = live_class.meeting_url
    @description = live_class.description

    mail(
      to: user.email,
      subject: "Live Class Reminder - #{@class_title}"
    )
  end

  def live_class_cancelled(live_class, user)
    @student_name = user.full_name || user.email
    @class_title = live_class.title
    @course_title = live_class.course&.title || live_class.batch&.course&.title
    @scheduled_time = live_class.start_time
    @reason = live_class.cancellation_reason || "No reason provided"

    mail(
      to: user.email,
      subject: "Live Class Cancelled - #{@class_title}"
    )
  end

  def live_class_rescheduled(live_class, user, old_time)
    @student_name = user.full_name || user.email
    @class_title = live_class.title
    @course_title = live_class.course&.title || live_class.batch&.course&.title
    @old_time = old_time
    @new_time = live_class.start_time
    @meeting_url = live_class.meeting_url

    mail(
      to: user.email,
      subject: "Live Class Rescheduled - #{@class_title}"
    )
  end
end
