class CreateLmsPrograms < ActiveRecord::Migration[7.2]
  def change
    create_table :lms_programs do |t|
      # Core fields
      t.string :title, null: false, index: { unique: true }
      t.boolean :published, default: false, index: true
      t.boolean :enforce_course_order, default: false, index: true

      # Statistics (read-only fields)
      t.integer :course_count, default: 0
      t.integer :member_count, default: 0

      # Child table content (Table fields)
      t.text :program_courses # Table field for LMS Program Course
      t.text :program_members # Table field for LMS Program Member

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
