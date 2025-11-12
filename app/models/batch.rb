class Batch < ApplicationRecord
  self.table_name = "lms_batches"
  belongs_to :instructor, class_name: "User", optional: true
  has_many :batch_enrollments, dependent: :destroy
  has_many :batch_courses, dependent: :destroy
  has_many :courses, through: :batch_courses
  has_many :users, through: :batch_enrollments, source: :user
  has_many :assessments, dependent: :destroy
  has_many :live_classes, dependent: :destroy
  has_many :batch_timetables, foreign_key: :parent, primary_key: :name, dependent: :destroy
  has_many :certificates, dependent: :destroy
  has_many :payments, as: :payable, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :timezone, presence: true
  validates :description, presence: true, length: { maximum: 1000 }
   validates :additional_info, presence: true
   validates :instructor, presence: true
  validate :validate_end_date_after_start_date
  validate :validate_time_order
  validate :validate_duplicate_courses
  validate :validate_payment_requirements
  # validate :validate_evaluation_end_date
  # validate :validate_timetable_consistency
  # validate :validate_seats_availability

  # Callbacks
  before_validation :set_timezone_default
  # before_save :set_published_at
  after_create :create_default_timetable
  after_update :handle_status_changes

  # Scopes
  scope :published, -> { where(published: true) }
  scope :active, -> { where(start_date: ..Date.current, end_date: Date.current..) }
  scope :upcoming, -> { where(start_date: Date.current..) }
  scope :completed, -> { where(end_date: ...Date.current) }
  scope :paid, -> { where(paid_batch: true) }
  scope :free, -> { where(paid_batch: false) }
  scope :with_certification, -> { where(certificate_enabled: true) }
  scope :allowing_self_enrollment, -> { where(allow_self_enrollment: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_instructor, ->(instructor) { where(instructor: instructor) }
  scope :starting_soon, -> { where(start_date: Date.current..7.days.from_now) }

  # Frappe compatibility methods
  def name
    title.parameterize.gsub("-", "_")
  end

  def status
    if end_date < Date.current
      "Completed"
    elsif start_date <= Date.current
      "Active"
    else
      "Upcoming"
    end
  end

  def active?
    status == "Active"
  end

  def upcoming?
    status == "Upcoming"
  end

  def completed?
    status == "Completed"
  end

  def max_seats
    max_students
  end

  def current_seats
    batch_enrollments.count
  end

  def seats_left
    return Float::INFINITY unless max_students&.positive?
    max_students - current_seats
  end

  def full?
    return false unless max_students&.positive?
    current_seats >= max_students
  end

  def seats_available?
    !full?
  end

  def accept_enrollments?
    return false unless allow_self_enrollment && published
    return false if full?
    return true if upcoming?
    return true if active? && start_time&.to_time > Time.current
    false
  end

  def duration_days
    (end_date - start_date).to_i + 1
  end

  def instructors_list
    instructors.is_a?(Array) ? instructors : []
  end

  def add_instructor(user)
    return false unless user.is_a?(User)

    current_instructors = instructors_list
    current_instructors << user.email unless current_instructors.include?(user.email)
    update(instructors: current_instructors)
  end

  def remove_instructor(user)
    return false unless user.is_a?(User)

    current_instructors = instructors_list
    current_instructors.delete(user.email)
    update(instructors: current_instructors)
  end

  def has_instructor?(user)
    instructors_list.include?(user.email)
  end

  # Timetable methods
  def get_timetable(start_date: nil, end_date: nil)
    timetable = batch_timetables.includes(:reference_doc)
                .order(:date, :start_time)

    if start_date
      timetable = timetable.where("date >= ?", start_date)
    end

    if end_date
      timetable = timetable.where("date <= ?", end_date)
    end

    # Include live classes if enabled
    if show_live_class
      timetable = timetable + live_classes.order(:date, :time)
    end

    timetable.sort_by { |entry| [ entry.date, entry.start_time || entry.time ] }
  end

  def add_timetable_entry(reference_doctype, reference_docname, date, start_time, end_time, milestone: false)
    batch_timetables.create!(
      reference_doctype: reference_doctype,
      reference_docname: reference_docname,
      date: date,
      start_time: start_time,
      end_time: end_time,
      milestone: milestone
    )
  end

  def create_live_class(title:, date:, time:, duration:, description: nil, auto_recording: "none")
    live_classes.create!(
      title: title,
      date: date,
      time: time,
      duration: duration,
      description: description,
      auto_recording: auto_recording,
      batch: self
    )
  end

  # Assessment methods
  def add_assessment(assessment_type, assessment_name, due_date: nil, max_marks: 100)
    assessments.create!(
      assessment_type: assessment_type,
      assessment_name: assessment_name,
      due_date: due_date,
      max_marks: max_marks
    )
  end

  def pending_assessments_for(user)
    user_assessment_submissions = LmsAssessmentSubmission.where(user: user, assessment: assessments)
                                                  .pluck(:assessment_id)

    assessments.where.not(id: user_assessment_submissions)
               .where("due_date IS NULL OR due_date >= ?", Date.current)
  end

  # Certificate methods
  def issue_certificate(user, template: "default")
    return false unless certificate_enabled && user.completed_batch?(self)

    certificates.create!(
      user: user,
      template: template,
      issue_date: Date.current,
      expiry_date: 1.year.from_now.to_date,
      published: true
    )
  end

  # Payment methods
  def create_payment(user, amount: nil, currency: nil)
    return false unless paid_batch

    payment_amount = amount || self.amount
    payment_currency = currency || self.currency

    payments.create!(
      user: user,
      amount: payment_amount,
      currency: payment_currency,
      status: "Pending",
      payment_date: Date.current
    )
  end

  def paid_by?(user)
    payments.where(user: user, status: "Completed").exists?
  end

  def enrollment_cost_for(user)
    return 0 unless paid_batch
    return 0 if paid_by?(user)
    amount || 0
  end

  # Statistics
  def enrollment_statistics
    {
      total_enrollments: batch_enrollments.count,
      active_enrollments: batch_enrollments.joins(:batch).where(batches: { end_date: Date.current.. }).count,
      completed_enrollments: batch_enrollments.joins(:batch).where(batches: { end_date: ...Date.current }).count,
      seats_filled: current_seats,
      seats_available: seats_left,
      fill_percentage: seat_count ? (current_seats.to_f / seat_count * 100).round(2) : 0,
      revenue: payments.where(status: "Completed").sum(:amount)
    }
  end

  def progress_statistics
    {
      total_students: batch_enrollments.count,
      average_progress: calculate_average_progress,
      completion_rate: calculate_completion_rate,
      certificate_issued: certificates.count
    }
  end

  # Alias for Frappe compatibility
  def certification
    certificate_enabled
  end

  def seat_count
    max_students
  end

  def evaluation_end_date
    # Not implemented in current schema, return nil for compatibility
    nil
  end

  def medium
    # Not implemented in current schema, return default for compatibility
    "Online"
  end

  def confirmation_email_template
    # Not implemented in current schema, return default for compatibility
    "batch_confirmation"
  end

  def instructors
    # Return array of instructor emails for Frappe compatibility
    [ instructor&.email ].compact
  end

  def zoom_account
    # Not implemented in current schema, return nil for compatibility
    nil
  end

  def paid_batch
    # Not implemented in current schema, return false for compatibility
    false
  end

  def amount
    # Not implemented in current schema, return 0 for compatibility
    0
  end

  def currency
    # Not implemented in current schema, return default for compatibility
    "NGN"
  end

  def amount_usd
    # Not implemented in current schema, return 0 for compatibility
    0
  end

  def show_live_class
    # Not implemented in current schema, return false for compatibility
    false
  end

  def allow_future
    # Not implemented in current schema, return false for compatibility
    false
  end

  def to_frappe_format
    {
      name: name,
      title: title,
      start_date: start_date&.strftime("%Y-%m-%d"),
      end_date: end_date&.strftime("%Y-%m-%d"),
      start_time: start_time&.strftime("%H:%M:%S"),
      end_time: end_time&.strftime("%H:%M:%S"),
      timezone: timezone,
      description: description,
        batch_details: additional_info,
      published: published,
      allow_self_enrollment: allow_self_enrollment,
      certification: certificate_enabled,
      seat_count: seat_count,
      evaluation_end_date: evaluation_end_date,
      medium: medium,
      category: category,
      confirmation_email_template: confirmation_email_template,
      instructors: instructors_list,
      zoom_account: zoom_account,
      paid_batch: paid_batch,
      amount: amount,
      currency: currency,
      amount_usd: amount_usd,
      show_live_class: show_live_class,
      allow_future: allow_future,
      status: status,
      current_seats: current_seats,
      seats_left: seats_left,
      full: full?,
      accept_enrollments: accept_enrollments?,
      courses: batch_courses.map(&:to_frappe_format),
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.categorize_batches(batches)
    {
      "active" => batches.select(&:active?),
      "upcoming" => batches.select(&:upcoming?),
      "completed" => batches.select(&:completed?)
    }
  end

  def self.get_available_batches(user = nil)
    query = published.allowing_self_enrollment.seats_available

    if user
      # Exclude batches user is already enrolled in
      enrolled_batch_ids = user.batch_enrollments.pluck(:batch_id)
      query = query.where.not(id: enrolled_batch_ids)
    end

    query
  end

  def self.get_batches_by_instructor(instructor)
    where("instructors LIKE ?", "%#{instructor.email}%")
  end

  def self.send_start_reminders
    tomorrow = Date.current + 1.day
    batches = published.where(start_date: tomorrow)

    batches.find_each do |batch|
      batch.batch_enrollments.includes(:user).find_each do |enrollment|
        BatchMailer.start_reminder(enrollment).deliver_later
      end
    end
  end

  private

  def validate_end_date_after_start_date
    return unless start_date && end_date

    if end_date < start_date
      errors.add(:end_date, "cannot be before the start date")
    end
  end

  def validate_time_order
    return unless start_time && end_time

    if start_time >= end_time
      errors.add(:end_time, "must be after the start time")
    end
  end

  def validate_duplicate_courses
    return unless batch_courses

    course_ids = batch_courses.pluck(:course_id)
    duplicates = course_ids.group_by(&:itself).select { |id, group| group.size > 1 }.keys

    if duplicates.any?
      duplicate_titles = Course.where(id: duplicates).pluck(:title)
      errors.add(:base, "Duplicate courses found: #{duplicate_titles.join(', ')}")
    end
  end

  def validate_payment_requirements
    return unless price&.positive?

    if price.blank? || currency.blank?
      errors.add(:base, "Price and currency are required for paid batches")
    end
  end

  def validate_evaluation_end_date
    return unless evaluation_end_date && end_date

    if evaluation_end_date < end_date
      errors.add(:evaluation_end_date, "cannot be before the batch end date")
    end
  end

  def validate_timetable_consistency
    return unless batch_timetables.any?

    batch_timetables.each do |entry|
      if entry.date && (entry.date < start_date || entry.date > end_date)
        errors.add(:base, "Timetable entry date #{entry.date} is outside batch duration")
      end

      if entry.start_time && entry.end_time
        if entry.start_time >= entry.end_time
          errors.add(:base, "Timetable entry start time must be before end time")
        end

        if entry.start_time < start_time || entry.end_time > end_time
          errors.add(:base, "Timetable entry time is outside batch time range")
        end
      end
    end
  end

  def validate_seats_availability
    return unless seat_count && seat_count.negative?

    errors.add(:seat_count, "cannot be negative")
  end

  def set_timezone_default
    self.timezone ||= "UTC"
  end

  def set_published_at
    if published? && published_at.blank?
      self.published_at = Time.current
    end
  end

  def create_default_timetable
    # Create default timetable entries if needed
    # This would be based on course content and batch duration
  end

  def handle_status_changes
    # Handle status change notifications and logic
    if saved_change_to_published? && published?
      notify_batch_published
    end

    if saved_change_to_start_date && start_date == Date.current
      notify_batch_started
    end

    if saved_change_to_end_date && end_date == Date.current
      notify_batch_completed
    end
  end

  def notify_batch_published
    # Send notifications to interested users
  end

  def notify_batch_started
    # Send start notifications to enrolled students
  end

  def notify_batch_completed
    # Send completion notifications and process certificates
  end

  def calculate_average_progress
    return 0 if batch_enrollments.empty?

    total_progress = batch_enrollments.joins(:user)
                                   .joins("LEFT JOIN course_progresses ON course_progresses.user_id = users.id")
                                   .where("course_progresses.course IN (?)", batch_courses.pluck(:course_id))
                                   .average("course_progresses.progress") || 0

    total_progress.round(2)
  end

  def calculate_completion_rate
    return 0 if batch_enrollments.empty?

    completed_count = batch_enrollments.joins(:user)
                                      .joins("LEFT JOIN course_progresses ON course_progresses.user_id = users.id")
                                      .where("course_progresses.course IN (?) AND course_progresses.status = ?",
                                             batch_courses.pluck(:course_id), "Completed")
                                      .distinct
                                      .count

    (completed_count.to_f / batch_enrollments.count * 100).round(2)
  end
end
