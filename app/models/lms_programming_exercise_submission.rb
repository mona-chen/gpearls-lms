class LmsProgrammingExerciseSubmission < ApplicationRecord
  self.table_name = "lms_programming_exercise_submissions"

  # Associations
  belongs_to :exercise, class_name: "LmsProgrammingExercise", foreign_key: :exercise
  belongs_to :member, class_name: "User", foreign_key: :member

  # Validations
  validates :exercise, :member, :code, presence: true
  validates :member, uniqueness: { scope: :exercise }

  # Scopes
  scope :by_exercise, ->(exercise_id) { where(exercise_id: exercise_id) }
  scope :by_member, ->(member_id) { where(member_id: member_id) }
  scope :passed, -> { where(status: "Passed") }
  scope :failed, -> { where(status: "Failed") }

  # Instance methods
  def passed?
    status == "Passed"
  end

  def failed?
    status == "Failed"
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "exercise" => exercise_id.to_s,
      "member" => member&.email,
      "code" => code,
      "language" => language,
      "status" => status,
      "output" => output,
      "error" => error,
      "execution_time" => execution_time,
      "memory_used" => memory_used,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
