class LmsProgrammingExercise < ApplicationRecord
  self.table_name = "lms_programming_exercises"

  # Associations
  has_many :lms_programming_exercise_submissions, foreign_key: :exercise, dependent: :destroy
  has_many :lms_test_cases, dependent: :destroy

  # Validations
  validates :title, :problem_statement, :language, presence: true
  validates :language, inclusion: { in: %w[Python JavaScript] }

  # Scopes
  scope :by_language, ->(language) { where(language: language) }
  scope :python, -> { where(language: "Python") }
  scope :javascript, -> { where(language: "JavaScript") }

  # Instance methods
  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "title" => title,
      "language" => language,
      "problem_statement" => problem_statement,
      "test_cases" => lms_test_cases.map(&:to_frappe_format),
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
