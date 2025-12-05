class LmsMessage < ApplicationRecord
  # Frappe-style fields
  attribute :name, :string
  attribute :owner, :string
  attribute :creation, :datetime
  attribute :modified, :datetime
  attribute :modified_by, :string
  attribute :docstatus, :string, default: "0"
  attribute :parent, :string
  attribute :parenttype, :string
  attribute :parentfield, :string
  attribute :idx, :integer

  # Associations
  belongs_to :author, class_name: "User", foreign_key: "author"
  belongs_to :course, optional: true
  belongs_to :lesson, class_name: "CourseLesson", foreign_key: "lesson", optional: true
  has_many :replies, class_name: "LmsMessage", foreign_key: "parent", dependent: :destroy

  # Validations
  validates :topic, presence: true
  validates :author, presence: true

  # Scopes
  scope :pinned, -> { where(is_pinned: true) }
  scope :featured, -> { where(is_featured: true) }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_lesson, ->(lesson) { where(lesson: lesson) }
  scope :by_author, ->(author) { where(author: author) }

  # Instance methods
  def author_name
    author&.full_name || author&.username || author&.email
  end

  def author_image
    author&.user_image
  end

  def reply_count
    replies.count
  end

  def is_reply?
    parent.present?
  end

  def parent_topic
    return nil unless is_reply?
    LmsMessage.find_by(name: parent)
  end

  def name
    self[:name] || "#{author}-#{created_at&.to_i}"
  end

  def to_frappe_format
    {
      "name" => name,
      "topic" => topic,
      "reply" => reply,
      "author" => author&.email,
      "author_name" => author_name,
      "author_image" => author_image,
      "course" => course&.name,
      "lesson" => lesson&.name,
      "is_pinned" => is_pinned,
      "is_featured" => is_featured,
      "reply_count" => reply_count,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "owner" => owner || author&.email
    }
  end
end
