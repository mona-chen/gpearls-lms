class Course < ApplicationRecord
  belongs_to :instructor, class_name: 'User', optional: true
  belongs_to :evaluator, class_name: 'User', optional: true

  has_many :chapters, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :course_progresses, dependent: :destroy
  has_many :quizzes, dependent: :destroy

  validates :title, presence: true
end