class CreateLmsTestCaseSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_test_case_submissions do |t|
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

      # Exact Frappe field structure from lms_test_case_submission.json
      # This is a child table (istable: 1) with parent references
      t.string :input                    # Data field
      t.string :expected_output, null: false  # Data field, reqd: 1
      t.string :output, null: false      # Data field, reqd: 1
      t.string :status, null: false      # Select: Passed/Failed, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_test_case_submissions, :status
    add_index :lms_test_case_submissions, :parent
    add_index :lms_test_case_submissions, :parenttype
    add_index :lms_test_case_submissions, :parentfield
    add_index :lms_test_case_submissions, [ :parent, :parenttype, :parentfield ], name: 'index_test_case_sub_on_parent_and_type_and_field'
    add_index :lms_test_case_submissions, :creation
    add_index :lms_test_case_submissions, :modified
  end
end
