class CreateFunctions < ActiveRecord::Migration[7.0]
  def change
    create_table :functions do |t|
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

      # Exact Frappe field structure from function.json
      # autoname: "field:function", naming_rule: "By fieldname"
      t.string :function, null: false                 # Data field, unique: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :functions, :function, unique: true
    add_index :functions, :creation
    add_index :functions, :modified

    # No foreign key constraints as this is a reference table
  end
end
