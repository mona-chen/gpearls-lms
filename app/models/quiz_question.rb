class QuizQuestion < ApplicationRecord
  self.inheritance_column = nil # Disable STI since we use 'type' for question type

  belongs_to :quiz
  has_many :quiz_results, dependent: :destroy

  validates :question, presence: true
end
