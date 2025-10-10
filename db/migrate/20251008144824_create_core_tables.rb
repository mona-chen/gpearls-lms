class CreateCoreTables < ActiveRecord::Migration[7.2]
  def change
    # Users (extends Devise)
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      # JWT Revocation
      t.string :jti

      # LMS specific fields
      t.string :full_name
      t.string :username
      t.string :user_image
      t.string :user_type, default: 'Website User'
      t.boolean :enabled, default: true
      t.datetime :last_active
      t.boolean :is_instructor, default: false
      t.boolean :is_moderator, default: false
      t.boolean :is_evaluator, default: false
      t.boolean :is_student, default: true

      t.timestamps
    end

    # Courses
    create_table :courses do |t|
      t.string :title, null: false
      t.text :description
      t.text :short_introduction
      t.string :video_link
      t.string :image
      t.string :card_gradient
      t.string :tags
      t.string :category
      t.boolean :published, default: false
      t.datetime :published_on
      t.boolean :featured, default: false
      t.boolean :upcoming, default: false
      t.boolean :paid_course, default: false
      t.boolean :enable_certification, default: false
      t.boolean :paid_certificate, default: false
      t.decimal :course_price, precision: 10, scale: 2
      t.string :currency
      t.references :instructor, foreign_key: { to_table: :users }
      t.references :evaluator, foreign_key: { to_table: :users }

      # Statistics
      t.integer :lessons_count, default: 0
      t.integer :enrollments_count, default: 0
      t.decimal :rating, precision: 3, scale: 2

      t.timestamps
    end

    # Chapters
    create_table :chapters do |t|
      t.string :title, null: false
      t.references :course, null: false, foreign_key: true
      t.integer :position

      # SCORM support
      t.boolean :is_scorm_package, default: false
      t.string :scorm_package_path
      t.string :manifest_file
      t.string :launch_file

      t.timestamps
    end

    # Lessons
    create_table :lessons do |t|
      t.string :title, null: false
      t.text :body
      t.text :content
      t.text :instructor_notes
      t.text :instructor_content
      t.string :youtube
      t.string :quiz_id
      t.string :question  # Assignment
      t.string :file_type
      t.boolean :include_in_preview, default: true
      t.references :chapter, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    # Enrollments
    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :batch, foreign_key: true
      t.decimal :progress, precision: 5, scale: 2, default: 0
      t.string :current_lesson
      t.string :member_type, default: 'Student'
      t.boolean :purchased_certificate, default: false
      t.string :certificate

      t.timestamps
    end

    # Course Progress
    create_table :course_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.string :status, default: 'Incomplete' # Complete/Incomplete

      t.timestamps
    end

    # Quizzes
    create_table :quizzes do |t|
      t.string :title, null: false
      t.text :description
      t.integer :passing_percentage, default: 100
      t.integer :total_marks
      t.references :course, foreign_key: true
      t.boolean :show_submission_history, default: true

      t.timestamps
    end

    # Quiz Questions
    create_table :quiz_questions do |t|
      t.text :question, null: false
      t.string :type, default: 'Choices' # Choices/True-False
      t.boolean :multiple, default: false
      t.string :option_1
      t.string :option_2
      t.string :option_3
      t.string :option_4
      t.text :explanation_1
      t.text :explanation_2
      t.text :explanation_3
      t.text :explanation_4
      t.integer :marks, default: 1
      t.references :quiz, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    # Quiz Submissions
    create_table :quiz_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.integer :score
      t.decimal :percentage, precision: 5, scale: 2
      t.string :quiz_title
      t.integer :total_marks

      t.timestamps
    end

    # Quiz Results (individual question answers)
    create_table :quiz_results do |t|
      t.references :quiz_submission, null: false, foreign_key: true
      t.string :question_name
      t.text :answer
      t.boolean :is_correct, default: false
      t.integer :marks_obtained
      t.integer :marks_out_of

      t.timestamps
    end

    # Batches
    create_table :batches do |t|
      t.string :title, null: false
      t.text :description
      t.text :batch_details
      t.date :start_date
      t.date :end_date
      t.time :start_time
      t.time :end_time
      t.integer :seat_count
      t.boolean :published, default: false
      t.boolean :paid_batch, default: false
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.decimal :amount_usd, precision: 10, scale: 2
      t.boolean :certification, default: false
      t.string :timezone
      t.string :category
      t.boolean :allow_self_enrollment, default: true

      t.timestamps
    end

    # Batch Enrollments
    create_table :batch_enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true

      t.timestamps
    end

    # Batch Courses (many-to-many between batches and courses)
    create_table :batch_courses do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :title
      t.references :evaluator, foreign_key: { to_table: :users }
      t.integer :position

      t.timestamps
    end

    # Certificates
    create_table :certificates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.references :batch, foreign_key: true
      t.date :issue_date
      t.date :expiry_date
      t.string :template
      t.boolean :published, default: false

      t.timestamps
    end

    # Certificate Evaluations
    create_table :certificate_evaluations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.references :evaluator, foreign_key: { to_table: :users }
      t.date :date
      t.time :start_time
      t.time :end_time
      t.string :status # Upcoming/Completed/Cancelled
      t.decimal :rating, precision: 3, scale: 2
      t.text :summary
      t.string :batch_name

      t.timestamps
    end

    # Assignments
    create_table :assignments do |t|
      t.string :title, null: false
      t.text :description
      t.string :type # Document/Image/Text
      t.references :course, foreign_key: true
      t.references :lesson, foreign_key: true

      t.timestamps
    end

    # Assignment Submissions
    create_table :assignment_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.text :answer
      t.string :status # Not Attempted/Pending/Completed
      t.text :comments

      t.timestamps
    end

    # Programming Exercises
    create_table :programming_exercises do |t|
      t.string :title, null: false
      t.text :description
      t.references :course, foreign_key: true

      t.timestamps
    end

    # Programming Exercise Submissions
    create_table :programming_exercise_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :programming_exercise, null: false, foreign_key: true
      t.text :code
      t.string :status # Passed/Failed

      t.timestamps
    end

    # Test Cases for Programming Exercises
    create_table :test_cases do |t|
      t.references :programming_exercise_submission, null: false, foreign_key: true
      t.text :input
      t.text :output
      t.text :expected_output
      t.string :status # Passed/Failed

      t.timestamps
    end

    # Video Watch Duration
    create_table :video_watch_durations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.string :source
      t.decimal :watch_time, precision: 10, scale: 2

      t.timestamps
    end

    # Discussions/Topics
    create_table :discussion_topics do |t|
      t.string :title
      t.text :description
      t.string :reference_doctype
      t.string :reference_docname
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Discussion Replies
    create_table :discussion_replies do |t|
      t.references :discussion_topic, null: false, foreign_key: true
      t.text :reply, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Notifications
    create_table :notifications do |t|
      t.string :subject
      t.text :email_content
      t.string :document_type
      t.string :document_name
      t.references :user, null: false, foreign_key: true
      t.references :from_user, foreign_key: { to_table: :users }
      t.string :type, default: 'Alert'
      t.string :link
      t.boolean :read, default: false

      t.timestamps
    end

    # Job Opportunities
    create_table :job_opportunities do |t|
      t.string :job_title, null: false
      t.string :location
      t.string :country
      t.string :type # Full-time/Part-time/Contract
      t.string :work_mode # Remote/On-site/Hybrid
      t.string :company_name
      t.string :company_logo
      t.string :company_website
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :published, default: true

      t.timestamps
    end

    # Job Applications
    create_table :job_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job_opportunity, null: false, foreign_key: true
      t.string :status # Applied/Shortlisted/Rejected/Hired

      t.timestamps
    end

    # Settings
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    # Add indexes
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :jti, unique: true
    add_index :courses, :published
    add_index :courses, :featured
    add_index :enrollments, [:user_id, :course_id], unique: true
    add_index :course_progresses, [:user_id, :lesson_id], unique: true
  end
end
