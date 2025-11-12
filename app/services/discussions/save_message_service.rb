module Discussions
  class SaveMessageService
    def self.call(params, user)
      new(params, user).call
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def call
      # Validate required parameters
      return error_response("User not found") unless @user
      return error_response("Discussion ID is required") unless @params[:discussion]
      return error_response("Content is required") unless @params[:content].present?

      discussion = Discussion.find_by(id: @params[:discussion])
      return error_response("Discussion not found") unless discussion

      # Check if discussion is open
      return error_response("Discussion is closed") unless discussion.open?

      # Validate parent message if provided
      if @params[:parent_message].present?
        parent_message = Message.find_by(id: @params[:parent_message])
        return error_response("Parent message not found") unless parent_message
        return error_response("Parent message is not in this discussion") unless parent_message.discussion_id == discussion.id
      end

      # Create message
      message = Message.new(
        discussion: discussion,
        user: @user,
        content: @params[:content],
        message_type: @params[:message_type] || "text",
        parent_message_id: @params[:parent_message]
      )

      if message.save
        success_response(message, "Message saved successfully")
      else
        error_response(message.errors.full_messages.join(", "))
      end
    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    end

    private

    def success_response(data, message = "Success")
      {
        success: true,
        data: data,
        message: message
      }
    end

    def error_response(message)
      {
        success: false,
        error: message,
        message: message
      }
    end
  end
end
