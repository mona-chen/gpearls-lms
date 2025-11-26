class CreateCourseLessons < ActiveRecord::Migration[7.0]
  def change
    create_table :course_lessons do |t|
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

      # Exact Frappe field structure from course_lesson.json
      t.string :title, null: false                     # Data field, reqd: 1
      t.boolean :include_in_preview, default: false   # Check field, default: "0"
      t.string :chapter, null: false                  # Link to Course Chapter, reqd: 1
      t.boolean :is_scorm_package, default: false      # Check field, fetched from chapter.is_scorm_package
      t.string :course                                 # Link to LMS Course, fetched from chapter.course
      t.text :content                                 # Text field
      t.text :body                                   # Markdown Editor field
      t.text :instructor_content                      # Text field
      t.text :instructor_notes                       # Markdown Editor field
      t.string :youtube                               # Data field for YouTube Video URL
      t.string :quiz_id                               # Data field for Quiz ID
      t.text :question                               # Small Text field for Assignment
      t.string :file_type                             # Select: Image/Document/PDF
      t.text :help                                   # HTML field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :course_lessons, :title
    add_index :course_lessons, :chapter
    add_index :course_lessons, :course
    add_index :course_lessons, :include_in_preview
    add_index :course_lessons, :is_scorm_package
    add_index :course_lessons, :creation
    add_index :course_lessons, :modified
    add_index :course_lessons, [ :chapter, :title ], name: 'index_course_lessons_on_chapter_and_title'
    add_index :course_lessons, [ :course, :title ], name: 'index_course_lessons_on_course_and_title'

    # Add foreign key constraints
    add_foreign_key :course_lessons, :course_chapters, column: :chapter
    add_foreign_key :course_lessons, :lms_courses, column: :course
  end
end
