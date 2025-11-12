class CreateLmsProgrammingExercises < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_programming_exercises do |t|
      # Core fields
      t.string :title, null: false, index: true
      t.string :language, null: false, default: "Python", index: true # Python, JavaScript
      t.text :problem_statement, null: false # Text Editor

      # Child table content (Table field)
      t.text :test_cases # Table field for LMS Test Case

      # Frappe standard fields
      t.string :name, null: false, index: { unique: true }
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      # Rails timestamps
      t.timestamps
    end

    # Indexes already added by t.index in create_table
  end
end
