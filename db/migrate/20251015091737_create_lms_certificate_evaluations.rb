class CreateLmsCertificateEvaluations < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_certificate_evaluations do |t|
      # Core fields
      t.string :member, null: false, index: true # Link to User
      t.string :course, null: false, index: true # Link to LMS Course
      t.string :batch_name, index: true # Link to LMS Batch
      t.string :evaluator, index: true # Link to User
      t.date :date, null: false, index: true
      t.time :start_time, null: false
      t.time :end_time
      t.string :status, null: false, default: "Pending", index: true # Pending, In Progress, Pass, Fail

      # Evaluation details
      t.decimal :rating, precision: 3, scale: 2 # Rating field
      t.text :summary

      # Fetched fields (read-only)
      t.string :member_name
      t.string :evaluator_name

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
