class AddWorkflowStateToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_courses, :workflow_state, :string
  end
end
