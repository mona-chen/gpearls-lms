class CreateLmsQuizResults < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quiz_results do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.string :status
      t.integer :score
      t.integer :max_score
      t.decimal :percentage
      t.integer :time_taken_seconds
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :submitted_at
      t.datetime :evaluated_at
      t.references :evaluator, null: false, foreign_key: true
      t.text :evaluator_notes

      t.timestamps
    end
  end
end
