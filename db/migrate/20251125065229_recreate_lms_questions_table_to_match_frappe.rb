class RecreateLmsQuestionsTableToMatchFrappe < ActiveRecord::Migration[7.2]
  def change
    # Drop existing table and recreate to match Frappe LMS exactly
    drop_table :lms_questions, if_exists: true

    create_table :lms_questions do |t|
      # Core question fields (matching Frappe exactly)
      t.string :name
      t.text :question, null: false
      t.string :type, null: false, default: "Choices"
      t.boolean :multiple, default: false

      # Choice options (1-4)
      t.string :option_1
      t.boolean :is_correct_1, default: false
      t.string :explanation_1

      t.string :option_2
      t.boolean :is_correct_2, default: false
      t.string :explanation_2

      t.string :option_3
      t.boolean :is_correct_3, default: false
      t.string :explanation_3

      t.string :option_4
      t.boolean :is_correct_4, default: false
      t.string :explanation_4

      # User input possibilities (1-4)
      t.string :possibility_1
      t.string :possibility_2
      t.string :possibility_3
      t.string :possibility_4

      # Timestamps
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    # Add index for performance
    add_index :lms_questions, :type
  end
end
