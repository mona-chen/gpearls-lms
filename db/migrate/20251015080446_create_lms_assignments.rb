class CreateLmsAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_assignments do |t|
      # LMS Assignments specific fields (based on Frappe Assignment doctype)
      t.string :title, null: false                        # Assignment title (primary field)
      t.references :course, null: false, foreign_key: { to_table: :lms_courses }  # Parent course
      t.references :chapter, foreign_key: { to_table: :course_chapters }, null: true  # Parent chapter
      t.text :description                                 # Assignment description
      t.string :assignment_code, null: true               # Unique assignment code
      t.string :status, default: "Draft"                  # Assignment status (Draft, Published, Archived)
      t.string :assignment_type, default: "Submission"     # Type (Submission, Quiz, Project, etc.)
      t.decimal :total_marks, precision: 10, scale: 2, default: 100.00  # Total possible marks
      t.decimal :passing_percentage, precision: 5, scale: 2, default: 70.00  # Passing percentage
      t.datetime :start_date, null: true                  # Assignment start date
      t.datetime :due_date, null: true                    # Assignment due date
      t.datetime :end_date, null: true                    # Assignment end date (late submission cutoff)
      t.boolean :allow_late_submission, default: true     # Allow late submissions
      t.decimal :late_penalty_percentage, precision: 5, scale: 2, default: 0.00  # Late submission penalty
      t.boolean :auto_grade, default: false               # Automatic grading
      t.text :instructions                                # Assignment instructions
      t.text :submission_format                           # Required submission format
      t.text :grading_criteria                            # Grading criteria (JSON)
      t.text :rubric                                      # Detailed rubric (JSON)
      t.boolean :allow_multiple_attempts, default: false  # Allow multiple submission attempts
      t.integer :max_attempts, default: 1                 # Maximum attempts allowed
      t.boolean :show_solution_after_due, default: true   # Show solution after due date
      t.text :solution                                    # Assignment solution
      t.text :sample_solution                             # Sample solution
      t.integer :estimated_duration_hours, default: 0     # Estimated completion time
      t.string :difficulty_level, default: "Medium"       # Difficulty level
      t.text :prerequisites                              # Prerequisites (JSON)
      t.text :learning_objectives                        # Learning objectives (JSON)
      t.text :resources                                   # Additional resources (JSON)
      t.boolean :plagiarism_check_enabled, default: false # Enable plagiarism checking
      t.text :plagiarism_settings                        # Plagiarism check settings (JSON)
      t.boolean :peer_review_enabled, default: false      # Enable peer review
      t.integer :peer_review_count, default: 0           # Number of peer reviews required
      t.text :peer_review_criteria                        # Peer review criteria (JSON)
      t.boolean :group_assignment, default: false         # Group assignment
      t.integer :max_group_size, default: 1              # Maximum group size
      t.integer :min_group_size, default: 1              # Minimum group size
      t.text :group_settings                             # Group assignment settings (JSON)
      t.boolean :template_provided, default: false        # Assignment template provided
      t.text :template_file                               # Template file information (JSON)
      t.boolean :anonymous_grading, default: false        # Anonymous grading enabled
      t.references :created_by, foreign_key: { to_table: :users }, null: true  # Creator
      t.references :updated_by, foreign_key: { to_table: :users }, null: true  # Last updater
      t.integer :submissions_count, default: 0           # Number of submissions
      t.decimal :average_score, precision: 5, scale: 2, default: 0.00  # Average score
      t.decimal :submission_rate, precision: 5, scale: 2, default: 0.00  # Submission rate percentage
      t.datetime :published_at, null: true                # Publication date
      t.integer :sort_order, default: 0                   # Sort order
      t.text :custom_fields                               # Custom fields (JSON)

      t.timestamps
    end

    # Add indexes for performance and common queries
    add_index :lms_assignments, :title
    # course_id and chapter_id indexes automatically created by references helpers
    add_index :lms_assignments, :assignment_code, unique: true
    add_index :lms_assignments, :status
    add_index :lms_assignments, :assignment_type
    add_index :lms_assignments, :start_date
    add_index :lms_assignments, :due_date
    add_index :lms_assignments, :end_date
    add_index :lms_assignments, :total_marks
    add_index :lms_assignments, :passing_percentage
    add_index :lms_assignments, :difficulty_level
    add_index :lms_assignments, :submissions_count
    add_index :lms_assignments, :average_score
    add_index :lms_assignments, :submission_rate
    add_index :lms_assignments, :published_at
    # created_by_id index automatically created by references helper
    add_index :lms_assignments, :sort_order
    add_index :lms_assignments, [:course_id, :status]
    add_index :lms_assignments, [:status, :due_date]
    add_index :lms_assignments, [:chapter_id, :status]
    add_index :lms_assignments, [:assignment_type, :status]
    add_index :lms_assignments, [:course_id, :due_date]
  end
end
