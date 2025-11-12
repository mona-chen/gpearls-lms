class AddUserIdToLmsBatchEnrollments < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_batch_enrollments, :user_id, :integer
    add_column :lms_batch_enrollments, :batch_id, :integer
    add_index :lms_batch_enrollments, :user_id
    add_index :lms_batch_enrollments, :batch_id
    add_index :lms_batch_enrollments, [ :user_id, :batch_id ], unique: true
  end
end
