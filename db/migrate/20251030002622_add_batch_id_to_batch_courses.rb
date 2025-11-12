class AddBatchIdToBatchCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :batch_courses, :batch_id, :integer
    add_column :batch_courses, :course_id, :integer
  end
end
