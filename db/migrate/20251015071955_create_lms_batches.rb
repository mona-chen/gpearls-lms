class CreateLmsBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_batches do |t|
      # LMS Batches specific fields (based on Frappe Batch doctype)
      t.string :title, null: false                        # Batch title (primary field)
      t.references :course, null: false, foreign_key: { to_table: :lms_courses }  # Parent course
      t.text :description                                 # Batch description
      t.string :batch_code, null: true                   # Unique batch code
      t.string :status, default: "Planned"               # Batch status (Planned, Active, Completed, Cancelled)
      t.datetime :start_date, null: false                # Batch start date
      t.datetime :end_date, null: false                  # Batch end date
      t.string :start_time                                # Daily start time
      t.string :end_time                                  # Daily end time
      t.string :timezone, default: "UTC"                 # Batch timezone
      t.string :schedule                                  # Schedule pattern (e.g., "Mon-Wed-Fri")
      t.string :delivery_mode, default: "Online"         # Delivery mode (Online, Offline, Hybrid)
      t.string :venue, null: true                        # Physical venue (if offline)
      t.string :location, null: true                     # Location details
      t.references :instructor, foreign_key: { to_table: :users }, null: true  # Batch instructor
      t.references :teaching_assistant, foreign_key: { to_table: :users }, null: true  # Teaching assistant
      t.integer :max_students, default: 30               # Maximum students allowed
      t.integer :min_students, default: 5                # Minimum students to run batch
      t.integer :current_students, default: 0            # Current enrolled students
      t.decimal :price, precision: 10, scale: 2, default: 0.00  # Batch price
      t.string :currency, default: "USD"                 # Currency code
      t.boolean :allow_self_enrollment, default: true    # Allow self enrollment
      t.boolean :require_approval, default: false        # Require approval for enrollment
      t.datetime :enrollment_start_date, null: true      # Enrollment start date
      t.datetime :enrollment_end_date, null: true        # Enrollment end date
      t.text :prerequisites                              # Enrollment prerequisites
      t.text :additional_info                            # Additional information for students
      t.string :meeting_link, null: true                 # Online meeting link
      t.string :meeting_id, null: true                   # Meeting ID
      t.string :meeting_password, null: true             # Meeting password
      t.boolean :record_sessions, default: false         # Record online sessions
      t.text :materials                                  # Study materials (JSON)
      t.text :schedule_details                           # Detailed schedule (JSON)
      t.boolean :certificate_enabled, default: false     # Enable certificates
      t.string :certificate_template, null: true         # Certificate template
      t.decimal :passing_percentage, precision: 5, scale: 2, default: 70.00  # Passing percentage
      t.text :evaluation_criteria                        # Evaluation criteria (JSON)
      t.boolean :feedback_enabled, default: true         # Enable student feedback
      t.string :status_message, null: true               # Status message for students
      t.integer :sort_order, default: 0                  # Sort order
      t.text :custom_fields                              # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_batches, :title
    # course_id index automatically created by references helper
    add_index :lms_batches, :batch_code, unique: true
    add_index :lms_batches, :status
    add_index :lms_batches, :start_date
    add_index :lms_batches, :end_date
    # instructor_id index automatically created by references helper
    # teaching_assistant_id index automatically created by references helper
    add_index :lms_batches, :delivery_mode
    add_index :lms_batches, :current_students
    add_index :lms_batches, :price
    add_index :lms_batches, :enrollment_start_date
    add_index :lms_batches, :enrollment_end_date
    add_index :lms_batches, :sort_order
    add_index :lms_batches, [ :course_id, :status ]
    add_index :lms_batches, [ :status, :start_date ]
    add_index :lms_batches, [ :instructor_id, :status ]
  end
end
