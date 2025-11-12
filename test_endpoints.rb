#!/usr/bin/env ruby

require_relative 'config/environment'

puts '🔬 TESTING ALL FRAPPE COMPATIBILITY ENDPOINTS'
puts '=================================================='

# Setup test data
instructor = User.create!(
  email: 'instructor@test.com',
  username: 'instructor',
  full_name: 'Test Instructor',
  password: 'password123',
  role: 'Course Creator'
)

student = User.create!(
  email: 'student@test.com',
  username: 'student',
  full_name: 'Test Student',
  password: 'password123',
  role: 'LMS Student'
)

course1 = Course.create!(
  title: 'Test Course',
  description: 'Test course description',
  short_introduction: 'Test intro',
  instructor: instructor,
  published: true
)

batch1 = Batch.create!(
  title: 'Test Batch',
  course: course1,
  start_date: Date.today,
  end_date: Date.today + 30.days
)

# Helper method to test endpoints
def route_to_frappe_method(method_path, params = {})
  begin
    uri = URI('http://localhost:3001/api/method/' + method_path)
    uri.query = URI.encode_www_form(params) unless params.empty?

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)

    response = http.request(request)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  rescue => e
    puts "Error testing #{method_path}: #{e.message}"
    nil
  end
end

# Test results tracking
test_results = []
total = 0

# Helper method to test and record
def test_endpoint(name, params = {}, &block)
  puts "Testing #{name}..."
  begin
    result = block.call
    success = !result.nil? && !result.is_a?(Hash) || !result.key?('status') || result['status'] != 'error'
    puts success ? '✅ PASS' : '❌ FAIL'
    [ name, success ]
  rescue => e
    puts "❌ ERROR: #{e.message}"
    [ name, false ]
  end
end

puts ''
puts '1. Testing User Management endpoints...'

# User Info
test_results << test_endpoint('lms.api.get_user_info') do
  route_to_frappe_method('lms.api.get_user_info')
end

# All Users
test_results << test_endpoint('lms.api.get_all_users') do
  route_to_frappe_method('lms.api.get_all_users')
end

# Members
test_results << test_endpoint('lms.api.get_members') do
  route_to_frappe_method('lms.api.get_members')
end

puts ''
puts '2. Testing Course Management endpoints...'

# My Courses
test_results << test_endpoint('lms.utils.get_my_courses') do
  route_to_frappe_method('lms.utils.get_my_courses')
end

# Courses
test_results << test_endpoint('lms.utils.get_courses') do
  route_to_frappe_method('lms.utils.get_courses')
end

# Course Details
test_results << test_endpoint('lms.utils.get_course_details') do
  route_to_frappe_method('lms.utils.get_course_details', course: course1.id)
end

puts ''
puts '3. Testing Analytics endpoints...'

# Course Progress Distribution
test_results << test_endpoint('lms.utils.get_course_progress_distribution') do
  route_to_frappe_method('lms.utils.get_course_progress_distribution', course: course1.id)
end

# Streak Info
test_results << test_endpoint('lms.utils.get_streak_info') do
  route_to_frappe_method('lms.utils.get_streak_info')
end

# Heatmap Data
test_results << test_endpoint('lms.utils.get_heatmap_data') do
  route_to_frappe_method('lms.utils.get_heatmap_data')
end

# Chart Details
test_results << test_endpoint('lms.api.get_chart_details') do
  route_to_frappe_method('lms.api.get_chart_details')
end

puts ''
puts '4. Testing Settings endpoints...'

# Branding
test_results << test_endpoint('lms.api.get_branding') do
  route_to_frappe_method('lms.api.get_branding')
end

# LMS Settings
test_results << test_endpoint('lms.api.get_lms_setting') do
  route_to_frappe_method('lms.api.get_lms_setting')
end

# Translations
test_results << test_endpoint('lms.api.get_translations') do
  route_to_frappe_method('lms.api.get_translations')
end

# Sidebar Settings
test_results << test_endpoint('lms.api.get_sidebar_settings') do
  route_to_frappe_method('lms.api.get_sidebar_settings')
end

puts ''
puts '5. Testing Notification endpoints...'

# Notifications
test_results << test_endpoint('lms.api.get_notifications') do
  route_to_frappe_method('lms.api.get_notifications')
end

# Mark as Read
test_results << test_endpoint('lms.api.mark_as_read') do
  route_to_frappe_method('lms.api.mark_as_read', name: 'test')
end

# Mark All as Read
test_results << test_endpoint('lms.api.mark_all_as_read') do
  route_to_frappe_method('lms.api.mark_all_as_read')
end

puts ''
puts '6. Testing File endpoints...'

# File Info
test_results << test_endpoint('lms.api.get_file_info') do
  route_to_frappe_method('lms.api.get_file_info', file_url: 'test')
end

# Upload Assignment
test_results << test_endpoint('lms.utils.upload_assignment') do
  route_to_frappe_method('lms.utils.upload_assignment', assignment: 1)
end

# Calculate results
total = test_results.size
working = test_results.count { |result| result[1] }

puts ''
puts '=================================================='
puts 'TEST RESULTS SUMMARY'
puts '=================================================='
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
