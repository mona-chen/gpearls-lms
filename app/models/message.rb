class Message < ApplicationRecord
  belongs_to :user
  belongs_to :discussion

  validates :content, presence: true, length: { maximum: 2000 }
  validates :message_type, presence: true, inclusion: { in: %w[text image file] }
  validates :user, presence: true
  validates :discussion, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_discussion, ->(discussion) { where(discussion: discussion) }

  def text?
    message_type == 'text'
  end

  def image?
    message_type == 'image'
  end

  def file?
    message_type == 'file'
  end
end
