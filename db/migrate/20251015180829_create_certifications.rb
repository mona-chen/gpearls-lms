class CreateCertifications < ActiveRecord::Migration[7.0]
  def change
    create_table :certifications do |t|
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

      # Exact Frappe field structure from certification.json
      # This is a child table (istable: 1) with autoname: "hash"
      t.string :certification_name, null: false    # Data field, reqd: 1
      t.string :organization, null: false          # Data field, reqd: 1
      t.text :description                           # Small Text field
      t.boolean :expire, default: false             # Check field, default: "0"
      t.date :issue_date, null: false              # Date field, reqd: 1
      t.string :expiration_date                    # Data field, depends_on: !expire

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :certifications, :certification_name
    add_index :certifications, :organization
    add_index :certifications, :issue_date
    add_index :certifications, :expire
    add_index :certifications, :parent
    add_index :certifications, :parenttype
    add_index :certifications, :parentfield
    add_index :certifications, [ :parent, :parenttype, :parentfield ], name: 'index_certifications_on_parent_and_type_and_field'
    add_index :certifications, :creation
    add_index :certifications, :modified
    add_index :certifications, [ :organization, :certification_name ]
  end
end
