class Certificate < ApplicationRecord
  belongs_to :user
  belongs_to :course, optional: true
  belongs_to :batch, optional: true

  validates :user_id, presence: true
end