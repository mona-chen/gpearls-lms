class Lesson < ApplicationRecord
  belongs_to :chapter
  belongs_to :course
  has_many :course_progresses, dependent: :destroy

  validates :title, presence: true
end