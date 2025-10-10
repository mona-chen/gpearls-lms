class Discussion < ApplicationRecord
  belongs_to :user
  belongs_to :course
  has_many :messages, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true, length: { maximum: 2000 }
  validates :status, presence: true, inclusion: { in: %w[open closed archived] }
  validates :user, presence: true
  validates :course, presence: true

  scope :open, -> { where(status: 'open') }
  scope :closed, -> { where(status: 'closed') }
  scope :recent, -> { order(created_at: :desc) }

  def open?
    status == 'open'
  end

  def close!
    update!(status: 'closed')
  end
end
