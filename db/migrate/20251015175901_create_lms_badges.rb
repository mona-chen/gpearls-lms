class CreateLmsBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_badges do |t|
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

      # Exact Frappe field structure from lms_badge.json
      t.boolean :enabled, default: true            # Check, default: "1"
      t.string :title, null: false                 # Data, reqd: 1, unique: 1
      t.text :description, null: false             # Small Text, reqd: 1
      t.string :reference_doctype, null: false     # Link to DocType, reqd: 1
      t.string :event, null: false                 # Select: New/Value Change/Auto Assign, reqd: 1
      t.string :image, null: false                 # Attach Image, reqd: 1
      t.boolean :grant_only_once, default: false   # Check, default: "0"
      t.string :user_field, null: false            # Select, reqd: 1
      t.string :field_to_check                     # Select, depends_on: event == 'Value Change'
      t.text :condition                            # Code field, mandatory_depends_on: event == "Auto Assign"

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_badges, :enabled
    add_index :lms_badges, :title, unique: true
    add_index :lms_badges, :reference_doctype
    add_index :lms_badges, :event
    add_index :lms_badges, :creation
    add_index :lms_badges, :modified
    add_index :lms_badges, [ :enabled, :event ]
    add_index :lms_badges, [ :reference_doctype, :event ]
  end
end
