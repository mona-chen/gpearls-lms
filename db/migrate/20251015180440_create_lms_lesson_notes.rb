class CreateLmsLessonNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_lesson_notes do |t|
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

      # Exact Frappe field structure from lms_lesson_note.json
      t.string :lesson, null: false                     # Link to Course Lesson, reqd: 1
      t.string :course                                  # Link to LMS Course, fetched from lesson.course
      t.string :member, null: false                     # Link to User, reqd: 1
      t.string :color, null: false                      # Select: Red/Blue/Green/Yellow/Purple, reqd: 1
      t.text :highlighted_text                          # Small Text field
      t.text :note                                      # Text Editor field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_lesson_notes, :lesson
    add_index :lms_lesson_notes, :course
    add_index :lms_lesson_notes, :member
    add_index :lms_lesson_notes, :color
    add_index :lms_lesson_notes, :creation
    add_index :lms_lesson_notes, :modified
    add_index :lms_lesson_notes, [ :member, :lesson ], unique: true, name: 'index_lesson_note_on_member_and_lesson'
    add_index :lms_lesson_notes, [ :course, :member ], name: 'index_lesson_note_on_course_and_member'

    # Add foreign key constraints
    # TODO: Add foreign keys when tables exist:
    # add_foreign_key :lms_lesson_notes, :course_lessons, column: :lesson
    add_foreign_key :lms_lesson_notes, :lms_courses, column: :course
    add_foreign_key :lms_lesson_notes, :users, column: :member
  end
end
