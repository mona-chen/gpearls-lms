class AddRoleToLmsEnrollments < ActiveRecord::Migration[7.2]
  def change
    add_column :lms_enrollments, :role, :string, default: "Member"
    add_index :lms_enrollments, :role
  end
end
