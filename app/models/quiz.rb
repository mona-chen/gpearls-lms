class Quiz < ApplicationRecord
  self.table_name = "lms_quizzes"

  belongs_to :course, optional: true
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_submissions, dependent: :destroy

  validates :title, presence: true
end
