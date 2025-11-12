class LmsProgramMember < ApplicationRecord
  # Associations
  belongs_to :lms_program
  belongs_to :user

  # Validations
  validates :lms_program_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :lms_program_id }
  validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Callbacks
  before_validation :set_defaults
  after_create :update_program_member_count
  after_destroy :update_program_member_count

  # Instance methods
  def update_progress(new_progress)
    return false if new_progress < progress # Progress should only increase

    update!(progress: new_progress, modified: Time.current)
  end

  def completed?
    progress >= 100.0
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: id,
      program: lms_program_id,
      member: user_id,
      member_name: user&.full_name,
      member_username: user&.username,
      progress: progress,
      completed: completed?,
      creation: creation&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: modified&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_defaults
    self.creation ||= Time.current
    self.modified ||= Time.current
    self.progress ||= 0.0
  end

  def update_program_member_count
    lms_program.update_counts
  end
end
