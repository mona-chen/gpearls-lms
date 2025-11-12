class RemoveForeignKeysFromCourseReviews < ActiveRecord::Migration[7.2]
  def change
    # Remove foreign key constraint for Frappe compatibility
    # The course column stores course name as string, not ID
    remove_foreign_key :lms_course_reviews, :lms_courses, column: :course if foreign_key_exists?(:lms_course_reviews, :lms_courses, column: :course)
  end
end
