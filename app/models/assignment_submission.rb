class AssignmentSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :assignment

  validates :user, :assignment, presence: true

  enum :status, { not_attempted: 0, submitted: 1, reviewed: 2 }
end
