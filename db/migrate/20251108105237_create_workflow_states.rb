class CreateWorkflowStates < ActiveRecord::Migration[7.2]
  def change
    create_table :workflow_states do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :state
      t.string :doc_status
      t.string :allow_edit
      t.string :next_action

      t.timestamps
    end
  end
end
