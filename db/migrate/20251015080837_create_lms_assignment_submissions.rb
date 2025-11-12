class CreateLmsAssignmentSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assignment_submissions do |t|
      # LMS Assignment Submissions specific fields (based on Frappe Assignment Submission doctype)
      t.references :assignment, null: false, foreign_key: { to_table: :lms_assignments }  # Parent assignment
      t.references :student, null: false, foreign_key: { to_table: :users }  # Student who submitted
      t.references :enrollment, foreign_key: { to_table: :lms_enrollments }, null: true  # Course enrollment
      t.string :submission_code, null: false             # Unique submission code
      t.integer :attempt_number, default: 1               # Attempt number
      t.string :status, default: "Draft"                 # Submission status (Draft, Submitted, Graded, Returned)
      t.text :submission_text                             # Text submission content
      t.text :submission_files                           # Uploaded files information (JSON)
      t.string :submission_url, null: true                # External submission URL
      t.datetime :submitted_at, null: true                # Submission timestamp
      t.datetime :due_date, null: true                   # Original due date
      t.boolean :late_submission, default: false          # Whether submitted after due date
      t.integer :late_days, default: 0                   # Number of days late
      t.decimal :late_penalty, precision: 5, scale: 2, default: 0.00  # Late penalty applied
      t.decimal :marks_obtained, precision: 10, scale: 2, null: true  # Marks obtained
      t.decimal :total_marks, precision: 10, scale: 2, default: 0.00  # Total possible marks
      t.decimal :percentage, precision: 5, scale: 2, default: 0.00  # Percentage score
      t.boolean :passed, default: false                  # Whether student passed
      t.text :feedback                                    # Instructor feedback
      t.text :detailed_feedback                           # Detailed feedback (JSON)
      t.text :grading_notes                               # Grading notes
      t.datetime :graded_at, null: true                   # When submission was graded
      t.references :graded_by, foreign_key: { to_table: :users }, null: true  # Who graded the submission
      t.boolean :auto_graded, default: false              # Whether automatically graded
      t.decimal :auto_grade_score, precision: 5, scale: 2, default: 0.00  # Auto-grade score
      t.text :auto_grade_details                          # Auto-grade details (JSON)
      t.boolean :plagiarism_checked, default: false       # Whether plagiarism check was performed
      t.decimal :plagiarism_score, precision: 5, scale: 2, default: 0.00  # Plagiarism similarity score
      t.text :plagiarism_report                          # Plagiarism report details (JSON)
      t.boolean :peer_review_completed, default: false    # Whether peer review is completed
      t.integer :peer_reviews_received, default: 0        # Number of peer reviews received
      t.decimal :peer_review_average_score, precision: 5, scale: 2, default: 0.00  # Average peer review score
      t.text :peer_review_feedback                        # Peer review feedback (JSON)
      t.boolean :returned_to_student, default: false      # Whether returned to student
      t.datetime :returned_at, null: true                 # When returned to student
      t.boolean :resubmission_allowed, default: false     # Whether resubmission is allowed
      t.integer :resubmission_count, default: 0           # Number of resubmissions
      t.datetime :resubmission_deadline, null: true       # Resubmission deadline
      t.text :submission_history                          # Submission history (JSON)
      t.string :ip_address, null: true                    # IP address during submission
      t.string :user_agent, null: true                    # Browser user agent
      t.text :technical_issues                            # Technical issues reported (JSON)
      t.text :custom_fields                               # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    # assignment_id, student_id, enrollment_id indexes automatically created by references helpers
    add_index :lms_assignment_submissions, :submission_code, unique: true
    add_index :lms_assignment_submissions, :status
    add_index :lms_assignment_submissions, :attempt_number
    add_index :lms_assignment_submissions, :submitted_at
    add_index :lms_assignment_submissions, :late_submission
    add_index :lms_assignment_submissions, :marks_obtained
    add_index :lms_assignment_submissions, :percentage
    add_index :lms_assignment_submissions, :passed
    add_index :lms_assignment_submissions, :graded_at
    # graded_by_id index automatically created by references helper
    add_index :lms_assignment_submissions, :auto_graded
    add_index :lms_assignment_submissions, :plagiarism_checked
    add_index :lms_assignment_submissions, :peer_review_completed
    add_index :lms_assignment_submissions, :returned_to_student
    add_index :lms_assignment_submissions, [:assignment_id, :student_id]
    add_index :lms_assignment_submissions, [:student_id, :assignment_id]
    add_index :lms_assignment_submissions, [:assignment_id, :status]
    add_index :lms_assignment_submissions, [:student_id, :status]
    add_index :lms_assignment_submissions, [:status, :submitted_at]
    add_index :lms_assignment_submissions, [:assignment_id, :student_id, :attempt_number], unique: true
  end
end
