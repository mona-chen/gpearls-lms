class CourseProgress < ApplicationRecord
  self.table_name = "lms_course_progresses"

  # Note: member and course are stored as strings (email/name), not foreign keys
  # belongs_to :user, foreign_key: :member
  # belongs_to :course, foreign_key: :course
  # lesson is stored as string (name), not association

  # Validations
  validates :member, presence: true
  validates :course, presence: true
  validates :lesson, presence: true
  validates :status, presence: true, inclusion: { in: %w[Incomplete Complete] }

  # Callbacks
  before_create :set_creation_date
  before_save :set_modified_date
  before_create :generate_name

  # Ensure a user can only have one progress record per lesson
  validates :member, uniqueness: { scope: [ :course, :lesson ] }

  # Scopes for different statuses
  scope :completed, -> { where(status: "Complete") }
  scope :incomplete, -> { where(status: "Incomplete") }

  # Class methods matching Frappe Python implementation
  def self.get_progress(course, member, lesson)
    find_by(member: member, course: course, lesson: lesson.name, status: "Complete")
  end

  def self.completed_lessons_count(course, member)
    where(member: member, course: course, status: "Complete").count
  end

  def self.mark_complete(course, member, lesson)
    find_or_initialize_by(
      member: member,
      course: course,
      lesson: lesson.name
    ).tap do |progress|
      progress.status = "Complete"
      progress.save!
    end
  end

  def self.mark_incomplete(course, member, lesson)
    progress = find_by(member: member, course: course, lesson: lesson.name)
    progress&.update!(status: "Incomplete")
  end

  # Instance methods
  def completed?
    status == "Complete"
  end

  def incomplete?
    status == "Incomplete"
  end

  def complete!
    update!(status: "Complete")
  end

  def incomplete!
    update!(status: "Incomplete")
  end

  # Helper method for Frappe compatibility
  def self.exists_complete(course, member, lesson)
    exists?(member: member, course: course, lesson: lesson.name, status: "Complete")
  end

  private

  def set_creation_date
    self.creation ||= Time.current
  end

  def set_modified_date
    self.modified = Time.current
    self.modified_by = owner || member
  end

  def generate_name
    self.name ||= SecureRandom.uuid
    self.owner ||= member
  end
end
