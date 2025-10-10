class JobApplication < ApplicationRecord
  belongs_to :job_opportunity
  belongs_to :user
  
  validates :status, inclusion: { in: %w[Applied Reviewing Accepted Rejected] }
  validates :user, uniqueness: { scope: :job_opportunity }
  
  scope :applied, -> { where(status: 'Applied') }
  scope :recent, -> { order(created_at: :desc) }
end
