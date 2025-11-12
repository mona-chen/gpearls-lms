class CreateLessonProgresses < ActiveRecord::Migration[7.2]
  def change
    create_table :lesson_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.integer :progress
      t.boolean :completed
      t.datetime :last_accessed_at

      t.timestamps
    end
  end
end
