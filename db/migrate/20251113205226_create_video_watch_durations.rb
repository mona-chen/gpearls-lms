class CreateVideoWatchDurations < ActiveRecord::Migration[7.0]
  def change
    create_table :video_watch_durations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course_lesson, null: false, foreign_key: true
      t.string :video_url, null: false
      t.integer :duration_watched, default: 0 # seconds
      t.integer :video_length, default: 0 # total video length in seconds
      t.integer :last_position, default: 0 # last watched position
      t.json :watch_sessions # array of watch sessions with timestamps
      t.datetime :first_watched_at
      t.datetime :last_watched_at

      t.timestamps
    end

    add_index :video_watch_durations, [ :user_id, :course_lesson_id, :video_url ],
              unique: true, name: 'unique_user_lesson_video'
    add_index :video_watch_durations, [ :course_lesson_id ], name: 'index_video_durations_on_course_lesson'
    add_index :video_watch_durations, [ :user_id, :updated_at ], name: 'index_video_durations_on_user_time'
  end
end
