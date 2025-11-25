class AddNameToLmsQuizzes < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_quizzes, :name, :string
    add_index :lms_quizzes, :name, unique: true
  end
end
