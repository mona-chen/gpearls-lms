class AddCreatorToLmsQuizzes < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_quizzes, :creator, :integer unless column_exists?(:lms_quizzes, :creator)
    add_index :lms_quizzes, :creator unless index_exists?(:lms_quizzes, :creator)
  end
end
