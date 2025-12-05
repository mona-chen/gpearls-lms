# app/models/course_lesson.rb
class CourseLesson < ApplicationRecord
  # Frappe-style fields
  attribute :name, :string
  attribute :owner, :string
  attribute :creation, :datetime
  attribute :modified, :datetime
  attribute :modified_by, :string
  attribute :docstatus, :string, default: "0"
  attribute :parent, :string
  attribute :parenttype, :string
  attribute :parentfield, :string
  attribute :idx, :integer

  # Associations
  belongs_to :chapter, class_name: "CourseChapter", foreign_key: "chapter"
  belongs_to :course, class_name: "Course", foreign_key: "course", optional: true
  alias_attribute :course_chapter, :chapter

  has_many :quiz_submissions, class_name: "LmsQuizSubmission", foreign_key: "lesson", dependent: :destroy
  has_many :assignment_submissions, class_name: "LmsAssignmentSubmission", foreign_key: "lesson", dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :chapter, presence: true
  validates :file_type, inclusion: { in: %w[Image Document PDF Video], allow_blank: true }

  # Callbacks
  before_validation :set_course_from_chapter
  before_validation :set_is_scorm_package_from_chapter
  before_create :set_name

  # Scopes
  scope :in_preview, -> { where(include_in_preview: true) }
  scope :for_course, ->(course) { where(course: course) }
  scope :for_chapter, ->(chapter) { where(chapter: chapter) }
  scope :with_quiz, -> { where.not(quiz_id: nil) }
  scope :with_video, -> { where.not(youtube: nil) }
  scope :with_assignment, -> { where.not(question: nil) }
  scope :scorm_packages, -> { where(is_scorm_package: true) }

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
    body.present? || content.present?
  end

  def has_instructor_content?
    instructor_content.present? || instructor_notes.present?
  end

  def quiz
    return nil unless quiz_id
    LmsQuiz.find_by(name: quiz_id)
  end

  def assignment
    return nil unless question.present?
    # Return assignment data if this lesson has an assignment
    {
      question: question,
      file_type: file_type,
      help: help
    }
  end

  def name
    self[:name] || "#{chapter}-#{title.parameterize}"
  end

  def display_name
    "#{idx.to_s.rjust(2, '0')} #{title}"
  end

  def to_frappe_format
    {
      "name" => name,
      "title" => title,
      "chapter" => chapter,
      "course" => course,
      "include_in_preview" => include_in_preview,
      "is_scorm_package" => is_scorm_package,
      "content" => content,
      "body" => body,
      "instructor_content" => instructor_content,
      "instructor_notes" => instructor_notes,
      "youtube" => youtube,
      "quiz_id" => quiz_id,
      "question" => question,
      "file_type" => file_type,
      "help" => help,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "owner" => owner || "Administrator"
    }
  end

  private

  def set_course_from_chapter
    self.course = chapter&.course if chapter.present?
  end

  def set_is_scorm_package_from_chapter
    self.is_scorm_package = chapter&.is_scorm_package if chapter.present?
  end

  def set_name
    self.name = "#{chapter}-#{title.parameterize}" unless self[:name]
  end
end
