class LmsAssignment < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :chapter, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  has_many :assignment_submissions, dependent: :destroy

  # Validations
  validates :title, :course, presence: true
  validates :total_marks, :passing_percentage, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :published, -> { where(status: "Published") }
  scope :due_soon, -> { where("due_date > ? AND due_date < ?", Time.current, 7.days.from_now) }
  scope :overdue, -> { where("due_date < ?", Time.current) }

  # Instance methods
  def allow_file_upload?
    # For now, allow file uploads for all assignments
    # In the future, this could check a specific field
    true
  end

  def submitted_by?(user)
    assignment_submissions.where(user: user).exists?
  end

  def submission_for(user)
    assignment_submissions.find_by(user: user)
  end

  def overdue?
    due_date.present? && due_date < Time.current
  end

  def due_soon?
    due_date.present? && due_date > Time.current && due_date < 7.days.from_now
  end
end
