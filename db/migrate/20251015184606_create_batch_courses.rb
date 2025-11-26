class CreateBatchCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :batch_courses do |t|
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

      # Exact Frappe field structure from batch_course.json
      # This is a child table (istable: 1) with parent references
      t.string :course, null: false                    # Link to LMS Course, reqd: 1
      t.string :title, null: false                     # Data, fetched from course.title
      t.string :evaluator                             # Link to Course Evaluator

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :batch_courses, :course
    add_index :batch_courses, :title
    add_index :batch_courses, :evaluator
    add_index :batch_courses, :parent
    add_index :batch_courses, :parenttype
    add_index :batch_courses, :parentfield
    add_index :batch_courses, [ :parent, :parenttype, :parentfield ], name: 'index_batch_courses_on_parent_and_type_and_field'
    add_index :batch_courses, :creation
    add_index :batch_courses, :modified
    add_index :batch_courses, [ :course, :evaluator ]

    # Add foreign key constraints
    add_foreign_key :batch_courses, :lms_courses, column: :course
    add_foreign_key :batch_courses, :course_evaluators, column: :evaluator
  end
end
