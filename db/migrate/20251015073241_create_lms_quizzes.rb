class CreateLmsQuizzes < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quizzes do |t|
      # LMS Quizzes specific fields (based on Frappe Quiz doctype)
      t.string :title, null: false                        # Quiz title (primary field)
      t.references :course, null: false, foreign_key: { to_table: :lms_courses }  # Parent course
      t.references :chapter, foreign_key: { to_table: :course_chapters }, null: true  # Parent chapter
      t.text :description                                 # Quiz description
      t.string :quiz_code, null: true                     # Unique quiz code
      t.string :status, default: "Draft"                  # Quiz status (Draft, Published, Archived)
      t.string :quiz_type, default: "Graded"              # Quiz type (Graded, Practice, Survey)
      t.decimal :total_marks, precision: 10, scale: 2, default: 100.00  # Total possible marks
      t.decimal :passing_percentage, precision: 5, scale: 2, default: 70.00  # Passing percentage
      t.integer :duration_minutes, default: 60            # Quiz duration in minutes
      t.integer :max_attempts, default: 1                 # Maximum attempts allowed
      t.boolean :allow_review, default: true              # Allow students to review answers
      t.boolean :show_correct_answers, default: true      # Show correct answers after review
      t.boolean :shuffle_questions, default: false        # Shuffle question order
      t.boolean :shuffle_options, default: false          # Shuffle option order
      t.boolean :randomize_questions, default: false      # Select random questions from pool
      t.integer :random_question_count, default: 0        # Number of questions to randomize
      t.datetime :start_date, null: true                  # Quiz start date
      t.datetime :end_date, null: true                    # Quiz end date
      t.boolean :time_bound, default: false               # Quiz is time-bound
      t.string :access_code, null: true                   # Access code for quiz
      t.boolean :require_password, default: false         # Require password to access
      t.string :password, null: true                      # Quiz password
      t.text :instructions                                # Quiz instructions
      t.text :completion_message                          # Message shown on completion
      t.text :feedback_settings                           # Feedback settings (JSON)
      t.integer :questions_count, default: 0              # Number of questions
      t.decimal :average_score, precision: 5, scale: 2, default: 0.00  # Average score across attempts
      t.integer :total_attempts, default: 0               # Total attempts across all students
      t.decimal :success_rate, precision: 5, scale: 2, default: 0.00  # Success rate percentage
      t.boolean :certificate_enabled, default: false     # Enable certificate on completion
      t.string :certificate_template, null: true         # Certificate template
      t.boolean :auto_grade, default: true                # Automatic grading
      t.text :grading_criteria                            # Grading criteria (JSON)
      t.boolean :allow_partial_credit, default: true      # Allow partial credit for answers
      t.decimal :negative_marking_percentage, precision: 5, scale: 2, default: 0.00  # Negative marking percentage
      t.boolean :show_results_immediately, default: true  # Show results immediately after submission
      t.datetime :published_at, null: true                # Publication date
      t.references :created_by, foreign_key: { to_table: :users }, null: true  # Creator
      t.references :updated_by, foreign_key: { to_table: :users }, null: true  # Last updater
      t.integer :sort_order, default: 0                   # Sort order
      t.text :custom_fields                               # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_quizzes, :title
    # course_id and chapter_id indexes automatically created by references helpers
    add_index :lms_quizzes, :quiz_code, unique: true
    add_index :lms_quizzes, :status
    add_index :lms_quizzes, :quiz_type
    add_index :lms_quizzes, :start_date
    add_index :lms_quizzes, :end_date
    add_index :lms_quizzes, :duration_minutes
    add_index :lms_quizzes, :total_marks
    add_index :lms_quizzes, :passing_percentage
    add_index :lms_quizzes, :average_score
    add_index :lms_quizzes, :success_rate
    add_index :lms_quizzes, :published_at
    # created_by_id index automatically created by references helper
    add_index :lms_quizzes, :sort_order
    add_index :lms_quizzes, [ :course_id, :status ]
    add_index :lms_quizzes, [ :status, :start_date ]
    add_index :lms_quizzes, [ :chapter_id, :status ]
    add_index :lms_quizzes, [ :quiz_type, :status ]
  end
end
