class DiscussionTopic < ApplicationRecord
  self.table_name = "discussion_topics"

  # Associations
  has_many :discussion_replies, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :reference_doctype, presence: true
  validates :reference_docname, presence: true

  # Scopes
  scope :by_reference, ->(doctype, docname) { where(reference_doctype: doctype, reference_docname: docname) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_create :set_title_if_blank

  # Instance methods
  def owner_name
    # In Frappe, owner is stored as email
    User.find_by(email: owner)&.full_name || owner
  end

  def reply_count
    discussion_replies.count
  end

  def last_reply_at
    discussion_replies.maximum(:created_at)
  end

  def last_reply_by
    discussion_replies.includes(:owner_user).order(created_at: :desc).first&.owner_user
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "title" => title,
      "reference_doctype" => reference_doctype,
      "reference_docname" => reference_docname,
      "owner" => owner,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_title_if_blank
    self.title ||= reference_docname if reference_docname
  end
end
