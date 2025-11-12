class CreateCourseInstructors < ActiveRecord::Migration[7.0]
  def change
    create_table :course_instructors do |t|
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

      # Exact Frappe field structure from course_instructor.json
      # This is a child table (istable: 1) with parent references
      t.string :instructor                    # Link to User

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :course_instructors, :instructor
    add_index :course_instructors, :parent
    add_index :course_instructors, :parenttype
    add_index :course_instructors, :parentfield
    add_index :course_instructors, [:parent, :parenttype, :parentfield], name: 'index_course_instructors_on_parent_and_type_and_field'
    add_index :course_instructors, :creation
    add_index :course_instructors, :modified

    # Add foreign key constraints
    add_foreign_key :course_instructors, :users, column: :instructor
  end
end
