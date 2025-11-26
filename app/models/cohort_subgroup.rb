class CohortSubgroup < ApplicationRecord
  belongs_to :cohort
  has_many :cohort_mentors, dependent: :destroy
  has_many :cohort_join_requests, dependent: :destroy
  has_many :enrollments, class_name: "Enrollment", foreign_key: "cohort_subgroup_id", dependent: :destroy
  has_many :users, through: :enrollments, source: :user
  has_many :mentors, through: :cohort_mentors, source: :user

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, length: { maximum: 100 }
  validates :invite_code, presence: true, uniqueness: true
  validate :validate_slug_format

  # Callbacks
  before_validation :generate_slug, :generate_invite_code
  before_validation :set_course_from_cohort

  # Scopes
  scope :by_cohort, ->(cohort) { where(cohort: cohort) }
  scope :with_mentor, ->(user) { joins(:cohort_mentors).where(cohort_mentors: { user: user }) }

  # Frappe compatibility methods
  def name
    "#{title} (#{cohort&.title})"
  end

  def get_cohort
    cohort
  end

  def get_mentors
    mentors
  end

  def get_students
    enrollments.where(member_type: "Student").includes(:user)
  end

  def pending_join_requests
    cohort_join_requests.where(status: "Pending").includes(:user)
  end

  def accepted_join_requests
    cohort_join_requests.where(status: "Accepted").includes(:user)
  end

  def rejected_join_requests
    cohort_join_requests.where(status: "Rejected").includes(:user)
  end

  def add_mentor(user)
    return false unless user && cohort

    cohort_mentors.find_or_create_by!(
      user: user,
      cohort: cohort,
      course: cohort.course
    )
  end

  def remove_mentor(user)
    cohort_mentors.where(user: user).destroy_all
  end

  def has_mentor?(user)
    mentors.include?(user)
  end

  def add_student(user)
    return false unless user && cohort

    # Check if there's an approved join request
    join_request = cohort_join_requests.find_by(user: user, status: "Accepted")
    if join_request
      enrollments.create!(
        user: user,
        course: cohort.course,
        cohort: cohort,
        cohort_subgroup: self,
        member_type: "Student",
        role: "Member"
      )
    else
      false
    end
  end

  def remove_student(user)
    enrollments.where(user: user, member_type: "Student").destroy_all
  end

  def create_join_request(user, message: nil)
    return false unless user && cohort

    # Check if user is already a member
    return false if enrollments.exists?(user: user, member_type: "Student")

    # Check if request already exists
    existing_request = cohort_join_requests.find_by(user: user)
    return existing_request if existing_request&.pending?

    cohort_join_requests.create!(
      user: user,
      cohort: cohort,
      message: message,
      status: "Pending"
    )
  end

  def approve_join_request(request)
    return false unless request.pending? && can_approve_requests?

    ActiveRecord::Base.transaction do
      request.update!(status: "Accepted")

      # Create enrollment
      enrollments.create!(
        user: request.user,
        course: cohort.course,
        cohort: cohort,
        cohort_subgroup: self,
        member_type: "Student",
        role: "Member"
      )
    end

    true
  end

  def reject_join_request(request, reason: nil)
    return false unless request.pending? && can_approve_requests?

    request.update!(
      status: "Rejected",
      rejection_reason: reason
    )

    true
  end

  def is_manager?(user)
    return true if user == cohort&.instructor
    return true if cohort&.is_admin?(user)
    return true if cohort&.is_staff?(user)
    return true if has_mentor?(user)

    false
  end

  def member_count
    enrollments.where(member_type: "Student").count
  end

  def mentor_count
    mentors.count
  end

  def pending_requests_count
    pending_join_requests.count
  end

  def get_stats
    {
      students: member_count,
      mentors: mentor_count,
      pending_requests: pending_requests_count,
      total_members: enrollments.count
    }
  end

  def to_frappe_format
    {
      name: name,
      title: title,
      slug: slug,
      cohort: cohort&.name || cohort&.id,
      cohort_title: cohort&.title,
      course: cohort&.course&.name || cohort&.course&.id,
      course_title: cohort&.course&.title,
      invite_code: invite_code,
      description: description,
      stats: get_stats,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.find_by_invite_code(code)
    find_by(invite_code: code)
  end

  def self.get_subgroups_by_mentor(user)
    joins(:cohort_mentors).where(cohort_mentors: { user: user })
  end

  private

  def validate_slug_format
    return if slug.blank?

    unless slug.match?(/\A[a-z0-9-]+\z/)
      errors.add(:slug, "can only contain lowercase letters, numbers, and hyphens")
    end
  end

  def generate_slug
    return if slug.present?

    base_slug = title.parameterize
    counter = 1
    new_slug = base_slug

    while CohortSubgroup.where(cohort: cohort, slug: new_slug).exists?
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = new_slug
  end

  def generate_invite_code
    return if invite_code.present?

    loop do
      code = SecureRandom.hex(4).upcase
      break code unless CohortSubgroup.where(invite_code: code).exists?
    end
  end

  def set_course_from_cohort
    self.course = cohort.course if cohort
  end

  def can_approve_requests?
    # This would be called in the context of current_user
    # For now, assume the method is called with proper authorization
    true
  end
end
