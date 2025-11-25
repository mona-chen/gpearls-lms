class LmsQuizSubmission < ApplicationRecord
  self.table_name = "lms_quiz_submissions"

  # Associations
  belongs_to :quiz, class_name: "LmsQuiz"
  belongs_to :member, class_name: "User", foreign_key: :member
  belongs_to :course, optional: true

  # Validations
  validates :quiz, presence: true
  validates :member, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Callbacks
  before_create :set_defaults

  # Scopes
  scope :by_quiz, ->(quiz_id) { where(quiz_id: quiz_id) }
  scope :by_member, ->(member_id) { where(member_id: member_id) }
  scope :passed, -> { where("percentage >= passing_percentage") }
  scope :failed, -> { where("percentage < passing_percentage") }

  # Instance methods
  def passed?
    return false unless percentage && quiz
    percentage >= quiz.passing_percentage
  end

  def failed?
    !passed?
  end

  def time_taken
    return nil unless started_at && completed_at
    ((completed_at - started_at) / 60).round(2) # in minutes
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "quiz" => quiz_id.to_s,
      "member" => member_id.to_s,
      "member_name" => member&.full_name,
      "score" => score,
      "percentage" => percentage,
      "passing_percentage" => quiz&.passing_percentage,
      "result" => passed? ? "Pass" : "Fail",
      "started_at" => started_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "completed_at" => completed_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "time_taken" => time_taken,
      "answers" => answers, # JSON field with user's answers
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
  private

  def set_defaults
    self.started_at ||= Time.current
    self.passing_percentage ||= quiz&.passing_percentage || 50
  end
end
