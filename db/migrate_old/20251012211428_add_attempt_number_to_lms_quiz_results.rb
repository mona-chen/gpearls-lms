class AddAttemptNumberToLmsQuizResults < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_quiz_results, :attempt_number, :integer
  end
end
