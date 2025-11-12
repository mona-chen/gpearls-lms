#!/usr/bin/env ruby

require_relative 'config/environment'
require 'net/http'
require 'json'

puts '🔬 TESTING ALL 108 FRAPPE LMS ENDPOINTS'
puts '=' * 50

# Create test user and get token
user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.username = "testuser#{Time.now.to_i}"
  u.full_name = 'Test User'
  u.first_name = 'Test'
  u.last_name = 'User'
  u.password = 'password123'
  u.role = 'LMS Student'
  u.status = 'Active'
end

# Generate JWT token (simple JWT encoding to match authentication)
require 'jwt'
payload = {
  sub: user.id,
  jti: SecureRandom.uuid,
  exp: 24.hours.from_now.to_i
}
secret_key = ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base)
token = JWT.encode(payload, secret_key, 'HS256')

puts "Created test user: #{user.email}"
puts "Generated token: #{token[0..20]}..."
puts ''

# Helper method to test endpoints
def test_endpoint(name, method_path, params = {}, token = nil, expect_auth = true)
  begin
    uri = URI('http://localhost:3001/api/method/' + method_path)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{token}" if token

    request.body = params.to_json unless params.empty?

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body) rescue response.body
      if expect_auth && result.is_a?(Hash) && result['message'] == 'Not authenticated'
        '❌ AUTH'
      elsif result.is_a?(Hash) && result.key?('status') && result['status'] == 'error'
        '❌ ERROR'
      else
        '✅ PASS'
      end
    else
      "❌ HTTP#{response.code}"
    end
  rescue => e
    '❌ EXCEPTION'
  end
end

# Complete list of all 108 Frappe LMS endpoints
endpoints = [
  # Core Course Management (8 endpoints)
  [ 'lms.utils.get_my_courses', {} ],
  [ 'lms.utils.get_courses', {} ],
  [ 'lms.utils.get_course_details', { course: '1' } ],
  [ 'lms.utils.get_course_progress_distribution', { course: '1' } ],
  [ 'lms.utils.get_course_completion_data', {} ],
  [ 'lms.utils.get_tags', {} ],
  [ 'lms.utils.get_reviews', {} ],
  [ 'lms.utils.save_current_lesson', {} ],

  # Batch Management (7 endpoints)
  [ 'lms.utils.get_my_batches', {} ],
  [ 'lms.utils.get_batches', {} ],
  [ 'lms.utils.get_batch_students', {} ],
  [ 'lms.utils.get_batch_timetable', {} ],
  [ 'lms.utils.enroll_in_batch', {} ],
  [ 'lms.utils.get_my_live_classes', {} ],
  [ 'lms.utils.get_upcoming_evals', {} ],

  # User Management (5 endpoints)
  [ 'lms.api.get_user_info', {} ],
  [ 'lms.api.get_all_users', {} ],
  [ 'lms.api.get_members', {} ],
  [ 'lms.utils.get_streak_info', {} ],
  [ 'lms.utils.is_onboarding_complete', {} ],

  # Programs (1 endpoint)
  [ 'lms.utils.get_programs', {} ],

  # Certifications (4 endpoints)
  [ 'lms.api.get_certification_categories', {} ],
  [ 'lms.api.get_certified_participants', {} ],
  [ 'lms.api.get_count_of_certified_members', {} ],

  # Payment System (5 endpoints)
  [ 'lms.utils.get_order_summary', {} ],
  [ 'lms.utils.get_payment_link', {} ],
  [ 'lms.utils.validate_billing_access', {} ],
  [ 'lms.api.get_payment_gateway_details', {} ],

  # Frappe Client Methods (7 endpoints)
  [ 'frappe.client.get', { doctype: 'User', name: 'test@example.com' } ],
  [ 'frappe.client.get_list', { doctype: 'User' } ],
  [ 'frappe.client.get_single_value', {} ],
  [ 'frappe.client.get_count', { doctype: 'User' } ],
  [ 'frappe.client.insert', {} ],
  [ 'frappe.client.set_value', {} ],
  [ 'frappe.client.delete', {} ],

  # System & Settings (11 endpoints)
  [ 'frappe.apps.get_apps', {} ],
  [ 'frappe.desk.search.search_link', {} ],
  [ 'lms.api.get_notifications', {} ],
  [ 'lms.api.mark_as_read', {} ],
  [ 'lms.api.mark_all_as_read', {} ],
  [ 'lms.api.get_branding', {} ],
  [ 'lms.api.get_lms_setting', {} ],
  [ 'lms.api.get_translations', {} ],
  [ 'lms.api.get_sidebar_settings', {} ],
  [ 'lms.api.get_file_info', {} ],
  [ 'lms.utils.upload_assignment', {} ],

  # Advanced Course Features (10 endpoints) - MISSING
  [ 'lms.utils.get_created_courses', {} ],
  [ 'lms.utils.reindex_exercises', {} ],
  [ 'lms.utils.get_lesson_info', {} ],
  [ 'lms.utils.get_lesson_creation_details', {} ],
  [ 'lms.utils.mark_lesson_progress', {} ],
  [ 'lms.utils.track_video_watch_duration', {} ],
  [ 'lms.utils.autosave_section', {} ],
  [ 'lms.utils.update_chapter_index', {} ],
  [ 'lms.utils.update_lesson_index', {} ],
  [ 'lms.utils.upsert_chapter', {} ],

  # Assessment & Quiz System (9 endpoints) - PARTIAL
  [ 'lms.utils.get_assessments', {} ],
  [ 'lms.utils.get_question_details', {} ],
  [ 'lms.utils.quiz_summary', {} ],
  [ 'lms.utils.check_answer', {} ],
  [ 'lms.utils.grade_assignment', {} ],
  [ 'lms.utils.get_assignment', {} ],
  [ 'lms.utils.save_assignment', {} ],
  [ 'lms.utils.submit_solution', {} ],
  [ 'lms.utils.create_programming_exercise_submission', {} ],

  # Discussion System (4 endpoints) - MISSING
  [ 'lms.utils.get_discussion_topics', {} ],
  [ 'lms.utils.get_discussion_replies', {} ],
  [ 'lms.utils.save_message', {} ],
  [ 'lms.utils.submit_review', {} ],

  # Program Management (2 endpoints) - MISSING
  [ 'lms.utils.get_program_details', {} ],
  [ 'lms.utils.enroll_in_program', {} ],

  # Certificate System (6 endpoints) - MISSING
  [ 'lms.utils.create_certificate', {} ],
  [ 'lms.utils.save_certificate_details', {} ],
  [ 'lms.utils.create_lms_certificate', {} ],
  [ 'lms.utils.get_admin_evals', {} ],
  [ 'lms.utils.cancel_evaluation', {} ],
  [ 'lms.utils.save_evaluation_details', {} ],

  # Cohort Management (4 endpoints) - MISSING
  [ 'lms.utils.join_cohort', {} ],
  [ 'lms.utils.approve_cohort_join_request', {} ],
  [ 'lms.utils.reject_cohort_join_request', {} ],
  [ 'lms.utils.undo_reject_cohort_join_request', {} ],

  # User Management Advanced (8 endpoints) - MISSING
  [ 'lms.utils.get_roles', {} ],
  [ 'lms.utils.add_an_evaluator', {} ],
  [ 'lms.utils.delete_evaluator', {} ],
  [ 'lms.utils.save_role', {} ],
  [ 'lms.utils.assign_badge', {} ],
  [ 'lms.utils.get_meta_info', {} ],
  [ 'lms.utils.update_meta_info', {} ],

  # Notifications (1 endpoint) - MISSING
  [ 'lms.api.get_announcements', {} ],

  # Jobs & Career (4 endpoints) - MISSING
  [ 'lms.utils.cancel_request', {} ],
  [ 'lms.utils.create_request', {} ],
  [ 'lms.utils.has_requested', {} ],
  [ 'lms.utils.capture_interest', {} ],

  # System & Settings (7 endpoints) - MISSING
  [ 'lms.utils.get_schedule', {} ],
  [ 'lms.utils.report', {} ],
  [ 'lms.utils.send_confirmation_email', {} ],
  [ 'lms.utils.setup_calendar_event', {} ],
  [ 'lms.utils.update_current_membership', {} ],
  [ 'lms.utils.create_membership', {} ],
  [ 'lms.utils.create_certificate_request', {} ],

  # Additional endpoints (4 endpoints)
  [ 'lms.api.get_unsplash_photos', {} ],
  [ 'lms.api.get_heatmap_data', {} ],
  [ 'lms.api.get_chart_details', {} ],
  [ 'lms.api.get_assigned_badges', {} ]
]

# Test all endpoints
results = []
working_count = 0
auth_fail_count = 0
error_count = 0
missing_count = 0

puts 'Testing all endpoints...'
puts ''

endpoints.each_with_index do |(endpoint, params), index|
  result = test_endpoint("#{index + 1}. #{endpoint}", endpoint, params, token)
  results << [ endpoint, result ]

  case result
  when '✅ PASS'
    working_count += 1
  when '❌ AUTH'
    auth_fail_count += 1
  when '❌ ERROR', '❌ EXCEPTION', /^❌ HTTP/
    error_count += 1
  else
    missing_count += 1
  end

  puts "#{result} #{endpoint}"
end

total = endpoints.size

puts ''
puts '=' * 50
puts 'FINAL RESULTS SUMMARY'
puts '=' * 50
puts "Total endpoints tested: #{total}"
puts "✅ Working endpoints: #{working_count}"
puts "❌ Auth failures: #{auth_fail_count}"
puts "❌ Error failures: #{error_count}"
puts "❌ Missing/Other: #{missing_count}"
puts "Success rate: #{(working_count.to_f / total * 100).round(2)}%"

if working_count == total
  puts '🎯 ALL ENDPOINTS WORKING - 100% COMPATIBILITY!'
elsif working_count >= total * 0.9
  puts '🟡 EXCELLENT COMPATIBILITY - 90%+ WORKING!'
elsif working_count >= total * 0.8
  puts '🟢 GOOD COMPATIBILITY - 80%+ WORKING!'
elsif working_count >= total * 0.7
  puts '🟡 FAIR COMPATIBILITY - 70%+ WORKING!'
else
  puts '🔴 NEEDS IMPROVEMENTS - <70% WORKING'
end

puts ''
puts '✅ WORKING ENDPOINTS:'
working_endpoints = results.select { |_, result| result == '✅ PASS' }.map(&:first)
working_endpoints.each { |endpoint| puts "  - #{endpoint}" }

puts ''
puts '❌ FAILED ENDPOINTS:'
failed_endpoints = results.select { |_, result| result != '✅ PASS' }.map(&:first)
failed_endpoints.each { |endpoint| puts "  - #{endpoint}" }
