class CreateLmsCourseInterests < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_course_interests do |t|
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

      # Exact Frappe field structure from lms_course_interest.json
      t.string :course, null: false                     # Link to LMS Course
      t.string :user, null: false                       # Link to User
      t.boolean :email_sent, default: false              # Check field, default: "0"

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_course_interests, :course
    add_index :lms_course_interests, :user
    add_index :lms_course_interests, :email_sent
    add_index :lms_course_interests, :creation
    add_index :lms_course_interests, :modified
    add_index :lms_course_interests, [ :course, :user ], unique: true, name: 'index_course_interest_on_course_and_user'
    add_index :lms_course_interests, [ :user, :email_sent ]

    # Add foreign key constraints
    add_foreign_key :lms_course_interests, :lms_courses, column: :course
    add_foreign_key :lms_course_interests, :users, column: :user
  end
end
