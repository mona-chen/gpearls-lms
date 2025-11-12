class CreateCriticalLmsDoctypes < ActiveRecord::Migration[7.0]
  def change
    # LMS Settings - Core system configuration
    unless table_exists?(:lms_settings)
      create_table :lms_settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :fieldtype, default: "Data"
      t.string :parent
      t.datetime :creation
      t.datetime :modified

      t.timestamps
    end

      add_index :lms_settings, :key, unique: true
    end

    # LMS Enrollment - Course enrollment records
    unless table_exists?(:lms_enrollments)
      create_table :lms_enrollments do |t|
        t.references :course, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.string :status, default: "Active"
        t.decimal :progress, precision: 5, scale: 2, default: 0.0
        t.datetime :enrollment_date
        t.datetime :completion_date
        t.string :batch_name
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_enrollments, [:course_id, :user_id], unique: true, name: 'index_lms_enrollments_on_course_and_user'
      add_index :lms_enrollments, :status, name: 'index_lms_enrollments_on_status'
      add_index :lms_enrollments, :user_id unless index_exists?(:lms_enrollments, :user_id)
    end

    # LMS Question - Quiz questions
    unless table_exists?(:lms_questions)
      create_table :lms_questions do |t|
        t.string :name, null: false
        t.text :question, null: false
        t.string :question_type, null: false # Multiple Choice, Subjective, etc.
        t.text :option_1
        t.text :option_2
        t.text :option_3
        t.text :option_4
        t.text :explanation_1
        t.text :explanation_2
        t.text :explanation_3
        t.text :explanation_4
        t.integer :correct_answer
        t.decimal :marks, precision: 5, scale: 2, default: 1.0
        t.boolean :is_mandatory, default: false
        t.string :owner
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_questions, :name, unique: true
      add_index :lms_questions, :question_type
      add_index :lms_questions, :owner
    end

    # LMS Quiz Question - Quiz to question mapping
    unless table_exists?(:lms_quiz_questions)
      create_table :lms_quiz_questions do |t|
        t.references :quiz, null: false, foreign_key: { to_table: :quizzes }
        t.references :question, null: false, foreign_key: { to_table: :lms_questions }
        t.integer :position
        t.decimal :marks, precision: 5, scale: 2
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_quiz_questions, [:quiz_id, :question_id], unique: true
      add_index :lms_quiz_questions, :position
    end

    # LMS Quiz Result - Quiz attempt results
    unless table_exists?(:lms_quiz_results)
      create_table :lms_quiz_results do |t|
        t.references :quiz, null: false, foreign_key: { to_table: :quizzes }
        t.references :user, null: false, foreign_key: true
        t.decimal :score, precision: 5, scale: 2
        t.decimal :total_marks, precision: 5, scale: 2
        t.decimal :percentage, precision: 5, scale: 2
        t.string :status, default: "Submitted" # Submitted, Evaluated, Passed, Failed
        t.datetime :start_time
        t.datetime :end_time
        t.integer :time_taken_seconds
        t.json :answers
        t.text :feedback
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_quiz_results, [:quiz_id, :user_id], name: 'index_lms_quiz_results_on_quiz_and_user'
      add_index :lms_quiz_results, :status, name: 'index_lms_quiz_results_on_status'
    end

    # LMS Quiz Submission - Quiz submission details
    unless table_exists?(:lms_quiz_submissions)
      create_table :lms_quiz_submissions do |t|
        t.references :quiz_result, null: false, foreign_key: { to_table: :lms_quiz_results }
        t.references :question, null: false, foreign_key: { to_table: :lms_questions }
        t.text :selected_answer
        t.text :explanation
        t.decimal :marks_obtained, precision: 5, scale: 2
        t.boolean :is_correct
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_quiz_submissions, [:quiz_result_id, :question_id], unique: true
    end

    # LMS Assessment - Course assessments
    unless table_exists?(:lms_assessments)
      create_table :lms_assessments do |t|
        t.string :name, null: false
        t.references :course, null: false, foreign_key: true
        t.references :batch, foreign_key: { to_table: :batches }
        t.string :assessment_type, null: false # Quiz, Assignment, Live Class, etc.
        t.string :assessment_name
        t.text :description
        t.decimal :max_marks, precision: 5, scale: 2
        t.decimal :passing_marks, precision: 5, scale: 2
        t.datetime :start_date
        t.datetime :end_date
        t.integer :duration_minutes
        t.string :status, default: "Draft" # Draft, Published, Ended
        t.boolean :allow_multiple_attempts, default: false
        t.integer :max_attempts
        t.string :owner
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_assessments, :name, unique: true
      add_index :lms_assessments, :course_id
      add_index :lms_assessments, :batch_id
      add_index :lms_assessments, :assessment_type
      add_index :lms_assessments, :status
    end

    # LMS Assignment - Course assignments
    unless table_exists?(:lms_assignments)
      create_table :lms_assignments do |t|
        t.string :name, null: false
        t.references :course, null: false, foreign_key: true
        t.references :chapter, foreign_key: { to_table: :chapters }
        t.references :lesson, foreign_key: { to_table: :lessons }
        t.text :description
        t.text :instructions
        t.decimal :max_marks, precision: 5, scale: 2
        t.datetime :submission_date
        t.string :status, default: "Draft" # Draft, Published, Closed
        t.boolean :allow_late_submission, default: false
        t.decimal :late_submission_penalty, precision: 5, scale: 2, default: 0.0
        t.string :owner
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_assignments, :name, unique: true
      add_index :lms_assignments, :course_id
      add_index :lms_assignments, :chapter_id
      add_index :lms_assignments, :lesson_id
      add_index :lms_assignments, :status
    end

    # LMS Assignment Submission - Assignment submissions
    unless table_exists?(:lms_assignment_submissions)
      create_table :lms_assignment_submissions do |t|
        t.references :assignment, null: false, foreign_key: { to_table: :lms_assignments }
        t.references :user, null: false, foreign_key: true
        t.text :content
        t.string :attachment
        t.decimal :marks_obtained, precision: 5, scale: 2
        t.text :feedback
        t.string :status, default: "Submitted" # Submitted, Evaluated, Returned
        t.datetime :submission_date
        t.datetime :evaluation_date
        t.string :evaluator_id
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_assignment_submissions, [:assignment_id, :user_id], unique: true
    end

    # LMS Badge - Achievement badges
    unless table_exists?(:lms_badges)
      create_table :lms_badges do |t|
        t.string :name, null: false
        t.text :description
        t.string :badge_type, null: false # Course Completion, Quiz Master, etc.
        t.string :icon
        t.string :color, default: "#007bff"
        t.text :criteria
        t.boolean :is_active, default: true
        t.string :owner
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_badges, :name, unique: true
      add_index :lms_badges, :badge_type
      add_index :lms_badges, :is_active
    end

    # LMS Badge Assignment - User badge assignments
    unless table_exists?(:lms_badge_assignments)
      create_table :lms_badge_assignments do |t|
        t.references :badge, null: false, foreign_key: { to_table: :lms_badges }
        t.references :user, null: false, foreign_key: true
        t.references :course, foreign_key: true
        t.text :notes
        t.datetime :awarded_date
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_badge_assignments, [:badge_id, :user_id], unique: true
      add_index :lms_badge_assignments, :user_id unless index_exists?(:lms_badge_assignments, :user_id)
    end

    # LMS Category - Course categories
    unless table_exists?(:lms_categories)
      create_table :lms_categories do |t|
        t.string :name, null: false
        t.text :description
        t.string :parent_category
        t.string :icon
        t.string :color, default: "#007bff"
        t.integer :position
        t.boolean :is_active, default: true
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_categories, :name, unique: true
      add_index :lms_categories, :parent_category
      add_index :lms_categories, :is_active
    end

    # LMS Course Review - Course reviews and ratings
    unless table_exists?(:lms_course_reviews)
      create_table :lms_course_reviews do |t|
        t.references :course, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.integer :rating, null: false # 1-5 stars
        t.text :review
        t.string :status, default: "Published" # Published, Hidden, Reported
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_course_reviews, [:course_id, :user_id], unique: true
      add_index :lms_course_reviews, :rating unless index_exists?(:lms_course_reviews, :rating)
      add_index :lms_course_reviews, :status unless index_exists?(:lms_course_reviews, :status)
    end

    # LMS Course Progress - Detailed course progress tracking
    unless table_exists?(:lms_course_progresses)
      create_table :lms_course_progresses do |t|
        t.references :course, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.references :chapter, foreign_key: true
        t.references :lesson, foreign_key: true
        t.decimal :progress, precision: 5, scale: 2, default: 0.0
        t.string :status, default: "Not Started" # Not Started, In Progress, Completed
        t.datetime :start_date
        t.datetime :completion_date
        t.integer :time_spent_seconds
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_course_progresses, [:course_id, :user_id, :chapter_id, :lesson_id], unique: true, name: 'index_course_progress_unique'
      add_index :lms_course_progresses, :user_id unless index_exists?(:lms_course_progresses, :user_id)
      add_index :lms_course_progresses, :status unless index_exists?(:lms_course_progresses, :status)
    end

    # LMS Mentor Request - Mentorship requests
    unless table_exists?(:lms_mentor_requests)
      create_table :lms_mentor_requests do |t|
        t.references :course, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.text :message
        t.string :status, default: "Pending" # Pending, Approved, Rejected
        t.text :response_message
        t.datetime :request_date
        t.datetime :response_date
        t.string :responded_by
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_mentor_requests, [:course_id, :user_id], unique: true
      add_index :lms_mentor_requests, :status unless index_exists?(:lms_mentor_requests, :status)
    end

    # LMS Payment - Payment records
    unless table_exists?(:lms_payments)
      create_table :lms_payments do |t|
        t.string :name, null: false
        t.references :user, null: false, foreign_key: true
        t.references :course, foreign_key: true
        t.references :batch, foreign_key: { to_table: :batches }
        t.references :program, foreign_key: { to_table: :lms_programs }
        t.decimal :amount, precision: 10, scale: 2, null: false
        t.string :currency, default: "USD"
        t.string :payment_method # Stripe, PayPal, Razorpay, etc.
        t.string :payment_status, default: "Pending" # Pending, Completed, Failed, Refunded
        t.string :transaction_id
        t.string :gateway_response
        t.datetime :payment_date
        t.datetime :creation
        t.datetime :modified

        t.timestamps
      end

      add_index :lms_payments, :name, unique: true
      add_index :lms_payments, :user_id unless index_exists?(:lms_payments, :user_id)
      add_index :lms_payments, :payment_status
      add_index :lms_payments, :payment_date
    end
  end
end
