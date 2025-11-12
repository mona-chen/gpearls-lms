class CreateRelatedCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :related_courses do |t|
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

      # Exact Frappe field structure from related_courses.json
      # This is a child table (istable: 1) with parent references
      t.string :course                    # Link to LMS Course

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :related_courses, :course
    add_index :related_courses, :parent
    add_index :related_courses, :parenttype
    add_index :related_courses, :parentfield
    add_index :related_courses, [:parent, :parenttype, :parentfield], name: 'index_related_courses_on_parent_and_type_and_field'
    add_index :related_courses, :creation
    add_index :related_courses, :modified

    # Add foreign key constraints
    add_foreign_key :related_courses, :lms_courses, column: :course
  end
end
