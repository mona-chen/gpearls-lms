class CreateLmsQuizResults < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_quiz_results do |t|
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

      # Exact Frappe field structure from lms_quiz_result.json
      # This is a child table (istable: 1) with parent references
      t.text :question, null: false                   # Text field, read_only: 1
      t.text :answer, null: false                     # Small Text field, read_only: 1
      t.boolean :is_correct, default: false           # Check field, default: "0"
      t.string :question_name                        # Link to LMS Question
      t.integer :marks                               # Integer field
      t.integer :marks_out_of                        # Integer field, read_only: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_quiz_results, :question_name
    add_index :lms_quiz_results, :is_correct
    add_index :lms_quiz_results, :marks
    add_index :lms_quiz_results, :marks_out_of
    add_index :lms_quiz_results, :parent
    add_index :lms_quiz_results, :parenttype
    add_index :lms_quiz_results, :parentfield
    add_index :lms_quiz_results, [ :parent, :parenttype, :parentfield ], name: 'index_quiz_results_on_parent_and_type_and_field'
    add_index :lms_quiz_results, :creation
    add_index :lms_quiz_results, :modified
    add_index :lms_quiz_results, [ :question_name, :is_correct ]
    add_index :lms_quiz_results, [ :parent, :question_name ]

    # Add foreign key constraints
    add_foreign_key :lms_quiz_results, :lms_questions, column: :question_name
  end
end
