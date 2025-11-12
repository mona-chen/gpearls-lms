class AddEvaluatorIdToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_courses, :evaluator_id, :integer
  end
end
