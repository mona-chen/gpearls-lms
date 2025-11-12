module Notifications
  class NotificationService
    def self.send_notification(document_type, event_type, document, recipients = nil)
      new(document_type, event_type, document, recipients).send_notifications
    end

    def initialize(document_type, event_type, document, recipients = nil)
      @document_type = document_type
      @event_type = event_type
      @document = document
      @recipients = recipients || determine_recipients
    end

    def send_notifications
      templates = NotificationTemplate.find_by_document_and_event(@document_type, @event_type)

      templates.each do |template|
        next unless template.should_send?(@document)

        @recipients.each do |recipient|
          send_to_recipient(template, recipient)
        end
      end
    end

    private

    def determine_recipients
      # Default recipients based on document type and event
      case @document_type
      when "Course"
        course_recipients
      when "Batch"
        batch_recipients
      when "Assignment"
        assignment_recipients
      when "Certificate"
        certificate_recipients
      else
        [ @document.created_by ].compact
      end
    end

    def course_recipients
      # Course instructors and enrolled students
      recipients = [ @document.instructor ].compact
      recipients += @document.enrollments.map(&:user)
      recipients.uniq
    end

    def batch_recipients
      # Batch evaluators and enrolled students
      recipients = [ @document.evaluator ].compact
      recipients += @document.enrollments.map(&:user)
      recipients.uniq
    end

    def assignment_recipients
      # Assignment creator and submitter
      [ @document.created_by, @document.submitted_by ].compact.uniq
    end

    def certificate_recipients
      # Certificate recipient and evaluators
      [ @document.recipient, @document.evaluator ].compact.uniq
    end

    def send_to_recipient(template, recipient)
      if template.email? || template.both?
        send_email_notification(template, recipient)
      end

      if template.system? || template.both?
        create_system_notification(template, recipient)
      end
    end

    def send_email_notification(template, recipient)
      subject = template.render_subject(@document, recipient)
      message = template.render_message(@document, recipient)

      # Use Rails mailer or custom email service
      NotificationMailer.notification_email(recipient, subject, message).deliver_later
    end

    def create_system_notification(template, recipient)
      subject = template.render_subject(@document, recipient)
      message = template.render_message(@document, recipient)

      Notification.create!(
        user: recipient,
        title: subject,
        message: message,
        notification_type: "system",
        related_document_type: @document_type,
        related_document_id: @document.id,
        read: false
      )
    end
  end
end
