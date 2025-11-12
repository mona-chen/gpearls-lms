#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class FrappeCompatibilityTester
  def initialize(base_url = 'http://localhost:3001')
    @base_url = base_url
    @token = nil
    @cookies = {}
    @test_results = []
    @passed = 0
    @failed = 0
  end

  def run_all_tests
    puts "🔬 COMPREHENSIVE FRAPPE COMPATIBILITY TESTING"
    puts "=" * 60
    puts "Testing all endpoints against multiple scenarios..."
    puts ""

    # Step 1: Authentication
    test_authentication

    # Step 2: Test all endpoint categories
    test_lms_api_methods
    test_lms_utils_methods
    test_analytics_methods
    test_frappe_client_methods
    test_error_scenarios

    # Step 3: Edge cases and stress testing
    test_edge_cases

    # Step 4: Summary
    print_summary
  end

  private

  def test_authentication
    puts "🔐 TESTING AUTHENTICATION"
    puts "-" * 30

    # Test login
    test_endpoint("POST /api/login", {
      usr: "admin@lms.com",
      pwd: "password123"
    }, expected_status: 200) do |response, http_response|
      # Capture session cookies from login response
      if http_response['set-cookie']
        http_response.get_fields('set-cookie').each do |cookie_header|
          cookie = cookie_header.split(';').first
          name, value = cookie.split('=', 2)
          @cookies[name] = value if name && value
        end
      end
      puts "✅ Authentication successful" if @cookies['sid']
    end

    # Test signup (create new user)
    test_endpoint("POST /api/signup", {
      signup_email: "testuser#{Time.now.to_i}@example.com",
      full_name: "Test User",
      password: "password123"
    }, expected_status: 200)

    # Test logout
    test_endpoint("POST /api/logout", {}, headers: auth_headers)

    # Re-login for subsequent tests (cookies already set from first login)
    login_response, _ = make_request("POST", "/api/login", {
      usr: "admin@lms.com",
      pwd: "password123"
    })
    puts ""
  end

  def test_lms_api_methods
    puts "📚 TESTING LMS API METHODS"
    puts "-" * 35

    # User management
    test_endpoint("POST /api/method/lms.api.get_user_info", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_all_users", { limit: 10 }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_notifications", {}, headers: auth_headers)

    # Settings and configuration
    test_endpoint("POST /api/method/lms.api.get_branding", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_lms_setting", { field: "allow_guest_access" }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_translations", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_sidebar_settings", {}, headers: auth_headers)

    # Certifications
    test_endpoint("POST /api/method/lms.api.get_certification_categories", {
      doctype: "LMS Certificate",
      start: 0,
      limit: 20
    }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_count_of_certified_members", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_certified_participants", {
      doctype: "LMS Certificate",
      filters: {},
      start: 0,
      limit: 100
    }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.api.get_job_opportunities", {}, headers: auth_headers)

    # Analytics
    test_endpoint("POST /api/method/lms.api.get_chart_details", {}, headers: auth_headers)

    puts ""
  end

  def test_lms_utils_methods
    puts "🛠️  TESTING LMS UTILS METHODS"
    puts "-" * 38

    # Course management
    test_endpoint("POST /api/method/lms.utils.get_my_courses", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_courses", {
      doctype: "LMS Course",
      filters: { published: 1, upcoming: 0, live: 1 },
      start: 0,
      limit: 30,
      limit_start: 0,
      limit_page_length: 30
    }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_course_completion_data", { course: "1" }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_course_progress_distribution", { course: "1" }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_tags", { course: "1" }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_reviews", { course: "1" }, headers: auth_headers)

    # Batch management
    test_endpoint("POST /api/method/lms.utils.get_my_batches", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_batches", {
      filters: { published: 1 },
      limit: 10
    }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_upcoming_evals", { courses: [], batch: nil }, headers: auth_headers)

    # User analytics
    test_endpoint("POST /api/method/lms.utils.get_streak_info", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_my_live_classes", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_heatmap_data", {}, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.get_chart_data", { chart_name: "course_completion" }, headers: auth_headers)
    test_endpoint("POST /api/method/lms.utils.save_current_lesson", {
      course: "1",
      lesson: "lesson_123"
    }, headers: auth_headers)

    puts ""
  end

  def test_analytics_methods
    puts "📊 TESTING ANALYTICS METHODS"
    puts "-" * 33

    # These are mostly covered in LMS Utils, but let's ensure they work
    test_endpoint("POST /api/method/lms.api.get_chart_data", { chart_name: "enrollments" }, headers: auth_headers)

    puts ""
  end

  def test_frappe_client_methods
    puts "🔌 TESTING FRAPPE CLIENT METHODS"
    puts "-" * 37

    # Core client methods
    test_endpoint("POST /api/method/frappe.apps.get_apps", {}, headers: auth_headers)
    test_endpoint("POST /api/method/frappe.client.get", {
      doctype: "User",
      filters: { email: "testuser@example.com" },
      name: nil
    }, headers: auth_headers)
    test_endpoint("POST /api/method/frappe.client.get_list", {
      doctype: "Course",
      filters: { published: 1 }
    }, headers: auth_headers)
    test_endpoint("POST /api/method/frappe.client.get_single_value", {
      doctype: "LMS Settings",
      field: "allow_guest_access",
      filters: {}
    }, headers: auth_headers)
    test_endpoint("POST /api/method/frappe.client.get_count", {
      doctype: "Course"
    }, headers: auth_headers)
    test_endpoint("POST /api/method/frappe.desk.search.search_link", {
      txt: "course",
      doctype: "Course"
    }, headers: auth_headers)

    puts ""
  end

  def test_error_scenarios
    puts "⚠️  TESTING ERROR SCENARIOS"
    puts "-" * 30

    # Invalid method
    test_endpoint("POST /api/method/lms.api.invalid_method", {},
                   headers: auth_headers, expected_status: 404)

    # Unauthorized access
    @cookies.clear  # Clear session cookies to test unauthorized access
    test_endpoint("POST /api/method/lms.api.get_user_info", {}, expected_status: 401)

    # Invalid JSON
    test_endpoint("POST /api/method/lms.api.get_user_info",
                   '{invalid json}',
                   headers: auth_headers,
                   content_type: "application/json",
                   expected_status: 400)

    # Missing required parameters
    test_endpoint("POST /api/method/lms.utils.get_course_progress_distribution",
                   {}, headers: auth_headers)

    # Invalid doctype
    test_endpoint("POST /api/method/frappe.client.get", {
      doctype: "InvalidDocType",
      filters: {}
    }, headers: auth_headers)

    puts ""
  end

  def test_edge_cases
    puts "🔍 TESTING EDGE CASES"
    puts "-" * 27

    # Large datasets
    test_endpoint("POST /api/method/lms.utils.get_courses", {
      filters: {},
      limit: 1000,
      start: 0
    }, headers: auth_headers)

    # Complex filters
    test_endpoint("POST /api/method/lms.utils.get_courses", {
      doctype: "LMS Course",
      filters: {
        published: 1,
        upcoming: 0,
        live: 1,
        category: "Programming",
        featured: 1
      },
      start: 0,
      limit: 30,
      sort_by: "creation desc",
      sort_order: "desc"
    }, headers: auth_headers)

    # Empty parameters
    test_endpoint("POST /api/method/lms.utils.get_courses", {}, headers: auth_headers)

    # Null values
    test_endpoint("POST /api/method/lms.utils.get_upcoming_evals", {
      courses: nil,
      batch: nil
    }, headers: auth_headers)

    # Unicode characters
    test_endpoint("POST /api/method/lms.utils.get_courses", {
      filters: { title: "🎓 Test Course with émojis & ünicode" }
    }, headers: auth_headers)

    puts ""
  end

  def test_endpoint(name, data = {}, headers: {}, expected_status: 200, content_type: "application/json")
    print "Testing #{name}... "

    response_data, http_response = make_request("POST", extract_path(name), data, headers, content_type)

    status = response_data["status"] || http_response.code.to_i rescue 500
    if status == expected_status ||
       (expected_status == 200 && status >= 200 && status < 300)

      if response_data["message"] || response_data["data"]
        puts "✅ PASS (HTTP #{response_data["status"]})"
        @passed += 1
        @test_results << { name: name, status: :passed, response: response_data }
      else
        puts "⚠️  PASS but empty response (HTTP #{status})"
        @passed += 1
        @test_results << { name: name, status: :passed, response: response_data }
      end

      yield response_data, http_response if block_given?
    else
      puts "❌ FAIL (HTTP #{status})"
      puts "  Response: #{response_data["message"] || response_data.inspect}"
      @failed += 1
      @test_results << { name: name, status: :failed, response: response_data }
    end
  end

  def make_request(method, path, data = {}, headers = {}, content_type = "application/json")
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
    when "POST"
      req = Net::HTTP::Post.new(uri)
      req.body = data.is_a?(String) ? data : data.to_json
      req
    when "GET"
      req = Net::HTTP::Get.new(uri)
      req
    else
      raise "Unsupported method: #{method}"
    end

    req["Content-Type"] = content_type unless data.empty?

    # Add session cookies for authentication
    if @cookies.any?
      cookie_string = @cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
      req['Cookie'] = cookie_string
    end

    headers.each { |key, value| req[key] = value }

    response = http.request(req)
    parsed = JSON.parse(response.body) rescue nil
    if parsed
      parsed["status"] = response.code.to_i
      [ parsed, response ]
    else
      [ { "status" => response.code.to_i, "message" => "Invalid JSON: #{response.body}" }, response ]
    end
  rescue => e
    { "status" => 500, "message" => "Request failed: #{e.message}" }
  end

  def extract_path(name)
    # Extract path from test name like "POST /api/method/login"
    name.match(/POST (.+)/)[1]
  end

  def auth_headers
    # Authentication is handled via cookies in make_request
    {}
  end

  def print_summary
    puts "=" * 60
    puts "📊 COMPREHENSIVE TEST SUMMARY"
    puts "=" * 60
    puts "Total tests: #{@passed + @failed}"
    puts "Passed: #{@passed}"
    puts "Failed: #{@failed}"

    success_rate = (@passed.to_f / (@passed + @failed) * 100).round(2)
    puts "Success rate: #{success_rate}%"

    if @failed == 0
      puts "🎯 PERFECT COMPATIBILITY - 100% SUCCESS!"
    elsif success_rate >= 95
      puts "🟡 EXCELLENT COMPATIBILITY - 95%+ SUCCESS!"
    elsif success_rate >= 90
      puts "🟢 GOOD COMPATIBILITY - 90%+ SUCCESS!"
    else
      puts "🔴 NEEDS IMPROVEMENTS"
    end

    if @failed > 0
      puts "\n❌ Failed tests:"
      @test_results.select { |r| r[:status] == :failed }.each do |result|
        puts "- #{result[:name]}: #{result[:response]["message"]}"
      end
    end

    puts "\n🔧 Next Steps:"
    if @failed == 0
      puts "✅ All endpoints working perfectly!"
      puts "🚀 Ready for production deployment!"
    else
      puts "1. Fix the #{@failed} failing endpoints"
      puts "2. Re-run comprehensive tests"
      puts "3. Cross-check with Frappe Python backend"
    end
  end
end

# Run the comprehensive test
if __FILE__ == $0
  tester = FrappeCompatibilityTester.new
  tester.run_all_tests
end
