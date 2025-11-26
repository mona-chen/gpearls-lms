class LiveClassParticipant < ApplicationRecord
  self.table_name = "lms_live_class_participants"

  # Associations
  belongs_to :live_class, class_name: "LiveClass", foreign_key: :live_class
  belongs_to :participant, class_name: "User", foreign_key: :participant

  # Validations
  validates :live_class, presence: true
  validates :participant, presence: true
  validates :participant_id, uniqueness: { scope: :live_class_id }

  # Scopes
  scope :by_live_class, ->(live_class_id) { where(live_class_id: live_class_id) }
  scope :by_participant, ->(participant_id) { where(participant_id: participant_id) }
  scope :attended, -> { where.not(attended_at: nil) }

  # Instance methods
  def attended?
    attended_at.present?
  end

  def mark_attended
    update(attended_at: Time.current) unless attended?
  end

  def name
    id.to_s
  end

  def to_frappe_format
    {
      "name" => id.to_s,
      "live_class" => live_class_id.to_s,
      "participant" => participant_id.to_s,
      "participant_name" => participant&.full_name,
      "attended_at" => attended_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "creation" => created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      "modified" => updated_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
end
