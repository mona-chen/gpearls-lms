class CreatePreferredFunctions < ActiveRecord::Migration[7.0]
  def change
    create_table :preferred_functions do |t|
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

      # Exact Frappe field structure from preferred_function.json
      # This is a child table (istable: 1) with parent references
      t.string :function, null: false                   # Link to Function

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :preferred_functions, :function
    add_index :preferred_functions, :parent
    add_index :preferred_functions, :parenttype
    add_index :preferred_functions, :parentfield
    add_index :preferred_functions, [:parent, :parenttype, :parentfield], name: 'index_preferred_functions_on_parent_and_type_and_field'
    add_index :preferred_functions, :creation
    add_index :preferred_functions, :modified

    # TODO: Add foreign key when functions table exists
    # add_foreign_key :preferred_functions, :functions, column: :function
  end
end


### **Migration 7: preferred_industry**
