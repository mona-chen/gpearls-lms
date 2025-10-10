class Notification < ApplicationRecord
  # Disable single-table inheritance since 'type' field is used for notification types
  self.inheritance_column = nil

  belongs_to :user

  validates :subject, presence: true

  # Set default value using Rails callback instead of default_value_for gem
  after_initialize :set_defaults, if: :new_record?

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end

  private

  def set_defaults
    self.read = false if read.nil?
  end
end
