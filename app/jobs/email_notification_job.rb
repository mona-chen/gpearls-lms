class EmailNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  # Generic email sending job that matches Frappe's email queue
  def perform(mailer_class, mailer_method, *args)
    mailer = mailer_class.constantize
    email = mailer.send(mailer_method, *args)

    # Log email sending attempt
    Rails.logger.info "Sending email: #{email.subject} to #{email.to.join(', ')}"

    begin
      email.deliver_now

      # Create notification record for tracking
      create_notification_record(email, "sent")

      Rails.logger.info "Email sent successfully: #{email.subject}"
    rescue => e
      Rails.logger.error "Email sending failed: #{e.message}"

      # Create failed notification record
      create_notification_record(email, "failed", e.message)

      # Re-raise to trigger retry logic
      raise e
    end
  end

  # Batch email sending for multiple recipients
  def perform_bulk(mailer_class, mailer_method, recipients_data)
    mailer = mailer_class.constantize

    recipients_data.each do |recipient_data|
      begin
        email = mailer.send(mailer_method, recipient_data)
        email.deliver_now

        create_notification_record(email, "sent")
      rescue => e
        Rails.logger.error "Bulk email failed for #{recipient_data}: #{e.message}"
        create_notification_record(nil, "failed", e.message, recipient_data)
      end
    end
  end

  private

  def create_notification_record(email, status, error_message = nil, recipient_data = nil)
    notification_data = {
      notification_type: "email",
      status: status,
      sent_at: Time.current
    }

    if email
      notification_data.merge!(
        recipient: email.to.first,
        subject: email.subject,
        content: extract_email_content(email)
      )
    else
      notification_data.merge!(
        recipient: recipient_data&.dig(:email) || "unknown",
        error_message: error_message
      )
    end

    # Create notification record (assuming Notification model exists)
    if defined?(Notification)
      Notification.create(notification_data)
    end
  rescue => e
    Rails.logger.error "Failed to create notification record: #{e.message}"
  end

  def extract_email_content(email)
    if email.html_part
      email.html_part.body.to_s
    elsif email.text_part
      email.text_part.body.to_s
    else
      email.body.to_s
    end
  end
end
