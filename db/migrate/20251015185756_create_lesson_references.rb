class CreateLessonReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :lesson_references do |t|
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

      # Exact Frappe field structure from lesson_reference.json
      # This is a child table (istable: 1) with parent references
      t.string :lesson, null: false                     # Link to Course Lesson, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lesson_references, :lesson
    add_index :lesson_references, :parent
    add_index :lesson_references, :parenttype
    add_index :lesson_references, :parentfield
    add_index :lesson_references, [ :parent, :parenttype, :parentfield ], name: 'index_lesson_refs_on_parent_and_type_and_field'
    add_index :lesson_references, :creation
    add_index :lesson_references, :modified

    # Add foreign key constraints
    # TODO: Add foreign key when table exists:
    # add_foreign_key :lesson_references, :course_lessons, column: :lesson
  end
end


### **Migration 6: preferred_function**
