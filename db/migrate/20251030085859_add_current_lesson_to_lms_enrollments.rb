class AddCurrentLessonToLmsEnrollments < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_enrollments, :current_lesson, :string
  end
end
