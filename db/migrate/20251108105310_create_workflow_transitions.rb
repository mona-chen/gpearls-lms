class CreateWorkflowTransitions < ActiveRecord::Migration[7.2]
  def change
    create_table :workflow_transitions do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :state
      t.string :action
      t.string :next_state
      t.string :allowed_roles
      t.string :condition

      t.timestamps
    end
  end
end
