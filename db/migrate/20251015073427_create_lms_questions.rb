class CreateLmsQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_questions do |t|
      # LMS Questions specific fields (based on Frappe Question doctype)
      t.string :question_text, null: false                   # Question text (primary field)
      t.references :quiz, null: false, foreign_key: { to_table: :lms_quizzes }  # Parent quiz
      t.string :question_type, default: "Multiple Choice"   # Question type (Multiple Choice, True/False, Short Answer, Essay, etc.)
      t.text :description                                   # Additional description
      t.text :explanation                                   # Explanation of correct answer
      t.text :question_image                                # Question image URL
      t.string :question_video                              # Question video URL
      t.text :question_audio                                # Question audio URL
      t.decimal :marks, precision: 5, scale: 2, default: 1.00  # Marks for this question
      t.decimal :negative_marks, precision: 5, scale: 2, default: 0.00  # Negative marks for wrong answer
      t.boolean :mandatory, default: false                  # Whether question is mandatory
      t.integer :difficulty_level, default: 1               # Difficulty level (1-5)
      t.string :difficulty_level_text, default: "Easy"      # Difficulty level text
      t.string :category, null: true                        # Question category
      t.text :tags                                          # Question tags (JSON array)
      t.integer :position, default: 0                       # Position in quiz
      t.boolean :shuffle_options, default: false            # Shuffle answer options
      t.text :options                                       # Answer options (JSON)
      t.string :correct_answer                              # Correct answer (stored as string for flexibility)
      t.text :correct_answer_explanation                    # Explanation for correct answer
      t.boolean :multiple_correct_answers, default: false   # Allow multiple correct answers
      t.text :correct_answers                              # Multiple correct answers (JSON array)
      t.boolean :case_sensitive, default: false            # Answer is case sensitive
      t.text :validation_rules                             # Answer validation rules (JSON)
      t.integer :time_limit_seconds, default: 0             # Time limit for this question
      t.boolean :show_explanation, default: true           # Show explanation after answer
      t.text :hints                                         # Hints for students (JSON)
      t.integer :attempts_allowed, default: 1              # Number of attempts allowed
      t.text :reference_material                            # Reference material (JSON)
      t.string :author, null: true                          # Question author
      t.references :created_by, foreign_key: { to_table: :users }, null: true  # Creator
      t.references :updated_by, foreign_key: { to_table: :users }, null: true  # Last updater
      t.boolean :is_public, default: false                 # Whether question is public (can be used in other quizzes)
      t.integer :usage_count, default: 0                   # How many times this question is used
      t.decimal :average_score, precision: 5, scale: 2, default: 0.00  # Average score across attempts
      t.integer :total_attempts, default: 0                # Total attempts across all students
      t.decimal :success_rate, precision: 5, scale: 2, default: 0.00  # Success rate percentage
      t.text :custom_fields                                 # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    # quiz_id index automatically created by references helper
    add_index :lms_questions, :question_type
    add_index :lms_questions, :marks
    add_index :lms_questions, :difficulty_level
    add_index :lms_questions, :category
    add_index :lms_questions, :position
    add_index :lms_questions, :mandatory
    add_index :lms_questions, :is_public
    add_index :lms_questions, :usage_count
    add_index :lms_questions, :average_score
    add_index :lms_questions, :success_rate
    # created_by_id and updated_by_id indexes automatically created by references helpers
    add_index :lms_questions, [ :quiz_id, :position ]
    add_index :lms_questions, [ :question_type, :difficulty_level ]
    add_index :lms_questions, [ :category, :is_public ]
    add_index :lms_questions, [ :mandatory, :position ]
  end
end
