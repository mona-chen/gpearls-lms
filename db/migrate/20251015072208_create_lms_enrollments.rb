class CreateLmsEnrollments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_enrollments do |t|
      # LMS Enrollments specific fields (based on Frappe Course Enrollment doctype)
      t.references :student, null: false, foreign_key: { to_table: :users }  # Enrolled student
      t.references :course, null: false, foreign_key: { to_table: :lms_courses }  # Enrolled course
      t.references :batch, foreign_key: { to_table: :lms_batches }, null: true  # Specific batch (if applicable)
      t.string :enrollment_number, null: false          # Unique enrollment number
      t.string :status, default: "Active"               # Enrollment status (Active, Completed, Suspended, Cancelled)
      t.datetime :enrollment_date, null: false          # Date of enrollment
      t.datetime :completion_date, null: true           # Date of completion
      t.decimal :progress_percentage, precision: 5, scale: 2, default: 0.00  # Overall progress percentage
      t.integer :lessons_completed, default: 0          # Number of lessons completed
      t.integer :total_lessons, default: 0              # Total lessons in course
      t.decimal :grade_obtained, precision: 5, scale: 2, null: true  # Final grade obtained
      t.decimal :passing_percentage, precision: 5, scale: 2, default: 70.00  # Passing percentage
      t.boolean :passed, default: false                 # Whether student passed
      t.string :certificate_number, null: true          # Certificate number (if issued)
      t.datetime :certificate_issued_date, null: true   # Certificate issue date
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0.00  # Amount paid for enrollment
      t.string :payment_status, default: "Pending"      # Payment status (Pending, Paid, Failed, Refunded)
      t.string :payment_method, null: true              # Payment method used
      t.datetime :payment_date, null: true              # Payment date
      t.string :transaction_id, null: true              # Payment transaction ID
      t.text :enrollment_notes                          # Notes about enrollment
      t.text :special_requirements                      # Special requirements or accommodations
      t.references :approved_by, foreign_key: { to_table: :users }, null: true  # Who approved enrollment
      t.datetime :approval_date, null: true             # Approval date
      t.string :rejection_reason, null: true            # Reason for rejection (if applicable)
      t.boolean :send_email_notifications, default: true  # Send email notifications
      t.datetime :last_access_date, null: true          # Last date student accessed course
      t.integer :total_time_spent_minutes, default: 0   # Total time spent in minutes
      t.text :progress_details                          # Detailed progress (JSON)
      t.text :quiz_scores                               # Quiz scores (JSON)
      t.text :assignment_scores                         # Assignment scores (JSON)
      t.boolean :feedback_provided, default: false      # Whether feedback was provided
      t.text :feedback                                  # Course feedback
      t.integer :rating, null: true                     # Course rating (1-5)
      t.datetime :feedback_date, null: true             # Feedback date
      t.string :enrollment_type, default: "Regular"     # Type of enrollment (Regular, Trial, Corporate)
      t.text :corporate_details                         # Corporate enrollment details (JSON)
      t.datetime :expiry_date, null: true               # Enrollment expiry date
      t.boolean :auto_renewal, default: false           # Auto-renewal enabled
      t.text :custom_fields                             # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    # student_id, course_id, batch_id indexes automatically created by references helpers
    add_index :lms_enrollments, :enrollment_number, unique: true
    add_index :lms_enrollments, :status
    add_index :lms_enrollments, :enrollment_date
    add_index :lms_enrollments, :completion_date
    add_index :lms_enrollments, :progress_percentage
    add_index :lms_enrollments, :payment_status
    add_index :lms_enrollments, :certificate_number
    add_index :lms_enrollments, :last_access_date
    add_index :lms_enrollments, :enrollment_type
    add_index :lms_enrollments, :expiry_date
    add_index :lms_enrollments, [:student_id, :course_id], unique: true
    add_index :lms_enrollments, [:course_id, :status]
    add_index :lms_enrollments, [:student_id, :status]
    add_index :lms_enrollments, [:status, :enrollment_date]
  end
end
