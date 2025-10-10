class Api::NotificationsController < Api::BaseController
  def get_notifications
    notifications = Notification.where(user: current_user)
                              .order(created_at: :desc)
                              .limit(50)
    
    render json: notifications.map do |notif|
      {
        name: notif.id,
        subject: notif.subject,
        email_content: notif.email_content,
        document_type: notif.document_type,
        document_name: notif.document_name,
        read: notif.read,
        creation: notif.created_at,
        link: notif.link,
        from_user: notif.from_user
      }
    end
  end
  
  def mark_as_read
    notification = Notification.find(params[:notification_id])
    return render json: { error: 'Not found' }, status: :not_found unless notification
    
    if notification.user == current_user
      notification.update!(read: true)
      render json: { success: true }
    else
      render json: { error: 'Unauthorized' }, status: :forbidden
    end
  end
  
  def mark_all_as_read
    Notification.where(user: current_user, read: false).update_all(read: true)
    render json: { success: true }
  end
end