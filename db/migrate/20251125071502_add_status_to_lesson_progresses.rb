class AddStatusToLessonProgresses < ActiveRecord::Migration[7.2]
  def change
    add_column :lesson_progresses, :status, :string, default: 'Incomplete'
  end
end
