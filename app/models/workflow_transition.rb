class WorkflowTransition < ApplicationRecord
  belongs_to :workflow

  validates :state, presence: true
  validates :action, presence: true
  validates :next_state, presence: true
end
