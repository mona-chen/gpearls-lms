# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_09_203317) do
  create_table "assignment_submissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "assignment_id", null: false
    t.text "answer"
    t.string "status"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_assignment_submissions_on_assignment_id"
    t.index ["user_id"], name: "index_assignment_submissions_on_user_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "type"
    t.integer "course_id"
    t.integer "lesson_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_assignments_on_course_id"
    t.index ["lesson_id"], name: "index_assignments_on_lesson_id"
  end

  create_table "batch_courses", force: :cascade do |t|
    t.integer "batch_id", null: false
    t.integer "course_id", null: false
    t.string "title"
    t.integer "evaluator_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_batch_courses_on_batch_id"
    t.index ["course_id"], name: "index_batch_courses_on_course_id"
    t.index ["evaluator_id"], name: "index_batch_courses_on_evaluator_id"
  end

  create_table "batch_enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_batch_enrollments_on_batch_id"
    t.index ["user_id"], name: "index_batch_enrollments_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "batch_details"
    t.date "start_date"
    t.date "end_date"
    t.time "start_time"
    t.time "end_time"
    t.integer "seat_count"
    t.boolean "published", default: false
    t.boolean "paid_batch", default: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency"
    t.decimal "amount_usd", precision: 10, scale: 2
    t.boolean "certification", default: false
    t.string "timezone"
    t.string "category"
    t.boolean "allow_self_enrollment", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "certificate_evaluations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id"
    t.integer "evaluator_id"
    t.date "date"
    t.time "start_time"
    t.time "end_time"
    t.string "status"
    t.decimal "rating", precision: 3, scale: 2
    t.text "summary"
    t.string "batch_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_certificate_evaluations_on_course_id"
    t.index ["evaluator_id"], name: "index_certificate_evaluations_on_evaluator_id"
    t.index ["user_id"], name: "index_certificate_evaluations_on_user_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id"
    t.integer "batch_id"
    t.date "issue_date"
    t.date "expiry_date"
    t.string "template"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_certificates_on_batch_id"
    t.index ["course_id"], name: "index_certificates_on_course_id"
    t.index ["user_id"], name: "index_certificates_on_user_id"
  end

  create_table "chapters", force: :cascade do |t|
    t.string "title", null: false
    t.integer "course_id", null: false
    t.integer "position"
    t.boolean "is_scorm_package", default: false
    t.string "scorm_package_path"
    t.string "manifest_file"
    t.string "launch_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_chapters_on_course_id"
  end

  create_table "course_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "lesson_id", null: false
    t.string "status", default: "Incomplete"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_progresses_on_course_id"
    t.index ["lesson_id"], name: "index_course_progresses_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_course_progresses_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_course_progresses_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "short_introduction"
    t.string "video_link"
    t.string "image"
    t.string "card_gradient"
    t.string "tags"
    t.string "category"
    t.boolean "published", default: false
    t.datetime "published_on"
    t.boolean "featured", default: false
    t.boolean "upcoming", default: false
    t.boolean "paid_course", default: false
    t.boolean "enable_certification", default: false
    t.boolean "paid_certificate", default: false
    t.decimal "course_price", precision: 10, scale: 2
    t.string "currency"
    t.integer "instructor_id"
    t.integer "evaluator_id"
    t.integer "lessons_count", default: 0
    t.integer "enrollments_count", default: 0
    t.decimal "rating", precision: 3, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluator_id"], name: "index_courses_on_evaluator_id"
    t.index ["featured"], name: "index_courses_on_featured"
    t.index ["instructor_id"], name: "index_courses_on_instructor_id"
    t.index ["published"], name: "index_courses_on_published"
  end

  create_table "discussion_replies", force: :cascade do |t|
    t.integer "discussion_topic_id", null: false
    t.text "reply", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_topic_id"], name: "index_discussion_replies_on_discussion_topic_id"
    t.index ["user_id"], name: "index_discussion_replies_on_user_id"
  end

  create_table "discussion_topics", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "reference_doctype"
    t.string "reference_docname"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_discussion_topics_on_user_id"
  end

  create_table "discussions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.string "title"
    t.string "content"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_discussions_on_course_id"
    t.index ["user_id"], name: "index_discussions_on_user_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "batch_id"
    t.decimal "progress", precision: 5, scale: 2, default: "0.0"
    t.string "current_lesson"
    t.string "member_type", default: "Student"
    t.boolean "purchased_certificate", default: false
    t.string "certificate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_enrollments_on_batch_id"
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "job_applications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "job_opportunity_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_opportunity_id"], name: "index_job_applications_on_job_opportunity_id"
    t.index ["user_id"], name: "index_job_applications_on_user_id"
  end

  create_table "job_opportunities", force: :cascade do |t|
    t.string "job_title", null: false
    t.string "location"
    t.string "country"
    t.string "type"
    t.string "work_mode"
    t.string "company_name"
    t.string "company_logo"
    t.string "company_website"
    t.text "description"
    t.integer "user_id", null: false
    t.boolean "published", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_job_opportunities_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "lesson_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "lesson_id", null: false
    t.integer "progress"
    t.boolean "completed"
    t.datetime "last_accessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_progresses_on_lesson_id"
    t.index ["user_id"], name: "index_lesson_progresses_on_user_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.text "content"
    t.text "instructor_notes"
    t.text "instructor_content"
    t.string "youtube"
    t.string "quiz_id"
    t.string "question"
    t.string "file_type"
    t.boolean "include_in_preview", default: true
    t.integer "chapter_id", null: false
    t.integer "course_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_lessons_on_chapter_id"
    t.index ["course_id"], name: "index_lessons_on_course_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "discussion_id", null: false
    t.text "content"
    t.string "message_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_id"], name: "index_messages_on_discussion_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "subject"
    t.text "email_content"
    t.string "document_type"
    t.string "document_name"
    t.integer "user_id", null: false
    t.integer "from_user_id"
    t.string "type", default: "Alert"
    t.string "link"
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_notifications_on_from_user_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "programming_exercise_submissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "programming_exercise_id", null: false
    t.text "code"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["programming_exercise_id"], name: "idx_on_programming_exercise_id_d649c0a654"
    t.index ["user_id"], name: "index_programming_exercise_submissions_on_user_id"
  end

  create_table "programming_exercises", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_programming_exercises_on_course_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.text "question", null: false
    t.string "type", default: "Choices"
    t.boolean "multiple", default: false
    t.string "option_1"
    t.string "option_2"
    t.string "option_3"
    t.string "option_4"
    t.text "explanation_1"
    t.text "explanation_2"
    t.text "explanation_3"
    t.text "explanation_4"
    t.integer "marks", default: 1
    t.integer "quiz_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quiz_results", force: :cascade do |t|
    t.integer "quiz_submission_id", null: false
    t.string "question_name"
    t.text "answer"
    t.boolean "is_correct", default: false
    t.integer "marks_obtained"
    t.integer "marks_out_of"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_submission_id"], name: "index_quiz_results_on_quiz_submission_id"
  end

  create_table "quiz_submissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "quiz_id", null: false
    t.integer "course_id"
    t.integer "score"
    t.decimal "percentage", precision: 5, scale: 2
    t.string "quiz_title"
    t.integer "total_marks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_quiz_submissions_on_course_id"
    t.index ["quiz_id"], name: "index_quiz_submissions_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_submissions_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "passing_percentage", default: 100
    t.integer "total_marks"
    t.integer "course_id"
    t.boolean "show_submission_history", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_quizzes_on_course_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_cases", force: :cascade do |t|
    t.integer "programming_exercise_submission_id", null: false
    t.text "input"
    t.text "output"
    t.text "expected_output"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["programming_exercise_submission_id"], name: "index_test_cases_on_programming_exercise_submission_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "jti"
    t.string "full_name"
    t.string "username"
    t.string "user_image"
    t.string "user_type", default: "Website User"
    t.boolean "enabled", default: true
    t.datetime "last_active"
    t.boolean "is_instructor", default: false
    t.boolean "is_moderator", default: false
    t.boolean "is_evaluator", default: false
    t.boolean "is_student", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_category"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "video_watch_durations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "lesson_id", null: false
    t.string "source"
    t.decimal "watch_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_video_watch_durations_on_lesson_id"
    t.index ["user_id"], name: "index_video_watch_durations_on_user_id"
  end

  add_foreign_key "assignment_submissions", "assignments"
  add_foreign_key "assignment_submissions", "users"
  add_foreign_key "assignments", "courses"
  add_foreign_key "assignments", "lessons"
  add_foreign_key "batch_courses", "batches"
  add_foreign_key "batch_courses", "courses"
  add_foreign_key "batch_courses", "users", column: "evaluator_id"
  add_foreign_key "batch_enrollments", "batches"
  add_foreign_key "batch_enrollments", "users"
  add_foreign_key "certificate_evaluations", "courses"
  add_foreign_key "certificate_evaluations", "users"
  add_foreign_key "certificate_evaluations", "users", column: "evaluator_id"
  add_foreign_key "certificates", "batches"
  add_foreign_key "certificates", "courses"
  add_foreign_key "certificates", "users"
  add_foreign_key "chapters", "courses"
  add_foreign_key "course_progresses", "courses"
  add_foreign_key "course_progresses", "lessons"
  add_foreign_key "course_progresses", "users"
  add_foreign_key "courses", "users", column: "evaluator_id"
  add_foreign_key "courses", "users", column: "instructor_id"
  add_foreign_key "discussion_replies", "discussion_topics"
  add_foreign_key "discussion_replies", "users"
  add_foreign_key "discussion_topics", "users"
  add_foreign_key "discussions", "courses"
  add_foreign_key "discussions", "users"
  add_foreign_key "enrollments", "batches"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
  add_foreign_key "job_applications", "job_opportunities"
  add_foreign_key "job_applications", "users"
  add_foreign_key "job_opportunities", "users"
  add_foreign_key "lesson_progresses", "lessons"
  add_foreign_key "lesson_progresses", "users"
  add_foreign_key "lessons", "chapters"
  add_foreign_key "lessons", "courses"
  add_foreign_key "messages", "discussions"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "from_user_id"
  add_foreign_key "programming_exercise_submissions", "programming_exercises"
  add_foreign_key "programming_exercise_submissions", "users"
  add_foreign_key "programming_exercises", "courses"
  add_foreign_key "quiz_questions", "quizzes"
  add_foreign_key "quiz_results", "quiz_submissions"
  add_foreign_key "quiz_submissions", "courses"
  add_foreign_key "quiz_submissions", "quizzes"
  add_foreign_key "quiz_submissions", "users"
  add_foreign_key "quizzes", "courses"
  add_foreign_key "test_cases", "programming_exercise_submissions"
  add_foreign_key "video_watch_durations", "lessons"
  add_foreign_key "video_watch_durations", "users"
end
