class CohortMentor < ApplicationRecord
  belongs_to :cohort
  belongs_to :cohort_subgroup
  belongs_to :user
  belongs_to :course

  # Validations
  validates :cohort, presence: true
  validates :cohort_subgroup, presence: true
  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [ :cohort_id, :cohort_subgroup_id ],
                                   message: "User is already a mentor for this subgroup" }
  validate :validate_cohort_consistency
  validate :validate_course_consistency

  # Callbacks
  before_validation :set_course_from_associations

  # Scopes
  scope :by_cohort, ->(cohort) { where(cohort: cohort) }
  scope :by_subgroup, ->(subgroup) { where(cohort_subgroup: subgroup) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_course, ->(course) { where(course: course) }

  # Frappe compatibility methods
  def email
    user&.email
  end

  def name
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

  def course_title
    course&.title
  end

  def is_primary_mentor?
    cohort_subgroup&.cohort_mentors&.first == self
  end

  def can_manage_subgroup?
    is_primary_mentor? || cohort&.instructor == user || cohort&.is_admin?(user)
  end

  def can_approve_requests?
    can_manage_subgroup?
  end

  def get_students
    cohort_subgroup&.get_students || []
  end

  def get_pending_requests
    cohort_subgroup&.pending_join_requests || []
  end

  def approve_join_request(request)
    return false unless can_approve_requests? && cohort_subgroup
    cohort_subgroup.approve_join_request(request)
  end

  def reject_join_request(request, reason: nil)
    return false unless can_approve_requests? && cohort_subgroup
    cohort_subgroup.reject_join_request(request, reason: reason)
  end

  def to_frappe_format
    {
      name: id,
      cohort: cohort&.name || cohort&.id,
      cohort_title: cohort&.title,
      subgroup: cohort_subgroup&.slug,
      subgroup_title: cohort_subgroup&.title,
      email: user&.email,
      user_name: user&.full_name,
      username: user&.username,
      course: course&.name || course&.id,
      course_title: course&.title,
      is_primary_mentor: is_primary_mentor?,
      can_manage_subgroup: can_manage_subgroup?,
      creation: created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # Class methods
  def self.find_mentor(cohort, user)
    joins(:cohort_subgroup)
      .where(cohort: cohort, user: user)
      .first
  end

  def self.get_mentors_by_user(user)
    where(user: user)
      .includes(:cohort, :cohort_subgroup, :course)
  end

  def self.get_primary_mentors(cohort)
    joins(:cohort_subgroup)
      .where(cohort: cohort)
      .select("DISTINCT ON (cohort_subgroup_id) *")
      .order("cohort_subgroup_id, created_at ASC")
  end

  def self.promote_to_primary(mentor)
    return false unless mentor.persisted?

    # Move this mentor to be the first in the subgroup
    other_mentors = cohort_subgroup.cohort_mentors.where.not(id: mentor.id).order(:created_at)

    ActiveRecord::Base.transaction do
      mentor.update!(created_at: 1.second.ago) if mentor.created_at > 1.second.ago

      other_mentors.each_with_index do |other_mentor, index|
        other_mentor.update!(created_at: (index + 2).seconds.from_now)
      end
    end

    true
  end

  private

  def validate_cohort_consistency
    return unless cohort && cohort_subgroup

    unless cohort_subgroup.cohort == cohort
      errors.add(:cohort_subgroup, "must belong to the same cohort")
    end
  end

  def validate_course_consistency
    return unless cohort && course

    unless cohort.course == course
      errors.add(:course, "must be the same as the cohort's course")
    end
  end

  def set_course_from_associations
    self.course = cohort.course if cohort && !course
    self.course = cohort_subgroup.cohort.course if cohort_subgroup && !course
  end
end
