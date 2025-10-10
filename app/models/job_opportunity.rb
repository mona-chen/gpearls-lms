class JobOpportunity < ApplicationRecord
  belongs_to :user
  has_many :job_applications, dependent: :destroy
  
  validates :job_title, :company_name, :description, presence: true
  validates :type, inclusion: { in: %w[Full-time Part-time Contract Internship] }, allow_blank: true
  validates :work_mode, inclusion: { in: %w[Remote On-site Hybrid] }, allow_blank: true
  
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end
