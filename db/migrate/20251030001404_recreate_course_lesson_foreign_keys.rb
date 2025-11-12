class RecreateCourseLessonForeignKeys < ActiveRecord::Migration[7.2]
  def change
    # Remove existing foreign keys (they reference wrong columns)
    remove_foreign_key :course_lessons, :course_chapters, column: :chapter if foreign_key_exists?(:course_lessons, :course_chapters, column: :chapter)
    remove_foreign_key :course_lessons, :lms_courses, column: :course if foreign_key_exists?(:course_lessons, :lms_courses, column: :course)

    # Add correct foreign keys
    # CourseChapter primary key is 'name', so reference that
    add_foreign_key :course_lessons, :course_chapters, column: :chapter, primary_key: :name
    # Course primary key is 'id' (default)
    add_foreign_key :course_lessons, :lms_courses, column: :course
  end
end
