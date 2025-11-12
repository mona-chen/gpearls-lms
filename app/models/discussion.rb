class Discussion < ApplicationRecord
  belongs_to :user
  belongs_to :course
  has_many :messages, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true, length: { maximum: 2000 }
  validates :status, presence: true, inclusion: { in: %w[open closed archived] }
  validates :user, presence: true
  validates :course, presence: true

  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :archived, -> { where(status: "archived") }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_course, ->(course) { where(course: course) }

  def open?
    status == "open"
  end

  def closed?
    status == "closed"
  end

  def archived?
    status == "archived"
  end

  def close!
    update!(status: "closed")
  end

  def archive!
    update!(status: "archived")
  end

  def reply_count
    messages.count
  end

  def last_reply_at
    messages.maximum(:created_at)
  end

  def last_reply_by
    messages.includes(:user).order(created_at: :desc).first&.user
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: id,
      title: title,
      content: content,
      status: status,
      course: course_id,
      course_title: course&.title,
      owner: user&.email,
      owner_name: user&.full_name,
      reply_count: reply_count,
      last_reply_at: last_reply_at&.strftime("%Y-%m-%d %H:%M:%S"),
      last_reply_by: last_reply_by&.full_name,
      creation: created_at.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
