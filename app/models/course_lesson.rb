# app/models/course_lesson.rb
class CourseLesson < ApplicationRecord
  # Associations
  belongs_to :chapter, class_name: "CourseChapter", foreign_key: "chapter"
  belongs_to :course, class_name: "Course", foreign_key: "course", optional: true
  alias_attribute :course_chapter, :chapter

  # Validations
  validates :title, presence: true
  validates :chapter, presence: true
  validates :file_type, inclusion: { in: %w[Image Document PDF], allow_blank: true }
  validates :file_type, presence: true, if: -> { question.present? }

  # Callbacks
  before_validation :set_course_from_chapter
  before_validation :set_is_scorm_package_from_chapter

  # Scopes
  scope :in_preview, -> { where(include_in_preview: true) }
  scope :for_course, ->(course) { where(course: course) }
  scope :for_chapter, ->(chapter) { where(chapter: chapter) }
  scope :with_quiz, -> { where.not(quiz_id: nil) }
  scope :with_video, -> { where.not(youtube: nil) }
  scope :with_assignment, -> { where.not(question: nil) }

  # Auto-naming similar to Frappe's autoname
  def display_name
    "#{id.to_s.rjust(4, '0')} #{title}"
  end

  # Instance methods
  def has_quiz?
    quiz_id.present?
  end

  def has_video?
    youtube.present?
  end

  def has_assignment?
    question.present?
  end

  def has_body_content?
    body.present?
  end

  def has_instructor_content?
    instructor_content.present? || instructor_notes.present?
  end

  private

  def set_course_from_chapter
    self.course = chapter&.course if chapter.present?
  end

  def set_is_scorm_package_from_chapter
    self.is_scorm_package = chapter&.is_scorm_package if chapter.present?
  end
end
