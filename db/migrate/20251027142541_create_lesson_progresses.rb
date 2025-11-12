class CreateLessonProgresses < ActiveRecord::Migration[7.2]
  def change
    create_table :lesson_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: { to_table: :course_lessons }
      t.integer :progress, default: 0
      t.boolean :completed, default: false
      t.datetime :last_accessed_at

      t.timestamps
    end

    add_index :lesson_progresses, [ :user_id, :lesson_id ], unique: true
  end
end
