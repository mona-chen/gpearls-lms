class CreateCodeRevisions < ActiveRecord::Migration[7.0]
  def change
    create_table :code_revisions do |t|
      t.text :code, null: false
      t.string :section_id, null: false
      t.string :section_type, null: false
      t.references :user, null: false, foreign_key: true
      t.text :notes
      t.json :metadata
      
      t.timestamps
    end
    
    add_index :code_revisions, [:section_id, :section_type, :user_id]
    add_index :code_revisions, [:user_id, :created_at]
  end
end