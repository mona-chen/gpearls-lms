class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    # Add indexes for common query patterns (only if they don't exist)

    # LMS Courses table - frequently queried fields
    add_index :lms_courses, [ :published, :featured ], name: 'index_lms_courses_on_published_and_featured' unless index_exists?(:lms_courses, [ :published, :featured ])
    add_index :lms_courses, [ :instructor_id, :published ], name: 'index_lms_courses_on_instructor_and_published' unless index_exists?(:lms_courses, [ :instructor_id, :published ])
    add_index :lms_courses, :updated_at, name: 'index_lms_courses_on_updated_at' unless index_exists?(:lms_courses, :updated_at)

    # LMS Enrollments table - common joins and filters
    add_index :lms_enrollments, [ :student_id, :course_id ], unique: true, name: 'index_lms_enrollments_on_student_and_course' unless index_exists?(:lms_enrollments, [ :student_id, :course_id ])
    add_index :lms_enrollments, [ :course_id, :created_at ], name: 'index_lms_enrollments_on_course_and_created_at' unless index_exists?(:lms_enrollments, [ :course_id, :created_at ])
    add_index :lms_enrollments, :progress_percentage, name: 'index_lms_enrollments_on_progress_percentage' unless index_exists?(:lms_enrollments, :progress_percentage)

    # Users table - authentication and role queries
    add_index :users, [ :role, :status ], name: 'index_users_on_role_and_status' unless index_exists?(:users, [ :role, :status ])
    add_index :users, :username, unique: true, name: 'index_users_on_username' unless index_exists?(:users, :username)

    # LMS Quiz submissions - performance for grading
    add_index :lms_quiz_submissions, [ :student_id, :quiz_id ], name: 'index_lms_quiz_submissions_on_student_and_quiz' unless index_exists?(:lms_quiz_submissions, [ :student_id, :quiz_id ])
    add_index :lms_quiz_submissions, :created_at, name: 'index_lms_quiz_submissions_on_created_at' unless index_exists?(:lms_quiz_submissions, :created_at)

    # LMS Assignment submissions - similar to quiz
    add_index :lms_assignment_submissions, [ :student_id, :assignment_id ], name: 'index_lms_assignment_submissions_on_student_and_assignment' unless index_exists?(:lms_assignment_submissions, [ :student_id, :assignment_id ])

    # LMS Course progress - lesson tracking
    add_index :lms_course_progresses, [ :member, :course ], unique: true, name: 'index_lms_course_progresses_on_member_and_course' unless index_exists?(:lms_course_progresses, [ :member, :course ])

    # Video watch durations - analytics
    add_index :video_watch_durations, [ :user_id, :course_lesson_id ], name: 'index_video_watch_durations_on_user_and_lesson' unless index_exists?(:video_watch_durations, [ :user_id, :course_lesson_id ])
    add_index :video_watch_durations, :updated_at, name: 'index_video_watch_durations_on_updated_at' unless index_exists?(:video_watch_durations, :updated_at)

    # Notifications - user inbox
    add_index :notifications, [ :user_id, :read ], name: 'index_notifications_on_user_and_read' unless index_exists?(:notifications, [ :user_id, :read ])
    add_index :notifications, :created_at, name: 'index_notifications_on_created_at' unless index_exists?(:notifications, :created_at)

    # Payments - transaction queries
    add_index :payments, [ :user_id, :status ], name: 'index_payments_on_user_and_status' unless index_exists?(:payments, [ :user_id, :status ])
    add_index :payments, :created_at, name: 'index_payments_on_created_at' unless index_exists?(:payments, :created_at)

    # LMS Live classes - scheduling
    add_index :lms_live_classes, [ :batch_id, :date ], name: 'index_lms_live_classes_on_batch_and_date' unless index_exists?(:lms_live_classes, [ :batch_id, :date ])
    add_index :lms_live_classes, :date, name: 'index_lms_live_classes_on_date' unless index_exists?(:lms_live_classes, :date)

    # SCORM completions - progress tracking
    add_index :scorm_completions, [ :user_id, :scorm_package_id ], unique: true, name: 'index_scorm_completions_on_user_and_package' unless index_exists?(:scorm_completions, [ :user_id, :scorm_package_id ])
    add_index :scorm_completions, :last_accessed_at, name: 'index_scorm_completions_on_last_accessed_at' unless index_exists?(:scorm_completions, :last_accessed_at)
  end
end
