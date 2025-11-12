class CreateWorkflows < ActiveRecord::Migration[7.2]
  def change
    create_table :workflows do |t|
      t.string :name
      t.string :document_type
      t.boolean :is_active
      t.text :states
      t.text :transitions

      t.timestamps
    end
  end
end
