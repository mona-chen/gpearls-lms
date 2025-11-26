class CreateCourseChapters < ActiveRecord::Migration[7.0]
  def change
    create_table :course_chapters do |t|
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

      # Exact Frappe field structure from course_chapter.json
      t.string :title, null: false                     # Data field, reqd: 1
      t.string :course, null: false                    # Link to LMS Course, reqd: 1
      t.string :course_title                           # Data, fetched from course.title
      t.boolean :is_scorm_package, default: false      # Check field, default: "0"
      t.string :scorm_package                         # Link to File, read_only: 1
      t.text :scorm_package_path                      # Code field, read_only: 1
      t.text :manifest_file                           # Code field, depends_on: is_scorm_package, read_only: 1
      t.text :launch_file                             # Code field, depends_on: is_scorm_package, read_only: 1
      t.string :lessons                               # Table field (child table reference to Lesson Reference)

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :course_chapters, :title
    add_index :course_chapters, :course
    add_index :course_chapters, :is_scorm_package
    add_index :course_chapters, :creation
    add_index :course_chapters, :modified
    add_index :course_chapters, [ :course, :title ], name: 'index_course_chapters_on_course_and_title'

    # Add foreign key constraints
    add_foreign_key :course_chapters, :lms_courses, column: :course
  end
end
