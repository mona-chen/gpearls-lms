class CreateLmsVideoWatchDurations < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_video_watch_durations do |t|
      # Frappe standard fields
      t.string :name, null: false
      t.string :owner, null: false
      t.datetime :creation, null: false
      t.datetime :modified, null: false
      t.string :modified_by, null: false
      t.string :docstatus, default: "0"
      t.string :parent, null: true
      t.string :parenttype, null: true
      t.string :parentfield, null: true
      t.integer :idx, null: true

      # Exact Frappe field structure from lms_video_watch_duration.json
      t.string :lesson, null: false                     # Link to Course Lesson, reqd: 1
      t.string :chapter                                 # Link to Course Chapter, fetched from lesson.chapter
      t.string :course                                  # Link to LMS Course, fetched from lesson.course
      t.string :member, null: false                     # Link to User, reqd: 1
      t.string :member_name                             # Data, fetched from member.full_name
      t.string :member_image                            # Attach Image, fetched from member.user_image
      t.string :member_username                         # Data, fetched from member.username
      t.string :source, null: false                     # Data field, reqd: 1
      t.string :watch_time, null: false                 # Data field, reqd: 1

      t.timestamps
    end

    # Add indexes for performance based on Frappe query patterns
    add_index :lms_video_watch_durations, :lesson
    add_index :lms_video_watch_durations, :chapter
    add_index :lms_video_watch_durations, :course
    add_index :lms_video_watch_durations, :member
    add_index :lms_video_watch_durations, :source
    add_index :lms_video_watch_durations, :creation
    add_index :lms_video_watch_durations, :modified
    add_index :lms_video_watch_durations, [:member, :lesson], unique: true, name: 'index_video_watch_on_member_and_lesson'
    add_index :lms_video_watch_durations, [:course, :member], name: 'index_video_watch_on_course_and_member'

    # Add foreign key constraints
    # TODO: Add foreign keys when tables exist:
    # add_foreign_key :lms_video_watch_durations, :course_lessons, column: :lesson
    # add_foreign_key :lms_video_watch_durations, :course_chapters, column: :chapter
    add_foreign_key :lms_video_watch_durations, :lms_courses, column: :course
    add_foreign_key :lms_video_watch_durations, :users, column: :member
  end
end
