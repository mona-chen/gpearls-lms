class AddMemberTypeAndRoleToLmsBatchEnrollments < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_batch_enrollments, :member_type, :string, default: "Student"
    add_column :lms_batch_enrollments, :role, :string, default: "Member"

    add_index :lms_batch_enrollments, :member_type
    add_index :lms_batch_enrollments, :role
  end
end