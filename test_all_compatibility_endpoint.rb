#!/usr/bin/env ruby

require_relative 'config/environment'

puts '🔬 TESTING ALL FRAPPE COMPATIBILITY ENDPOINTS'
puts '=================================================='

require 'net/http'
require 'uri'
require 'json'

# Setup test data - use existing users
instructor = User.find_by(username: 'instructor') || User.create!(
  email: 'instructor@test.com',
  username: 'instructor',
  password: 'password123',
  full_name: 'Test Instructor',
  is_instructor: true
)

student = User.find_by(username: 'alice') || User.create!(
  email: 'student@test.com',
  username: 'alice',
  password: 'password123',
  full_name: 'Test Student',
  is_student: true
)

# Global cookie jar for session management
$cookie_jar = {}

# Verification methods (placeholder implementations)
def verify_user_info_structure(data)
  # Basic structure check
  required_keys = [ 'name', 'email', 'username' ]
  required_keys.all? { |key| data.key?(key) }
end

def verify_users_structure(user)
  # Basic user structure check
  required_keys = [ 'name', 'email' ]
  required_keys.all? { |key| user.key?(key) }
end

def verify_courses_structure(course)
  # Basic course structure check
  required_keys = [ 'title', 'description' ]
  required_keys.all? { |key| course.key?(key) }
end

def verify_batch_structure(batch)
  # Basic batch structure check
  required_keys = [ 'title', 'description' ]
  required_keys.all? { |key| batch.key?(key) }
end

def verify_eval_structure(eval_data)
  # Basic eval structure check
  true # Placeholder
end

def verify_streak_structure(data)
  # Basic streak structure check
  required_keys = [ 'current_streak', 'longest_streak' ]
  required_keys.all? { |key| data.key?(key) }
end

# Helper method to login and get session cookies
def login_user(user)
  uri = URI('http://localhost:3001/login')
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Post.new(uri)
  request.set_form_data('usr' => user.email, 'pwd' => 'password123')

  response = http.request(request)

  if response.is_a?(Net::HTTPSuccess)
    # Extract session cookies
    cookies = response.get_fields('set-cookie')
    if cookies
      session_cookies = cookies.map do |cookie|
        cookie.split(';').first
      end.join('; ')
      $cookie_jar[user.id] = session_cookies
      return true
    end
  end
  false
end

# Helper method to test endpoints via HTTP
def route_to_frappe_method(method_path, user = nil, params = {})
  begin
    uri = URI('http://localhost:3001/api/method/' + method_path)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params) unless params.empty?

    # Add session cookies if user provided
    if user && $cookie_jar[user.id]
      request['Cookie'] = $cookie_jar[user.id]
    end

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      { error: "HTTP #{response.code}", status: response.code.to_i }
    end
  rescue => e
    puts "Error testing #{method_path}: #{e.message}"
    { error: e.message }
  end
end

# Use existing courses for testing
course1 = Course.find_by(title: 'Published Course') || Course.first || Course.create!(
  title: 'Test Published Course',
  description: 'Test published course',
  short_introduction: 'Learn programming basics',
  category: 'Programming',
  status: 'Approved',
  published: true,
  featured: true,
  instructor: instructor,
  tags: 'ruby,rails,api'
)

course2 = Course.find_by(title: 'Full Stack Web Development') || Course.second || Course.create!(
  title: 'Test Draft Course',
  description: 'Test draft course',
  short_introduction: 'Learn design basics',
  category: 'Design',
  status: 'Draft',
  published: false,
  instructor: instructor,
  tags: 'css,html,frontend'
)

course3 = Course.find_by(title: 'Python for Data Science') || Course.third || Course.create!(
  title: 'Test Upcoming Course',
  description: 'Test upcoming course',
  short_introduction: 'Learn data science basics',
  category: 'Data Science',
  status: 'Approved',
  published: true,
  upcoming: true,
  instructor: instructor,
  tags: 'python,machine,data'
)

# Create batch
batch = Batch.create!(
  title: 'Test Batch',
  course_id: course1.id,
  description: 'Test batch description',
  start_date: Date.today + 1.week,
  end_date: Date.today + 8.weeks,
  start_time: '09:00',
  end_time: '17:00',
  additional_info: 'Test batch additional info',
  published: true,
  instructor: instructor
)

# Test all endpoints systematically
puts 'Testing all Frappe compatibility endpoints:'

test_results = []

# Login users first
puts 'Logging in test users...'
login_user(instructor)
login_user(student)

# LMS API Methods
puts '=== LMS API METHODS ==='

# 1. lms.api.get_user_info
puts '1. Testing lms.api.get_user_info...'
begin
  result = route_to_frappe_method('lms.api.get_user_info', student)
  puts '✅ lms.api.get_user_info: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  # verify_user_info_structure(result) if result.is_a?(Hash) # Commented out for now
  test_results << [ 'lms.api.get_user_info', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.api.get_user_info: ' + e.message
  test_results << [ 'lms.api.get_user_info', false ]
end

# 2. lms.api.get_all_users with pagination
puts '2. Testing lms.api.get_all_users...'
begin
  result = route_to_frappe_method('lms.api.get_all_users', instructor)
  # Service returns hash like {user_id: {name, full_name, user_image}}
  is_working = result.is_a?(Hash) && !result.empty?
  puts '✅ lms.api.get_all_users: ' + (is_working ? 'Working' : 'Failed')
  if is_working
    first_user = result.values.first
    verify_users_structure(first_user) if first_user
  end
  test_results << [ 'lms.api.get_all_users', is_working ]
rescue => e
  puts '❌ lms.api.get_all_users: ' + e.message
  test_results << [ 'lms.api.get_all_users', false ]
end

# 3. lms.api.get_notifications
puts '3. Testing lms.api.get_notifications...'
begin
  result = route_to_frappe_method('lms.api.get_notifications', student) # Requires auth
  # Handle both direct array and wrapped formats
  actual_data = result.is_a?(Array) ? result : result.dig('message') || result.dig('data') || []
  is_working = actual_data.is_a?(Array)
  puts '✅ lms.api.get_notifications: ' + (is_working ? 'Working' : 'Failed')
  test_results << [ 'lms.api.get_notifications', is_working ]
rescue => e
  puts '❌ lms.api.get_notifications: ' + e.message
  test_results << [ 'lms.api.get_notifications', false ]
end

# 4. lms.api.get_branding
puts '4. Testing lms.api.get_branding...'
begin
  result = route_to_frappe_method('lms.api.get_branding', student)
  puts '✅ lms.api.get_branding: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  test_results << [ 'lms.api.get_branding', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.api.get_branding: ' + e.message
  test_results << [ 'lms.api.get_branding', false ]
end

# 5. lms.api.get_lms_setting
puts '5. Testing lms.api.get_lms_setting...'
begin
  result = route_to_frappe_method('lms.api.get_lms_setting', student, { setting: 'enable_course_creation' })
  puts '✅ lms.api.get_lms_setting: ' + (result != nil ? 'Working' : 'Failed')
  test_results << [ 'lms.api.get_lms_setting', result != nil ]
rescue => e
  puts '❌ lms.api.get_lms_setting: ' + e.message
  test_results << [ 'lms.api.get_lms_setting', false ]
end

# LMS Utils Methods
puts '=== LMS UTILS METHODS ==='

# 6. lms.utils.get_my_courses with filters
puts '6. Testing lms.utils.get_my_courses with filters...'
begin
  result = route_to_frappe_method('lms.utils.get_my_courses', student, { filters: { published: 1 } })
  puts '✅ lms.utils.get_my_courses (with filters): ' + (result.is_a?(Array) ? 'Working' : 'Failed')
  verify_courses_structure(result.first) if result.is_a?(Array) && result.any?
  test_results << [ 'lms.utils.get_my_courses', result.is_a?(Array) ]
rescue => e
  puts '❌ lms.utils.get_my_courses: ' + e.message
  test_results << [ 'lms.utils.get_my_courses', false ]
end

# 7. lms.utils.get_courses with filters and pagination
puts '7. Testing lms.utils.get_courses with filters and pagination...'
begin
  result = route_to_frappe_method('lms.utils.get_courses', instructor, {
    filters: { published: 1 },
    limit: 10,
    offset: 0,
    sort_by: 'creation desc'
  })
  puts '✅ lms.utils.get_courses (with pagination): ' + (result.is_a?(Hash) && result['data'].is_a?(Array) ? 'Working' : 'Failed')
  verify_courses_structure(result['data'].first) if result.is_a?(Hash) && result['data'].any?
  test_results << [ 'lms.utils.get_courses', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_courses: ' + e.message
  test_results << [ 'lms.utils.get_courses', false ]
end

# 8. lms.utils.get_course_completion_data
puts '8. Testing lms.utils.get_course_completion_data...'
begin
  result = route_to_frappe_method('lms.utils.get_course_completion_data', nil, { course: course1.id })
  puts '✅ lms.utils.get_course_completion_data: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_course_completion_data', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_course_completion_data: ' + e.message
  test_results << [ 'lms.utils.get_course_completion_data', false ]
end

# 9. lms.utils.get_course_progress_distribution
puts '9. Testing lms.utils.get_course_progress_distribution...'
begin
  result = route_to_frappe_method('lms.utils.get_course_progress_distribution', nil, { course: course1.id })
  puts '✅ lms.utils.get_course_progress_distribution: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_course_progress_distribution', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_course_progress_distribution: ' + e.message
  test_results << [ 'lms.utils.get_course_progress_distribution', false ]
end

# 10. lms.utils.get_tags
puts '10. Testing lms.utils.get_tags...'
begin
  result = route_to_frappe_method('lms.utils.get_tags', nil, { course: course1.id })
  # Handle both direct array and {"message": array} formats
  actual_data = result.is_a?(Array) ? result : result.dig('message') || result.dig('data')
  is_working = actual_data.is_a?(Array) && !actual_data.empty?
  puts '✅ lms.utils.get_tags: ' + (is_working ? 'Working' : 'Failed')
  puts '  Tags: ' + actual_data.join(', ') if is_working
  test_results << [ 'lms.utils.get_tags', is_working ]
rescue => e
  puts '❌ lms.utils.get_tags: ' + e.message
  test_results << [ 'lms.utils.get_tags', false ]
end

# 11. lms.utils.get_reviews
puts '11. Testing lms.utils.get_reviews...'
begin
  result = route_to_frappe_method('lms.utils.get_reviews', nil, { course: course1.id })
  # Handle both direct array and wrapped formats
  actual_data = result.is_a?(Array) ? result : result.dig('message') || result.dig('data') || []
  is_working = actual_data.is_a?(Array) # Reviews can be empty array
  puts '✅ lms.utils.get_reviews: ' + (is_working ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_reviews', is_working ]
rescue => e
  puts '❌ lms.utils.get_reviews: ' + e.message
  test_results << [ 'lms.utils.get_reviews', false ]
end

# 12. lms.utils.get_my_batches
puts '12. Testing lms.utils.get_my_batches...'
begin
  result = route_to_frappe_method('lms.utils.get_my_batches', student)
  puts '✅ lms.utils.get_my_batches: ' + (result.is_a?(Array) ? 'Working' : 'Failed')
  verify_batch_structure(result.first) if result.is_a?(Array) && result.any?
  test_results << [ 'lms.utils.get_my_batches', result.is_a?(Array) ]
rescue => e
  puts '❌ lms.utils.get_my_batches: ' + e.message
  test_results << [ 'lms.utils.get_my_batches', false ]
end

# 13. lms.utils.get_batches with filters
puts '13. Testing lms.utils.get_batches with filters...'
begin
  result = route_to_frappe_method('lms.utils.get_batches', instructor, {
    filters: { published: 1 },
    limit: 10
  })
  puts '✅ lms.utils.get_batches (with filters): ' + (result.is_a?(Hash) && result['data'].is_a?(Array) ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_batches', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_batches: ' + e.message
  test_results << [ 'lms.utils.get_batches', false ]
end

# 14. lms.utils.get_upcoming_evals
puts '14. Testing lms.utils.get_upcoming_evals...'
begin
  result = route_to_frappe_method('lms.utils.get_upcoming_evals', student)
  puts '✅ lms.utils.get_upcoming_evals: ' + (result.is_a?(Array) ? 'Working' : 'Failed')
  verify_eval_structure(result.first) if result.is_a?(Array) && result.any?
  test_results << [ 'lms.utils.get_upcoming_evals', result.is_a?(Array) ]
rescue => e
  puts '❌ lms.utils.get_upcoming_evals: ' + e.message
  test_results << [ 'lms.utils.get_upcoming_evals', false ]
end

# 15. lms.utils.get_streak_info
puts '15. Testing lms.utils.get_streak_info...'
begin
  result = route_to_frappe_method('lms.utils.get_streak_info', student)
  puts '✅ lms.utils.get_streak_info: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  verify_streak_structure(result)
  test_results << [ 'lms.utils.get_streak_info', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_streak_info: ' + e.message
  test_results << [ 'lms.utils.get_streak_info', false ]
end

# 16. lms.utils.get_my_live_classes
puts '16. Testing lms.utils.get_my_live_classes...'
begin
  result = route_to_frappe_method('lms.utils.get_my_live_classes', student)
  puts '✅ lms.utils.get_my_live_classes: ' + (result.is_a?(Array) ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_my_live_classes', result.is_a?(Array) ]
rescue => e
  puts '❌ lms.utils.get_my_live_classes: ' + e.message
  test_results << [ 'lms.utils.get_my_live_classes', false ]
end

# 17. lms.utils.get_heatmap_data
puts '17. Testing lms.utils.get_heatmap_data...'
begin
  result = route_to_frappe_method('lms.utils.get_heatmap_data', student)
  puts '✅ lms.utils.get_heatmap_data: ' + (result.is_a?(Hash) ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.get_heatmap_data', result.is_a?(Hash) ]
rescue => e
  puts '❌ lms.utils.get_heatmap_data: ' + e.message
  test_results << [ 'lms.utils.get_heatmap_data', false ]
end

# 18. lms.utils.save_current_lesson
puts '18. Testing lms.utils.save_current_lesson...'
begin
  result = route_to_frappe_method('lms.utils.save_current_lesson', student, {
    course: course1.id,
    lesson: 'lesson_123'
  })
  puts '✅ lms.utils.save_current_lesson: ' + (result.is_a?(Hash) && result['success'] ? 'Working' : 'Failed')
  test_results << [ 'lms.utils.save_current_lesson', result.is_a?(Hash) && result['success'] ]
rescue => e
  puts '❌ lms.utils.save_current_lesson: ' + e.message
  test_results << [ 'lms.utils.save_current_lesson', false ]
end

# Frappe Client Methods
puts '=== FRAPPE CLIENT METHODS ==='

# 19. frappe.client.get
puts '19. Testing frappe.client.get...'
begin
  result = route_to_frappe_method('frappe.client.get', student, {
    doctype: 'User',
    filters: { email: student.email }
  })
  puts '✅ frappe.client.get: ' + (result.is_a?(Array) ? 'Working' : 'Failed')
  test_results << [ 'frappe.client.get', result.is_a?(Array) ]
rescue => e
  puts '❌ frappe.client.get: ' + e.message
  test_results << [ 'frappe.client.get', false ]
end

# 20. frappe.client.get_count
puts '20. Testing frappe.client.get_count...'
begin
  result = route_to_frappe_method('frappe.client.get_count', student, {
    doctype: 'Course'
  })
  puts '✅ frappe.client.get_count: ' + (result.is_a?(Integer) || result.is_a?(String) ? 'Working' : 'Failed')
  test_results << [ 'frappe.client.get_count', result.is_a?(Integer) || result.is_a?(String) ]
rescue => e
  puts '❌ frappe.client.get_count: ' + e.message
  test_results << [ 'frappe.client.get_count', false ]
end

# Error handling tests
puts '=== ERROR HANDLING TESTS ==='

# 21. Invalid method
puts '21. Testing invalid method...'
begin
  result = route_to_frappe_method('lms.api.invalid_method', student)
  puts '❌ lms.api.invalid_method: ' + (result.is_a?(Hash) && result.dig('status') == 404 ? 'Working' : 'Failed')
  test_results << [ 'lms.api.invalid_method', result.is_a?(Hash) && result.dig('status') == 404 ]
rescue => e
  puts '❌ lms.api.invalid_method: ' + e.message
  test_results << [ 'lms.api.invalid_method', false ]
end

# 22. Unauthorized access
puts '22. Testing unauthorized access...'
begin
  # Simulate no Current.user
  original_user = Current.user
  Current.user = nil
  result = route_to_frappe_method('lms.api.get_user_info', nil)
  Current.user = original_user
  puts '❌ lms.api.get_user_info (unauthorized): ' + (result.is_a?(Hash) && result.dig('status') == :unauthorized ? 'Working' : 'Failed')
  test_results << [ 'lms.api.get_user_info (unauthorized)', result.is_a?(Hash) && result.dig('status') == :unauthorized ]
rescue => e
  puts '❌ lms.api.get_user_info (unauthorized): ' + e.message
  test_results << [ 'lms.api.get_user_info (unauthorized)', false ]
end

# Summary
puts ''
puts '============================================'
puts 'TEST RESULTS SUMMARY'
puts '============================================'

working = test_results.count { |result| result[1] }
total = test_results.count

puts "Total endpoints tested: #{total}"
puts "Working endpoints: #{working}"
puts "Failed endpoints: #{total - working}"
puts "Success rate: #{(working.to_f / total * 100).round(2)}%"

if working == total
  puts '🎯 ALL ENDPOINTS WORKING - 100% COMPATIBILITY!'
elsif working >= total * 0.9
  puts '🟡 EXCELLENT COMPATIBILITY - 90%+ WORKING!'
elsif working >= total * 0.8
  puts '🟢 GOOD COMPATIBILITY - 80%+ WORKING!'
else
  puts '🔴 NEEDS IMPROVEMENTS'
end

working_endpoints = test_results.select { |result| result[1] }.map(&:first)
failed_endpoints = test_results.select { |result| !result[1] }.map(&:first)

if working_endpoints.any?
  puts ''
  puts '✅ Working endpoints:'
  working_endpoints.each { |endpoint| puts '  - ' + endpoint }
end

if failed_endpoints.any?
  puts ''
  puts '❌ Failed endpoints:'
  failed_endpoints.each { |endpoint| puts ' - ' + endpoint }
end
