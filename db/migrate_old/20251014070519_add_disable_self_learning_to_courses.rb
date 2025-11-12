class AddDisableSelfLearningToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :disable_self_learning, :boolean, default: false, null: false
  end
end
