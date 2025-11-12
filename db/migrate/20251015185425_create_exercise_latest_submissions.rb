class CreateExerciseLatestSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :exercise_latest_submissions do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from exercise_latest_submission.json
      t.string :exercise, null: false                    # Link to LMS Exercise
      t.string :status                                   # Select: Correct/Incorrect
      t.string :batch_old                                # Link to LMS Batch Old
      t.string :exercise_title, null: false              # Data, fetched from exercise.title
      t.string :course                                   # Link to LMS Course, fetched from exercise.course
      t.string :lesson                                  # Link to Course Lesson, fetched from exercise.lesson
      t.text :image                                     # Code field, fetched from latest_submission.image
      t.text :test_results                              # Small Text, fetched from latest_submission.test_results
      t.text :comments                                  # Small Text field
      t.text :solution                                  # Code field, fetched from latest_submission.solution
      t.string :latest_submission                       # Link to Exercise Submission
      t.string :member, null: false                     # Link to LMS Enrollment
      t.string :member_email                            # Link to User, fetched from member.member
      t.string :member_cohort                           # Link to Cohort, fetched from member.cohort
      t.string :member_subgroup                         # Link to Cohort Subgroup, fetched from member.subgroup

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :exercise_latest_submissions, :exercise
    add_index :exercise_latest_submissions, :status
    add_index :exercise_latest_submissions, :course
    add_index :exercise_latest_submissions, :lesson
    add_index :exercise_latest_submissions, :member
    add_index :exercise_latest_submissions, :member_email
    add_index :exercise_latest_submissions, :member_cohort
    add_index :exercise_latest_submissions, :member_subgroup
    add_index :exercise_latest_submissions, :latest_submission
    add_index :exercise_latest_submissions, :creation
    add_index :exercise_latest_submissions, :modified
    add_index :exercise_latest_submissions, [:exercise, :member], unique: true, name: 'index_exercise_latest_on_exercise_and_member'
    add_index :exercise_latest_submissions, [:member, :status], name: 'index_exercise_latest_on_member_and_status'

    # Add foreign key constraints
    add_foreign_key :exercise_latest_submissions, :lms_exercises, column: :exercise
    add_foreign_key :exercise_latest_submissions, :lms_courses, column: :course
    # TODO: Add foreign keys when tables exist:
    # add_foreign_key :exercise_latest_submissions, :course_lessons, column: :lesson
    # add_foreign_key :exercise_latest_submissions, :exercise_submissions, column: :latest_submission
    add_foreign_key :exercise_latest_submissions, :lms_enrollments, column: :member
    add_foreign_key :exercise_latest_submissions, :users, column: :member_email
    add_foreign_key :exercise_latest_submissions, :cohorts, column: :member_cohort
    add_foreign_key :exercise_latest_submissions, :cohort_subgroups, column: :member_subgroup
  end
end


### **Migration 5: lesson_reference**
