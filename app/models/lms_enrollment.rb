class LmsEnrollment < ApplicationRecord
  # Database column aliases (Frappe compatibility)
  alias_attribute :progress, :progress_percentage
  alias_attribute :user_id, :student_id

  # Associations
  belongs_to :course
  belongs_to :user

  # Validations
  validates :course_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :course_id, message: "is already enrolled in this course" }
  validates :status, presence: true, inclusion: { in: %w[Active Completed Suspended Cancelled] }
  validates :progress_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Callbacks
  before_validation :set_defaults
  before_create :set_enrollment_date
  before_create :generate_enrollment_number
  after_update :update_completion_date

  # Scopes
  scope :active, -> { where(status: "Active") }
  scope :completed, -> { where(status: "Completed") }
  scope :suspended, -> { where(status: "Suspended") }
  scope :cancelled, -> { where(status: "Cancelled") }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_course, ->(course) { where(course: course) }
  scope :recent, -> { order(enrollment_date: :desc) }
  scope :by_progress, ->(min_progress = 0) { where("progress >= ?", min_progress) }

  # Instance methods
  def active?
    status == "Active"
  end

  def completed?
    status == "Completed"
  end

  def suspended?
    status == "Suspended"
  end

  def cancelled?
    status == "Cancelled"
  end

  def update_progress(new_progress)
    return false if new_progress < progress || new_progress > 100

    update!(progress: new_progress)

    # Check if course is completed
    if new_progress >= 100 && status != "Completed"
      update!(status: "Completed", completion_date: Time.current)
    end

    true
  end

  def mark_completed
    update!(
      status: "Completed",
      progress: 100.0,
      completion_date: Time.current
    )
  end

  def suspend
    update!(status: "Suspended")
  end

  def reactivate
    update!(status: "Active")
  end

  def cancel
    update!(status: "Cancelled")
  end

  def time_enrolled
    return nil unless enrollment_date
    Time.current - enrollment_date
  end

  def completion_time
    return nil unless completion_date && enrollment_date
    completion_date - enrollment_date
  end

  def days_to_complete
    return nil unless completion_time
    (completion_time / 1.day).to_i
  end

  def current_lesson
    course_progresses.joins(:lesson).where("lms_course_progresses.status != ?", "Completed").order(:position).first&.lesson
  end

  def completed_lessons
    course_progresses.where(status: "Completed").joins(:lesson).order(:position)
  end

  def total_lessons
    course.lessons.count
  end

  def lessons_completed_count
    completed_lessons.count
  end

  def completion_percentage_by_lessons
    return 0 if total_lessons.zero?
    (lessons_completed_count.to_f / total_lessons * 100).round(2)
  end

  def to_frappe_format
    {
      "name" => "#{course.name}-#{user.id}",
      "course" => course.name,
      "member" => user.email,
      "status" => status,
      "progress" => progress,
      "enrollment_date" => enrollment_date&.strftime("%Y-%m-%d %H:%M:%S"),
      "completion_date" => completion_date&.strftime("%Y-%m-%d %H:%M:%S"),
      "batch_name" => batch_name,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.enroll_user(user, course, options = {})
    return nil unless user && course

    enrollment = find_or_initialize_by(user: user, course: course)

    if enrollment.new_record?
      enrollment.assign_attributes(options)
      enrollment.save!
    end

    enrollment
  end

  def self.get_user_enrollments(user, status = nil)
    enrollments = by_user(user)
    enrollments = enrollments.where(status: status) if status.present?
    enrollments.includes(:course, :user)
  end

  def self.get_course_enrollments(course, status = nil)
    enrollments = by_course(course)
    enrollments = enrollments.where(status: status) if status.present?
    enrollments.includes(:course, :user)
  end

  def self.get_enrollment_stats(course = nil)
    if course
      enrollments = by_course(course)
    else
      enrollments = all
    end

    {
      total: enrollments.count,
      active: enrollments.active.count,
      completed: enrollments.completed.count,
      suspended: enrollments.suspended.count,
      cancelled: enrollments.cancelled.count,
      average_progress: enrollments.average(:progress)&.round(2) || 0
    }
  end

  def self.get_recent_enrollments(limit = 10)
    recent.limit(limit).includes(:course, :user)
  end

  def self.get_enrollments_by_date_range(start_date, end_date)
    where(enrollment_date: start_date..end_date)
  end

  def self.get_completion_rate(course = nil)
    enrollments = course ? by_course(course) : all
    total = enrollments.count
    return 0 if total.zero?

    completed = enrollments.completed.count
    (completed.to_f / total * 100).round(2)
  end

  def self.get_active_enrollments_count
    active.count
  end

  def self.get_completed_enrollments_count
    completed.count
  end

  def self.get_enrollments_by_status
    group(:status).count
  end

  def self.get_enrollments_by_progress_ranges
    ranges = {
      "0-25%" => 0..25,
      "26-50%" => 26..50,
      "51-75%" => 51..75,
      "76-99%" => 76..99,
      "100%" => 100..100
    }

    result = {}
    ranges.each do |label, range|
      result[label] = where(progress: range).count
    end

    result
  end

  private

  def set_defaults
    self.status ||= "Active"
    self.progress ||= 0.0
  end

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

  def update_completion_date
    if saved_change_to_status? && status == "Completed" && !completion_date
      self.completion_date = Time.current
    end
  end
end
