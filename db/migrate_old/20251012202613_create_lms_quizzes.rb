class CreateLmsQuizzes < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quizzes do |t|
      t.string :name
      t.string :title
      t.text :description
      t.references :course, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: true
      t.integer :max_attempts
      t.integer :duration_minutes
      t.decimal :passing_percentage
      t.string :status
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :published_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
