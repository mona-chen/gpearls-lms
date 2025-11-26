class Api::DiscussionsController < Api::BaseController
  # Authentication required for all discussion actions

  def create
    create_discussion_topic
  end

  def create_reply
    create_discussion_reply
  end
  def get_discussion_topics
    doctype = params[:doctype]
    docname = params[:docname]
    single_thread = params[:single_thread] == "1"

    if single_thread
      topic = DiscussionTopic.find_by(reference_doctype: doctype, reference_docname: docname)
      if topic
        render json: [ topic.to_frappe_format ]
      else
        # Create new topic
        topic = DiscussionTopic.create!(
          title: docname,
          reference_doctype: doctype,
          reference_docname: docname,
          owner: current_user.email
        )
        render json: [ topic.to_frappe_format ]
      end
    else
      topics = DiscussionTopic.by_reference(doctype, docname).recent
      topics_data = topics.map do |topic|
        topic_data = topic.to_frappe_format
        topic_data["user"] = {
          "full_name" => topic.owner_name,
          "user_image" => current_user&.profile_image
        }
        topic_data
      end
      render json: topics_data
    end
  end

  def get_discussion_replies
    topic_id = params[:topic]
    replies = DiscussionReply.by_topic(topic_id).recent

    replies_data = replies.map do |reply|
      reply_data = reply.to_frappe_format
      reply_data["user"] = {
        "full_name" => reply.owner_name,
        "user_image" => reply.owner_user&.profile_image
      }
      reply_data
    end

    render json: replies_data
  end

  def create_discussion_topic
    discussion_params = params.require(:discussion).permit(:title, :content, :course_id)
    topic = DiscussionTopic.create!(
      title: discussion_params[:title],
      content: discussion_params[:content],
      reference_doctype: "Course",
      reference_docname: discussion_params[:course_id],
      owner: current_user.email
    )

    render json: { id: topic.id, title: topic.title, content: topic.content }, status: :created
  end

  def create_discussion_reply
    reply_params = params.require(:reply).permit(:content, :discussion_id)
    reply = DiscussionReply.create!(
      topic_id: reply_params[:discussion_id],
      reply: reply_params[:content],
      owner: current_user.email
    )

    render json: { id: reply.id, content: reply.reply }, status: :created
  end
end
