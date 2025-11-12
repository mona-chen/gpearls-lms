class CreateCohortSystem < ActiveRecord::Migration[7.0]
  def change
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

    add_index :cohorts, [:course_id, :slug], unique: true unless index_exists?(:cohorts, [:course_id, :slug])
    add_index :cohorts, :instructor_id unless index_exists?(:cohorts, :instructor_id)
    add_index :cohorts, :status unless index_exists?(:cohorts, :status)

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

    add_index :cohort_subgroups, [:cohort_id, :slug], unique: true unless index_exists?(:cohort_subgroups, [:cohort_id, :slug])
    add_index :cohort_subgroups, :invite_code, unique: true unless index_exists?(:cohort_subgroups, :invite_code)
    add_index :cohort_subgroups, :course_id unless index_exists?(:cohort_subgroups, :course_id)

    # Create cohort_mentors table
    create_table :cohort_mentors do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :cohort_subgroup, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.timestamps
    end

    add_index :cohort_mentors, [:cohort_id, :cohort_subgroup_id, :user_id], unique: true, name: "idx_cohort_mentors_unique" unless index_exists?(:cohort_mentors, [:cohort_id, :cohort_subgroup_id, :user_id])
    add_index :cohort_mentors, :user_id unless index_exists?(:cohort_mentors, :user_id)
    add_index :cohort_mentors, :course_id unless index_exists?(:cohort_mentors, :course_id)

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

    add_index :cohort_join_requests, [:cohort_id, :cohort_subgroup_id, :user_id], unique: true, name: "idx_cohort_join_requests_unique" unless index_exists?(:cohort_join_requests, [:cohort_id, :cohort_subgroup_id, :user_id])
    add_index :cohort_join_requests, :status unless index_exists?(:cohort_join_requests, :status)
    add_index :cohort_join_requests, :user_id unless index_exists?(:cohort_join_requests, :user_id)

    # Create cohort_staffs table
    create_table :cohort_staffs do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'Staff'
      t.references :course, foreign_key: true
      t.timestamps
    end

    add_index :cohort_staffs, [:cohort_id, :user_id], unique: true unless index_exists?(:cohort_staffs, [:cohort_id, :user_id])
    add_index :cohort_staffs, :user_id unless index_exists?(:cohort_staffs, :user_id)
    add_index :cohort_staffs, :course_id unless index_exists?(:cohort_staffs, :course_id)

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

    add_index :cohort_web_pages, [:cohort_id, :slug], unique: true unless index_exists?(:cohort_web_pages, [:cohort_id, :slug])
    add_index :cohort_web_pages, :scope unless index_exists?(:cohort_web_pages, :scope)

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

    add_index :batch_timetables, [:batch_id, :date] unless index_exists?(:batch_timetables, [:batch_id, :date])
    add_index :batch_timetables, [:reference_doctype, :reference_docname], name: "idx_batch_timetables_ref" unless index_exists?(:batch_timetables, [:reference_doctype, :reference_docname])

    # Create sources table for batch enrollment source tracking
    create_table :sources do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :sources, :name, unique: true unless index_exists?(:sources, :name)

    # Add columns to enrollments table for cohort support
    add_reference :enrollments, :cohort, foreign_key: true unless foreign_key_exists?(:enrollments, :cohort_id)
    add_reference :enrollments, :cohort_subgroup, foreign_key: true unless foreign_key_exists?(:enrollments, :cohort_subgroup_id)
    add_index :enrollments, :cohort_id unless index_exists?(:enrollments, :cohort_id)
    add_index :enrollments, :cohort_subgroup_id unless index_exists?(:enrollments, :cohort_subgroup_id)

    # Add columns to users table for batch/cohort roles
    add_column :users, :is_batch_instructor, :boolean, default: false
    add_column :users, :is_cohort_mentor, :boolean, default: false
    add_column :users, :is_cohort_staff, :boolean, default: false
    add_index :users, :is_batch_instructor unless index_exists?(:users, :is_batch_instructor)
    add_index :users, :is_cohort_mentor unless index_exists?(:users, :is_cohort_mentor)
    add_index :users, :is_cohort_staff unless index_exists?(:users, :is_cohort_staff)

    # Seed default sources
    reversible do |dir|
      dir.up do
        # Use raw SQL to insert source data
        execute <<-SQL
          INSERT INTO sources (name, description, active, created_at, updated_at) VALUES
          ('Newsletter', 'Users who subscribed to newsletter', 1, datetime('now'), datetime('now')),
          ('LinkedIn', 'Users coming from LinkedIn', 1, datetime('now'), datetime('now')),
          ('Twitter', 'Users coming from Twitter', 1, datetime('now'), datetime('now')),
          ('Website', 'Users from website direct traffic', 1, datetime('now'), datetime('now')),
          ('Friend/Colleague/Connection', 'Referred by someone', 1, datetime('now'), datetime('now')),
          ('Google Search', 'Users from Google search', 1, datetime('now'), datetime('now'))
        SQL
      end
    end
  end
end
