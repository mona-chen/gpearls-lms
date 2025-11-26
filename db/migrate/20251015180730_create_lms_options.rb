class CreateLmsOptions < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_options do |t|
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

      # Exact Frappe field structure from lms_option.json
      # This is a child table (istable: 1) with parent references
      t.string :option                    # Data field
      t.boolean :is_correct, default: false  # Check field, default: "0"

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_options, :option
    add_index :lms_options, :is_correct
    add_index :lms_options, :parent
    add_index :lms_options, :parenttype
    add_index :lms_options, :parentfield
    add_index :lms_options, [ :parent, :parenttype, :parentfield ], name: 'index_options_on_parent_and_type_and_field'
    add_index :lms_options, :creation
    add_index :lms_options, :modified
    add_index :lms_options, [ :parent, :is_correct ]
  end
end
