class AddMissingBatchColumns < ActiveRecord::Migration[7.0]
  def change
    # Add missing columns to batches table
    add_column :batches, :batch_details_raw, :text
    add_column :batches, :published_at, :datetime
    add_column :batches, :evaluation_end_date, :date
    add_column :batches, :medium, :string, default: 'Online'
    add_column :batches, :confirmation_email_template, :string
    add_column :batches, :instructors, :string, null: false, default: '[]'
    add_column :batches, :zoom_account, :string
    add_column :batches, :show_live_class, :boolean, default: false
    add_column :batches, :allow_future, :boolean, default: true
    add_column :batches, :timetable_template, :string
    add_column :batches, :custom_component, :text
    add_column :batches, :custom_script, :text
    add_column :batches, :meta_image, :string

    # Add missing columns to batch_enrollments table
    add_reference :batch_enrollments, :payment, foreign_key: true unless foreign_key_exists?(:batch_enrollments, :payment_id)
    add_column :batch_enrollments, :confirmation_email_sent, :boolean, default: false

    # Add missing columns to batch_courses table
    # evaluator_id already exists, so skip

    # Add indexes for performance
    add_index :batches, :published_at
    add_index :batches, :evaluation_end_date
    add_index :batches, :medium
    add_index :batches, :category
    # Remove source_id index as source_id column doesn't exist
    add_index :batch_enrollments, :confirmation_email_sent
    add_index :batch_courses, :evaluator_id unless index_exists?(:batch_courses, :evaluator_id)

    # Add indexes for batch courses uniqueness and performance
    add_index :batch_courses, [ :batch_id, :course_id ], unique: true unless index_exists?(:batch_courses, [ :batch_id, :course_id ])
  end
end
