class AddEvaluatorIdToBatchCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :batch_courses, :evaluator_id, :integer
  end
end
