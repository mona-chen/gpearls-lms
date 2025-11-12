class CreateLmsZoomSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_zoom_settings do |t|
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

      # Exact Frappe field structure from lms_zoom_settings.json
      t.boolean :enabled, default: false               # Check field, default: "0"
      t.string :account_name, null: false              # Data field, reqd: 1, unique: 1
      t.string :member, null: false                    # Link to User, reqd: 1
      t.string :member_name                           # Data, fetched from member.full_name
      t.string :member_image                          # Attach Image, fetched from member.user_image
      t.string :account_id, null: false                # Data field, reqd: 1
      t.string :client_id, null: false                  # Data field, reqd: 1
      t.string :client_secret, null: false              # Password field, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_zoom_settings, :enabled
    add_index :lms_zoom_settings, :account_name, unique: true
    add_index :lms_zoom_settings, :member
    add_index :lms_zoom_settings, :member_name
    add_index :lms_zoom_settings, :account_id
    add_index :lms_zoom_settings, :client_id
    add_index :lms_zoom_settings, :creation
    add_index :lms_zoom_settings, :modified
    add_index :lms_zoom_settings, [:member, :enabled]
    add_index :lms_zoom_settings, [:account_name, :member]

    # Add foreign key constraints
    add_foreign_key :lms_zoom_settings, :users, column: :member
  end
end
