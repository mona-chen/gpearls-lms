class CreateLmsQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_quiz_submissions do |t|
      t.references :quiz_result, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :quiz_question, null: false, foreign_key: true
      t.text :answer
      t.boolean :correct
      t.integer :marks_obtained
      t.text :feedback
      t.integer :time_taken_seconds

      t.timestamps
    end
  end
end
