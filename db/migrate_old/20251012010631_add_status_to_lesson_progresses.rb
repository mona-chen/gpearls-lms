class AddStatusToLessonProgresses < ActiveRecord::Migration[7.2]
  def change
    add_column :lesson_progresses, :status, :string
  end
end
