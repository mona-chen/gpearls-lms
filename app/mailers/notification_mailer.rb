class NotificationMailer < ApplicationMailer
  def notification_email(recipient, subject, message)
    @recipient = recipient
    @message = message

    mail(
      to: recipient.email,
      subject: subject,
      template_path: "notifications",
      template_name: "notification_email"
    )
  end
end
