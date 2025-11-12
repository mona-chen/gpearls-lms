class CreateLmsLiveClassParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_live_class_participants do |t|
      # Core fields
      t.string :live_class, null: false, index: true # Link to LMS Live Class
      t.string :member, null: false, index: true # Link to User
      t.datetime :joined_at, null: false
      t.datetime :left_at, null: false
      t.integer :duration, null: false

      # Member details (fetched fields)
      t.string :member_name
      t.string :member_image # Attach Image
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
