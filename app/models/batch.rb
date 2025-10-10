class Batch < ApplicationRecord
  belongs_to :instructor, class_name: 'User', optional: true
  has_many :batch_enrollments, dependent: :destroy
  has_many :batch_courses, dependent: :destroy
  has_many :certificates, dependent: :destroy

  validates :title, presence: true
end