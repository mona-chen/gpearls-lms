class JobOpportunity < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :owner, optional: true
  has_many :job_applications, dependent: :destroy

  # Validations
  validates :job_title, :location, :country, :company_name, :company_website, :company_email_address, :description, presence: true
  validates :type, inclusion: { in: %w[Full\ Time Part\ Time Freelance Contract] }, allow_blank: true
  validates :work_mode, inclusion: { in: %w[Remote Hybrid On-site] }, allow_blank: true
  validates :status, inclusion: { in: %w[Open Closed] }, allow_blank: true

  # Callbacks
  before_create :set_defaults

  # Scopes
  scope :published, -> { where(disabled: false) }
  scope :open, -> { where(status: "Open", disabled: false) }
  scope :closed, -> { where(status: "Closed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_type, ->(type) { where(type: type) }
  scope :by_work_mode, ->(work_mode) { where(work_mode: work_mode) }

  # Instance methods
  def open?
    status == "Open" && !disabled?
  end

  def closed?
    status == "Closed" || disabled?
  end

  def disabled?
    disabled == true
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "job_title" => job_title,
      "location" => location,
      "country" => country,
      "type" => type,
      "work_mode" => work_mode,
      "status" => status,
      "disabled" => disabled || false,
      "company_name" => company_name,
      "company_website" => company_website,
      "company_logo" => company_logo,
      "company_email_address" => company_email_address,
      "description" => description,
      "owner" => owner&.email,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  private

  def set_defaults
    self.status ||= "Open"
    self.type ||= "Full Time"
    self.disabled ||= false
  end
end
