class CertificationCategory < ApplicationRecord
  # LMS Certification Categories
  # Matches Frappe's Certification Category doctype

  validates :name, presence: true, uniqueness: true
  validates :description, presence: false

  # Associations
  has_many :certifications, dependent: :destroy

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_name, -> { order(:name) }

  # Instance methods
  def to_frappe_format
    {
      name: name,
      description: description,
      enabled: enabled,
      creation: created_at.strftime('%Y-%m-%d %H:%M:%S'),
      modified: updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end
end
