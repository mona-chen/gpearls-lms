class CreateLmsProgrammingExerciseSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_programming_exercise_submissions do |t|
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

      # Exact Frappe field structure from lms_programming_exercise_submission.json
      t.string :exercise, null: false                    # Link to LMS Programming Exercise, reqd: 1
      t.string :exercise_title, null: false              # Data, fetched from exercise.title
      t.string :status                                   # Select: Passed/Failed
      t.string :member, null: false                      # Link to User, reqd: 1
      t.string :member_name, null: false                 # Data, fetched from member.full_name
      t.string :member_image                             # Attach, fetched from member.user_image
      t.text :code, null: false                          # Code field, reqd: 1
      t.string :test_cases                               # Table field (child table reference)

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_programming_exercise_submissions, :exercise
    add_index :lms_programming_exercise_submissions, :member
    add_index :lms_programming_exercise_submissions, :status
    add_index :lms_programming_exercise_submissions, :creation
    add_index :lms_programming_exercise_submissions, :modified
    add_index :lms_programming_exercise_submissions, [ :exercise, :member ], unique: true, name: 'index_prog_exercise_sub_on_exercise_and_member'
    add_index :lms_programming_exercise_submissions, [ :member, :status ]

    # Add foreign key constraints
    add_foreign_key :lms_programming_exercise_submissions, :lms_programming_exercises, column: :exercise
    add_foreign_key :lms_programming_exercise_submissions, :users, column: :member
  end
end
