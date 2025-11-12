class CreateCourseEvaluators < ActiveRecord::Migration[7.0]
  def change
    create_table :course_evaluators do |t|
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

      # Exact Frappe field structure from course_evaluator.json
      t.string :evaluator, null: false                 # Link to User, reqd: 1, unique: 1
      t.string :full_name                             # Data, fetched from evaluator.full_name
      t.string :user_image                            # Attach Image, fetched from evaluator.user_image
      t.string :username                              # Data, fetched from evaluator.username
      t.string :schedule                              # Table field (child table reference to Evaluator Schedule)
      t.date :unavailable_from                        # Date field
      t.date :unavailable_to                          # Date field

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :course_evaluators, :evaluator, unique: true
    add_index :course_evaluators, :full_name
    add_index :course_evaluators, :creation
    add_index :course_evaluators, :modified
    add_index :course_evaluators, :unavailable_from
    add_index :course_evaluators, :unavailable_to

    # Add foreign key constraints
    add_foreign_key :course_evaluators, :users, column: :evaluator
  end
end
