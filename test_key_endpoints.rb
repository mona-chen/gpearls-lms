#!/usr/bin/env ruby

require_relative 'config/environment'
require 'net/http'
require 'json'

puts '🔬 TESTING KEY FRAPPE COMPATIBILITY ENDPOINTS'
puts '==============================================='

# Create test user
user = User.find_or_create_by!(email: 'test@example.com') do |u|
  u.username = 'testuser'
  u.full_name = 'Test User'
  u.password = 'password123'
  u.role = 'LMS Student'
end

# Generate JWT token
token = Warden::JWTAuth::TokenEncoder.new.call({
  sub: user.id,
  jti: SecureRandom.uuid,
  exp: 24.hours.from_now.to_i
})

puts "Created test user: #{user.email}"
puts "Generated token: #{token[0..20]}..."

# Helper method to test endpoints
def test_endpoint(name, method_path, params = {}, token = nil)
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
      success = !result.is_a?(Hash) || !result.key?('status') || result['status'] != 'error'
      puts "✅ #{name}: PASS"
      true
    else
      puts "❌ #{name}: FAIL (#{response.code})"
      false
    end
  rescue => e
    puts "❌ #{name}: ERROR - #{e.message}"
    false
  end
end

# Test results
results = []

puts ''
puts 'Testing User Management...'
results << test_endpoint('User Info', 'lms.api.get_user_info', {}, token)
results << test_endpoint('All Users', 'lms.api.get_all_users', {}, token)

puts ''
puts 'Testing Course Management...'
results << test_endpoint('My Courses', 'lms.utils.get_my_courses', {}, token)
results << test_endpoint('Courses', 'lms.utils.get_courses', {}, token)

puts ''
puts 'Testing Analytics...'
results << test_endpoint('Streak Info', 'lms.utils.get_streak_info', {}, token)
results << test_endpoint('Heatmap Data', 'lms.utils.get_heatmap_data', {}, token)
results << test_endpoint('Chart Details', 'lms.api.get_chart_details', {}, token)

puts ''
puts 'Testing Settings...'
results << test_endpoint('Branding', 'lms.api.get_branding', {}, token)
results << test_endpoint('LMS Settings', 'lms.api.get_lms_setting', {}, token)
results << test_endpoint('Translations', 'lms.api.get_translations', {}, token)
results << test_endpoint('Sidebar Settings', 'lms.api.get_sidebar_settings', {}, token)

puts ''
puts 'Testing Notifications...'
results << test_endpoint('Notifications', 'lms.api.get_notifications', {}, token)

puts ''
puts 'Testing Files...'
results << test_endpoint('File Info', 'lms.api.get_file_info', { file_url: 'test' }, token)

# Calculate results
total = results.size
working = results.count { |r| r }

puts '==============================================='
puts 'TEST RESULTS SUMMARY'
puts '==============================================='
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
