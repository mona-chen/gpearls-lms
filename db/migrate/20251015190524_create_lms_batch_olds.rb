class CreateLmsBatchOlds < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_batch_olds do |t|
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

      # Exact Frappe field structure from lms_batch_old.json
      t.string :course, null: false                    # Link to LMS Course, reqd: 1
      t.date :start_date                              # Date field
      t.time :start_time                              # Time field
      t.string :title, null: false                     # Data field, reqd: 1
      t.string :sessions_on                             # Data field
      t.time :end_time                                # Time field
      t.text :description                             # Markdown Editor field
      t.string :visibility, default: "Public"        # Select: Public/Unlisted/Private
      t.string :membership                             # Select: Open/Restricted/Invite Only/Closed
      t.string :status, default: "Active"             # Select: Active/Inactive
      t.string :stage, default: "Ready"                # Select: Ready/In Progress/Completed/Cancelled

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_batch_olds, :course
    add_index :lms_batch_olds, :title
    add_index :lms_batch_olds, :start_date
    add_index :lms_batch_olds, :status
    add_index :lms_batch_olds, :stage
    add_index :lms_batch_olds, :visibility
    add_index :lms_batch_olds, :membership
    add_index :lms_batch_olds, :creation
    add_index :lms_batch_olds, :modified
    add_index :lms_batch_olds, [ :course, :status ]
    add_index :lms_batch_olds, [ :course, :start_date ]
    add_index :lms_batch_olds, [ :start_date, :start_time ]

    # Add foreign key constraints
    add_foreign_key :lms_batch_olds, :lms_courses, column: :course
  end
end
