class Certificate < ApplicationRecord
  self.table_name = "lms_certificates"

  belongs_to :user, foreign_key: :student_id
  belongs_to :course, optional: true
  belongs_to :batch, optional: true

  validates :user_id, presence: true
  validates :name, presence: true
  validates :category, presence: true
end
