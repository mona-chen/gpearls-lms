class CreateLmsBadgeAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_badge_assignments do |t|
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

      # Exact Frappe field structure from lms_badge_assignment.json
      t.string :member, null: false                      # Link to User, reqd: 1
      t.string :member_name                             # Data, fetched from member.full_name
      t.string :member_username                         # Data, fetched from member.username
      t.string :member_image                            # Attach Image, fetched from member.user_image
      t.date :issued_on, null: false                    # Date, reqd: 1, options: "Today"
      t.string :badge, null: false                      # Link to LMS Badge, reqd: 1
      t.string :badge_image, null: false                # Attach, fetched from badge.image, reqd: 1
      t.text :badge_description, null: false            # Small Text, fetched from badge.description, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_badge_assignments, :member
    add_index :lms_badge_assignments, :badge
    add_index :lms_badge_assignments, :issued_on
    add_index :lms_badge_assignments, :creation
    add_index :lms_badge_assignments, :modified
    add_index :lms_badge_assignments, [:member, :badge], unique: true, name: 'index_badge_assign_on_member_and_badge'
    add_index :lms_badge_assignments, [:badge, :issued_on], name: 'index_badge_assign_on_badge_and_issued_on'
    add_index :lms_badge_assignments, [:member, :issued_on], name: 'index_badge_assign_on_member_and_issued_on'

    # Add foreign key constraints
    add_foreign_key :lms_badge_assignments, :users, column: :member
    add_foreign_key :lms_badge_assignments, :lms_badges, column: :badge
  end
end
