module Notifications
  class UserNotificationsService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return [] unless @user

      notifications = fetch_system_notifications
      notifications += fetch_course_notifications
      notifications.sort_by { |n| n[:creation] }.reverse
    end

    private

    def fetch_system_notifications
      # Fetch real system notifications from database
      system_notifications = Notification.where(user: @user, notification_type: 'system')
                                       .order(created_at: :desc)
                                       .limit(5)

      if system_notifications.any?
        system_notifications.map { |notification| format_notification(notification, 'System') }
      else
        [default_welcome_notification]
      end
    end

    def fetch_course_notifications
      return [] unless @user.enrollments.any?

      notifications = []

      # Get recent course progress notifications
      @user.enrollments.includes(:course).limit(3).each do |enrollment|
        notifications << course_progress_notification(enrollment)
      end

      # Get real database notifications for courses
      db_notifications = Notification.where(user: @user)
                                    .where.not(notification_type: 'system')
                                    .order(created_at: :desc)
                                    .limit(5)

      db_notifications.each do |notification|
        context_name = notification.document_name || 'Course'
        notifications << format_notification(notification, context_name)
      end

      notifications
    end

    def default_welcome_notification
      {
        name: "welcome_notification",
        notification_type: "Alert",
        for_user: @user.email,
        document_type: "User",
        subject: "Welcome to LMS!",
        email_content: "Welcome to the Learning Management System. Start exploring courses today!",
        read: false,
        creation: Date.today.strftime('%Y-%m-%d'),
        modified: Date.today.strftime('%Y-%m-%d'),
        comment_type: "Info",
        reference_name: "Welcome Message"
      }
    end

    def course_progress_notification(enrollment)
      {
        name: "course_progress_#{enrollment.id}",
        notification_type: "Mention",
        for_user: @user.email,
        document_type: "Course",
        document_name: enrollment.course.title,
        subject: "Continue Learning: #{enrollment.course.title}",
        email_content: "You have made progress in #{enrollment.course.title}. Keep going!",
        read: false,
        creation: (Date.today - rand(1..7).days).strftime('%Y-%m-%d'),
        modified: (Date.today - rand(1..7).days).strftime('%Y-%m-%d'),
        comment_type: "Info",
        reference_name: enrollment.course.title
      }
    end

    def format_notification(notification, context_name)
      {
        name: notification.id,
        notification_type: notification.notification_type&.titleize || "Alert",
        for_user: notification.user&.email,
        document_type: "Course",
        document_name: context_name,
        subject: notification.subject,
        email_content: notification.email_content,
        read: notification.read,
        creation: notification.created_at.strftime('%Y-%m-%d'),
        modified: notification.updated_at.strftime('%Y-%m-%d'),
        comment_type: notification.type || "Info",
        reference_name: context_name
      }
    end
  end
end
