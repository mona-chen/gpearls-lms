class Message < ApplicationRecord
  belongs_to :user
  belongs_to :discussion
  belongs_to :parent_message, class_name: "Message", optional: true
  has_many :replies, class_name: "Message", foreign_key: "parent_message_id", dependent: :destroy

  validates :content, presence: true, length: { maximum: 2000 }
  validates :message_type, presence: true, inclusion: { in: %w[text image file review] }
  validates :user, presence: true
  validates :discussion, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_discussion, ->(discussion) { where(discussion: discussion) }
  scope :root_messages, -> { where(parent_message_id: nil) }
  scope :replies, -> { where.not(parent_message_id: nil) }
  scope :reviews, -> { where(message_type: "review") }

  def text?
    message_type == "text"
  end

  def image?
    message_type == "image"
  end

  def file?
    message_type == "file"
  end

  def review?
    message_type == "review"
  end

  def reply?
    parent_message_id.present?
  end

  def root_message?
    parent_message_id.nil?
  end

  def reply_count
    replies.count
  end

  def last_reply_at
    replies.maximum(:created_at)
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: id,
      content: content,
      message_type: message_type,
      discussion: discussion_id,
      owner: user&.email,
      owner_name: user&.full_name,
      parent_message: parent_message_id,
      reply_count: reply_count,
      last_reply_at: last_reply_at&.strftime("%Y-%m-%d %H:%M:%S"),
      creation: created_at.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
