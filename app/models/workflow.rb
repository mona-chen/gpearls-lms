class Workflow < ApplicationRecord
  has_many :workflow_states, dependent: :destroy
  has_many :workflow_transitions, dependent: :destroy

  validates :name, presence: true
  validates :document_type, presence: true

  scope :active, -> { where(is_active: true) }

  def states_list
    workflow_states.order(:id).pluck(:state)
  end

  def initial_state
    workflow_states.find_by(doc_status: "Draft")&.state || workflow_states.first&.state
  end
end
