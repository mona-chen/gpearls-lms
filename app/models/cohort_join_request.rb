class CohortJoinRequest < ApplicationRecord
  belongs_to :cohort
  belongs_to :cohort_subgroup
  belongs_to :user

  # Validations
  validates :cohort, presence: true
  validates :cohort_subgroup, presence: true
  validates :user, presence: true
  validates :status, presence: true, inclusion: { in: %w[Pending Accepted Rejected] }
  validates :user_id, uniqueness: { scope: [ :cohort_id, :cohort_subgroup_id ],
                                  message: "User already has a join request for this subgroup" }
  validate :validate_cohort_consistency
  validate :validate_not_already_member

  # Callbacks
  after_update :handle_status_change

  # Scopes
  scope :pending, -> { where(status: "Pending") }
  scope :accepted, -> { where(status: "Accepted") }
  scope :rejected, -> { where(status: "Rejected") }
  scope :by_cohort, ->(cohort) { where(cohort: cohort) }
  scope :by_subgroup, ->(subgroup) { where(cohort_subgroup: subgroup) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Frappe compatibility methods
  def email
    user&.email
  end

  def member_name
    user&.full_name
  end

  def username
    user&.username
  end

  def subgroup_title
    cohort_subgroup&.title
  end

  def cohort_title
    cohort&.title
  end

  def pending?
    status == "Pending"
  end

  def accepted?
    status == "Accepted"
  end

  def rejected?
    status == "Rejected"
  end

  def approve(approved_by: nil)
    return false unless pending?

    ActiveRecord::Base.transaction do
      update!(status: "Accepted")

      # Create enrollment
      Enrollment.create!(
        user: user,
        course: cohort.course,
        cohort: cohort,
        cohort_subgroup: cohort_subgroup,
        member_type: "Student",
        role: "Member"
      )

      # Send notification
      CohortMailer.join_request_approved(user, cohort, cohort_subgroup, approved_by).deliver_later
    end

    true
  end

  def reject(reason: nil, rejected_by: nil)
    return false unless pending?

    update!(
      status: "Rejected",
      rejection_reason: reason,
      rejected_by: rejected_by
    )

    CohortMailer.join_request_rejected(user, cohort, cohort_subgroup, reason, rejected_by).deliver_later
    true
  end

  def undo_reject(undone_by: nil)
    return false unless rejected?

    update!(
      status: "Pending",
      rejection_reason: nil,
      rejected_by: nil,
      undone_by: undone_by
    )

    # Send notification that rejection was undone
    CohortMailer.join_request_rejection_undone(user, cohort, cohort_subgroup, undone_by).deliver_later
    true
  end

  def can_be_approved_by?(approving_user)
    return true if approving_user == cohort.instructor
    return true if cohort.is_admin?(approving_user)
    return true if cohort.is_staff?(approving_user)
    return true if cohort_subgroup.has_mentor?(approving_user)

    false
  end

  def can_be_rejected_by?(rejecting_user)
    can_be_approved_by?(rejecting_user)
  end

  def days_pending
    return 0 unless created_at
    ((Time.current - created_at) / 1.day).to_i
  end

  def to_frappe_format
    {
      name: id,
      cohort: cohort&.name || cohort&.id,
      cohort_title: cohort&.title,
      subgroup: cohort_subgroup&.slug,
      subgroup_title: cohort_subgroup&.title,
      email: user&.email,
      member_name: user&.full_name,
      username: user&.username,
      status: status,
      message: message,
      rejection_reason: rejection_reason,
      rejected_by: rejected_by,
      days_pending: days_pending,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.create_request(user, cohort, subgroup, message: nil)
    return false unless user && cohort && subgroup

    # Check if user is already a member
    return nil if Enrollment.exists?(user: user, cohort_subgroup: subgroup, member_type: "Student")

    # Check if request already exists
    existing_request = find_by(user: user, cohort_subgroup: subgroup)
    return existing_request if existing_request&.pending?

    create!(
      user: user,
      cohort: cohort,
      cohort_subgroup: subgroup,
      message: message,
      status: "Pending"
    )
  end

  def self.get_pending_requests_for(user)
    pending.by_user(user)
      .includes(:cohort, :cohort_subgroup)
  end

  def self.get_requests_for_approver(approver_user)
    # Get requests that the user can approve
    pending_requests = pending.includes(:cohort, :cohort_subgroup, :user)

    pending_requests.select do |request|
      request.can_be_approved_by?(approver_user)
    end
  end

  def self.auto_approve_old_requests(days_threshold = 30)
    old_requests = pending.where("created_at < ?", days_threshold.days.ago)

    old_requests.find_each do |request|
      request.reject(
        reason: "Request automatically rejected due to age (#{days_threshold} days)",
        rejected_by: "System"
      )
    end

    old_requests.count
  end

  def self.get_statistics(cohort: nil, subgroup: nil, days: 30)
    scope = where(created_at: days.days.ago..)
    scope = scope.where(cohort: cohort) if cohort
    scope = scope.where(cohort_subgroup: subgroup) if subgroup

    {
      total: scope.count,
      pending: scope.pending.count,
      accepted: scope.accepted.count,
      rejected: scope.rejected.count,
      approval_rate: scope.count > 0 ? (scope.accepted.count.to_f / scope.count * 100).round(2) : 0
    }
  end

  private

  def validate_cohort_consistency
    return unless cohort && cohort_subgroup

    unless cohort_subgroup.cohort == cohort
      errors.add(:cohort_subgroup, "must belong to the same cohort")
    end
  end

  def validate_not_already_member
    return unless user && cohort_subgroup

    if Enrollment.exists?(user: user, cohort_subgroup: cohort_subgroup, member_type: "Student")
      errors.add(:user, "is already a member of this subgroup")
    end
  end

  def handle_status_change
    return unless saved_change_to_status

    case status
    when "Accepted"
      handle_acceptance
    when "Rejected"
      handle_rejection
    end
  end

  def handle_acceptance
    # Additional logic for accepted requests
    cohort_subgroup&.increment!(:member_count)
  end

  def handle_rejection
    # Additional logic for rejected requests
    # Could implement cooldown period or other restrictions
  end
end
