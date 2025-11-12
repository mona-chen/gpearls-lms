class CourseChapter < ApplicationRecord
  self.table_name = "course_chapters"
  self.primary_key = "name"

  belongs_to :course, class_name: "Course", foreign_key: "course"
  has_many :lessons, class_name: "CourseLesson", foreign_key: "chapter", dependent: :destroy

  validates :title, presence: true
end
