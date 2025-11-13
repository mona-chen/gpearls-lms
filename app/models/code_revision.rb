class CodeRevision < ApplicationRecord
  belongs_to :user
  belongs_to :exercise_section, polymorphic: true
  
  validates :code, presence: true
  validates :section_id, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_section, ->(section) { where(section_id: section, section_type: section.class.name) }
  
  def self.autosave_for_section(section_id, section_type, code, user)
    create!(
      section_id: section_id,
      section_type: section_type,
      code: code,
      user: user
    )
  end
  
  def self.latest_for_section(section_id, section_type, user)
    where(
      section_id: section_id, 
      section_type: section_type,
      user: user
    ).order(created_at: :desc).first
  end
end