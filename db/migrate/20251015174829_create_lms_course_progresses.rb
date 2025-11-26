class CreateLmsCourseProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_course_progresses do |t|
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

      # Exact Frappe field structure from lms_course_progress.json
      t.string :member                          # Link to User, search_index: 1
      t.string :member_name                     # Data, fetched from member.full_name, read_only: 1
      t.string :status, null: false             # Select: Complete/Partially Complete/Incomplete, search_index: 1
      t.string :lesson                          # Link to Course Lesson, search_index: 1
      t.string :chapter                         # Link to Course Chapter, fetched from lesson.chapter, read_only: 1, search_index: 1
      t.string :course                          # Link to LMS Course, fetched from chapter.course, read_only: 1, search_index: 1
      t.boolean :is_scorm_chapter, default: false  # Check, default: "0", fetched from chapter.is_scorm_package, read_only: 1, search_index: 1
      t.text :scorm_content                     # Long Text, depends_on: is_scorm_chapter == 1 && status == 'Partially Complete', read_only: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_course_progresses, :member
    add_index :lms_course_progresses, :status
    add_index :lms_course_progresses, :lesson
    add_index :lms_course_progresses, :chapter
    add_index :lms_course_progresses, :course
    add_index :lms_course_progresses, :is_scorm_chapter
    add_index :lms_course_progresses, :creation
    add_index :lms_course_progresses, :modified
    add_index :lms_course_progresses, [ :member, :course ], name: 'index_course_prog_on_member_and_course'
    add_index :lms_course_progresses, [ :member, :status ], name: 'index_course_prog_on_member_and_status'
    add_index :lms_course_progresses, [ :course, :status ], name: 'index_course_prog_on_course_and_status'
    add_index :lms_course_progresses, [ :chapter, :lesson ], name: 'index_course_prog_on_chapter_and_lesson'
    add_index :lms_course_progresses, [ :member, :chapter, :lesson ], name: 'index_course_prog_on_member_chapter_lesson'

    # Add foreign key constraints
    add_foreign_key :lms_course_progresses, :users, column: :member
    # TODO: Add foreign keys when tables exist:
    # add_foreign_key :lms_course_progresses, :course_lessons, column: :lesson
    # add_foreign_key :lms_course_progresses, :course_chapters, column: :chapter
    add_foreign_key :lms_course_progresses, :lms_courses, column: :course
  end
end
