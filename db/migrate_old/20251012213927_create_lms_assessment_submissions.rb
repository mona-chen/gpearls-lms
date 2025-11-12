class CreateLmsAssessmentSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assessment_submissions do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.references :assessment_attempt, null: false, foreign_key: true
      t.references :evaluator, null: false, foreign_key: true
      t.string :status
      t.integer :score
      t.integer :max_score
      t.decimal :percentage
      t.integer :time_taken_seconds
      t.integer :attempt_number
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :submitted_at
      t.datetime :evaluated_at
      t.text :evaluator_notes
      t.text :submission_data

      t.timestamps
    end
  end
end
