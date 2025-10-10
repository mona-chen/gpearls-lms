class LessonProgress < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  validates :progress, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :user, presence: true
  validates :lesson, presence: true

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false).where('progress > 0') }
  scope :not_started, -> { where(progress: 0) }

  def complete!
    update!(progress: 100, completed: true)
  end

  def in_progress?
    progress > 0 && !completed?
  end
end
