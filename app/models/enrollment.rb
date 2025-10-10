class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :batch, optional: true

  validates :user_id, uniqueness: { scope: :course_id }

  def completed?
    progress >= 100
  end
end