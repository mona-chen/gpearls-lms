class Chapter < ApplicationRecord
  belongs_to :course
  has_many :lessons, dependent: :destroy

  validates :title, presence: true
end