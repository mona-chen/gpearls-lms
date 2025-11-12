class CreateLmsLiveClasses < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_live_classes do |t|
      # Core fields
      t.string :title, null: false, index: true
      t.text :description
      t.date :date, null: false, index: true
      t.time :time, null: false
      t.integer :duration, null: false
      t.string :timezone, null: false
      t.string :password

      # Host and batch information
      t.string :host, null: false, index: true # Link to User
      t.string :batch_name # Link to LMS Batch
      t.string :zoom_account, null: false # Link to LMS Zoom Settings

      # Event and recording settings
      t.string :event # Link to Event
      t.string :auto_recording, default: "No Recording" # No Recording, Local, Cloud

      # Zoom meeting details
      t.string :meeting_id
      t.string :uuid
      t.integer :attendees, default: 0
      t.text :start_url # Read-only
      t.text :join_url # Read-only

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
