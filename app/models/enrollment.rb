class Enrollment < ApplicationRecord
  self.table_name = "lms_enrollments"

  # Database column aliases (Frappe compatibility)
  alias_attribute :user_id, :student_id

  # Associations
  belongs_to :user, foreign_key: :student_id
  belongs_to :course
  belongs_to :batch, optional: true

  # Association for lesson progress (through user)
  has_many :lesson_progresses, through: :user, source: :lesson_progress

  # Validations
  validates :user_id, uniqueness: { scope: :course_id }
  validates :progress_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Callbacks
  before_create :set_enrollment_date
  before_create :generate_enrollment_number

  # Scopes
  scope :completed, -> { where("progress_percentage >= 100") }
  scope :in_progress, -> { where("progress_percentage < 100") }
  scope :active, -> { where(status: "Active") }
  scope :by_course, ->(course) { where(course: course) }

  # Instance Methods
  def completed?
    progress_percentage >= 100
  end

  def is_completed?
    completed?
  end

  def in_progress?
    progress_percentage.present? && progress_percentage > 0 && progress_percentage < 100
  end

  def not_started?
    progress_percentage.nil? || progress_percentage == 0
  end

  def progress_percentage
    return 0 if course.nil?

    total_lessons = course.lessons.count
    return 0 if total_lessons.zero?

    # Count completed lessons that belong to this course
    completed_lessons = lesson_progresses.where(status: "Complete")
                                         .select { |lp| lp.lesson&.course == course }
                                         .count
    (completed_lessons.to_f / total_lessons * 100).round
  end

  def completion_percentage
    progress_percentage
  end

  def completed_lessons_count
    lesson_progresses.where(status: "Complete")
                     .select { |lp| lp.lesson&.course == course }
                     .count
  end

  def current_lesson
    # Find the first lesson that is not completed
    course.lessons.each do |lesson|
      return lesson unless lesson_progresses.where(lesson: lesson, status: "Complete").exists?
    end
    # If all lessons are completed, return the last lesson
    course.lessons.last
  end

  # Alias for backward compatibility
  def progress
    progress_percentage
  end

  def days_enrolled
    (Date.current - enrollment_date.to_date).to_i
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "course" => course.title,
      "course_name" => course.name,
      "member" => user.email,
      "member_name" => user.full_name,
      "progress" => progress_percentage || 0,
      "enrollment_date" => enrollment_date&.strftime("%Y-%m-%d %H:%M:%S"),
      "completion_date" => completed? ? updated_at.strftime("%Y-%m-%d %H:%M:%S") : nil,
      "status" => completed? ? "Completed" : "In Progress"
    }
  end

  private

  def set_enrollment_date
    self.enrollment_date ||= Time.current
  end

  def generate_enrollment_number
    return if enrollment_number.present?

    # Generate a unique enrollment number like ENR-00001
    loop do
      number = "ENR-#{SecureRandom.random_number(100000).to_s.rjust(5, '0')}"
      self.enrollment_number = number
      break unless self.class.exists?(enrollment_number: number)
    end
  end
end
