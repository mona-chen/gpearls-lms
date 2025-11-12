class AddIsCorrectFieldsToLmsQuestions < ActiveRecord::Migration[7.2]
  def change
    # Add the missing is_correct fields to match Frappe LMS Question schema
    add_column :lms_questions, :is_correct_1, :boolean, default: false
    add_column :lms_questions, :is_correct_2, :boolean, default: false
    add_column :lms_questions, :is_correct_3, :boolean, default: false
    add_column :lms_questions, :is_correct_4, :boolean, default: false

    # Add the multiple field to match Frappe schema
    add_column :lms_questions, :multiple, :boolean, default: false

    # Add index for performance (only if it doesn't exist)
    unless index_exists?(:lms_questions, :name)
      add_index :lms_questions, :name
    end
  end
end
