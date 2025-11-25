class QuizSubmission < ApplicationRecord
  self.table_name = "lms_quiz_submissions"

  belongs_to :user, foreign_key: :student_id
  belongs_to :quiz, class_name: "LmsQuiz"
  belongs_to :course, optional: true

  validates :student_id, presence: true
  validates :quiz_id, presence: true

  # Alias for compatibility
  alias_attribute :score, :percentage
  alias_attribute :user_id, :student_id
  validates :percentage, presence: true, numericality: { in: 0..100 }
  validates :total_marks, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :passed, -> { where("percentage >= ?", 70) }
  scope :failed, -> { where("percentage < ?", 70) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def passed?
    percentage >= 70
  end

  def failed?
    percentage < 70
  end

  def grade
    case percentage
    when 90..100 then "A"
    when 80..89 then "B"
    when 70..79 then "C"
    when 60..69 then "D"
    else "F"
    end
  end

  # Frappe compatibility methods
  def self.get_user_submissions(user, course = nil)
    submissions = where(user: user)
    submissions = submissions.where(course: course) if course
    submissions.order(created_at: :desc)
  end

  def self.get_pass_rate(course = nil)
    submissions = course ? where(course: course) : all
    total = submissions.count
    return 0 if total == 0

    passed = submissions.passed.count
    (passed.to_f / total * 100).round(2)
  end

  def self.get_average_score(course = nil)
    submissions = course ? where(course: course) : all
    return 0 if submissions.empty?

    submissions.average(:percentage).round(2)
  end
end
