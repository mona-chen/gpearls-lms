class LmsQuizQuestion < ApplicationRecord
  self.table_name = "lms_quiz_questions"

  # Associations
  belongs_to :lms_quiz, foreign_key: :quiz_id
  belongs_to :quiz, foreign_key: :quiz_id, class_name: "LmsQuiz"
  belongs_to :lms_question, foreign_key: :question_id

  # Validations
  validates :quiz_id, presence: true
  validates :question_id, presence: true
  validates :marks, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :by_quiz, ->(quiz_id) { where(quiz_id: quiz_id) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }

  # Instance methods
  def question_detail
    lms_question&.question
  end

  def question_type
    lms_question&.type
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "quiz" => quiz.to_s,
      "question" => question.to_s,
      "marks" => marks,
      "question_detail" => question_detail,
      "type" => question_type,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
