class CreateLmsCourseMentorMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_course_mentor_mappings do |t|
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

      # Exact Frappe field structure from lms_course_mentor_mapping.json
      t.string :course, null: false                    # Link to LMS Course
      t.string :mentor, null: false                     # Link to User
      t.string :mentor_name                            # Data, fetched from mentor.full_name

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_course_mentor_mappings, :course
    add_index :lms_course_mentor_mappings, :mentor
    add_index :lms_course_mentor_mappings, :mentor_name
    add_index :lms_course_mentor_mappings, :creation
    add_index :lms_course_mentor_mappings, :modified
    add_index :lms_course_mentor_mappings, [ :course, :mentor ], unique: true, name: 'index_course_mentor_mapping_on_course_and_mentor'
    add_index :lms_course_mentor_mappings, [ :mentor, :course ]

    # Add foreign key constraints
    add_foreign_key :lms_course_mentor_mappings, :lms_courses, column: :course
    add_foreign_key :lms_course_mentor_mappings, :users, column: :mentor
  end
end
