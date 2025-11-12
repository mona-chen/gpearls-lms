class CreateLmsPrograms < ActiveRecord::Migration[7.0]
  def change
    # LMS Programs table
    create_table :lms_programs do |t|
      t.string :name, null: false
      t.string :title, null: false
      t.text :description
      t.string :image
      t.string :video_link
      t.string :short_introduction
      t.boolean :published, default: false
      t.boolean :featured, default: false
      t.string :status, default: "Draft"
      t.string :category
      t.text :tags
      t.integer :course_count, default: 0
      t.integer :member_count, default: 0
      t.string :owner
      t.datetime :creation
      t.datetime :modified

      t.timestamps
    end

    add_index :lms_programs, :name, unique: true
    add_index :lms_programs, :published
    add_index :lms_programs, :featured
    add_index :lms_programs, :category

    # LMS Program Members table (join table for users enrolled in programs)
    create_table :lms_program_members do |t|
      t.references :lms_program, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :progress, precision: 5, scale: 2, default: 0.0
      t.datetime :creation
      t.datetime :modified

      t.timestamps
    end

    add_index :lms_program_members, [:lms_program_id, :user_id], unique: true, name: 'index_lms_program_members_on_program_and_user'

    # LMS Program Courses table (join table for courses in programs)
    create_table :lms_program_courses do |t|
      t.references :lms_program, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: { to_table: :courses }
      t.integer :position
      t.datetime :creation
      t.datetime :modified

      t.timestamps
    end

    add_index :lms_program_courses, [:lms_program_id, :course_id], unique: true, name: 'index_lms_program_courses_on_program_and_course'
    add_index :lms_program_courses, :position, name: 'index_lms_program_courses_on_position'
  end
end
