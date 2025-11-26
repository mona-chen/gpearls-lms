class DiscussionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "discussion_#{params[:discussion_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_message(data)
    discussion = Discussion.find_by(id: params[:discussion_id])
    if discussion
      message = Message.create!(
        user: current_user,
        discussion: discussion,
        content: data["content"],
        message_type: data["message_type"] || "text"
      )

      # Broadcast new message to all subscribers
      ActionCable.server.broadcast(
        "discussion_#{params[:discussion_id]}",
        type: "new_message",
        message: message.as_json(include: [ :user, :discussion ])
      )
    end
  end

  def update_message(data)
    message = Message.find_by(id: data["message_id"], user: current_user)
    if message && message.update(content: data["content"])
      # Broadcast message update to all subscribers
      ActionCable.server.broadcast(
        "discussion_#{params[:discussion_id]}",
        type: "message_updated",
        message: message.as_json(include: [ :user, :discussion ])
      )
    end
  end

  def delete_message(data)
    message = Message.find_by(id: data["message_id"], user: current_user)
    if message
      message_id = message.id
      message.destroy

      # Broadcast message deletion to all subscribers
      ActionCable.server.broadcast(
        "discussion_#{params[:discussion_id]}",
        type: "message_deleted",
        message_id: message_id
      )
    end
  end
end
