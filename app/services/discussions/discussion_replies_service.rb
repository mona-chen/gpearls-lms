module Discussions
  class DiscussionRepliesService
    def self.call(discussion_id, params = {})
      new(discussion_id, params).call
    end

    def initialize(discussion_id, params = {})
      @discussion_id = discussion_id
      @params = params
    end

    def call
      discussion = Discussion.find_by(id: @discussion_id)
      return { "data" => [] } unless discussion

      messages = Message.includes(:user, :replies)
                        .where(discussion: discussion)

      # Filter by parent message if provided (for threaded replies)
      if @params[:parent_message].present?
        messages = messages.where(parent_message_id: @params[:parent_message])
      else
        messages = messages.root_messages # Default to root messages
      end

      # Filter by message type
      if @params[:message_type].present?
        messages = messages.where(message_type: @params[:message_type])
      end

      # Apply ordering
      if @params[:order_by].present?
        messages = messages.order(@params[:order_by])
      else
        messages = messages.recent
      end

      # Apply pagination
      limit = @params[:limit] || 50
      offset = @params[:start] || 0
      messages = messages.limit(limit).offset(offset)

      replies_data = messages.map do |message|
        message.to_frappe_format.merge(
          "replies" => message.replies.limit(10).map(&:to_frappe_format) # Include first 10 direct replies
        )
      end

      { "data" => replies_data }
    end
  end
end
