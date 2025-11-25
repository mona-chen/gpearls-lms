class LmsBadgeAssignment < ApplicationRecord
  self.table_name = "lms_badge_assignments"

  # Associations
  belongs_to :badge, class_name: "LmsBadge", foreign_key: :badge
  belongs_to :member, class_name: "User", foreign_key: :member

  # Validations
  validates :badge, presence: true
  validates :member, presence: true
  validates :member, uniqueness: { scope: :badge }

  # Scopes
  scope :by_badge, ->(badge_id) { where(badge_id: badge_id) }
  scope :by_member, ->(member_id) { where(member_id: member_id) }
  scope :recent, -> { order(issued_on: :desc) }
  scope :active, -> { where(status: "Active") }
  scope :expired, -> { where("expires_on < ?", Date.current) }

  # Instance methods
  def active?
    status == "Active"
  end

  def expired?
    expires_on.present? && expires_on < Date.current
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "badge" => badge_id.to_s,
      "member" => member&.email,
      "issued_on" => issued_on&.strftime("%Y-%m-%d"),
      "expires_on" => expires_on&.strftime("%Y-%m-%d"),
      "status" => status,
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end