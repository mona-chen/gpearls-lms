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

ActiveRecord::Schema[7.2].define(version: 2025_11_25_103529) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "batch_courses", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "course", null: false
    t.string "title", null: false
    t.string "evaluator"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batch_id"
    t.integer "course_id"
    t.integer "evaluator_id"
    t.index ["course", "evaluator"], name: "index_batch_courses_on_course_and_evaluator"
    t.index ["course"], name: "index_batch_courses_on_course"
    t.index ["creation"], name: "index_batch_courses_on_creation"
    t.index ["evaluator"], name: "index_batch_courses_on_evaluator"
    t.index ["modified"], name: "index_batch_courses_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_batch_courses_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_batch_courses_on_parent"
    t.index ["parentfield"], name: "index_batch_courses_on_parentfield"
    t.index ["parenttype"], name: "index_batch_courses_on_parenttype"
    t.index ["title"], name: "index_batch_courses_on_title"
  end

  create_table "certificate_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "evaluator_id", null: false
    t.date "date"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.string "google_meet_link"
    t.decimal "rating"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_certificate_requests_on_course_id"
    t.index ["evaluator_id"], name: "index_certificate_requests_on_evaluator_id"
    t.index ["user_id"], name: "index_certificate_requests_on_user_id"
  end

  create_table "certification_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "certifications", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "certification_name", null: false
    t.string "organization", null: false
    t.text "description"
    t.boolean "expire", default: false
    t.date "issue_date", null: false
    t.string "expiration_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certification_name"], name: "index_certifications_on_certification_name"
    t.index ["creation"], name: "index_certifications_on_creation"
    t.index ["expire"], name: "index_certifications_on_expire"
    t.index ["issue_date"], name: "index_certifications_on_issue_date"
    t.index ["modified"], name: "index_certifications_on_modified"
    t.index ["organization", "certification_name"], name: "index_certifications_on_organization_and_certification_name"
    t.index ["organization"], name: "index_certifications_on_organization"
    t.index ["parent", "parenttype", "parentfield"], name: "index_certifications_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_certifications_on_parent"
    t.index ["parentfield"], name: "index_certifications_on_parentfield"
    t.index ["parenttype"], name: "index_certifications_on_parenttype"
  end

  create_table "chapter_references", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "chapter", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter"], name: "index_chapter_references_on_chapter"
    t.index ["creation"], name: "index_chapter_references_on_creation"
    t.index ["modified"], name: "index_chapter_references_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_chapter_refs_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_chapter_references_on_parent"
    t.index ["parentfield"], name: "index_chapter_references_on_parentfield"
    t.index ["parenttype"], name: "index_chapter_references_on_parenttype"
  end

  create_table "code_revisions", force: :cascade do |t|
    t.text "code", null: false
    t.string "section_id", null: false
    t.string "section_type", null: false
    t.integer "user_id", null: false
    t.text "notes"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "section_type", "user_id"], name: "index_code_revisions_on_section_id_and_section_type_and_user_id"
    t.index ["user_id", "created_at"], name: "index_code_revisions_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_code_revisions_on_user_id"
  end

  create_table "cohort_join_requests", force: :cascade do |t|
    t.string "cohort", null: false
    t.string "email", null: false
    t.string "subgroup", null: false
    t.string "status", default: "Pending", null: false
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort"], name: "index_cohort_join_requests_on_cohort"
    t.index ["email"], name: "index_cohort_join_requests_on_email"
    t.index ["name"], name: "index_cohort_join_requests_on_name", unique: true
    t.index ["status"], name: "index_cohort_join_requests_on_status"
    t.index ["subgroup"], name: "index_cohort_join_requests_on_subgroup"
  end

  create_table "cohort_mentors", force: :cascade do |t|
    t.string "cohort", null: false
    t.string "email", null: false
    t.string "subgroup", null: false
    t.string "course"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort"], name: "index_cohort_mentors_on_cohort"
    t.index ["email"], name: "index_cohort_mentors_on_email"
    t.index ["name"], name: "index_cohort_mentors_on_name", unique: true
    t.index ["subgroup"], name: "index_cohort_mentors_on_subgroup"
  end

  create_table "cohort_staffs", force: :cascade do |t|
    t.string "cohort", null: false
    t.string "email", null: false
    t.string "role", null: false
    t.string "course"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort"], name: "index_cohort_staffs_on_cohort"
    t.index ["email"], name: "index_cohort_staffs_on_email"
    t.index ["name"], name: "index_cohort_staffs_on_name", unique: true
    t.index ["role"], name: "index_cohort_staffs_on_role"
  end

  create_table "cohort_subgroups", force: :cascade do |t|
    t.string "cohort", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.string "invite_code"
    t.text "description"
    t.string "course"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort"], name: "index_cohort_subgroups_on_cohort"
    t.index ["name"], name: "index_cohort_subgroups_on_name", unique: true
    t.index ["slug"], name: "index_cohort_subgroups_on_slug"
    t.index ["title", "cohort"], name: "index_cohort_subgroups_on_title_and_cohort", unique: true
    t.index ["title"], name: "index_cohort_subgroups_on_title"
  end

  create_table "cohort_web_pages", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "slug", null: false
    t.string "title", null: false
    t.string "template", null: false
    t.string "scope", default: "Cohort"
    t.string "required_role", default: "Public"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_cohort_web_pages_on_creation"
    t.index ["modified"], name: "index_cohort_web_pages_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_cohort_web_pages_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_cohort_web_pages_on_parent"
    t.index ["parentfield"], name: "index_cohort_web_pages_on_parentfield"
    t.index ["parenttype"], name: "index_cohort_web_pages_on_parenttype"
    t.index ["required_role"], name: "index_cohort_web_pages_on_required_role"
    t.index ["scope", "required_role"], name: "index_cohort_web_pages_on_scope_and_required_role"
    t.index ["scope"], name: "index_cohort_web_pages_on_scope"
    t.index ["slug", "title"], name: "index_cohort_web_pages_on_slug_and_title"
    t.index ["slug"], name: "index_cohort_web_pages_on_slug"
    t.index ["template"], name: "index_cohort_web_pages_on_template"
    t.index ["title"], name: "index_cohort_web_pages_on_title"
  end

  create_table "cohorts", force: :cascade do |t|
    t.string "course", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.string "instructor", null: false
    t.string "status", default: "Upcoming", null: false
    t.date "begin_date"
    t.date "end_date"
    t.string "duration"
    t.text "description"
    t.text "pages"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "slug"], name: "index_cohorts_on_course_and_slug", unique: true
    t.index ["course"], name: "index_cohorts_on_course"
    t.index ["instructor"], name: "index_cohorts_on_instructor"
    t.index ["name"], name: "index_cohorts_on_name", unique: true
    t.index ["slug"], name: "index_cohorts_on_slug", unique: true
    t.index ["status"], name: "index_cohorts_on_status"
    t.index ["title"], name: "index_cohorts_on_title"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "country_name", null: false
    t.string "country_code", null: false
    t.string "nationality"
    t.string "dial_code"
    t.string "currency"
    t.string "date_format"
    t.string "time_format"
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_countries_on_country_code", unique: true
    t.index ["country_name"], name: "index_countries_on_country_name", unique: true
    t.index ["creation"], name: "index_countries_on_creation"
    t.index ["currency"], name: "index_countries_on_currency"
    t.index ["dial_code"], name: "index_countries_on_dial_code"
    t.index ["enabled"], name: "index_countries_on_enabled"
    t.index ["modified"], name: "index_countries_on_modified"
    t.index ["nationality"], name: "index_countries_on_nationality"
  end

  create_table "course_chapters", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "title", null: false
    t.string "course", null: false
    t.string "course_title"
    t.boolean "is_scorm_package", default: false
    t.string "scorm_package"
    t.text "scorm_package_path"
    t.text "manifest_file"
    t.text "launch_file"
    t.string "lessons"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "title"], name: "index_course_chapters_on_course_and_title"
    t.index ["course"], name: "index_course_chapters_on_course"
    t.index ["creation"], name: "index_course_chapters_on_creation"
    t.index ["is_scorm_package"], name: "index_course_chapters_on_is_scorm_package"
    t.index ["modified"], name: "index_course_chapters_on_modified"
    t.index ["name"], name: "index_course_chapters_on_name", unique: true
    t.index ["title"], name: "index_course_chapters_on_title"
  end

  create_table "course_evaluators", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "evaluator", null: false
    t.string "full_name"
    t.string "user_image"
    t.string "username"
    t.string "schedule"
    t.date "unavailable_from"
    t.date "unavailable_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_course_evaluators_on_creation"
    t.index ["evaluator"], name: "index_course_evaluators_on_evaluator", unique: true
    t.index ["full_name"], name: "index_course_evaluators_on_full_name"
    t.index ["modified"], name: "index_course_evaluators_on_modified"
    t.index ["unavailable_from"], name: "index_course_evaluators_on_unavailable_from"
    t.index ["unavailable_to"], name: "index_course_evaluators_on_unavailable_to"
  end

  create_table "course_instructors", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "instructor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_course_instructors_on_creation"
    t.index ["instructor"], name: "index_course_instructors_on_instructor"
    t.index ["modified"], name: "index_course_instructors_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_course_instructors_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_course_instructors_on_parent"
    t.index ["parentfield"], name: "index_course_instructors_on_parentfield"
    t.index ["parenttype"], name: "index_course_instructors_on_parenttype"
  end

  create_table "course_lessons", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "title", null: false
    t.boolean "include_in_preview", default: false
    t.string "chapter", null: false
    t.boolean "is_scorm_package", default: false
    t.string "course"
    t.text "content"
    t.text "body"
    t.text "instructor_content"
    t.text "instructor_notes"
    t.string "youtube"
    t.string "quiz_id"
    t.text "question"
    t.string "file_type"
    t.text "help"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter", "title"], name: "index_course_lessons_on_chapter_and_title"
    t.index ["chapter"], name: "index_course_lessons_on_chapter"
    t.index ["course", "title"], name: "index_course_lessons_on_course_and_title"
    t.index ["course"], name: "index_course_lessons_on_course"
    t.index ["creation"], name: "index_course_lessons_on_creation"
    t.index ["include_in_preview"], name: "index_course_lessons_on_include_in_preview"
    t.index ["is_scorm_package"], name: "index_course_lessons_on_is_scorm_package"
    t.index ["modified"], name: "index_course_lessons_on_modified"
    t.index ["title"], name: "index_course_lessons_on_title"
  end

  create_table "discussion_replies", force: :cascade do |t|
    t.integer "topic_id"
    t.text "reply"
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.string "modified_by"
    t.integer "docstatus", default: 0
    t.integer "idx", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_discussion_replies_on_topic_id"
  end

  create_table "discussion_topics", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "reference_doctype"
    t.string "reference_docname"
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.string "modified_by"
    t.integer "docstatus", default: 0
    t.integer "idx", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_doctype", "reference_docname"], name: "idx_on_reference_doctype_reference_docname_b3074dff7c"
  end

  create_table "discussions", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "status", default: "open", null: false
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "status"], name: "index_discussions_on_course_id_and_status"
    t.index ["course_id"], name: "index_discussions_on_course_id"
    t.index ["created_at"], name: "index_discussions_on_created_at"
    t.index ["user_id"], name: "index_discussions_on_user_id"
  end

  create_table "education_details", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", default: "User", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "institution_name", null: false
    t.string "location", null: false
    t.string "degree_type", null: false
    t.string "major", null: false
    t.string "grade_type"
    t.string "grade"
    t.date "start_date"
    t.date "end_date"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["degree_type"], name: "index_education_details_on_degree_type"
    t.index ["institution_name"], name: "index_education_details_on_institution_name"
    t.index ["location"], name: "index_education_details_on_location"
    t.index ["major"], name: "index_education_details_on_major"
    t.index ["name"], name: "index_education_details_on_name", unique: true
    t.index ["parent"], name: "index_education_details_on_parent"
  end

  create_table "evaluator_schedules", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "day", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_evaluator_schedules_on_creation"
    t.index ["day", "end_time"], name: "index_evaluator_schedules_on_day_and_end_time"
    t.index ["day", "start_time"], name: "index_evaluator_schedules_on_day_and_start_time"
    t.index ["day"], name: "index_evaluator_schedules_on_day"
    t.index ["end_time"], name: "index_evaluator_schedules_on_end_time"
    t.index ["modified"], name: "index_evaluator_schedules_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_evaluator_schedules_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_evaluator_schedules_on_parent"
    t.index ["parentfield"], name: "index_evaluator_schedules_on_parentfield"
    t.index ["parenttype"], name: "index_evaluator_schedules_on_parenttype"
    t.index ["start_time"], name: "index_evaluator_schedules_on_start_time"
  end

  create_table "exercise_latest_submissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "exercise", null: false
    t.string "status"
    t.string "batch_old"
    t.string "exercise_title", null: false
    t.string "course"
    t.string "lesson"
    t.text "image"
    t.text "test_results"
    t.text "comments"
    t.text "solution"
    t.string "latest_submission"
    t.string "member", null: false
    t.string "member_email"
    t.string "member_cohort"
    t.string "member_subgroup"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_exercise_latest_submissions_on_course"
    t.index ["creation"], name: "index_exercise_latest_submissions_on_creation"
    t.index ["exercise", "member"], name: "index_exercise_latest_on_exercise_and_member", unique: true
    t.index ["exercise"], name: "index_exercise_latest_submissions_on_exercise"
    t.index ["latest_submission"], name: "index_exercise_latest_submissions_on_latest_submission"
    t.index ["lesson"], name: "index_exercise_latest_submissions_on_lesson"
    t.index ["member", "status"], name: "index_exercise_latest_on_member_and_status"
    t.index ["member"], name: "index_exercise_latest_submissions_on_member"
    t.index ["member_cohort"], name: "index_exercise_latest_submissions_on_member_cohort"
    t.index ["member_email"], name: "index_exercise_latest_submissions_on_member_email"
    t.index ["member_subgroup"], name: "index_exercise_latest_submissions_on_member_subgroup"
    t.index ["modified"], name: "index_exercise_latest_submissions_on_modified"
    t.index ["status"], name: "index_exercise_latest_submissions_on_status"
  end

  create_table "exercise_submissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "exercise", null: false
    t.string "status"
    t.string "batch_old"
    t.string "exercise_title", null: false
    t.string "course"
    t.string "lesson"
    t.text "image"
    t.text "test_results"
    t.text "comments"
    t.text "solution"
    t.string "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_exercise_submissions_on_course"
    t.index ["creation"], name: "index_exercise_submissions_on_creation"
    t.index ["exercise", "member"], name: "index_exercise_submissions_on_exercise_and_member", unique: true
    t.index ["exercise"], name: "index_exercise_submissions_on_exercise"
    t.index ["lesson"], name: "index_exercise_submissions_on_lesson"
    t.index ["member"], name: "index_exercise_submissions_on_member"
    t.index ["modified"], name: "index_exercise_submissions_on_modified"
    t.index ["status"], name: "index_exercise_submissions_on_status"
  end

  create_table "functions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "function", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_functions_on_creation"
    t.index ["function"], name: "index_functions_on_function", unique: true
    t.index ["modified"], name: "index_functions_on_modified"
  end

  create_table "has_roles", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", null: false
    t.string "role", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent", "role", "user_id"], name: "index_has_roles_on_parent_role_user_id", unique: true
    t.index ["parent"], name: "index_has_roles_on_parent"
    t.index ["role"], name: "index_has_roles_on_role"
    t.index ["user_id"], name: "index_has_roles_on_user_id"
    t.index ["user_id"], name: "index_has_roles_on_user_id_unique"
  end

  create_table "industries", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "industry", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_industries_on_creation"
    t.index ["industry"], name: "index_industries_on_industry", unique: true
    t.index ["modified"], name: "index_industries_on_modified"
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
    t.string "name"
    t.index ["name"], name: "index_job_opportunities_on_name", unique: true
    t.index ["user_id"], name: "index_job_opportunities_on_user_id"
  end

  create_table "job_reports", force: :cascade do |t|
    t.string "job_opportunity", null: false
    t.string "reported_by", null: false
    t.string "reason", null: false
    t.text "description"
    t.string "status", default: "pending"
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.string "modified_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resolution_action"
    t.index ["job_opportunity"], name: "index_job_reports_on_job_opportunity"
    t.index ["reported_by"], name: "index_job_reports_on_reported_by"
    t.index ["status"], name: "index_job_reports_on_status"
  end

  create_table "lesson_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "lesson_id", null: false
    t.integer "progress", default: 0
    t.boolean "completed", default: false
    t.datetime "last_accessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "Incomplete"
    t.index ["lesson_id"], name: "index_lesson_progresses_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_lesson_progresses_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_lesson_progresses_on_user_id"
  end

  create_table "lesson_references", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "lesson", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lesson_references_on_creation"
    t.index ["lesson"], name: "index_lesson_references_on_lesson"
    t.index ["modified"], name: "index_lesson_references_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_lesson_refs_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lesson_references_on_parent"
    t.index ["parentfield"], name: "index_lesson_references_on_parentfield"
    t.index ["parenttype"], name: "index_lesson_references_on_parenttype"
  end

  create_table "lms_assessments", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "assessment_type", null: false
    t.string "assessment_name", null: false
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_type"], name: "index_lms_assessments_on_assessment_type"
    t.index ["name"], name: "index_lms_assessments_on_name", unique: true
    t.index ["parent"], name: "index_lms_assessments_on_parent"
  end

  create_table "lms_assignment_submissions", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.integer "student_id", null: false
    t.integer "enrollment_id"
    t.string "submission_code", null: false
    t.integer "attempt_number", default: 1
    t.string "status", default: "Draft"
    t.text "submission_text"
    t.text "submission_files"
    t.string "submission_url"
    t.datetime "submitted_at"
    t.datetime "due_date"
    t.boolean "late_submission", default: false
    t.integer "late_days", default: 0
    t.decimal "late_penalty", precision: 5, scale: 2, default: "0.0"
    t.decimal "marks_obtained", precision: 10, scale: 2
    t.decimal "total_marks", precision: 10, scale: 2, default: "0.0"
    t.decimal "percentage", precision: 5, scale: 2, default: "0.0"
    t.boolean "passed", default: false
    t.text "feedback"
    t.text "detailed_feedback"
    t.text "grading_notes"
    t.datetime "graded_at"
    t.integer "graded_by_id"
    t.boolean "auto_graded", default: false
    t.decimal "auto_grade_score", precision: 5, scale: 2, default: "0.0"
    t.text "auto_grade_details"
    t.boolean "plagiarism_checked", default: false
    t.decimal "plagiarism_score", precision: 5, scale: 2, default: "0.0"
    t.text "plagiarism_report"
    t.boolean "peer_review_completed", default: false
    t.integer "peer_reviews_received", default: 0
    t.decimal "peer_review_average_score", precision: 5, scale: 2, default: "0.0"
    t.text "peer_review_feedback"
    t.boolean "returned_to_student", default: false
    t.datetime "returned_at"
    t.boolean "resubmission_allowed", default: false
    t.integer "resubmission_count", default: 0
    t.datetime "resubmission_deadline"
    t.text "submission_history"
    t.string "ip_address"
    t.string "user_agent"
    t.text "technical_issues"
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "status"], name: "index_lms_assignment_submissions_on_assignment_id_and_status"
    t.index ["assignment_id", "student_id", "attempt_number"], name: "idx_on_assignment_id_student_id_attempt_number_ac829a1f1b", unique: true
    t.index ["assignment_id", "student_id"], name: "idx_on_assignment_id_student_id_a3b19910d8"
    t.index ["assignment_id"], name: "index_lms_assignment_submissions_on_assignment_id"
    t.index ["attempt_number"], name: "index_lms_assignment_submissions_on_attempt_number"
    t.index ["auto_graded"], name: "index_lms_assignment_submissions_on_auto_graded"
    t.index ["enrollment_id"], name: "index_lms_assignment_submissions_on_enrollment_id"
    t.index ["graded_at"], name: "index_lms_assignment_submissions_on_graded_at"
    t.index ["graded_by_id"], name: "index_lms_assignment_submissions_on_graded_by_id"
    t.index ["late_submission"], name: "index_lms_assignment_submissions_on_late_submission"
    t.index ["marks_obtained"], name: "index_lms_assignment_submissions_on_marks_obtained"
    t.index ["passed"], name: "index_lms_assignment_submissions_on_passed"
    t.index ["peer_review_completed"], name: "index_lms_assignment_submissions_on_peer_review_completed"
    t.index ["percentage"], name: "index_lms_assignment_submissions_on_percentage"
    t.index ["plagiarism_checked"], name: "index_lms_assignment_submissions_on_plagiarism_checked"
    t.index ["returned_to_student"], name: "index_lms_assignment_submissions_on_returned_to_student"
    t.index ["status", "submitted_at"], name: "index_lms_assignment_submissions_on_status_and_submitted_at"
    t.index ["status"], name: "index_lms_assignment_submissions_on_status"
    t.index ["student_id", "assignment_id"], name: "idx_on_student_id_assignment_id_82ebbcbf22"
    t.index ["student_id", "status"], name: "index_lms_assignment_submissions_on_student_id_and_status"
    t.index ["student_id"], name: "index_lms_assignment_submissions_on_student_id"
    t.index ["submission_code"], name: "index_lms_assignment_submissions_on_submission_code", unique: true
    t.index ["submitted_at"], name: "index_lms_assignment_submissions_on_submitted_at"
  end

  create_table "lms_assignments", force: :cascade do |t|
    t.string "title", null: false
    t.integer "course_id", null: false
    t.integer "chapter_id"
    t.text "description"
    t.string "assignment_code"
    t.string "status", default: "Draft"
    t.string "assignment_type", default: "Submission"
    t.decimal "total_marks", precision: 10, scale: 2, default: "100.0"
    t.decimal "passing_percentage", precision: 5, scale: 2, default: "70.0"
    t.datetime "start_date"
    t.datetime "due_date"
    t.datetime "end_date"
    t.boolean "allow_late_submission", default: true
    t.decimal "late_penalty_percentage", precision: 5, scale: 2, default: "0.0"
    t.boolean "auto_grade", default: false
    t.text "instructions"
    t.text "submission_format"
    t.text "grading_criteria"
    t.text "rubric"
    t.boolean "allow_multiple_attempts", default: false
    t.integer "max_attempts", default: 1
    t.boolean "show_solution_after_due", default: true
    t.text "solution"
    t.text "sample_solution"
    t.integer "estimated_duration_hours", default: 0
    t.string "difficulty_level", default: "Medium"
    t.text "prerequisites"
    t.text "learning_objectives"
    t.text "resources"
    t.boolean "plagiarism_check_enabled", default: false
    t.text "plagiarism_settings"
    t.boolean "peer_review_enabled", default: false
    t.integer "peer_review_count", default: 0
    t.text "peer_review_criteria"
    t.boolean "group_assignment", default: false
    t.integer "max_group_size", default: 1
    t.integer "min_group_size", default: 1
    t.text "group_settings"
    t.boolean "template_provided", default: false
    t.text "template_file"
    t.boolean "anonymous_grading", default: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "submissions_count", default: 0
    t.decimal "average_score", precision: 5, scale: 2, default: "0.0"
    t.decimal "submission_rate", precision: 5, scale: 2, default: "0.0"
    t.datetime "published_at"
    t.integer "sort_order", default: 0
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_code"], name: "index_lms_assignments_on_assignment_code", unique: true
    t.index ["assignment_type", "status"], name: "index_lms_assignments_on_assignment_type_and_status"
    t.index ["assignment_type"], name: "index_lms_assignments_on_assignment_type"
    t.index ["average_score"], name: "index_lms_assignments_on_average_score"
    t.index ["chapter_id", "status"], name: "index_lms_assignments_on_chapter_id_and_status"
    t.index ["chapter_id"], name: "index_lms_assignments_on_chapter_id"
    t.index ["course_id", "due_date"], name: "index_lms_assignments_on_course_id_and_due_date"
    t.index ["course_id", "status"], name: "index_lms_assignments_on_course_id_and_status"
    t.index ["course_id"], name: "index_lms_assignments_on_course_id"
    t.index ["created_by_id"], name: "index_lms_assignments_on_created_by_id"
    t.index ["difficulty_level"], name: "index_lms_assignments_on_difficulty_level"
    t.index ["due_date"], name: "index_lms_assignments_on_due_date"
    t.index ["end_date"], name: "index_lms_assignments_on_end_date"
    t.index ["passing_percentage"], name: "index_lms_assignments_on_passing_percentage"
    t.index ["published_at"], name: "index_lms_assignments_on_published_at"
    t.index ["sort_order"], name: "index_lms_assignments_on_sort_order"
    t.index ["start_date"], name: "index_lms_assignments_on_start_date"
    t.index ["status", "due_date"], name: "index_lms_assignments_on_status_and_due_date"
    t.index ["status"], name: "index_lms_assignments_on_status"
    t.index ["submission_rate"], name: "index_lms_assignments_on_submission_rate"
    t.index ["submissions_count"], name: "index_lms_assignments_on_submissions_count"
    t.index ["title"], name: "index_lms_assignments_on_title"
    t.index ["total_marks"], name: "index_lms_assignments_on_total_marks"
    t.index ["updated_by_id"], name: "index_lms_assignments_on_updated_by_id"
  end

  create_table "lms_badge_assignments", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "member", null: false
    t.string "member_name"
    t.string "member_username"
    t.string "member_image"
    t.date "issued_on", null: false
    t.string "badge", null: false
    t.string "badge_image", null: false
    t.text "badge_description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge", "issued_on"], name: "index_badge_assign_on_badge_and_issued_on"
    t.index ["badge"], name: "index_lms_badge_assignments_on_badge"
    t.index ["creation"], name: "index_lms_badge_assignments_on_creation"
    t.index ["issued_on"], name: "index_lms_badge_assignments_on_issued_on"
    t.index ["member", "badge"], name: "index_badge_assign_on_member_and_badge", unique: true
    t.index ["member", "issued_on"], name: "index_badge_assign_on_member_and_issued_on"
    t.index ["member"], name: "index_lms_badge_assignments_on_member"
    t.index ["modified"], name: "index_lms_badge_assignments_on_modified"
  end

  create_table "lms_badges", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.boolean "enabled", default: true
    t.string "title", null: false
    t.text "description", null: false
    t.string "reference_doctype", null: false
    t.string "event", null: false
    t.string "image", null: false
    t.boolean "grant_only_once", default: false
    t.string "user_field", null: false
    t.string "field_to_check"
    t.text "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_badges_on_creation"
    t.index ["enabled", "event"], name: "index_lms_badges_on_enabled_and_event"
    t.index ["enabled"], name: "index_lms_badges_on_enabled"
    t.index ["event"], name: "index_lms_badges_on_event"
    t.index ["modified"], name: "index_lms_badges_on_modified"
    t.index ["reference_doctype", "event"], name: "index_lms_badges_on_reference_doctype_and_event"
    t.index ["reference_doctype"], name: "index_lms_badges_on_reference_doctype"
    t.index ["title"], name: "index_lms_badges_on_title", unique: true
  end

  create_table "lms_batch_enrollments", force: :cascade do |t|
    t.string "member", null: false
    t.string "batch", null: false
    t.string "payment"
    t.string "source"
    t.boolean "confirmation_email_sent", default: false
    t.string "member_name"
    t.string "member_username"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "batch_id"
    t.string "member_type", default: "Student"
    t.string "role", default: "Member"
    t.index ["batch"], name: "index_lms_batch_enrollments_on_batch"
    t.index ["batch_id"], name: "index_lms_batch_enrollments_on_batch_id"
    t.index ["member"], name: "index_lms_batch_enrollments_on_member"
    t.index ["member_type"], name: "index_lms_batch_enrollments_on_member_type"
    t.index ["name"], name: "index_lms_batch_enrollments_on_name", unique: true
    t.index ["role"], name: "index_lms_batch_enrollments_on_role"
    t.index ["user_id", "batch_id"], name: "index_lms_batch_enrollments_on_user_id_and_batch_id", unique: true
    t.index ["user_id"], name: "index_lms_batch_enrollments_on_user_id"
  end

  create_table "lms_batch_feedbacks", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "member", null: false
    t.string "member_name", null: false
    t.string "member_image"
    t.string "batch", null: false
    t.text "feedback", null: false
    t.integer "content"
    t.integer "instructors"
    t.integer "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch"], name: "index_lms_batch_feedbacks_on_batch"
    t.index ["content"], name: "index_lms_batch_feedbacks_on_content"
    t.index ["creation"], name: "index_lms_batch_feedbacks_on_creation"
    t.index ["instructors"], name: "index_lms_batch_feedbacks_on_instructors"
    t.index ["member", "batch"], name: "index_batch_feedback_on_member_and_batch", unique: true
    t.index ["member"], name: "index_lms_batch_feedbacks_on_member"
    t.index ["modified"], name: "index_lms_batch_feedbacks_on_modified"
    t.index ["value"], name: "index_lms_batch_feedbacks_on_value"
  end

  create_table "lms_batch_olds", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "course", null: false
    t.date "start_date"
    t.time "start_time"
    t.string "title", null: false
    t.string "sessions_on"
    t.time "end_time"
    t.text "description"
    t.string "visibility", default: "Public"
    t.string "membership"
    t.string "status", default: "Active"
    t.string "stage", default: "Ready"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "start_date"], name: "index_lms_batch_olds_on_course_and_start_date"
    t.index ["course", "status"], name: "index_lms_batch_olds_on_course_and_status"
    t.index ["course"], name: "index_lms_batch_olds_on_course"
    t.index ["creation"], name: "index_lms_batch_olds_on_creation"
    t.index ["membership"], name: "index_lms_batch_olds_on_membership"
    t.index ["modified"], name: "index_lms_batch_olds_on_modified"
    t.index ["stage"], name: "index_lms_batch_olds_on_stage"
    t.index ["start_date", "start_time"], name: "index_lms_batch_olds_on_start_date_and_start_time"
    t.index ["start_date"], name: "index_lms_batch_olds_on_start_date"
    t.index ["status"], name: "index_lms_batch_olds_on_status"
    t.index ["title"], name: "index_lms_batch_olds_on_title"
    t.index ["visibility"], name: "index_lms_batch_olds_on_visibility"
  end

  create_table "lms_batch_timetables", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "reference_doctype"
    t.string "reference_docname"
    t.date "date"
    t.integer "day"
    t.time "start_time"
    t.time "end_time"
    t.string "duration"
    t.boolean "milestone", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_batch_timetables_on_creation"
    t.index ["date", "start_time"], name: "index_lms_batch_timetables_on_date_and_start_time"
    t.index ["date"], name: "index_lms_batch_timetables_on_date"
    t.index ["day"], name: "index_lms_batch_timetables_on_day"
    t.index ["end_time"], name: "index_lms_batch_timetables_on_end_time"
    t.index ["milestone"], name: "index_lms_batch_timetables_on_milestone"
    t.index ["modified"], name: "index_lms_batch_timetables_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_batch_tt_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lms_batch_timetables_on_parent"
    t.index ["parentfield"], name: "index_lms_batch_timetables_on_parentfield"
    t.index ["parenttype"], name: "index_lms_batch_timetables_on_parenttype"
    t.index ["reference_docname"], name: "index_lms_batch_timetables_on_reference_docname"
    t.index ["reference_doctype", "reference_docname"], name: "index_batch_tt_on_ref_doctype_and_docname"
    t.index ["reference_doctype"], name: "index_lms_batch_timetables_on_reference_doctype"
    t.index ["start_time"], name: "index_lms_batch_timetables_on_start_time"
  end

  create_table "lms_batches", force: :cascade do |t|
    t.string "title", null: false
    t.integer "course_id", null: false
    t.text "description"
    t.string "batch_code"
    t.string "status", default: "Planned"
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.string "start_time"
    t.string "end_time"
    t.string "timezone", default: "UTC"
    t.string "schedule"
    t.string "delivery_mode", default: "Online"
    t.string "venue"
    t.string "location"
    t.integer "instructor_id"
    t.integer "teaching_assistant_id"
    t.integer "max_students", default: 30
    t.integer "min_students", default: 5
    t.integer "current_students", default: 0
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.boolean "allow_self_enrollment", default: true
    t.boolean "require_approval", default: false
    t.datetime "enrollment_start_date"
    t.datetime "enrollment_end_date"
    t.text "prerequisites"
    t.text "additional_info"
    t.string "meeting_link"
    t.string "meeting_id"
    t.string "meeting_password"
    t.boolean "record_sessions", default: false
    t.text "materials"
    t.text "schedule_details"
    t.boolean "certificate_enabled", default: false
    t.string "certificate_template"
    t.decimal "passing_percentage", precision: 5, scale: 2, default: "70.0"
    t.text "evaluation_criteria"
    t.boolean "feedback_enabled", default: true
    t.string "status_message"
    t.integer "sort_order", default: 0
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.boolean "published", default: false
    t.index ["batch_code"], name: "index_lms_batches_on_batch_code", unique: true
    t.index ["category"], name: "index_lms_batches_on_category"
    t.index ["course_id", "status"], name: "index_lms_batches_on_course_id_and_status"
    t.index ["course_id"], name: "index_lms_batches_on_course_id"
    t.index ["current_students"], name: "index_lms_batches_on_current_students"
    t.index ["delivery_mode"], name: "index_lms_batches_on_delivery_mode"
    t.index ["end_date"], name: "index_lms_batches_on_end_date"
    t.index ["enrollment_end_date"], name: "index_lms_batches_on_enrollment_end_date"
    t.index ["enrollment_start_date"], name: "index_lms_batches_on_enrollment_start_date"
    t.index ["instructor_id", "status"], name: "index_lms_batches_on_instructor_id_and_status"
    t.index ["instructor_id"], name: "index_lms_batches_on_instructor_id"
    t.index ["price"], name: "index_lms_batches_on_price"
    t.index ["published"], name: "index_lms_batches_on_published"
    t.index ["sort_order"], name: "index_lms_batches_on_sort_order"
    t.index ["start_date"], name: "index_lms_batches_on_start_date"
    t.index ["status", "start_date"], name: "index_lms_batches_on_status_and_start_date"
    t.index ["status"], name: "index_lms_batches_on_status"
    t.index ["teaching_assistant_id"], name: "index_lms_batches_on_teaching_assistant_id"
    t.index ["title"], name: "index_lms_batches_on_title"
  end

  create_table "lms_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "parent_category"
    t.integer "lft"
    t.integer "rght"
    t.integer "depth"
    t.string "icon"
    t.string "color"
    t.boolean "is_group", default: false
    t.integer "old_parent"
    t.string "route"
    t.boolean "published", default: true
    t.integer "course_count", default: 0
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.index ["course_count"], name: "index_lms_categories_on_course_count"
    t.index ["depth"], name: "index_lms_categories_on_depth"
    t.index ["is_active"], name: "index_lms_categories_on_is_active"
    t.index ["lft", "rght"], name: "index_lms_categories_on_lft_and_rght"
    t.index ["name"], name: "index_lms_categories_on_name", unique: true
    t.index ["parent_category"], name: "index_lms_categories_on_parent_category"
    t.index ["position"], name: "index_lms_categories_on_position"
    t.index ["published"], name: "index_lms_categories_on_published"
    t.index ["route"], name: "index_lms_categories_on_route"
  end

  create_table "lms_certificate_evaluations", force: :cascade do |t|
    t.string "member", null: false
    t.string "course", null: false
    t.string "batch_name"
    t.string "evaluator"
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time"
    t.string "status", default: "Pending", null: false
    t.decimal "rating", precision: 3, scale: 2
    t.text "summary"
    t.string "member_name"
    t.string "evaluator_name"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_name"], name: "index_lms_certificate_evaluations_on_batch_name"
    t.index ["course"], name: "index_lms_certificate_evaluations_on_course"
    t.index ["date"], name: "index_lms_certificate_evaluations_on_date"
    t.index ["evaluator"], name: "index_lms_certificate_evaluations_on_evaluator"
    t.index ["member"], name: "index_lms_certificate_evaluations_on_member"
    t.index ["name"], name: "index_lms_certificate_evaluations_on_name", unique: true
    t.index ["status"], name: "index_lms_certificate_evaluations_on_status"
  end

  create_table "lms_certificate_requests", force: :cascade do |t|
    t.string "course", null: false
    t.string "member", null: false
    t.string "evaluator"
    t.date "date", null: false
    t.string "day"
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "status", default: "Upcoming"
    t.string "batch_name"
    t.string "timezone"
    t.string "google_meet_link"
    t.string "course_title"
    t.string "member_name"
    t.string "evaluator_name"
    t.string "batch_title"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_lms_certificate_requests_on_course"
    t.index ["date"], name: "index_lms_certificate_requests_on_date"
    t.index ["evaluator"], name: "index_lms_certificate_requests_on_evaluator"
    t.index ["member"], name: "index_lms_certificate_requests_on_member"
    t.index ["name"], name: "index_lms_certificate_requests_on_name", unique: true
    t.index ["status"], name: "index_lms_certificate_requests_on_status"
  end

  create_table "lms_certificates", force: :cascade do |t|
    t.string "name", null: false
    t.integer "student_id", null: false
    t.integer "course_id"
    t.integer "batch_id"
    t.integer "program_id"
    t.integer "quiz_id"
    t.integer "assignment_id"
    t.string "certificate_type", default: "Course"
    t.string "status", default: "Draft"
    t.string "certificate_code", null: false
    t.string "certificate_title", null: false
    t.text "description"
    t.string "template_name"
    t.text "template_data"
    t.datetime "issue_date"
    t.datetime "expiry_date"
    t.boolean "has_expiry", default: false
    t.integer "validity_days", default: 0
    t.decimal "grade_obtained", precision: 5, scale: 2
    t.decimal "percentage_obtained", precision: 5, scale: 2
    t.string "grade_achieved"
    t.string "completion_status", default: "Completed"
    t.text "achievements"
    t.text "skills_attained"
    t.string "instructor_name"
    t.string "instructor_signature"
    t.string "authority_name"
    t.string "authority_signature"
    t.string "authority_seal"
    t.text "additional_signees"
    t.string "certificate_url"
    t.string "verification_code"
    t.boolean "publicly_accessible", default: false
    t.integer "verification_count", default: 0
    t.datetime "last_verified_at"
    t.text "metadata"
    t.integer "issued_by_id"
    t.datetime "revoked_at"
    t.string "revocation_reason"
    t.integer "revoked_by_id"
    t.text "revocation_notes"
    t.boolean "digital_signature", default: false
    t.text "digital_signature_data"
    t.string "blockchain_hash"
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_lms_certificates_on_assignment_id"
    t.index ["batch_id"], name: "index_lms_certificates_on_batch_id"
    t.index ["certificate_code"], name: "index_lms_certificates_on_certificate_code", unique: true
    t.index ["certificate_type", "status"], name: "index_lms_certificates_on_certificate_type_and_status"
    t.index ["certificate_type"], name: "index_lms_certificates_on_certificate_type"
    t.index ["course_id", "student_id"], name: "index_lms_certificates_on_course_id_and_student_id"
    t.index ["course_id"], name: "index_lms_certificates_on_course_id"
    t.index ["expiry_date"], name: "index_lms_certificates_on_expiry_date"
    t.index ["issue_date"], name: "index_lms_certificates_on_issue_date"
    t.index ["issued_by_id"], name: "index_lms_certificates_on_issued_by_id"
    t.index ["name"], name: "index_lms_certificates_on_name", unique: true
    t.index ["program_id"], name: "index_lms_certificates_on_program_id"
    t.index ["publicly_accessible", "verification_count"], name: "idx_on_publicly_accessible_verification_count_5b1cf50188"
    t.index ["publicly_accessible"], name: "index_lms_certificates_on_publicly_accessible"
    t.index ["quiz_id"], name: "index_lms_certificates_on_quiz_id"
    t.index ["revoked_at"], name: "index_lms_certificates_on_revoked_at"
    t.index ["revoked_by_id"], name: "index_lms_certificates_on_revoked_by_id"
    t.index ["status", "issue_date"], name: "index_lms_certificates_on_status_and_issue_date"
    t.index ["status"], name: "index_lms_certificates_on_status"
    t.index ["student_id", "certificate_type"], name: "index_lms_certificates_on_student_id_and_certificate_type"
    t.index ["student_id", "status"], name: "index_lms_certificates_on_student_id_and_status"
    t.index ["student_id"], name: "index_lms_certificates_on_student_id"
    t.index ["verification_code"], name: "index_lms_certificates_on_verification_code", unique: true
    t.index ["verification_count"], name: "index_lms_certificates_on_verification_count"
  end

  create_table "lms_course_interests", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "course", null: false
    t.string "user", null: false
    t.boolean "email_sent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "user"], name: "index_course_interest_on_course_and_user", unique: true
    t.index ["course"], name: "index_lms_course_interests_on_course"
    t.index ["creation"], name: "index_lms_course_interests_on_creation"
    t.index ["email_sent"], name: "index_lms_course_interests_on_email_sent"
    t.index ["modified"], name: "index_lms_course_interests_on_modified"
    t.index ["user", "email_sent"], name: "index_lms_course_interests_on_user_and_email_sent"
    t.index ["user"], name: "index_lms_course_interests_on_user"
  end

  create_table "lms_course_mentor_mappings", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "course", null: false
    t.string "mentor", null: false
    t.string "mentor_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "mentor"], name: "index_course_mentor_mapping_on_course_and_mentor", unique: true
    t.index ["course"], name: "index_lms_course_mentor_mappings_on_course"
    t.index ["creation"], name: "index_lms_course_mentor_mappings_on_creation"
    t.index ["mentor", "course"], name: "index_lms_course_mentor_mappings_on_mentor_and_course"
    t.index ["mentor"], name: "index_lms_course_mentor_mappings_on_mentor"
    t.index ["mentor_name"], name: "index_lms_course_mentor_mappings_on_mentor_name"
    t.index ["modified"], name: "index_lms_course_mentor_mappings_on_modified"
  end

  create_table "lms_course_progresses", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "member"
    t.string "member_name"
    t.string "status", null: false
    t.string "lesson"
    t.string "chapter"
    t.string "course"
    t.boolean "is_scorm_chapter", default: false
    t.text "scorm_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter", "lesson"], name: "index_course_prog_on_chapter_and_lesson"
    t.index ["chapter"], name: "index_lms_course_progresses_on_chapter"
    t.index ["course", "status"], name: "index_course_prog_on_course_and_status"
    t.index ["course"], name: "index_lms_course_progresses_on_course"
    t.index ["creation"], name: "index_lms_course_progresses_on_creation"
    t.index ["is_scorm_chapter"], name: "index_lms_course_progresses_on_is_scorm_chapter"
    t.index ["lesson"], name: "index_lms_course_progresses_on_lesson"
    t.index ["member", "chapter", "lesson"], name: "index_course_prog_on_member_chapter_lesson"
    t.index ["member", "course"], name: "index_course_prog_on_member_and_course"
    t.index ["member", "status"], name: "index_course_prog_on_member_and_status"
    t.index ["member"], name: "index_lms_course_progresses_on_member"
    t.index ["modified"], name: "index_lms_course_progresses_on_modified"
    t.index ["status"], name: "index_lms_course_progresses_on_status"
  end

  create_table "lms_course_reviews", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.text "review"
    t.integer "rating", null: false
    t.string "course", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "creation"], name: "index_course_review_on_course_and_creation"
    t.index ["course", "rating"], name: "index_course_review_on_course_and_rating"
    t.index ["course"], name: "index_lms_course_reviews_on_course"
    t.index ["creation"], name: "index_lms_course_reviews_on_creation"
    t.index ["modified"], name: "index_lms_course_reviews_on_modified"
    t.index ["rating"], name: "index_lms_course_reviews_on_rating"
  end

  create_table "lms_courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "short_introduction"
    t.string "category"
    t.string "status", default: "Draft"
    t.string "video_link"
    t.string "image"
    t.text "tags"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.boolean "published", default: false
    t.boolean "featured", default: false
    t.boolean "allow_self_enrollment", default: true
    t.boolean "require_approval", default: false
    t.integer "max_students", default: 0
    t.integer "duration_hours", default: 0
    t.string "difficulty_level", default: "Beginner"
    t.string "language", default: "English"
    t.text "prerequisites"
    t.text "learning_objectives"
    t.text "target_audience"
    t.string "instructor_name"
    t.integer "instructor_id"
    t.integer "enrollments_count", default: 0
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.integer "reviews_count", default: 0
    t.datetime "published_at"
    t.datetime "last_updated_on"
    t.text "metadata"
    t.string "course_code"
    t.boolean "certificate_enabled", default: false
    t.text "seo_title"
    t.text "seo_description"
    t.string "slug"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "upcoming"
    t.integer "evaluator_id"
    t.string "workflow_state"
    t.index ["category", "published"], name: "index_lms_courses_on_category_and_published"
    t.index ["category"], name: "index_lms_courses_on_category"
    t.index ["course_code"], name: "index_lms_courses_on_course_code", unique: true
    t.index ["difficulty_level"], name: "index_lms_courses_on_difficulty_level"
    t.index ["enrollments_count"], name: "index_lms_courses_on_enrollments_count"
    t.index ["featured"], name: "index_lms_courses_on_featured"
    t.index ["instructor_id", "published"], name: "index_lms_courses_on_instructor_and_published"
    t.index ["instructor_id"], name: "index_lms_courses_on_instructor_id"
    t.index ["language"], name: "index_lms_courses_on_language"
    t.index ["price"], name: "index_lms_courses_on_price"
    t.index ["published", "featured"], name: "index_lms_courses_on_published_and_featured"
    t.index ["published"], name: "index_lms_courses_on_published"
    t.index ["published_at"], name: "index_lms_courses_on_published_at"
    t.index ["rating"], name: "index_lms_courses_on_rating"
    t.index ["slug"], name: "index_lms_courses_on_slug", unique: true
    t.index ["sort_order"], name: "index_lms_courses_on_sort_order"
    t.index ["status"], name: "index_lms_courses_on_status"
    t.index ["title"], name: "index_lms_courses_on_title"
    t.index ["updated_at"], name: "index_lms_courses_on_updated_at"
  end

  create_table "lms_enrollments", force: :cascade do |t|
    t.integer "student_id", null: false
    t.integer "course_id", null: false
    t.integer "batch_id"
    t.string "enrollment_number", null: false
    t.string "status", default: "Active"
    t.datetime "enrollment_date", null: false
    t.datetime "completion_date"
    t.decimal "progress_percentage", precision: 5, scale: 2, default: "0.0"
    t.integer "lessons_completed", default: 0
    t.integer "total_lessons", default: 0
    t.decimal "grade_obtained", precision: 5, scale: 2
    t.decimal "passing_percentage", precision: 5, scale: 2, default: "70.0"
    t.boolean "passed", default: false
    t.string "certificate_number"
    t.datetime "certificate_issued_date"
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.string "payment_status", default: "Pending"
    t.string "payment_method"
    t.datetime "payment_date"
    t.string "transaction_id"
    t.text "enrollment_notes"
    t.text "special_requirements"
    t.integer "approved_by_id"
    t.datetime "approval_date"
    t.string "rejection_reason"
    t.boolean "send_email_notifications", default: true
    t.datetime "last_access_date"
    t.integer "total_time_spent_minutes", default: 0
    t.text "progress_details"
    t.text "quiz_scores"
    t.text "assignment_scores"
    t.boolean "feedback_provided", default: false
    t.text "feedback"
    t.integer "rating"
    t.datetime "feedback_date"
    t.string "enrollment_type", default: "Regular"
    t.text "corporate_details"
    t.datetime "expiry_date"
    t.boolean "auto_renewal", default: false
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_lesson"
    t.string "role", default: "Member"
    t.index ["approved_by_id"], name: "index_lms_enrollments_on_approved_by_id"
    t.index ["batch_id"], name: "index_lms_enrollments_on_batch_id"
    t.index ["certificate_number"], name: "index_lms_enrollments_on_certificate_number"
    t.index ["completion_date"], name: "index_lms_enrollments_on_completion_date"
    t.index ["course_id", "created_at"], name: "index_lms_enrollments_on_course_and_created_at"
    t.index ["course_id", "status"], name: "index_lms_enrollments_on_course_id_and_status"
    t.index ["course_id"], name: "index_lms_enrollments_on_course_id"
    t.index ["enrollment_date"], name: "index_lms_enrollments_on_enrollment_date"
    t.index ["enrollment_number"], name: "index_lms_enrollments_on_enrollment_number", unique: true
    t.index ["enrollment_type"], name: "index_lms_enrollments_on_enrollment_type"
    t.index ["expiry_date"], name: "index_lms_enrollments_on_expiry_date"
    t.index ["last_access_date"], name: "index_lms_enrollments_on_last_access_date"
    t.index ["payment_status"], name: "index_lms_enrollments_on_payment_status"
    t.index ["progress_percentage"], name: "index_lms_enrollments_on_progress_percentage"
    t.index ["role"], name: "index_lms_enrollments_on_role"
    t.index ["status", "enrollment_date"], name: "index_lms_enrollments_on_status_and_enrollment_date"
    t.index ["status"], name: "index_lms_enrollments_on_status"
    t.index ["student_id", "course_id"], name: "index_lms_enrollments_on_student_id_and_course_id", unique: true
    t.index ["student_id", "status"], name: "index_lms_enrollments_on_student_id_and_status"
    t.index ["student_id"], name: "index_lms_enrollments_on_student_id"
  end

  create_table "lms_exercises", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "code"
    t.text "answer"
    t.text "hints"
    t.text "tests"
    t.text "image"
    t.integer "index_"
    t.string "index_label"
    t.string "course"
    t.string "lesson"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_lms_exercises_on_name", unique: true
    t.index ["title"], name: "index_lms_exercises_on_title"
  end

  create_table "lms_files", force: :cascade do |t|
    t.string "file_name", null: false
    t.string "file_url", null: false
    t.string "file_type"
    t.integer "file_size"
    t.string "content_hash"
    t.boolean "is_private", default: false
    t.boolean "is_folder", default: false
    t.integer "folder_id"
    t.boolean "is_home_folder", default: false
    t.boolean "is_attachments_folder", default: false
    t.string "attached_to_doctype"
    t.string "attached_to_name"
    t.string "attached_to_field"
    t.integer "uploaded_by_id"
    t.datetime "uploaded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attached_to_doctype", "attached_to_name"], name: "index_lms_files_on_attached_to_doctype_and_attached_to_name"
    t.index ["file_url"], name: "index_lms_files_on_file_url"
    t.index ["uploaded_by_id"], name: "index_lms_files_on_uploaded_by_id"
  end

  create_table "lms_lesson_notes", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "lesson", null: false
    t.string "course"
    t.string "member", null: false
    t.string "color", null: false
    t.text "highlighted_text"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color"], name: "index_lms_lesson_notes_on_color"
    t.index ["course", "member"], name: "index_lesson_note_on_course_and_member"
    t.index ["course"], name: "index_lms_lesson_notes_on_course"
    t.index ["creation"], name: "index_lms_lesson_notes_on_creation"
    t.index ["lesson"], name: "index_lms_lesson_notes_on_lesson"
    t.index ["member", "lesson"], name: "index_lesson_note_on_member_and_lesson", unique: true
    t.index ["member"], name: "index_lms_lesson_notes_on_member"
    t.index ["modified"], name: "index_lms_lesson_notes_on_modified"
  end

  create_table "lms_live_class_participants", force: :cascade do |t|
    t.string "live_class", null: false
    t.string "member", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at", null: false
    t.integer "duration", null: false
    t.string "member_name"
    t.string "member_image"
    t.string "member_username"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_class"], name: "index_lms_live_class_participants_on_live_class"
    t.index ["member"], name: "index_lms_live_class_participants_on_member"
    t.index ["name"], name: "index_lms_live_class_participants_on_name", unique: true
  end

  create_table "lms_live_classes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.date "date", null: false
    t.time "time", null: false
    t.integer "duration", null: false
    t.string "timezone", null: false
    t.string "password"
    t.string "host", null: false
    t.string "batch_name"
    t.string "zoom_account", null: false
    t.string "event"
    t.string "auto_recording", default: "No Recording"
    t.string "meeting_id"
    t.string "uuid"
    t.integer "attendees", default: 0
    t.text "start_url"
    t.text "join_url"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batch_id"
    t.index ["batch_id", "date"], name: "index_lms_live_classes_on_batch_and_date"
    t.index ["date"], name: "index_lms_live_classes_on_date"
    t.index ["host"], name: "index_lms_live_classes_on_host"
    t.index ["name"], name: "index_lms_live_classes_on_name", unique: true
    t.index ["title"], name: "index_lms_live_classes_on_title"
  end

  create_table "lms_mentor_requests", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "member"
    t.string "course"
    t.string "reviewed_by"
    t.string "member_name"
    t.string "status", default: "Pending"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course", "status"], name: "index_mentor_req_on_course_and_status"
    t.index ["course"], name: "index_lms_mentor_requests_on_course"
    t.index ["creation"], name: "index_lms_mentor_requests_on_creation"
    t.index ["member", "course"], name: "index_mentor_req_on_member_and_course", unique: true
    t.index ["member", "status"], name: "index_mentor_req_on_member_and_status"
    t.index ["member"], name: "index_lms_mentor_requests_on_member"
    t.index ["modified"], name: "index_lms_mentor_requests_on_modified"
    t.index ["reviewed_by"], name: "index_lms_mentor_requests_on_reviewed_by"
    t.index ["status"], name: "index_lms_mentor_requests_on_status"
  end

  create_table "lms_options", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "option"
    t.boolean "is_correct", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_options_on_creation"
    t.index ["is_correct"], name: "index_lms_options_on_is_correct"
    t.index ["modified"], name: "index_lms_options_on_modified"
    t.index ["option"], name: "index_lms_options_on_option"
    t.index ["parent", "is_correct"], name: "index_lms_options_on_parent_and_is_correct"
    t.index ["parent", "parenttype", "parentfield"], name: "index_options_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lms_options_on_parent"
    t.index ["parentfield"], name: "index_lms_options_on_parentfield"
    t.index ["parenttype"], name: "index_lms_options_on_parenttype"
  end

  create_table "lms_payments", force: :cascade do |t|
    t.string "payment_number", null: false
    t.integer "student_id", null: false
    t.integer "enrollment_id"
    t.integer "course_id"
    t.integer "batch_id"
    t.integer "program_id"
    t.string "payment_type", default: "Course Enrollment"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD"
    t.string "status", default: "Pending"
    t.string "payment_method"
    t.string "gateway"
    t.string "transaction_id"
    t.string "gateway_response"
    t.text "gateway_response_data"
    t.datetime "payment_date"
    t.datetime "due_date"
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.decimal "balance_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.string "discount_code"
    t.integer "discount_applied_id"
    t.string "billing_name"
    t.string "billing_email"
    t.string "billing_phone"
    t.text "billing_address"
    t.string "billing_city"
    t.string "billing_state"
    t.string "billing_country"
    t.string "billing_postal_code"
    t.string "payment_description"
    t.text "payment_notes"
    t.integer "processed_by_id"
    t.text "refund_details"
    t.decimal "refund_amount", precision: 10, scale: 2, default: "0.0"
    t.string "refund_reason"
    t.datetime "refund_date"
    t.integer "refund_processed_by_id"
    t.string "invoice_number"
    t.datetime "invoice_date"
    t.text "invoice_details"
    t.boolean "recurring_payment", default: false
    t.string "recurring_frequency"
    t.datetime "next_payment_date"
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_lms_payments_on_amount"
    t.index ["amount_paid"], name: "index_lms_payments_on_amount_paid"
    t.index ["balance_amount"], name: "index_lms_payments_on_balance_amount"
    t.index ["batch_id"], name: "index_lms_payments_on_batch_id"
    t.index ["course_id", "student_id"], name: "index_lms_payments_on_course_id_and_student_id"
    t.index ["course_id"], name: "index_lms_payments_on_course_id"
    t.index ["currency"], name: "index_lms_payments_on_currency"
    t.index ["discount_applied_id"], name: "index_lms_payments_on_discount_applied_id"
    t.index ["discount_code"], name: "index_lms_payments_on_discount_code"
    t.index ["due_date"], name: "index_lms_payments_on_due_date"
    t.index ["enrollment_id", "student_id"], name: "index_lms_payments_on_enrollment_id_and_student_id"
    t.index ["enrollment_id"], name: "index_lms_payments_on_enrollment_id"
    t.index ["gateway", "status"], name: "index_lms_payments_on_gateway_and_status"
    t.index ["gateway"], name: "index_lms_payments_on_gateway"
    t.index ["invoice_number"], name: "index_lms_payments_on_invoice_number"
    t.index ["payment_date"], name: "index_lms_payments_on_payment_date"
    t.index ["payment_method"], name: "index_lms_payments_on_payment_method"
    t.index ["payment_number"], name: "index_lms_payments_on_payment_number", unique: true
    t.index ["payment_type", "status"], name: "index_lms_payments_on_payment_type_and_status"
    t.index ["payment_type"], name: "index_lms_payments_on_payment_type"
    t.index ["processed_by_id"], name: "index_lms_payments_on_processed_by_id"
    t.index ["program_id"], name: "index_lms_payments_on_program_id"
    t.index ["refund_amount"], name: "index_lms_payments_on_refund_amount"
    t.index ["refund_processed_by_id"], name: "index_lms_payments_on_refund_processed_by_id"
    t.index ["status", "payment_date"], name: "index_lms_payments_on_status_and_payment_date"
    t.index ["status"], name: "index_lms_payments_on_status"
    t.index ["student_id", "status"], name: "index_lms_payments_on_student_id_and_status"
    t.index ["student_id"], name: "index_lms_payments_on_student_id"
    t.index ["transaction_id"], name: "index_lms_payments_on_transaction_id"
  end

  create_table "lms_program_courses", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", default: "LMS Program", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "course", null: false
    t.string "course_title"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_lms_program_courses_on_course"
    t.index ["name"], name: "index_lms_program_courses_on_name", unique: true
    t.index ["parent"], name: "index_lms_program_courses_on_parent"
  end

  create_table "lms_program_members", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", default: "LMS Program", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "member", null: false
    t.string "full_name"
    t.integer "progress", default: 0
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member"], name: "index_lms_program_members_on_member"
    t.index ["name"], name: "index_lms_program_members_on_name", unique: true
    t.index ["parent"], name: "index_lms_program_members_on_parent"
  end

  create_table "lms_programming_exercise_submissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "exercise", null: false
    t.string "exercise_title", null: false
    t.string "status"
    t.string "member", null: false
    t.string "member_name", null: false
    t.string "member_image"
    t.text "code", null: false
    t.string "test_cases"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_programming_exercise_submissions_on_creation"
    t.index ["exercise", "member"], name: "index_prog_exercise_sub_on_exercise_and_member", unique: true
    t.index ["exercise"], name: "index_lms_programming_exercise_submissions_on_exercise"
    t.index ["member", "status"], name: "index_lms_programming_exercise_submissions_on_member_and_status"
    t.index ["member"], name: "index_lms_programming_exercise_submissions_on_member"
    t.index ["modified"], name: "index_lms_programming_exercise_submissions_on_modified"
    t.index ["status"], name: "index_lms_programming_exercise_submissions_on_status"
  end

  create_table "lms_programming_exercises", force: :cascade do |t|
    t.string "title", null: false
    t.string "language", default: "Python", null: false
    t.text "problem_statement", null: false
    t.text "test_cases"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["language"], name: "index_lms_programming_exercises_on_language"
    t.index ["name"], name: "index_lms_programming_exercises_on_name", unique: true
    t.index ["title"], name: "index_lms_programming_exercises_on_title"
  end

  create_table "lms_programs", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "published", default: false
    t.boolean "enforce_course_order", default: false
    t.integer "course_count", default: 0
    t.integer "member_count", default: 0
    t.text "program_courses"
    t.text "program_members"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enforce_course_order"], name: "index_lms_programs_on_enforce_course_order"
    t.index ["name"], name: "index_lms_programs_on_name", unique: true
    t.index ["published"], name: "index_lms_programs_on_published"
    t.index ["title"], name: "index_lms_programs_on_title", unique: true
  end

  create_table "lms_questions", force: :cascade do |t|
    t.text "question", null: false
    t.string "type", default: "Choices", null: false
    t.boolean "multiple", default: false
    t.string "option_1"
    t.boolean "is_correct_1", default: false
    t.string "explanation_1"
    t.string "option_2"
    t.boolean "is_correct_2", default: false
    t.string "explanation_2"
    t.string "option_3"
    t.boolean "is_correct_3", default: false
    t.string "explanation_3"
    t.string "option_4"
    t.boolean "is_correct_4", default: false
    t.string "explanation_4"
    t.string "possibility_1"
    t.string "possibility_2"
    t.string "possibility_3"
    t.string "possibility_4"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_lms_questions_on_type"
  end

  create_table "lms_quiz_questions", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "question_id", null: false
    t.integer "position", default: 0
    t.decimal "marks", precision: 5, scale: 2, default: "1.0"
    t.decimal "negative_marks", precision: 5, scale: 2, default: "0.0"
    t.boolean "mandatory", default: false
    t.text "question_override"
    t.text "options_override"
    t.string "correct_answer_override"
    t.text "explanation_override"
    t.boolean "shuffle_options", default: false
    t.integer "time_limit_seconds", default: 0
    t.text "custom_instructions"
    t.text "reference_material"
    t.boolean "show_explanation", default: true
    t.integer "attempts_allowed", default: 1
    t.text "validation_rules"
    t.text "hints"
    t.boolean "is_active", default: true
    t.datetime "added_at"
    t.integer "added_by_id"
    t.text "notes"
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_at"], name: "index_lms_quiz_questions_on_added_at"
    t.index ["added_by_id"], name: "index_lms_quiz_questions_on_added_by_id"
    t.index ["is_active"], name: "index_lms_quiz_questions_on_is_active"
    t.index ["mandatory", "position"], name: "index_lms_quiz_questions_on_mandatory_and_position"
    t.index ["mandatory"], name: "index_lms_quiz_questions_on_mandatory"
    t.index ["marks"], name: "index_lms_quiz_questions_on_marks"
    t.index ["position"], name: "index_lms_quiz_questions_on_position"
    t.index ["question_id", "is_active"], name: "index_lms_quiz_questions_on_question_id_and_is_active"
    t.index ["question_id"], name: "index_lms_quiz_questions_on_question_id"
    t.index ["quiz_id", "is_active"], name: "index_lms_quiz_questions_on_quiz_id_and_is_active"
    t.index ["quiz_id", "position"], name: "index_lms_quiz_questions_on_quiz_id_and_position", unique: true
    t.index ["quiz_id", "question_id"], name: "index_lms_quiz_questions_on_quiz_id_and_question_id", unique: true
    t.index ["quiz_id"], name: "index_lms_quiz_questions_on_quiz_id"
  end

  create_table "lms_quiz_results", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.text "question", null: false
    t.text "answer", null: false
    t.boolean "is_correct", default: false
    t.string "question_name"
    t.integer "marks"
    t.integer "marks_out_of"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_quiz_results_on_creation"
    t.index ["is_correct"], name: "index_lms_quiz_results_on_is_correct"
    t.index ["marks"], name: "index_lms_quiz_results_on_marks"
    t.index ["marks_out_of"], name: "index_lms_quiz_results_on_marks_out_of"
    t.index ["modified"], name: "index_lms_quiz_results_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_quiz_results_on_parent_and_type_and_field"
    t.index ["parent", "question_name"], name: "index_lms_quiz_results_on_parent_and_question_name"
    t.index ["parent"], name: "index_lms_quiz_results_on_parent"
    t.index ["parentfield"], name: "index_lms_quiz_results_on_parentfield"
    t.index ["parenttype"], name: "index_lms_quiz_results_on_parenttype"
    t.index ["question_name", "is_correct"], name: "index_lms_quiz_results_on_question_name_and_is_correct"
    t.index ["question_name"], name: "index_lms_quiz_results_on_question_name"
  end

  create_table "lms_quiz_submissions", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "student_id", null: false
    t.integer "enrollment_id"
    t.string "submission_code", null: false
    t.integer "attempt_number", default: 1
    t.string "status", default: "In Progress"
    t.datetime "start_time", null: false
    t.datetime "end_time"
    t.integer "duration_seconds", default: 0
    t.decimal "total_marks", precision: 10, scale: 2, default: "0.0"
    t.decimal "maximum_marks", precision: 10, scale: 2, default: "0.0"
    t.decimal "percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "passing_percentage", precision: 5, scale: 2, default: "70.0"
    t.boolean "passed", default: false
    t.integer "correct_answers", default: 0
    t.integer "incorrect_answers", default: 0
    t.integer "unanswered_questions", default: 0
    t.integer "partial_credit_questions", default: 0
    t.text "answers"
    t.text "answer_details"
    t.text "question_scores"
    t.text "feedback"
    t.text "question_feedback"
    t.boolean "auto_graded", default: false
    t.datetime "graded_at"
    t.integer "graded_by_id"
    t.text "grading_notes"
    t.boolean "review_allowed", default: true
    t.datetime "review_start_time"
    t.datetime "review_end_time"
    t.boolean "review_completed", default: false
    t.datetime "review_completed_at"
    t.text "review_notes"
    t.string "ip_address"
    t.string "user_agent"
    t.text "suspicious_activity"
    t.boolean "integrity_check_passed", default: true
    t.text "integrity_check_details"
    t.text "time_log"
    t.integer "tab_switches", default: 0
    t.boolean "window_focus_lost", default: false
    t.text "technical_issues"
    t.boolean "late_submission", default: false
    t.datetime "late_submission_reason"
    t.boolean "extension_granted", default: false
    t.integer "extension_minutes", default: 0
    t.text "extension_reason"
    t.integer "extension_approved_by_id"
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_lms_quiz_submissions_on_created_at"
    t.index ["end_time"], name: "index_lms_quiz_submissions_on_end_time"
    t.index ["enrollment_id"], name: "index_lms_quiz_submissions_on_enrollment_id"
    t.index ["extension_approved_by_id"], name: "index_lms_quiz_submissions_on_extension_approved_by_id"
    t.index ["graded_at"], name: "index_lms_quiz_submissions_on_graded_at"
    t.index ["graded_by_id"], name: "index_lms_quiz_submissions_on_graded_by_id"
    t.index ["late_submission"], name: "index_lms_quiz_submissions_on_late_submission"
    t.index ["passed"], name: "index_lms_quiz_submissions_on_passed"
    t.index ["percentage"], name: "index_lms_quiz_submissions_on_percentage"
    t.index ["quiz_id", "status"], name: "index_lms_quiz_submissions_on_quiz_id_and_status"
    t.index ["quiz_id", "student_id", "attempt_number"], name: "idx_on_quiz_id_student_id_attempt_number_4670806a17", unique: true
    t.index ["quiz_id", "student_id"], name: "index_lms_quiz_submissions_on_quiz_id_and_student_id"
    t.index ["quiz_id"], name: "index_lms_quiz_submissions_on_quiz_id"
    t.index ["review_completed"], name: "index_lms_quiz_submissions_on_review_completed"
    t.index ["start_time"], name: "index_lms_quiz_submissions_on_start_time"
    t.index ["status", "start_time"], name: "index_lms_quiz_submissions_on_status_and_start_time"
    t.index ["status"], name: "index_lms_quiz_submissions_on_status"
    t.index ["student_id", "quiz_id"], name: "index_lms_quiz_submissions_on_student_id_and_quiz_id"
    t.index ["student_id", "status"], name: "index_lms_quiz_submissions_on_student_id_and_status"
    t.index ["student_id"], name: "index_lms_quiz_submissions_on_student_id"
    t.index ["submission_code"], name: "index_lms_quiz_submissions_on_submission_code", unique: true
    t.index ["total_marks"], name: "index_lms_quiz_submissions_on_total_marks"
  end

  create_table "lms_quizzes", force: :cascade do |t|
    t.string "title", null: false
    t.integer "course_id", null: false
    t.integer "chapter_id"
    t.text "description"
    t.string "quiz_code"
    t.string "status", default: "Draft"
    t.string "quiz_type", default: "Graded"
    t.decimal "total_marks", precision: 10, scale: 2, default: "100.0"
    t.decimal "passing_percentage", precision: 5, scale: 2, default: "70.0"
    t.integer "duration_minutes", default: 60
    t.integer "max_attempts", default: 1
    t.boolean "allow_review", default: true
    t.boolean "show_correct_answers", default: true
    t.boolean "shuffle_questions", default: false
    t.boolean "shuffle_options", default: false
    t.boolean "randomize_questions", default: false
    t.integer "random_question_count", default: 0
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean "time_bound", default: false
    t.string "access_code"
    t.boolean "require_password", default: false
    t.string "password"
    t.text "instructions"
    t.text "completion_message"
    t.text "feedback_settings"
    t.integer "questions_count", default: 0
    t.decimal "average_score", precision: 5, scale: 2, default: "0.0"
    t.integer "total_attempts", default: 0
    t.decimal "success_rate", precision: 5, scale: 2, default: "0.0"
    t.boolean "certificate_enabled", default: false
    t.string "certificate_template"
    t.boolean "auto_grade", default: true
    t.text "grading_criteria"
    t.boolean "allow_partial_credit", default: true
    t.decimal "negative_marking_percentage", precision: 5, scale: 2, default: "0.0"
    t.boolean "show_results_immediately", default: true
    t.datetime "published_at"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "sort_order", default: 0
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "creator"
    t.index ["average_score"], name: "index_lms_quizzes_on_average_score"
    t.index ["chapter_id", "status"], name: "index_lms_quizzes_on_chapter_id_and_status"
    t.index ["chapter_id"], name: "index_lms_quizzes_on_chapter_id"
    t.index ["course_id", "status"], name: "index_lms_quizzes_on_course_id_and_status"
    t.index ["course_id"], name: "index_lms_quizzes_on_course_id"
    t.index ["created_by_id"], name: "index_lms_quizzes_on_created_by_id"
    t.index ["creator"], name: "index_lms_quizzes_on_creator"
    t.index ["duration_minutes"], name: "index_lms_quizzes_on_duration_minutes"
    t.index ["end_date"], name: "index_lms_quizzes_on_end_date"
    t.index ["name"], name: "index_lms_quizzes_on_name", unique: true
    t.index ["passing_percentage"], name: "index_lms_quizzes_on_passing_percentage"
    t.index ["published_at"], name: "index_lms_quizzes_on_published_at"
    t.index ["quiz_code"], name: "index_lms_quizzes_on_quiz_code", unique: true
    t.index ["quiz_type", "status"], name: "index_lms_quizzes_on_quiz_type_and_status"
    t.index ["quiz_type"], name: "index_lms_quizzes_on_quiz_type"
    t.index ["sort_order"], name: "index_lms_quizzes_on_sort_order"
    t.index ["start_date"], name: "index_lms_quizzes_on_start_date"
    t.index ["status", "start_date"], name: "index_lms_quizzes_on_status_and_start_date"
    t.index ["status"], name: "index_lms_quizzes_on_status"
    t.index ["success_rate"], name: "index_lms_quizzes_on_success_rate"
    t.index ["title"], name: "index_lms_quizzes_on_title"
    t.index ["total_marks"], name: "index_lms_quizzes_on_total_marks"
    t.index ["updated_by_id"], name: "index_lms_quizzes_on_updated_by_id"
  end

  create_table "lms_settings", force: :cascade do |t|
    t.string "enable_learner_dashboard", default: "1"
    t.string "enable_moderator_dashboard", default: "1"
    t.string "enable_course_creation", default: "1"
    t.string "default_course_category"
    t.string "enable_certificates", default: "1"
    t.string "enable_badges", default: "1"
    t.string "enable_discussions", default: "1"
    t.string "enable_live_classes", default: "1"
    t.string "enable_assignments", default: "1"
    t.string "enable_quizzes", default: "1"
    t.string "enable_programs", default: "1"
    t.string "enable_cohorts", default: "1"
    t.string "zoom_api_key"
    t.text "zoom_api_secret"
    t.string "default_currency"
    t.string "payment_gateway_settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_course_category"], name: "index_lms_settings_on_default_course_category"
    t.index ["enable_course_creation"], name: "index_lms_settings_on_enable_course_creation"
    t.index ["enable_learner_dashboard"], name: "index_lms_settings_on_enable_learner_dashboard"
  end

  create_table "lms_sidebar_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "web_page", null: false
    t.string "title"
    t.string "icon", null: false
    t.string "route"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_sidebar_items_on_creation"
    t.index ["icon"], name: "index_lms_sidebar_items_on_icon"
    t.index ["modified"], name: "index_lms_sidebar_items_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_sidebar_items_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lms_sidebar_items_on_parent"
    t.index ["parentfield"], name: "index_lms_sidebar_items_on_parentfield"
    t.index ["parenttype"], name: "index_lms_sidebar_items_on_parenttype"
    t.index ["route"], name: "index_lms_sidebar_items_on_route"
    t.index ["title"], name: "index_lms_sidebar_items_on_title"
    t.index ["web_page", "title"], name: "index_lms_sidebar_items_on_web_page_and_title"
    t.index ["web_page"], name: "index_lms_sidebar_items_on_web_page"
  end

  create_table "lms_sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_sources_on_creation"
    t.index ["modified"], name: "index_lms_sources_on_modified"
    t.index ["source"], name: "index_lms_sources_on_source", unique: true
  end

  create_table "lms_test_case_submissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "input"
    t.string "expected_output", null: false
    t.string "output", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_test_case_submissions_on_creation"
    t.index ["modified"], name: "index_lms_test_case_submissions_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_test_case_sub_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lms_test_case_submissions_on_parent"
    t.index ["parentfield"], name: "index_lms_test_case_submissions_on_parentfield"
    t.index ["parenttype"], name: "index_lms_test_case_submissions_on_parenttype"
    t.index ["status"], name: "index_lms_test_case_submissions_on_status"
  end

  create_table "lms_test_cases", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", default: "LMS Programming Exercise", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "input", null: false
    t.string "expected_output", null: false
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expected_output"], name: "index_lms_test_cases_on_expected_output"
    t.index ["input"], name: "index_lms_test_cases_on_input"
    t.index ["name"], name: "index_lms_test_cases_on_name", unique: true
    t.index ["parent"], name: "index_lms_test_cases_on_parent"
  end

  create_table "lms_timetable_legends", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "reference_doctype", null: false
    t.string "label", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color"], name: "index_lms_timetable_legends_on_color"
    t.index ["creation"], name: "index_lms_timetable_legends_on_creation"
    t.index ["label"], name: "index_lms_timetable_legends_on_label"
    t.index ["modified"], name: "index_lms_timetable_legends_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_timetable_legends_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_lms_timetable_legends_on_parent"
    t.index ["parentfield"], name: "index_lms_timetable_legends_on_parentfield"
    t.index ["parenttype"], name: "index_lms_timetable_legends_on_parenttype"
    t.index ["reference_doctype", "color"], name: "index_lms_timetable_legends_on_reference_doctype_and_color"
    t.index ["reference_doctype", "label"], name: "index_lms_timetable_legends_on_reference_doctype_and_label"
    t.index ["reference_doctype"], name: "index_lms_timetable_legends_on_reference_doctype"
  end

  create_table "lms_timetable_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "title"
    t.string "timetable"
    t.string "timetable_legends"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_lms_timetable_templates_on_creation"
    t.index ["modified"], name: "index_lms_timetable_templates_on_modified"
    t.index ["title"], name: "index_lms_timetable_templates_on_title"
  end

  create_table "lms_video_watch_durations", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "lesson", null: false
    t.string "chapter"
    t.string "course"
    t.string "member", null: false
    t.string "member_name"
    t.string "member_image"
    t.string "member_username"
    t.string "source", null: false
    t.string "watch_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter"], name: "index_lms_video_watch_durations_on_chapter"
    t.index ["course", "member"], name: "index_video_watch_on_course_and_member"
    t.index ["course"], name: "index_lms_video_watch_durations_on_course"
    t.index ["creation"], name: "index_lms_video_watch_durations_on_creation"
    t.index ["lesson"], name: "index_lms_video_watch_durations_on_lesson"
    t.index ["member", "lesson"], name: "index_video_watch_on_member_and_lesson", unique: true
    t.index ["member"], name: "index_lms_video_watch_durations_on_member"
    t.index ["modified"], name: "index_lms_video_watch_durations_on_modified"
    t.index ["source"], name: "index_lms_video_watch_durations_on_source"
  end

  create_table "lms_zoom_settings", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.boolean "enabled", default: false
    t.string "account_name", null: false
    t.string "member", null: false
    t.string "member_name"
    t.string "member_image"
    t.string "account_id", null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_lms_zoom_settings_on_account_id"
    t.index ["account_name", "member"], name: "index_lms_zoom_settings_on_account_name_and_member"
    t.index ["account_name"], name: "index_lms_zoom_settings_on_account_name", unique: true
    t.index ["client_id"], name: "index_lms_zoom_settings_on_client_id"
    t.index ["creation"], name: "index_lms_zoom_settings_on_creation"
    t.index ["enabled"], name: "index_lms_zoom_settings_on_enabled"
    t.index ["member", "enabled"], name: "index_lms_zoom_settings_on_member_and_enabled"
    t.index ["member"], name: "index_lms_zoom_settings_on_member"
    t.index ["member_name"], name: "index_lms_zoom_settings_on_member_name"
    t.index ["modified"], name: "index_lms_zoom_settings_on_modified"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.string "message_type", default: "text", null: false
    t.integer "user_id", null: false
    t.integer "discussion_id", null: false
    t.integer "parent_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_id", "created_at"], name: "index_messages_on_discussion_id_and_created_at"
    t.index ["discussion_id"], name: "index_messages_on_discussion_id"
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "subject", null: false
    t.text "email_content"
    t.string "document_type"
    t.string "document_name"
    t.string "notification_type"
    t.string "type"
    t.boolean "read", default: false
    t.datetime "read_at"
    t.string "link"
    t.string "from_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payment_countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_payment_countries_on_country"
    t.index ["creation"], name: "index_payment_countries_on_creation"
    t.index ["modified"], name: "index_payment_countries_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_payment_countries_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_payment_countries_on_parent"
    t.index ["parentfield"], name: "index_payment_countries_on_parentfield"
    t.index ["parenttype"], name: "index_payment_countries_on_parenttype"
  end

  create_table "payment_gateways", force: :cascade do |t|
    t.string "name", null: false
    t.string "gateway_type", null: false
    t.string "status", default: "inactive", null: false
    t.json "settings", default: {}, null: false
    t.boolean "is_primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gateway_type"], name: "index_payment_gateways_on_gateway_type"
    t.index ["is_primary"], name: "index_payment_gateways_on_is_primary"
    t.index ["name"], name: "index_payment_gateways_on_name", unique: true
    t.index ["status"], name: "index_payment_gateways_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "payable_type", null: false
    t.integer "payable_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "Pending", null: false
    t.string "payment_method"
    t.string "transaction_id"
    t.string "gateway_response"
    t.datetime "payment_date"
    t.datetime "refunded_at"
    t.text "refund_reason"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_payments_on_created_at"
    t.index ["gateway_response"], name: "index_payments_on_gateway_response"
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id"
    t.index ["user_id", "status"], name: "index_payments_on_user_id_and_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "doctype"
    t.string "action"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preferred_functions", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "function", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_preferred_functions_on_creation"
    t.index ["function"], name: "index_preferred_functions_on_function"
    t.index ["modified"], name: "index_preferred_functions_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_preferred_functions_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_preferred_functions_on_parent"
    t.index ["parentfield"], name: "index_preferred_functions_on_parentfield"
    t.index ["parenttype"], name: "index_preferred_functions_on_parenttype"
  end

  create_table "preferred_industries", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "industry", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_preferred_industries_on_creation"
    t.index ["industry"], name: "index_preferred_industries_on_industry"
    t.index ["modified"], name: "index_preferred_industries_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_preferred_industries_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_preferred_industries_on_parent"
    t.index ["parentfield"], name: "index_preferred_industries_on_parentfield"
    t.index ["parenttype"], name: "index_preferred_industries_on_parenttype"
  end

  create_table "pwa_install_trackings", force: :cascade do |t|
    t.integer "user_id"
    t.string "action", null: false
    t.string "platform", null: false
    t.text "user_agent"
    t.datetime "timestamp", null: false
    t.string "ip_address"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_pwa_install_trackings_on_action"
    t.index ["platform"], name: "index_pwa_install_trackings_on_platform"
    t.index ["timestamp"], name: "index_pwa_install_trackings_on_timestamp"
    t.index ["user_id", "timestamp"], name: "index_pwa_install_trackings_on_user_id_and_timestamp"
    t.index ["user_id"], name: "index_pwa_install_trackings_on_user_id"
  end

  create_table "related_courses", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "course"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_related_courses_on_course"
    t.index ["creation"], name: "index_related_courses_on_creation"
    t.index ["modified"], name: "index_related_courses_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_related_courses_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_related_courses_on_parent"
    t.index ["parentfield"], name: "index_related_courses_on_parentfield"
    t.index ["parenttype"], name: "index_related_courses_on_parenttype"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "role_name", null: false
    t.text "description"
    t.string "status", default: "Active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
    t.index ["role_name"], name: "index_roles_on_role_name", unique: true
    t.index ["status"], name: "index_roles_on_status"
  end

  create_table "scheduled_flows", force: :cascade do |t|
    t.string "name", null: false
    t.string "owner", null: false
    t.datetime "creation", null: false
    t.datetime "modified", null: false
    t.string "modified_by", null: false
    t.string "docstatus", default: "0"
    t.string "parent"
    t.string "parenttype"
    t.string "parentfield"
    t.integer "idx"
    t.string "lesson", null: false
    t.string "lesson_title", null: false
    t.date "date", null: false
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creation"], name: "index_scheduled_flows_on_creation"
    t.index ["date", "end_time"], name: "index_scheduled_flows_on_date_and_end_time"
    t.index ["date", "start_time"], name: "index_scheduled_flows_on_date_and_start_time"
    t.index ["date"], name: "index_scheduled_flows_on_date"
    t.index ["end_time"], name: "index_scheduled_flows_on_end_time"
    t.index ["lesson"], name: "index_scheduled_flows_on_lesson"
    t.index ["lesson_title"], name: "index_scheduled_flows_on_lesson_title"
    t.index ["modified"], name: "index_scheduled_flows_on_modified"
    t.index ["parent", "parenttype", "parentfield"], name: "index_scheduled_flows_on_parent_and_type_and_field"
    t.index ["parent"], name: "index_scheduled_flows_on_parent"
    t.index ["parentfield"], name: "index_scheduled_flows_on_parentfield"
    t.index ["parenttype"], name: "index_scheduled_flows_on_parenttype"
    t.index ["start_time"], name: "index_scheduled_flows_on_start_time"
  end

  create_table "scorm_completions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "scorm_package_id", null: false
    t.integer "course_lesson_id", null: false
    t.integer "completion_status", default: 0
    t.integer "success_status", default: 0
    t.float "score_raw"
    t.float "score_min"
    t.float "score_max"
    t.integer "total_time"
    t.integer "session_time"
    t.text "suspend_data"
    t.string "location"
    t.json "interactions_data"
    t.json "objectives_data"
    t.json "scorm_data"
    t.datetime "started_at"
    t.datetime "last_accessed_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completion_status"], name: "index_scorm_completions_on_status"
    t.index ["course_lesson_id"], name: "index_scorm_completions_on_course_lesson_id"
    t.index ["course_lesson_id"], name: "index_scorm_completions_on_lesson"
    t.index ["last_accessed_at"], name: "index_scorm_completions_on_access_time"
    t.index ["scorm_package_id"], name: "index_scorm_completions_on_scorm_package_id"
    t.index ["user_id", "scorm_package_id"], name: "unique_user_scorm_completion", unique: true
    t.index ["user_id"], name: "index_scorm_completions_on_user_id"
  end

  create_table "scorm_packages", force: :cascade do |t|
    t.integer "course_lesson_id", null: false
    t.integer "uploaded_by_id", null: false
    t.string "title", null: false
    t.text "manifest_file"
    t.text "launch_file"
    t.string "version"
    t.integer "status", default: 0
    t.text "manifest_content"
    t.text "extracted_path"
    t.text "error_message"
    t.json "metadata"
    t.datetime "extracted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_lesson_id"], name: "index_scorm_packages_on_course_lesson_id"
    t.index ["course_lesson_id"], name: "index_scorm_packages_on_lesson"
    t.index ["status"], name: "index_scorm_packages_on_status"
    t.index ["uploaded_by_id"], name: "index_scorm_packages_on_uploaded_by_id"
    t.index ["uploaded_by_id"], name: "index_scorm_packages_on_uploader"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "category"
    t.string "skill_type", default: "Technical"
    t.integer "proficiency_levels", default: 4
    t.string "default_level", default: "Beginner"
    t.boolean "is_active", default: true
    t.string "icon"
    t.string "color"
    t.text "competency_criteria"
    t.integer "sort_order", default: 0
    t.string "parent_skill"
    t.integer "usage_count", default: 0
    t.text "custom_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_skills_on_category"
    t.index ["is_active"], name: "index_skills_on_is_active"
    t.index ["name"], name: "index_skills_on_name", unique: true
    t.index ["parent_skill"], name: "index_skills_on_parent_skill"
    t.index ["skill_type"], name: "index_skills_on_skill_type"
    t.index ["sort_order"], name: "index_skills_on_sort_order"
    t.index ["usage_count"], name: "index_skills_on_usage_count"
  end

  create_table "user_skills", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "skill_name", null: false
    t.string "proficiency_level", default: "Beginner"
    t.integer "years_of_experience", default: 0
    t.string "last_used"
    t.text "description"
    t.boolean "verified", default: false
    t.string "verified_by"
    t.datetime "verified_on"
    t.text "certifications"
    t.string "skill_level"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proficiency_level"], name: "index_user_skills_on_proficiency_level"
    t.index ["skill_name"], name: "index_user_skills_on_skill_name"
    t.index ["user_id", "skill_name"], name: "index_user_skills_on_user_id_and_skill_name", unique: true
    t.index ["user_id"], name: "index_user_skills_on_user_id"
    t.index ["verified"], name: "index_user_skills_on_verified"
    t.index ["years_of_experience"], name: "index_user_skills_on_years_of_experience"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "full_name"
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "role", default: "LMS Student"
    t.string "status", default: "Active"
    t.string "phone"
    t.string "mobile_no"
    t.date "birth_date"
    t.string "gender"
    t.string "bio"
    t.string "profile_image"
    t.string "timezone", default: "UTC"
    t.string "language", default: "English"
    t.string "country"
    t.string "city"
    t.text "address"
    t.string "postal_code"
    t.string "company"
    t.string "job_title"
    t.string "department"
    t.string "website"
    t.string "linkedin_profile"
    t.string "twitter_profile"
    t.boolean "email_verified", default: false
    t.datetime "email_verified_at"
    t.string "verification_token"
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.datetime "current_login_at"
    t.string "current_login_ip"
    t.integer "login_count", default: 0
    t.boolean "receive_email_notifications", default: true
    t.boolean "receive_sms_notifications", default: false
    t.text "notification_preferences"
    t.text "preferences"
    t.text "skills"
    t.text "interests"
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.integer "reviews_count", default: 0
    t.integer "courses_created_count", default: 0
    t.integer "students_taught_count", default: 0
    t.text "social_links"
    t.text "custom_fields"
    t.datetime "deactivated_at"
    t.string "deactivation_reason"
    t.boolean "is_mentor", default: false
    t.boolean "is_instructor", default: false
    t.boolean "is_admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_moderator", default: false
    t.boolean "is_evaluator", default: false
    t.string "jti"
    t.datetime "persona_captured_at"
    t.string "persona_role"
    t.string "persona_use_case"
    t.text "persona_responses"
    t.string "encrypted_password"
    t.index ["city"], name: "index_users_on_city"
    t.index ["company"], name: "index_users_on_company"
    t.index ["country", "city"], name: "index_users_on_country_and_city"
    t.index ["country"], name: "index_users_on_country"
    t.index ["courses_created_count"], name: "index_users_on_courses_created_count"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verified"], name: "index_users_on_email_verified"
    t.index ["first_name"], name: "index_users_on_first_name"
    t.index ["full_name"], name: "index_users_on_full_name"
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["is_instructor", "rating"], name: "index_users_on_is_instructor_and_rating"
    t.index ["is_instructor"], name: "index_users_on_is_instructor"
    t.index ["is_mentor"], name: "index_users_on_is_mentor"
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["login_count"], name: "index_users_on_login_count"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["rating"], name: "index_users_on_rating"
    t.index ["role", "status"], name: "index_users_on_role_and_status"
    t.index ["role"], name: "index_users_on_role"
    t.index ["status", "last_login_at"], name: "index_users_on_status_and_last_login_at"
    t.index ["status"], name: "index_users_on_status"
    t.index ["students_taught_count"], name: "index_users_on_students_taught_count"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "video_watch_durations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_lesson_id", null: false
    t.string "video_url", null: false
    t.integer "duration_watched", default: 0
    t.integer "video_length", default: 0
    t.integer "last_position", default: 0
    t.json "watch_sessions"
    t.datetime "first_watched_at"
    t.datetime "last_watched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_lesson_id"], name: "index_video_durations_on_course_lesson"
    t.index ["course_lesson_id"], name: "index_video_watch_durations_on_course_lesson_id"
    t.index ["updated_at"], name: "index_video_watch_durations_on_updated_at"
    t.index ["user_id", "course_lesson_id", "video_url"], name: "unique_user_lesson_video", unique: true
    t.index ["user_id", "course_lesson_id"], name: "index_video_watch_durations_on_user_and_lesson"
    t.index ["user_id", "updated_at"], name: "index_video_durations_on_user_time"
    t.index ["user_id"], name: "index_video_watch_durations_on_user_id"
  end

  create_table "work_experiences", force: :cascade do |t|
    t.string "parent", null: false
    t.string "parenttype", default: "User", null: false
    t.integer "parentfield", default: 0, null: false
    t.string "title", null: false
    t.string "company", null: false
    t.string "location", null: false
    t.text "description"
    t.boolean "current", default: false
    t.date "from_date", null: false
    t.date "to_date"
    t.string "name", null: false
    t.string "owner"
    t.datetime "creation"
    t.datetime "modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company"], name: "index_work_experiences_on_company"
    t.index ["current"], name: "index_work_experiences_on_current"
    t.index ["from_date"], name: "index_work_experiences_on_from_date"
    t.index ["location"], name: "index_work_experiences_on_location"
    t.index ["name"], name: "index_work_experiences_on_name", unique: true
    t.index ["parent"], name: "index_work_experiences_on_parent"
    t.index ["title"], name: "index_work_experiences_on_title"
  end

  create_table "workflow_states", force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.string "state"
    t.string "doc_status"
    t.string "allow_edit"
    t.string "next_action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id"], name: "index_workflow_states_on_workflow_id"
  end

  create_table "workflow_transitions", force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.string "state"
    t.string "action"
    t.string "next_state"
    t.string "allowed_roles"
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id"], name: "index_workflow_transitions_on_workflow_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "name"
    t.string "document_type"
    t.boolean "is_active"
    t.text "states"
    t.text "transitions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zoom_settings", force: :cascade do |t|
    t.string "account_name", null: false
    t.string "api_key", null: false
    t.string "api_secret", null: false
    t.string "webhook_secret"
    t.string "account_id", null: false
    t.string "user_id", null: false
    t.string "user_email", null: false
    t.boolean "enabled", default: true
    t.boolean "auto_record_meetings", default: false
    t.string "recording_option", default: "local"
    t.boolean "enable_chat", default: true
    t.boolean "enable_waiting_room", default: true
    t.boolean "enable_breakout_rooms", default: true
    t.boolean "enable_polling", default: true
    t.boolean "enable_annotation", default: true
    t.boolean "enable_remote_control", default: true
    t.boolean "enable_co_host", default: true
    t.boolean "mute_on_entry", default: false
    t.string "default_meeting_duration", default: "60"
    t.string "default_timezone", default: "UTC"
    t.text "meeting_settings"
    t.text "security_settings"
    t.string "alternative_hosts"
    t.boolean "require_password", default: false
    t.string "password_type", default: "numeric"
    t.integer "password_length", default: 6
    t.boolean "enable_join_before_host", default: false
    t.integer "join_before_host_minutes", default: 5
    t.boolean "auto_start_recording", default: false
    t.boolean "auto_stop_recording", default: false
    t.text "recording_settings"
    t.boolean "enable_live_transcription", default: false
    t.string "transcription_language", default: "en-US"
    t.boolean "save_captions", default: false
    t.text "branding_settings"
    t.string "meeting_theme"
    t.boolean "virtual_background_enabled", default: true
    t.text "virtual_background_settings"
    t.datetime "last_sync_at"
    t.string "sync_status", default: "success"
    t.text "sync_error_message"
    t.integer "api_call_count", default: 0
    t.datetime "api_rate_limit_reset_at"
    t.boolean "webhook_enabled", default: false
    t.string "webhook_url"
    t.text "webhook_events"
    t.datetime "last_webhook_received_at"
    t.boolean "test_mode", default: false
    t.text "test_meeting_settings"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_zoom_settings_on_account_id"
    t.index ["account_name", "enabled"], name: "index_zoom_settings_on_account_name_and_enabled"
    t.index ["account_name"], name: "index_zoom_settings_on_account_name", unique: true
    t.index ["api_key"], name: "index_zoom_settings_on_api_key"
    t.index ["auto_record_meetings"], name: "index_zoom_settings_on_auto_record_meetings"
    t.index ["created_by_id"], name: "index_zoom_settings_on_created_by_id"
    t.index ["default_timezone"], name: "index_zoom_settings_on_default_timezone"
    t.index ["enabled", "sync_status"], name: "index_zoom_settings_on_enabled_and_sync_status"
    t.index ["enabled"], name: "index_zoom_settings_on_enabled"
    t.index ["last_sync_at"], name: "index_zoom_settings_on_last_sync_at"
    t.index ["recording_option"], name: "index_zoom_settings_on_recording_option"
    t.index ["sync_status"], name: "index_zoom_settings_on_sync_status"
    t.index ["test_mode"], name: "index_zoom_settings_on_test_mode"
    t.index ["updated_by_id"], name: "index_zoom_settings_on_updated_by_id"
    t.index ["webhook_enabled"], name: "index_zoom_settings_on_webhook_enabled"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "batch_courses", "course_evaluators", column: "evaluator"
  add_foreign_key "batch_courses", "lms_courses", column: "course"
  add_foreign_key "certificate_requests", "evaluators"
  add_foreign_key "certificate_requests", "users"
  add_foreign_key "chapter_references", "course_chapters", column: "chapter"
  add_foreign_key "code_revisions", "users"
  add_foreign_key "course_chapters", "lms_courses", column: "course"
  add_foreign_key "course_evaluators", "users", column: "evaluator"
  add_foreign_key "course_instructors", "users", column: "instructor"
  add_foreign_key "course_lessons", "course_chapters", column: "chapter", primary_key: "name"
  add_foreign_key "course_lessons", "lms_courses", column: "course"
  add_foreign_key "discussions", "courses"
  add_foreign_key "discussions", "users"
  add_foreign_key "exercise_latest_submissions", "cohort_subgroups", column: "member_subgroup"
  add_foreign_key "exercise_latest_submissions", "cohorts", column: "member_cohort"
  add_foreign_key "exercise_latest_submissions", "lms_courses", column: "course"
  add_foreign_key "exercise_latest_submissions", "lms_enrollments", column: "member"
  add_foreign_key "exercise_latest_submissions", "lms_exercises", column: "exercise"
  add_foreign_key "exercise_latest_submissions", "users", column: "member_email"
  add_foreign_key "exercise_submissions", "lms_courses", column: "course"
  add_foreign_key "exercise_submissions", "lms_enrollments", column: "member"
  add_foreign_key "exercise_submissions", "lms_exercises", column: "exercise"
  add_foreign_key "has_roles", "users"
  add_foreign_key "job_opportunities", "users"
  add_foreign_key "lesson_progresses", "course_lessons", column: "lesson_id"
  add_foreign_key "lesson_progresses", "users"
  add_foreign_key "lms_assignment_submissions", "lms_assignments", column: "assignment_id"
  add_foreign_key "lms_assignment_submissions", "lms_enrollments", column: "enrollment_id"
  add_foreign_key "lms_assignment_submissions", "users", column: "graded_by_id"
  add_foreign_key "lms_assignment_submissions", "users", column: "student_id"
  add_foreign_key "lms_assignments", "course_chapters", column: "chapter_id"
  add_foreign_key "lms_assignments", "lms_courses", column: "course_id"
  add_foreign_key "lms_assignments", "users", column: "created_by_id"
  add_foreign_key "lms_assignments", "users", column: "updated_by_id"
  add_foreign_key "lms_badge_assignments", "lms_badges", column: "badge"
  add_foreign_key "lms_badge_assignments", "users", column: "member"
  add_foreign_key "lms_batch_feedbacks", "lms_batches", column: "batch"
  add_foreign_key "lms_batch_feedbacks", "users", column: "member"
  add_foreign_key "lms_batch_olds", "lms_courses", column: "course"
  add_foreign_key "lms_batches", "lms_courses", column: "course_id"
  add_foreign_key "lms_batches", "users", column: "instructor_id"
  add_foreign_key "lms_batches", "users", column: "teaching_assistant_id"
  add_foreign_key "lms_certificates", "lms_assignments", column: "assignment_id"
  add_foreign_key "lms_certificates", "lms_batches", column: "batch_id"
  add_foreign_key "lms_certificates", "lms_courses", column: "course_id"
  add_foreign_key "lms_certificates", "lms_programs", column: "program_id"
  add_foreign_key "lms_certificates", "lms_quizzes", column: "quiz_id"
  add_foreign_key "lms_certificates", "users", column: "issued_by_id"
  add_foreign_key "lms_certificates", "users", column: "revoked_by_id"
  add_foreign_key "lms_certificates", "users", column: "student_id"
  add_foreign_key "lms_course_interests", "lms_courses", column: "course"
  add_foreign_key "lms_course_interests", "users", column: "user"
  add_foreign_key "lms_course_mentor_mappings", "lms_courses", column: "course"
  add_foreign_key "lms_course_mentor_mappings", "users", column: "mentor"
  add_foreign_key "lms_courses", "users", column: "instructor_id"
  add_foreign_key "lms_enrollments", "lms_batches", column: "batch_id"
  add_foreign_key "lms_enrollments", "lms_courses", column: "course_id"
  add_foreign_key "lms_enrollments", "users", column: "approved_by_id"
  add_foreign_key "lms_enrollments", "users", column: "student_id"
  add_foreign_key "lms_lesson_notes", "lms_courses", column: "course"
  add_foreign_key "lms_lesson_notes", "users", column: "member"
  add_foreign_key "lms_mentor_requests", "lms_courses", column: "course"
  add_foreign_key "lms_mentor_requests", "users", column: "member"
  add_foreign_key "lms_mentor_requests", "users", column: "reviewed_by"
  add_foreign_key "lms_payments", "lms_badges", column: "discount_applied_id"
  add_foreign_key "lms_payments", "lms_batches", column: "batch_id"
  add_foreign_key "lms_payments", "lms_courses", column: "course_id"
  add_foreign_key "lms_payments", "lms_enrollments", column: "enrollment_id"
  add_foreign_key "lms_payments", "lms_programs", column: "program_id"
  add_foreign_key "lms_payments", "users", column: "processed_by_id"
  add_foreign_key "lms_payments", "users", column: "refund_processed_by_id"
  add_foreign_key "lms_payments", "users", column: "student_id"
  add_foreign_key "lms_programming_exercise_submissions", "lms_programming_exercises", column: "exercise"
  add_foreign_key "lms_programming_exercise_submissions", "users", column: "member"
  add_foreign_key "lms_quiz_questions", "lms_questions", column: "question_id"
  add_foreign_key "lms_quiz_questions", "lms_quizzes", column: "quiz_id"
  add_foreign_key "lms_quiz_questions", "users", column: "added_by_id"
  add_foreign_key "lms_quiz_results", "lms_questions", column: "question_name"
  add_foreign_key "lms_quiz_submissions", "lms_enrollments", column: "enrollment_id"
  add_foreign_key "lms_quiz_submissions", "lms_quizzes", column: "quiz_id"
  add_foreign_key "lms_quiz_submissions", "users", column: "extension_approved_by_id"
  add_foreign_key "lms_quiz_submissions", "users", column: "graded_by_id"
  add_foreign_key "lms_quiz_submissions", "users", column: "student_id"
  add_foreign_key "lms_quizzes", "course_chapters", column: "chapter_id"
  add_foreign_key "lms_quizzes", "lms_courses", column: "course_id"
  add_foreign_key "lms_quizzes", "users", column: "created_by_id"
  add_foreign_key "lms_quizzes", "users", column: "updated_by_id"
  add_foreign_key "lms_video_watch_durations", "lms_courses", column: "course"
  add_foreign_key "lms_video_watch_durations", "users", column: "member"
  add_foreign_key "lms_zoom_settings", "users", column: "member"
  add_foreign_key "messages", "discussions"
  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "preferred_industries", "industries", column: "industry"
  add_foreign_key "pwa_install_trackings", "users"
  add_foreign_key "related_courses", "lms_courses", column: "course"
  add_foreign_key "scorm_completions", "course_lessons"
  add_foreign_key "scorm_completions", "scorm_packages"
  add_foreign_key "scorm_completions", "users"
  add_foreign_key "scorm_packages", "course_lessons"
  add_foreign_key "scorm_packages", "users", column: "uploaded_by_id"
  add_foreign_key "user_skills", "users"
  add_foreign_key "video_watch_durations", "course_lessons"
  add_foreign_key "video_watch_durations", "users"
  add_foreign_key "workflow_states", "workflows"
  add_foreign_key "workflow_transitions", "workflows"
  add_foreign_key "zoom_settings", "users", column: "created_by_id"
  add_foreign_key "zoom_settings", "users", column: "updated_by_id"
end
