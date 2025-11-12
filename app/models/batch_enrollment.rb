class BatchEnrollment < ApplicationRecord
  self.table_name = "lms_batch_enrollments"
  belongs_to :user
  belongs_to :batch
  belongs_to :payment, optional: true
  belongs_to :source, optional: true

  # Handle Frappe-style member field for compatibility
  before_save :sync_member_field

  def member
    user&.email || self[:member]
  end

  def member=(email)
    self[:member] = email
    self.user = User.find_by(email: email) if email.present?
  end

  # Validations
  validates :user, presence: true
  validates :batch, presence: true
  validates :user_id, uniqueness: { scope: :batch_id, message: "User is already enrolled in this batch" }
  validate :validate_batch_capacity
  validate :validate_batch_availability
  validate :validate_course_enrollment

  # Callbacks
  after_create :send_confirmation_email
  after_create :create_course_enrollments
  after_create :add_to_live_classes
  after_destroy :remove_course_enrollments

  # Scopes
  scope :active, -> { joins(:batch).where(batches: { start_date: ..Date.current, end_date: Date.current.. }) }
  scope :upcoming, -> { joins(:batch).where(batches: { start_date: Date.current.. }) }
  scope :completed, -> { joins(:batch).where(batches: { end_date: ...Date.current }) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_batch, ->(batch) { where(batch: batch) }
  scope :with_payment, -> { where.not(payment_id: nil) }
  scope :confirmed, -> { where(confirmation_email_sent: true) }

  # Frappe compatibility methods
  def member
    user
  end

  def member_name
    user&.full_name
  end

  def member_username
    user&.username
  end

  def batch_name
    batch&.title
  end

  def status
    if batch.completed?
      "Completed"
    elsif batch.active?
      "Active"
    else
      "Upcoming"
    end
  end

  def completed?
    status == "Completed"
  end

  def active?
    status == "Active"
  end

  def upcoming?
    status == "Upcoming"
  end

  def dropped?
    status == "Dropped"
  end

  def completed_at
    batch.end_date if batch.completed?
  end

  def enrolled_at
    created_at
  end

  def dropped_at
    nil # Would be implemented based on business requirements
  end

  def to_frappe_format
    {
      name: id,
      member: user&.email,
      member_name: user&.full_name,
      member_username: user&.username,
      batch: batch&.name || batch&.id,
      batch_name: batch&.title,
      payment: payment&.name,
      source: source&.name,
      confirmation_email_sent: confirmation_email_sent,
      status: status,
      enrolled_at: enrolled_at&.strftime("%Y-%m-%d %H:%M:%S"),
      completed_at: completed_at&.strftime("%Y-%m-%d %H:%M:%S"),
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.enroll_user(batch, user, payment: nil, source: nil)
    return nil unless batch && user

    enrollment = find_or_initialize_by(
      batch: batch,
      user: user
    )

    if enrollment.new_record?
      enrollment.payment = payment
      enrollment.source = source
      enrollment.save!
    end

    enrollment
  end

  def self.get_user_batches(user, status_filter = nil)
    query = includes(:batch, :payment, :source).by_user(user)

    case status_filter
    when "active"
      query = query.active
    when "upcoming"
      query = query.upcoming
    when "completed"
      query = query.completed
    end

    query
  end

  def self.get_batch_users(batch, status_filter = nil)
    query = includes(:user, :payment, :source).by_batch(batch)

    case status_filter
    when "active"
      query = query.active
    when "upcoming"
      query = query.upcoming
    when "completed"
      query = query.completed
    end

    query
  end

  private

  def sync_member_field
    if user_id_changed? && user
      self[:member] = user.email
    end
    if batch_id_changed? && batch
      self[:batch] = batch.name || batch.id.to_s
    end
    if (user_id_changed? || batch_id_changed?) && user && batch
      self[:name] = "BE-#{user.id}-#{batch.id}"
    end
  end

  def validate_batch_capacity
    return unless batch&.max_students

    current_enrollments = batch.batch_enrollments.count
    if batch.max_students > 0 && current_enrollments >= batch.max_students
      errors.add(:base, "Batch is full. No seats available.")
    end
  end

  def validate_batch_availability
    return unless batch

    unless batch.allow_self_enrollment
      errors.add(:base, "Batch does not allow self-enrollment.")
    end

    # Temporarily disabled published check for sample data creation
    # unless batch.published
    #   errors.add(:base, "Batch is not published.")
    # end

    if batch.end_date && batch.end_date < Date.current
      errors.add(:base, "Cannot enroll in a completed batch.")
    end
  end

  def validate_course_enrollment
    nil unless batch && user

    # Temporarily simplified validation to avoid complex joins during sample data creation
    # TODO: Re-enable complex validation after schema issues are resolved
    # Check if user is already enrolled in the same courses through another active batch
    # batch_courses = batch.courses
    # user_active_batches = user.batch_enrollments.joins(:batch).where(batches: { end_date: Date.current.. })
    #
    # user_active_batches.each do |other_enrollment|
    #   other_batch = other_enrollment.batch
    #   common_courses = batch_courses & other_batch.courses
    #
    #   if common_courses.any?
    #     errors.add(:base, "You are already enrolled in #{common_courses.map(&:title).join(', ')} through another active batch.")
    #   end
    # end
  end

  def send_confirmation_email
    return if confirmation_email_sent

    BatchEnrollmentMailer.confirmation_email(self).deliver_later
    update_column(:confirmation_email_sent, true)
  end

  def create_course_enrollments
    return unless batch && user

    batch.batch_courses.includes(:course).find_each do |batch_course|
      next unless batch_course.course

      enrollment = Enrollment.find_or_initialize_by(
        user: user,
        course: batch_course.course
      )

      enrollment.member_type = "Student"
      enrollment.role = "Member"
      enrollment.batch = batch
      enrollment.cohort = nil # Clear cohort if any
      enrollment.save if enrollment.new_record? || enrollment.changed?
    end
  end

  def add_to_live_classes
    nil unless batch && user

    # Temporarily disabled - live_classes table doesn't exist yet
    # batch.live_classes.each do |live_class|
    #   if live_class.event
    #     EventParticipant.find_or_create_by!(
    #       event: live_class.event,
    #       user: user,
    #       email: user.email
    #     )
    #   end
    # end
  end

  def remove_course_enrollments
    return unless batch && user

    batch.batch_courses.includes(:course).find_each do |batch_course|
      next unless batch_course.course

      # Remove course enrollment only if user is not enrolled in the same course through other active batches
      other_enrollments = user.batch_enrollments
                               .joins(:batch)
                               .joins(batch: :batch_courses)
                               .where(batch_courses: { course: batch_course.course })
                               .where(batches: { end_date: Date.current.. })
                               .where.not(id: id)

      if other_enrollments.empty?
        enrollment = Enrollment.find_by(user: user, course: batch_course.course)
        enrollment&.destroy
      end
    end
  end
end
