module Notifications
  class MarkAsReadService
    def self.call(notification_id, user)
      new(notification_id, user).call
    end

    def initialize(notification_id, user)
      @notification_id = notification_id
      @user = user
    end

    def call
      notification = find_notification
      return { error: "Notification not found" } unless notification
      return { error: "Unauthorized" } unless authorized?(notification)

      mark_as_read(notification)
      { success: true }
    end

    private

    def find_notification
      Notification.find_by(id: @notification_id)
    end

    def authorized?(notification)
      notification.user == @user
    end

    def mark_as_read(notification)
      notification.mark_as_read!
    end
  end
end
