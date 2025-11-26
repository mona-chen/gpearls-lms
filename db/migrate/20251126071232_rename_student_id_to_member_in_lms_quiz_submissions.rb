class RenameStudentIdToMemberInLmsQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    rename_column :lms_quiz_submissions, :student_id, :member
  end
end
