class Certification < ApplicationRecord
  # LMS Certifications
  # Matches Frappe's Certification doctype

  belongs_to :user
  belongs_to :course
  belongs_to :category, class_name: "CertificationCategory", optional: true
  belongs_to :evaluator, class_name: "User", optional: true

  validates :user, :course, presence: true
  validates :docstatus, presence: true
  validates :certificate_number, uniqueness: true, allow_nil: true

  enum :docstatus, "Draft" => 0, "Submitted" => 1, "Under Review" => 2, "Approved" => 3, "Rejected" => 4, "Issued" => 5

  # Alias for Frappe compatibility
  alias_attribute :status, :docstatus

  # Scopes matching Frappe Python patterns
  scope :published, -> { where(status: "Issued") }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_course, ->(course) { where(course: course) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def issued?
    status == "Issued"
  end

  def approved?
    status == "Approved"
  end

  def pending?
    [ "Draft", "Submitted", "Under Review" ].include?(status)
  end

  def rejected?
    status == "Rejected"
  end

  def generate_certificate_number
    return if certificate_number.present?

    # Generate unique certificate number
    loop do
      number = "CERT-#{Time.current.year}-#{SecureRandom.hex(4).upcase}"
      break number unless Certification.exists?(certificate_number: number)
    end
  end

  def issue_certificate
    return unless approved?

    update(
      status: "Issued",
      certificate_number: generate_certificate_number,
      issued_at: Time.current
    )
  end

  # Frappe compatibility methods
  def to_frappe_format
    {
      name: id,
      user: user&.email,
      user_name: user&.full_name,
      course: course_id,
      course_name: course&.title,
      category: category&.name,
      evaluator: evaluator&.email,
      evaluator_name: evaluator&.full_name,
      status: status,
      certificate_number: certificate_number,
      issued_at: issued_at&.strftime("%Y-%m-%d %H:%M:%S"),
      creation: created_at.strftime("%Y-%m-%d %H:%M:%S"),
      modified: updated_at.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  def self.get_certified_participants(filters = {})
    certifications = published.includes(:user, :course, :category)

    if filters[:category].present?
      certifications = certifications.where(category: CertificationCategory.find_by(name: filters[:category]))
    end

    if filters[:course].present?
      certifications = certifications.where(course: Course.find_by(title: filters[:course]))
    end

    certifications.recent.map(&:to_frappe_format)
  end
end
