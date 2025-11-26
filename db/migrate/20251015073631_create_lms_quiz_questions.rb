class CreateLmsQuizQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quiz_questions do |t|
      # LMS Quiz Questions specific fields (based on Frappe Quiz Question doctype)
      t.references :quiz, null: false, foreign_key: { to_table: :lms_quizzes }  # Parent quiz
      t.references :question, null: false, foreign_key: { to_table: :lms_questions }  # Question reference
      t.integer :position, default: 0                       # Position in quiz
      t.decimal :marks, precision: 5, scale: 2, default: 1.00  # Override marks for this quiz
      t.decimal :negative_marks, precision: 5, scale: 2, default: 0.00  # Override negative marks
      t.boolean :mandatory, default: false                  # Whether question is mandatory in this quiz
      t.text :question_override                             # Override question text (if different)
      t.text :options_override                              # Override answer options (if different)
      t.string :correct_answer_override                     # Override correct answer (if different)
      t.text :explanation_override                          # Override explanation (if different)
      t.boolean :shuffle_options, default: false            # Shuffle options for this question
      t.integer :time_limit_seconds, default: 0             # Time limit for this question in this quiz
      t.text :custom_instructions                           # Custom instructions for this question
      t.text :reference_material                            # Reference material for this question
      t.boolean :show_explanation, default: true           # Show explanation after answering
      t.integer :attempts_allowed, default: 1              # Attempts allowed for this question
      t.text :validation_rules                             # Custom validation rules (JSON)
      t.text :hints                                         # Hints for this question (JSON)
      t.boolean :is_active, default: true                   # Whether this question is active in the quiz
      t.datetime :added_at                                  # When question was added to quiz
      t.references :added_by, foreign_key: { to_table: :users }, null: true  # Who added this question
      t.text :notes                                        # Notes about this question in quiz context
      t.text :custom_fields                                # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    # quiz_id and question_id indexes automatically created by references helpers
    add_index :lms_quiz_questions, :position
    add_index :lms_quiz_questions, :marks
    add_index :lms_quiz_questions, :mandatory
    add_index :lms_quiz_questions, :is_active
    add_index :lms_quiz_questions, :added_at
    # added_by_id index automatically created by references helper
    add_index :lms_quiz_questions, [ :quiz_id, :position ], unique: true
    add_index :lms_quiz_questions, [ :quiz_id, :question_id ], unique: true
    add_index :lms_quiz_questions, [ :quiz_id, :is_active ]
    add_index :lms_quiz_questions, [ :question_id, :is_active ]
    add_index :lms_quiz_questions, [ :mandatory, :position ]
  end
end
