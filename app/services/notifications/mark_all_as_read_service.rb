module Notifications
  class MarkAllAsReadService
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      mark_all_as_read
      { success: true }
    end

    private

    def mark_all_as_read
      Notification.where(user: @user, read: false).find_each do |notification|
        notification.mark_as_read!
      end
    end
  end
end
