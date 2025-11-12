class CreatePaymentCountries < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_countries do |t|
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

      # Exact Frappe field structure from payment_country.json
      # This is a child table (istable: 1) with parent references
      t.string :country                 # Link to Country

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :payment_countries, :country
    add_index :payment_countries, :parent
    add_index :payment_countries, :parenttype
    add_index :payment_countries, :parentfield
    add_index :payment_countries, [:parent, :parenttype, :parentfield], name: 'index_payment_countries_on_parent_and_type_and_field'
    add_index :payment_countries, :creation
    add_index :payment_countries, :modified

    # Note: Foreign key constraint removed due to migration order dependency
    # Countries table is created after this migration
    # add_foreign_key :payment_countries, :countries, column: :country
  end
end
