class Certificate < ApplicationRecord
  self.table_name = "lms_certificates"

  # Associations
  belongs_to :member, class_name: "User", foreign_key: :member
  belongs_to :course, optional: true
  belongs_to :batch, optional: true
  belongs_to :evaluator, class_name: "User", optional: true

  # Validations
  validates :member, presence: true
  validates :issue_date, presence: true

  # Callbacks
  before_create :set_defaults

  # Scopes
  scope :published, -> { where(published: true) }
  scope :by_member, ->(member_id) { where(member_id: member_id) }
  scope :by_course, ->(course_id) { where(course_id: course_id) }
  scope :by_batch, ->(batch_id) { where(batch_id: batch_id) }
  scope :expired, -> { where("expiry_date < ?", Date.current) }
  scope :valid_certificates, -> { where("expiry_date IS NULL OR expiry_date >= ?", Date.current) }

  # Instance methods
  def member_name
    member&.full_name
  end

  def evaluator_name
    evaluator&.full_name
  end

  def course_title
    course&.title
  end

  def batch_title
    batch&.title
  end

  def expired?
    expiry_date.present? && expiry_date < Date.current
  end

  def valid?
    !expired?
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "member" => member_id.to_s,
      "member_name" => member_name,
      "evaluator" => evaluator&.id.to_s,
      "evaluator_name" => evaluator_name,
      "issue_date" => issue_date&.strftime("%Y-%m-%d"),
      "expiry_date" => expiry_date&.strftime("%Y-%m-%d"),
      "template" => template,
      "published" => published || false,
      "course" => course&.name,
      "course_title" => course_title,
      "batch_name" => batch&.name,
      "batch_title" => batch_title,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_defaults
    self.issue_date ||= Date.current
    self.published ||= false
  end
end
