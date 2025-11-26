class Cohort < ApplicationRecord
  belongs_to :course
  belongs_to :instructor, class_name: "User"
  has_many :cohort_subgroups, dependent: :destroy
  has_many :cohort_mentors, dependent: :destroy
  has_many :cohort_staffs, dependent: :destroy
  has_many :cohort_join_requests, dependent: :destroy
  has_many :cohort_web_pages, dependent: :destroy
  has_many :mentors, through: :cohort_mentors, source: :user
  has_many :enrollments, class_name: "Enrollment", foreign_key: "cohort_id", dependent: :destroy
  has_many :users, through: :enrollments, source: :user

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, length: { maximum: 100 }, uniqueness: { scope: :course_id }
  validates :course, presence: true
  validates :instructor, presence: true
  validates :status, presence: true, inclusion: { in: %w[Upcoming Live Completed Cancelled] }
  validate :validate_slug_format
  validate :validate_dates_consistency

  # Callbacks
  before_validation :generate_slug
  before_save :update_status_based_on_dates
  after_create :create_default_subgroup
  after_update :handle_status_changes

  # Scopes
  scope :active, -> { where(status: "Live") }
  scope :upcoming, -> { where(status: "Upcoming") }
  scope :completed, -> { where(status: "Completed") }
  scope :cancelled, -> { where(status: "Cancelled") }
  scope :by_course, ->(course) { where(course: course) }
  scope :by_instructor, ->(instructor) { where(instructor: instructor) }
  scope :with_mentor, ->(user) { joins(:cohort_mentors).where(cohort_mentors: { user: user }) }
  scope :with_staff, ->(user) { joins(:cohort_staffs).where(cohort_staffs: { user: user }) }

  # Frappe compatibility methods
  def name
    "#{course.name}/#{slug}" if course && slug
  end

  def get_url
    "#{Rails.application.credentials[:app_url] || 'http://localhost:3000'}/lms/courses/#{course&.slug || course&.id}/cohorts/#{slug}"
  end

  def get_subgroups(include_counts: false, sort_by: nil)
    subgroups = cohort_subgroups.includes(:cohort_mentors, :cohort_join_requests, :enrollments)

    if include_counts
      subgroups = subgroups.map do |subgroup|
        subgroup.num_mentors = subgroup.mentors.count
        subgroup.num_students = subgroup.students.count
        subgroup.num_join_requests = subgroup.pending_join_requests.count
        subgroup
      end
    end

    if sort_by
      subgroups = subgroups.sort_by { |sg| sg.send(sort_by) }.reverse
    end

    subgroups
  end

  def get_subgroup(slug)
    cohort_subgroups.find_by(slug: slug)
  end

  def get_mentor(email)
    cohort_mentors.joins(:user).find_by(users: { email: email })
  end

  def is_mentor?(user)
    mentors.include?(user)
  end

  def is_admin?(user)
    cohort_staffs.joins(:user).where(users: { email: user.email }, role: "Admin").exists?
  end

  def is_staff?(user)
    cohort_staffs.joins(:user).where(users: { email: user.email }).exists?
  end

  def get_page(slug, scope: nil)
    cohort_web_pages.find_by(slug: slug, scope: scope)
  end

  def get_pages(scope: nil)
    if scope
      cohort_web_pages.where(scope: scope)
    else
      cohort_web_pages
    end
  end

  def get_page_template(slug, scope: nil)
    page = get_page(slug, scope: scope)
    page&.get_template_html
  end

  def get_stats
    {
      subgroups: cohort_subgroups.count,
      mentors: mentors.count,
      students: enrollments.where(member_type: "Student").count,
      join_requests: cohort_join_requests.where(status: "Pending").count,
      total_members: enrollments.count
    }
  end

  def add_mentor(user, subgroup: nil)
    return false unless user

    cohort_mentors.find_or_create_by!(
      user: user,
      cohort_subgroup: subgroup || cohort_subgroups.first,
      course: course
    )
  end

  def remove_mentor(user)
    cohort_mentors.where(user: user).destroy_all
  end

  def add_staff(user, role: "Staff")
    cohort_staffs.find_or_create_by!(
      user: user,
      role: role,
      course: course
    )
  end

  def remove_staff(user)
    cohort_staffs.where(user: user).destroy_all
  end

  def create_join_request(user, subgroup, message: nil)
    return false unless user && subgroup

    # Check if user is already a member
    return false if enrollments.exists?(user: user, cohort_subgroup: subgroup)

    # Check if request already exists
    existing_request = cohort_join_requests.find_by(user: user, cohort_subgroup: subgroup)
    return existing_request if existing_request&.pending?

    cohort_join_requests.create!(
      user: user,
      cohort_subgroup: subgroup,
      message: message,
      status: "Pending"
    )
  end

  def approve_join_request(request)
    return false unless request.pending? && can_approve_requests?(request.user)

    ActiveRecord::Base.transaction do
      request.update!(status: "Accepted")

      # Create enrollment
      enrollments.create!(
        user: request.user,
        course: course,
        cohort_subgroup: request.cohort_subgroup,
        member_type: "Student",
        role: "Member"
      )

      # Send notification
      send_join_approval_notification(request.user, request.cohort_subgroup)
    end

    true
  end

  def reject_join_request(request, reason: nil)
    return false unless request.pending? && can_approve_requests?(request.user)

    request.update!(
      status: "Rejected",
      rejection_reason: reason
    )

    send_join_rejection_notification(request.user, request.cohort_subgroup)
    true
  end

  def get_members(member_type: nil)
    query = enrollments.includes(:user)
    query = query.where(member_type: member_type) if member_type
    query
  end

  def get_students
    get_members(member_type: "Student")
  end

  def add_student(user, subgroup: nil)
    return false unless user

    target_subgroup = subgroup || cohort_subgroups.first
    return false unless target_subgroup

    enrollments.create!(
      user: user,
      course: course,
      cohort_subgroup: target_subgroup,
      member_type: "Student",
      role: "Member"
    )
  end

  def remove_student(user)
    enrollments.where(user: user, member_type: "Student").destroy_all
  end

  def active?
    status == "Live"
  end

  def upcoming?
    status == "Upcoming"
  end

  def completed?
    status == "Completed"
  end

  def cancelled?
    status == "Cancelled"
  end

  def to_frappe_format
    {
      name: name,
      title: title,
      slug: slug,
      course: course&.name || course&.id,
      course_title: course&.title,
      instructor: instructor&.email,
      instructor_name: instructor&.full_name,
      status: status,
      begin_date: begin_date&.strftime("%Y-%m-%d"),
      end_date: end_date&.strftime("%Y-%m-%d"),
      duration: duration,
      description: description,
      url: get_url,
      stats: get_stats,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.get_available_cohorts(user = nil)
    query = where(status: %w[Upcoming Live])

    if user
      # Exclude cohorts user is already enrolled in
      enrolled_cohort_ids = user.enrollments.where.not(cohort_id: nil).pluck(:cohort_id)
      query = query.where.not(id: enrolled_cohort_ids)
    end

    query
  end

  def self.get_cohorts_by_instructor(instructor)
    where(instructor: instructor)
  end

  def self.get_cohorts_by_mentor(user)
    joins(:cohort_mentors).where(cohort_mentors: { user: user })
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = title.parameterize
    counter = 1
    new_slug = base_slug

    while Cohort.where(course: course, slug: new_slug).exists?
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = new_slug
  end

  def validate_slug_format
    return if slug.blank?

    unless slug.match?(/\A[a-z0-9-]+\z/)
      errors.add(:slug, "can only contain lowercase letters, numbers, and hyphens")
    end
  end

  def validate_dates_consistency
    return unless begin_date && end_date

    if end_date < begin_date
      errors.add(:end_date, "cannot be before the begin date")
    end
  end

  def update_status_based_on_dates
    return unless begin_date && end_date

    today = Date.current

    if status_changed?
      # Don't override manual status changes
      return
    end

    if today < begin_date
      self.status = "Upcoming"
    elsif today >= begin_date && today <= end_date
      self.status = "Live"
    else
      self.status = "Completed"
    end
  end

  def create_default_subgroup
    cohort_subgroups.create!(
      title: "Main Group",
      slug: "main",
      description: "Default subgroup for all cohort members",
      invite_code: generate_invite_code
    )
  end

  def generate_invite_code
    loop do
      code = SecureRandom.hex(4).upcase
      break code unless CohortSubgroup.where(invite_code: code).exists?
    end
  end

  def handle_status_changes
    if saved_change_to_status
      case status
      when "Live"
        notify_cohort_started
      when "Completed"
        notify_cohort_completed
      when "Cancelled"
        notify_cohort_cancelled
      end
    end
  end

  def notify_cohort_started
    # Send notifications to all enrolled members
    get_members.includes(:user).find_each do |enrollment|
      CohortMailer.cohort_started(enrollment.user, self).deliver_later
    end
  end

  def notify_cohort_completed
    # Send completion notifications and process certificates
    get_students.includes(:user).find_each do |enrollment|
      CohortMailer.cohort_completed(enrollment.user, self).deliver_later
    end
  end

  def notify_cohort_cancelled
    # Send cancellation notifications
    get_members.includes(:user).find_each do |enrollment|
      CohortMailer.cohort_cancelled(enrollment.user, self).deliver_later
    end
  end

  def send_join_approval_notification(user, subgroup)
    CohortMailer.join_request_approved(user, self, subgroup).deliver_later
  end

  def send_join_rejection_notification(user, subgroup)
    CohortMailer.join_request_rejected(user, self, subgroup).deliver_later
  end

  def can_approve_requests?(approving_user)
    return true if approving_user == instructor
    return true if is_admin?(approving_user)
    return true if is_staff?(approving_user)
    return true if is_mentor?(approving_user)

    false
  end
end
