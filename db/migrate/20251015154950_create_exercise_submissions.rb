class CreateExerciseSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :exercise_submissions do |t|
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

      # Exact Frappe field structure from exercise_submission.json
      t.string :exercise, null: false                    # Link to LMS Exercise
      t.string :status                                   # Select: Correct/Incorrect
      t.string :batch_old                                # Link to LMS Batch Old
      t.string :exercise_title, null: false              # Data, fetched from exercise.title
      t.string :course                                   # Link to LMS Course, fetched from exercise.course
      t.string :lesson                                   # Link to Course Lesson, fetched from exercise.lesson
      t.text :image                                      # Code field, read_only
      t.text :test_results                               # Small Text
      t.text :comments                                   # Small Text
      t.text :solution                                   # Code field
      t.string :member, null: false                      # Link to LMS Enrollment

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :exercise_submissions, :exercise
    add_index :exercise_submissions, :member
    add_index :exercise_submissions, :status
    add_index :exercise_submissions, :course
    add_index :exercise_submissions, :lesson
    add_index :exercise_submissions, [ :exercise, :member ], unique: true
    add_index :exercise_submissions, :creation
    add_index :exercise_submissions, :modified

    # Add foreign key constraints
    add_foreign_key :exercise_submissions, :lms_exercises, column: :exercise
    add_foreign_key :exercise_submissions, :lms_enrollments, column: :member
    add_foreign_key :exercise_submissions, :lms_courses, column: :course
  end
end
