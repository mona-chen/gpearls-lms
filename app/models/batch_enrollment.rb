class BatchEnrollment < ApplicationRecord
  belongs_to :user
  belongs_to :batch

  validates :user_id, uniqueness: { scope: :batch_id }
end