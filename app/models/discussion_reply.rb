class DiscussionReply < ApplicationRecord
  self.table_name = "discussion_replies"

  # Associations
  belongs_to :topic, class_name: "DiscussionTopic", foreign_key: :topic
  belongs_to :owner_user, class_name: "User", foreign_key: :owner, primary_key: :email, optional: true

  # Validations
  validates :topic, presence: true
  validates :reply, presence: true

  # Scopes
  scope :by_topic, ->(topic_id) { where(topic_id: topic_id) }
  scope :recent, -> { order(created_at: :asc) }

  # Instance methods
  def owner_name
    owner_user&.full_name || owner
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "topic" => topic_id.to_s,
      "owner" => owner,
      "reply" => reply,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
