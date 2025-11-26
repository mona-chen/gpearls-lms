class CreatePreferredIndustries < ActiveRecord::Migration[7.0]
  def change
    create_table :preferred_industries do |t|
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

      # Exact Frappe field structure from preferred_industry.json
      # This is a child table (istable: 1) with parent references
      t.string :industry, null: false                  # Link to Industry, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :preferred_industries, :industry
    add_index :preferred_industries, :parent
    add_index :preferred_industries, :parenttype
    add_index :preferred_industries, :parentfield
    add_index :preferred_industries, [ :parent, :parenttype, :parentfield ], name: 'index_preferred_industries_on_parent_and_type_and_field'
    add_index :preferred_industries, :creation
    add_index :preferred_industries, :modified

    # Add foreign key constraints
    add_foreign_key :preferred_industries, :industries, column: :industry
  end
end
