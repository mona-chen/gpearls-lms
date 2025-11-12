class CreateCohorts < ActiveRecord::Migration[7.2]
  def change
    create_table :cohorts do |t|
      # Core fields
      t.string :course, null: false, index: true # Link to LMS Course
      t.string :title, null: false, index: true
      t.string :slug, null: false, index: { unique: true }
      t.string :instructor, null: false, index: true # Link to User
      t.string :status, null: false, default: "Upcoming", index: true # Upcoming, Live, Completed, Cancelled

      # Date and duration fields
      t.date :begin_date
      t.date :end_date
      t.string :duration

      # Description and content
      t.text :description # Markdown Editor
      t.text :pages # Table field for Cohort Web Page

      # Frappe standard fields
      t.string :name, null: false, index: { unique: true }
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      # Rails timestamps
      t.timestamps
    end

    # Indexes already added by t.index in create_table

    # Add unique index for autoname format: {course}/{slug}
    add_index :cohorts, [:course, :slug], unique: true, name: 'index_cohorts_on_course_and_slug'
  end
end
