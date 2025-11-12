class CreateLmsSources < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_sources do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from lms_source.json
      t.string :source, null: false                    # Data field, unique: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_sources, :source, unique: true
    add_index :lms_sources, :creation
    add_index :lms_sources, :modified
  end
end
