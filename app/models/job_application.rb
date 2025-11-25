class JobApplication < ApplicationRecord
  belongs_to :job, class_name: "JobOpportunity", foreign_key: :job
  belongs_to :user

  # Validations
  validates :user, :job, :resume, presence: true
  validates :user, uniqueness: { scope: :job }

  # Callbacks
  before_save :set_fetched_fields

  # Scopes
  scope :by_job, ->(job_id) { where(job_id: job_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def job_title
    job&.job_title
  end

  def company
    job&.company_name
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "user" => user&.email,
      "resume" => resume,
      "job" => job_id.to_s,
      "job_title" => job_title,
      "company" => company,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_fetched_fields
    # These are handled by the database triggers/fetch in Frappe
    # In Rails, we can set them manually or use callbacks
  end
end
