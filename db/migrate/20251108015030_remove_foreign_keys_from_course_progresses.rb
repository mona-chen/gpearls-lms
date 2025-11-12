class RemoveForeignKeysFromCourseProgresses < ActiveRecord::Migration[7.2]
  def change
    # Remove foreign key constraints for Frappe compatibility
    # The course and member columns store names/emails as strings, not IDs
    remove_foreign_key :lms_course_progresses, :lms_courses, column: :course if foreign_key_exists?(:lms_course_progresses, :lms_courses, column: :course)
    remove_foreign_key :lms_course_progresses, :users, column: :member if foreign_key_exists?(:lms_course_progresses, :users, column: :member)
  end
end
