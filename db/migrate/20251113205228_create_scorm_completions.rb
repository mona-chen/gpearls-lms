class CreateScormCompletions < ActiveRecord::Migration[7.0]
  def change
    create_table :scorm_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scorm_package, null: false, foreign_key: true
      t.references :course_lesson, null: false, foreign_key: true
      t.integer :completion_status, default: 0
      t.integer :success_status, default: 0
      t.float :score_raw
      t.float :score_min
      t.float :score_max
      t.integer :total_time # in seconds
      t.integer :session_time # in seconds
      t.text :suspend_data
      t.string :location
      t.json :interactions_data
      t.json :objectives_data
      t.json :scorm_data # full SCORM data for debugging
      t.datetime :started_at
      t.datetime :last_accessed_at
      t.datetime :completed_at
      
      t.timestamps
    end
    
    add_index :scorm_completions, [:user_id, :scorm_package_id], unique: true, name: 'unique_user_scorm_completion'
    add_index :scorm_completions, [:course_lesson_id], name: 'index_scorm_completions_on_lesson'
    add_index :scorm_completions, [:completion_status], name: 'index_scorm_completions_on_status'
    add_index :scorm_completions, [:last_accessed_at], name: 'index_scorm_completions_on_access_time'
  end
end