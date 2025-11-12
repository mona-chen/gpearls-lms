class CreateCountries < ActiveRecord::Migration[7.0]
  def change
    create_table :countries do |t|
      # Frappe standard fields for core system tables
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

      # Standard Country fields (based on Frappe Country doctype structure)
      t.string :country_name, null: false             # Country name (required)
      t.string :country_code, null: false              # Country code (required)
      t.string :nationality                          # Nationality
      t.string :dial_code                           # Phone dial code
      t.string :currency                           # Default currency
      t.string :date_format                         # Date format
      t.string :time_format                         # Time format
      t.boolean :enabled, default: true              # Whether country is enabled

      t.timestamps
    end

    # Add indexes for performance
    add_index :countries, :country_name, unique: true
    add_index :countries, :country_code, unique: true
    add_index :countries, :nationality
    add_index :countries, :dial_code
    add_index :countries, :currency
    add_index :countries, :enabled
    add_index :countries, :creation
    add_index :countries, :modified
  end
end
