class CreateLmsCertificateRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_certificate_requests do |t|
      # Core fields
      t.string :course, null: false, index: true # Link to LMS Course
      t.string :member, null: false, index: true # Link to User
      t.string :evaluator, index: true # Link to User
      t.date :date, null: false, index: true
      t.string :day # Sunday, Monday, Tuesday, etc.
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :status, default: "Upcoming", index: true # Upcoming, Completed, Cancelled

      # Batch information
      t.string :batch_name # Link to LMS Batch
      t.string :timezone # Fetched from batch timezone
      t.string :google_meet_link

      # Fetched fields (read-only)
      t.string :course_title
      t.string :member_name
      t.string :evaluator_name
      t.string :batch_title

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
