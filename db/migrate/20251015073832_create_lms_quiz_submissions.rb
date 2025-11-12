class CreateLmsQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quiz_submissions do |t|
      # LMS Quiz Submissions specific fields (based on Frappe Quiz Submission doctype)
      t.references :quiz, null: false, foreign_key: { to_table: :lms_quizzes }  # Parent quiz
      t.references :student, null: false, foreign_key: { to_table: :users }  # Student who submitted
      t.references :enrollment, foreign_key: { to_table: :lms_enrollments }, null: true  # Course enrollment
      t.string :submission_code, null: false             # Unique submission code
      t.integer :attempt_number, default: 1               # Attempt number
      t.string :status, default: "In Progress"           # Submission status (In Progress, Submitted, Evaluated, Expired)
      t.datetime :start_time, null: false                # Quiz start time
      t.datetime :end_time, null: true                   # Quiz end time
      t.integer :duration_seconds, default: 0            # Actual time taken in seconds
      t.decimal :total_marks, precision: 10, scale: 2, default: 0.00  # Total marks obtained
      t.decimal :maximum_marks, precision: 10, scale: 2, default: 0.00  # Maximum possible marks
      t.decimal :percentage, precision: 5, scale: 2, default: 0.00  # Percentage score
      t.decimal :passing_percentage, precision: 5, scale: 2, default: 70.00  # Passing percentage
      t.boolean :passed, default: false                  # Whether student passed
      t.integer :correct_answers, default: 0             # Number of correct answers
      t.integer :incorrect_answers, default: 0           # Number of incorrect answers
      t.integer :unanswered_questions, default: 0        # Number of unanswered questions
      t.integer :partial_credit_questions, default: 0    # Questions with partial credit
      t.text :answers                                     # Student answers (JSON)
      t.text :answer_details                              # Detailed answer breakdown (JSON)
      t.text :question_scores                             # Individual question scores (JSON)
      t.text :feedback                                    # Overall feedback
      t.text :question_feedback                           # Individual question feedback (JSON)
      t.boolean :auto_graded, default: false              # Whether automatically graded
      t.datetime :graded_at, null: true                   # When submission was graded
      t.references :graded_by, foreign_key: { to_table: :users }, null: true  # Who graded the submission
      t.text :grading_notes                               # Grading notes
      t.boolean :review_allowed, default: true            # Whether student can review answers
      t.datetime :review_start_time, null: true           # When review period started
      t.datetime :review_end_time, null: true             # When review period ends
      t.boolean :review_completed, default: false         # Whether student completed review
      t.datetime :review_completed_at, null: true         # When review was completed
      t.text :review_notes                                # Student review notes
      t.string :ip_address, null: true                    # IP address during submission
      t.string :user_agent, null: true                    # Browser user agent
      t.text :suspicious_activity                        # Suspicious activity flags (JSON)
      t.boolean :integrity_check_passed, default: true    # Whether integrity checks passed
      t.text :integrity_check_details                     # Integrity check details (JSON)
      t.text :time_log                                    # Time spent on each question (JSON)
      t.integer :tab_switches, default: 0                 # Number of tab switches
      t.boolean :window_focus_lost, default: false        # Whether window focus was lost
      t.text :technical_issues                            # Technical issues reported (JSON)
      t.boolean :late_submission, default: false          # Whether submitted after deadline
      t.datetime :late_submission_reason, null: true      # Reason for late submission
      t.boolean :extension_granted, default: false        # Whether time extension was granted
      t.integer :extension_minutes, default: 0            # Extension minutes granted
      t.text :extension_reason                            # Reason for extension
      t.references :extension_approved_by, foreign_key: { to_table: :users }, null: true  # Who approved extension
      t.text :custom_fields                               # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    # quiz_id, student_id, enrollment_id indexes automatically created by references helpers
    add_index :lms_quiz_submissions, :submission_code, unique: true
    add_index :lms_quiz_submissions, :status
    add_index :lms_quiz_submissions, :start_time
    add_index :lms_quiz_submissions, :end_time
    add_index :lms_quiz_submissions, :total_marks
    add_index :lms_quiz_submissions, :percentage
    add_index :lms_quiz_submissions, :passed
    add_index :lms_quiz_submissions, :graded_at
    # graded_by_id index automatically created by references helper
    add_index :lms_quiz_submissions, :review_completed
    add_index :lms_quiz_submissions, :late_submission
    add_index :lms_quiz_submissions, [:quiz_id, :student_id]
    add_index :lms_quiz_submissions, [:student_id, :quiz_id]
    add_index :lms_quiz_submissions, [:quiz_id, :status]
    add_index :lms_quiz_submissions, [:student_id, :status]
    add_index :lms_quiz_submissions, [:status, :start_time]
    add_index :lms_quiz_submissions, [:quiz_id, :student_id, :attempt_number], unique: true
  end
end
