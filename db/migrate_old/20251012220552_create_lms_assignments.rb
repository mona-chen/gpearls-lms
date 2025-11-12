class CreateLmsAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assignments do |t|
      t.string :name
      t.string :title
      t.text :description
      t.string :assignment_type
      t.references :course, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.references :chapter, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: true
      t.references :evaluator, null: false, foreign_key: true
      t.integer :max_marks
      t.integer :passing_marks
      t.integer :min_word_count
      t.integer :max_word_count
      t.integer :duration_minutes
      t.string :status
      t.string :difficulty_level
      t.text :instructions
      t.text :resources
      t.text :rubric
      t.text :sample_answer
      t.datetime :publish_date
      t.datetime :due_date
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :allow_late_submission
      t.integer :late_submission_penalty
      t.boolean :allow_resubmission
      t.integer :max_resubmissions
      t.boolean :require_peer_review
      t.integer :min_peer_reviewers
      t.boolean :require_file_upload
      t.integer :max_file_size
      t.string :allowed_file_types
      t.boolean :auto_grade
      t.boolean :show_immediate_feedback
      t.boolean :require_proctoring
      t.boolean :randomize_questions
      t.boolean :show_correct_answers
      t.boolean :include_in_grading

      t.timestamps
    end
  end
end
