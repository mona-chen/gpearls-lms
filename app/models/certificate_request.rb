class CertificateRequest < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :evaluator, class_name: "User", optional: true

  validates :user, :course, presence: true
  validates :status, presence: true
  validates :rating, numericality: { in: 0..5 }, allow_nil: true

  enum :status, {
    "Pending" => 0,
    "Upcoming" => 1,
    "Completed" => 2,
    "Cancelled" => 3
  }

  # Scopes matching Frappe Python patterns
  scope :upcoming_evals, -> { where(status: "Upcoming", date: Date.current..) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_course, ->(course) { where(course: course) }
  scope :for_evaluator, ->(evaluator) { where(evaluator: evaluator) }
  scope :by_date, -> { order(:date, :start_time) }

  # Instance methods
  def upcoming?
    status == "Upcoming" && date >= Date.current
  end

  def pending?
    status == "Pending"
  end

  def completed?
    status == "Completed"
  end

  def cancelled?
    status == "Cancelled"
  end

  def google_meet_link
    # This would be implemented based on business requirements
    nil
  end

  def batch_name
    # This would be implemented based on business requirements
    nil
  end

  # Frappe compatibility methods
  def self.get_upcoming_evaluations(user, courses = nil, batch = nil)
    evaluations = for_user(user).upcoming_evals
    evaluations = evaluations.where(course: courses) if courses.present?
    evaluations = evaluations.where(batch_name: batch) if batch.present?
    evaluations.by_date
  end

  def self.get_evaluation_details(evaluation_id)
    includes(:user, :course, :evaluator)
      .find_by(id: evaluation_id)
  end

  def to_frappe_format
    {
      name: id,
      date: date&.strftime("%Y-%m-%d"),
      start_time: start_time&.strftime("%H:%M:%S"),
      end_time: end_time&.strftime("%H:%M:%S"),
      course: course_id,
      evaluator: evaluator_id,
      google_meet_link: google_meet_link,
      member: user&.email,
      member_name: user&.full_name,
      course_title: course&.title,
      evaluator_name: evaluator&.full_name,
      rating: rating,
      status: status,
      summary: summary
    }
  end
end
