class CreateLmsMentorRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_mentor_requests do |t|
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

      # Exact Frappe field structure from lms_mentor_request.json
      t.string :member                          # Link to User
      t.string :course                          # Link to LMS Course
      t.string :reviewed_by                     # Link to User (Reviewed By)
      t.string :member_name                     # Data, fetched from member.full_name
      t.string :status, default: "Pending"      # Select: Pending/Approved/Rejected/Withdrawn
      t.text :comments                          # Small Text field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_mentor_requests, :member
    add_index :lms_mentor_requests, :course
    add_index :lms_mentor_requests, :reviewed_by
    add_index :lms_mentor_requests, :status
    add_index :lms_mentor_requests, :creation
    add_index :lms_mentor_requests, :modified
    add_index :lms_mentor_requests, [ :member, :course ], unique: true, name: 'index_mentor_req_on_member_and_course'
    add_index :lms_mentor_requests, [ :course, :status ], name: 'index_mentor_req_on_course_and_status'
    add_index :lms_mentor_requests, [ :member, :status ], name: 'index_mentor_req_on_member_and_status'

    # Add foreign key constraints
    add_foreign_key :lms_mentor_requests, :users, column: :member
    add_foreign_key :lms_mentor_requests, :lms_courses, column: :course
    add_foreign_key :lms_mentor_requests, :users, column: :reviewed_by
  end
end
