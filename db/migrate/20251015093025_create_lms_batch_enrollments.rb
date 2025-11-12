class CreateLmsBatchEnrollments < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_batch_enrollments do |t|
      # Core fields
      t.string :member, null: false, index: true # Link to User
      t.string :batch, null: false, index: true # Link to LMS Batch
      t.string :payment # Link to LMS Payment
      t.string :source # Link to LMS Source
      t.boolean :confirmation_email_sent, default: false

      # Member details (fetched fields)
      t.string :member_name
      t.string :member_username

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
