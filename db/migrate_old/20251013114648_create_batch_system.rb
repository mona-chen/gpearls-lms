class CreateBatchSystem < ActiveRecord::Migration[7.0]
  def change
    # Create batches table
    return if table_exists?(:batches)

    create_table :batches do |t|
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :timezone, null: false, default: 'UTC'
      t.text :description, null: false
      t.text :batch_details, null: false
      t.text :batch_details_raw
      t.boolean :published, default: false
      t.boolean :allow_self_enrollment, default: false
      t.boolean :certification, default: false
      t.integer :seat_count
      t.date :evaluation_end_date
      t.string :medium, default: 'Online'
      t.string :category
      t.string :confirmation_email_template
      t.string :instructors, null: false, default: '[]'
      t.string :zoom_account
      t.boolean :paid_batch, default: false
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.decimal :amount_usd, precision: 10, scale: 2
      t.boolean :show_live_class, default: false
      t.boolean :allow_future, default: true
      t.string :timetable_template
      t.string :custom_component
      t.text :custom_script
      t.string :meta_image
      t.datetime :published_at
      t.timestamps
    end

    # Create batch_courses table
    create_table :batch_courses do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :evaluator, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :batch_courses, [:batch_id, :course_id], unique: true
    add_index :batch_courses, :evaluator_id

    # Create batch_enrollments table
    create_table :batch_enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :batch, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.references :source, foreign_key: true
      t.boolean :confirmation_email_sent, default: false
      t.timestamps
    end

    add_index :batch_enrollments, [:user_id, :batch_id], unique: true
    add_index :batch_enrollments, :payment_id
    add_index :batch_enrollments, :source_id

    # Create batch_timetables table
    create_table :batch_timetables do |t|
      t.references :batch, null: false, foreign_key: true
      t.string :reference_doctype
      t.string :reference_docname
      t.date :date
      t.time :start_time
      t.time :end_time
      t.string :duration
      t.boolean :milestone, default: false
      t.timestamps
    end

    add_index :batch_timetables, [:batch_id, :date]
    add_index :batch_timetables, [:reference_doctype, :reference_docname]

    # Create cohorts table
    create_table :cohorts do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.references :instructor, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: 'Upcoming'
      t.date :begin_date
      t.date :end_date
      t.string :duration
      t.text :description
      t.timestamps
    end

    add_index :cohorts, [:course_id, :slug], unique: true
    add_index :cohorts, :instructor_id
    add_index :cohorts, :status

    # Create cohort_subgroups table
    create_table :cohort_subgroups do |t|
      t.references :cohort, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :invite_code, null: false
      t.references :course, foreign_key: true
      t.timestamps
    end

    add_index :cohort_subgroups, [:cohort_id, :slug], unique: true
    add_index :cohort_subgroups, :invite_code, unique: true
    add_index :cohort_subgroups, :course_id

    # Create cohort_mentors table
    create_table :cohort_mentors do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :cohort_subgroup, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.timestamps
    end

    add_index :cohort_mentors, [:cohort_id, :cohort_subgroup_id, :user_id], unique: true
    add_index :cohort_mentors, :user_id
    add_index :cohort_mentors, :course_id

    # Create cohort_join_requests table
    create_table :cohort_join_requests do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :cohort_subgroup, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'Pending'
      t.text :message
      t.text :rejection_reason
      t.string :rejected_by
      t.timestamps
    end

    add_index :cohort_join_requests, [:cohort_id, :cohort_subgroup_id, :user_id], unique: true
    add_index :cohort_join_requests, :status
    add_index :cohort_join_requests, :user_id

    # Create cohort_staffs table
    create_table :cohort_staffs do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'Staff'
      t.references :course, foreign_key: true
      t.timestamps
    end

    add_index :cohort_staffs, [:cohort_id, :user_id], unique: true
    add_index :cohort_staffs, :user_id
    add_index :cohort_staffs, :course_id

    # Create cohort_web_pages table
    create_table :cohort_web_pages do |t|
      t.references :cohort, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.text :content
      t.string :scope, default: 'public'
      t.text :template_html
      t.timestamps
    end

    add_index :cohort_web_pages, [:cohort_id, :slug], unique: true
    add_index :cohort_web_pages, :scope

    # Add columns to enrollments table for cohort support
    add_reference :enrollments, :cohort, foreign_key: true
    add_reference :enrollments, :cohort_subgroup, foreign_key: true
    add_index :enrollments, :cohort_id
    add_index :enrollments, :cohort_subgroup_id

    # Add columns to users table for batch/cohort roles
    add_column :users, :is_batch_instructor, :boolean, default: false
    add_column :users, :is_cohort_mentor, :boolean, default: false
    add_column :users, :is_cohort_staff, :boolean, default: false
    add_index :users, :is_batch_instructor
    add_index :users, :is_cohort_mentor
    add_index :users, :is_cohort_staff

    # Create sources table for batch enrollment source tracking
    create_table :sources do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :sources, :name, unique: true

    # Seed default sources
    reversible do |dir|
      dir.up do
        Source.create!([
          { name: 'Newsletter', description: 'Users who subscribed to newsletter' },
          { name: 'LinkedIn', description: 'Users coming from LinkedIn' },
          { name: 'Twitter', description: 'Users coming from Twitter' },
          { name: 'Website', description: 'Users from website direct traffic' },
          { name: 'Friend/Colleague/Connection', description: 'Referred by someone' },
          { name: 'Google Search', description: 'Users from Google search' }
        ])
      end
    end
  end
end
