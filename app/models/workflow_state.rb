class WorkflowState < ApplicationRecord
  belongs_to :workflow

  validates :state, presence: true
  validates :doc_status, presence: true
end
