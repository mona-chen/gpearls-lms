class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def mark_as_read(data)
    notification = Notification.find_by(id: data['notification_id'], user: current_user)
    if notification
      notification.update(read: true, read_at: Time.current)
      # Broadcast updated notification status
      ActionCable.server.broadcast(
        "notifications_#{current_user.id}",
        type: 'notification_read',
        notification: notification.as_json(include: [:user])
      )
    end
  end

  def mark_all_as_read
    notifications = Notification.where(user: current_user, read: false)
    notifications.update_all(read: true, read_at: Time.current)

    ActionCable.server.broadcast(
      "notifications_#{current_user.id}",
      type: 'all_notifications_read',
      user_id: current_user.id
    )
  end
end