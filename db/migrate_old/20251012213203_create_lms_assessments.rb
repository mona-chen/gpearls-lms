class CreateLmsAssessments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assessments do |t|
      t.string :name
      t.string :title
      t.text :description
      t.references :course, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: true
      t.references :evaluator, null: false, foreign_key: true
      t.string :assessment_type
      t.integer :max_marks
      t.integer :passing_marks
      t.integer :duration_minutes
      t.string :status
      t.string :difficulty_level
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :published_at
      t.datetime :ended_at
      t.integer :attempts_allowed
      t.integer :total_questions
      t.boolean :randomize_questions
      t.boolean :show_immediate_results
      t.boolean :allow_review
      t.boolean :require_proctoring
      t.text :instructions
      t.text :resources
      t.text :rubric
      t.text :tags
      t.text :metadata

      t.timestamps
    end
  end
end
