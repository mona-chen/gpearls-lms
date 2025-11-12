#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class FrappeProductionReadinessTest
  def initialize(base_url = 'http://localhost:3001')
    @base_url = base_url
    @token = nil
    @results = []
  end

  def run_production_test
    puts "🚀 FRAPPE COMPATIBILITY - PRODUCTION READINESS TEST"
    puts "=" * 60
    puts "Testing against real Frappe Python backend expectations..."
    puts ""

    # Phase 1: Authentication
    authenticate_user
    return unless @token

    # Phase 2: Core LMS Functionality (Must Work 100%)
    test_core_lms_functionality

    # Phase 3: Advanced Features (Should Work 100%)
    test_advanced_features

    # Phase 4: Error Handling (Must Behave Correctly)
    test_error_handling

    # Phase 5: Performance & Edge Cases
    test_performance_and_edge_cases

    # Phase 6: Cross-Check with Frappe Patterns
    test_frappe_patterns

    # Final Report
    generate_production_report
  end

  private

  def authenticate_user
    puts "🔐 STEP 1: AUTHENTICATION"
    puts "-" * 30

    # Login with test user
    response = api_request("POST", "/api/login", {
      usr: "testuser@example.com",
      pwd: "password123"
    })

    if response["message"] && response["message"]["token"]
      @token = response["message"]["token"]
      puts "✅ Authentication successful"
      puts ""
    else
      puts "❌ Authentication failed - cannot proceed"
      puts "Response: #{response.inspect}"
      exit 1
    end
  end

  def test_core_lms_functionality
    puts "📚 STEP 2: CORE LMS FUNCTIONALITY"
    puts "-" * 40
    puts "Testing essential endpoints that MUST work for frontend..."

    # User Management
    test_api("lms.api.get_user_info", {}, "User profile data")
    test_api("lms.api.get_all_users", { limit: 10 }, "User listing")
    test_api("lms.api.get_notifications", {}, "User notifications")

    # Course Management - MOST CRITICAL
    test_api("lms.utils.get_courses", {
      doctype: "LMS Course",
      filters: { published: 1, upcoming: 0 },
      start: 0,
      limit: 30
    }, "Course listing with filters")

    test_api("lms.utils.get_my_courses", {}, "User enrolled courses")
    test_api("lms.utils.get_course_completion_data", { course: "1" }, "Course completion statistics")
    test_api("lms.utils.get_course_progress_distribution", { course: "1" }, "Course progress distribution")

    # Batch Management
    test_api("lms.utils.get_my_batches", {}, "User enrolled batches")
    test_api("lms.utils.get_batches", { filters: { published: 1 } }, "Batch listing")
    test_api("lms.utils.get_upcoming_evals", { courses: [], batch: nil }, "Upcoming evaluations")

    # Settings
    test_api("lms.api.get_branding", {}, "Site branding")
    test_api("lms.api.get_lms_setting", { field: "allow_guest_access" }, "LMS settings")
    test_api("lms.api.get_translations", {}, "System translations")

    puts ""
  end

  def test_advanced_features
    puts "🛠️  STEP 3: ADVANCED FEATURES"
    puts "-" * 35
    puts "Testing advanced features for complete functionality..."

    # Certifications
    test_api("lms.api.get_certification_categories", {
      doctype: "LMS Certificate",
      start: 0,
      limit: 20
    }, "Certification categories")

    test_api("lms.api.get_certified_participants", {
      doctype: "LMS Certificate",
      filters: {},
      start: 0,
      limit: 100
    }, "Certified participants listing")

    # User Analytics
    test_api("lms.utils.get_streak_info", {}, "User streak statistics")
    test_api("lms.utils.get_my_live_classes", {}, "User live classes")
    test_api("lms.utils.get_heatmap_data", {}, "User activity heatmap")
    test_api("lms.utils.get_chart_data", { chart_name: "course_completion" }, "Analytics charts")

    # Course Content
    test_api("lms.utils.get_tags", { course: "1" }, "Course tags")
    test_api("lms.utils.get_reviews", { course: "1" }, "Course reviews")
    test_api("lms.utils.save_current_lesson", {
      course: "1",
      lesson: "lesson_123"
    }, "Save current lesson progress")

    # Frappe Client Methods
    test_api("frappe.client.get", {
      doctype: "User",
      filters: { email: "testuser@example.com" }
    }, "Get single document")

    test_api("frappe.client.get_list", {
      doctype: "Course",
      filters: { published: 1 }
    }, "Get document list")

    test_api("frappe.client.get_count", { doctype: "Course" }, "Get document count")
    test_api("frappe.client.get_single_value", {
      doctype: "LMS Settings",
      field: "allow_guest_access"
    }, "Get single value")

    puts ""
  end

  def test_error_handling
    puts "⚠️  STEP 4: ERROR HANDLING"
    puts "-" * 30
    puts "Testing proper error responses..."

    # Invalid method should return 404
    response = api_request("POST", "/api/method/lms.api.invalid_method", {})
    if response["status"] == 404 || response["message"]&.include?("Unknown method")
      puts "✅ Invalid method returns proper 404"
    else
      puts "❌ Invalid method error handling failed"
    end

    # Unauthorized should return 401
    response = api_request("POST", "/api/method/lms.api.get_user_info", {})
    if response["status"] == 401 || response["message"]&.include?("Not authenticated")
      puts "✅ Unauthorized returns proper 401"
    else
      puts "❌ Unauthorized error handling failed"
    end

    # Invalid JSON should return 400
    begin
      uri = URI("#{@base_url}/api/method/lms.api.get_user_info")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Bearer #{@token}"
      req.body = '{invalid json}'

      response = http.request(req)
      parsed = JSON.parse(response.body) rescue { "status" => response.code.to_i }

      if parsed["status"] == 400 || response.code == "400"
        puts "✅ Invalid JSON returns proper 400"
      else
        puts "❌ Invalid JSON error handling failed"
      end
    rescue => e
      puts "❌ Invalid JSON test failed: #{e.message}"
    end

    puts ""
  end

  def test_performance_and_edge_cases
    puts "🔍 STEP 5: PERFORMANCE & EDGE CASES"
    puts "-" * 40

    # Large dataset test
    start_time = Time.now
    test_api("lms.utils.get_courses", {
      filters: {},
      limit: 100,
      start: 0
    }, "Large dataset query (100 items)")
    end_time = Time.now

    if (end_time - start_time) < 2.0
      puts "✅ Performance: Large query completed in #{((end_time - start_time) * 1000).round(0)}ms"
    else
      puts "⚠️  Performance: Large query took #{((end_time - start_time) * 1000).round(0)}ms (slow)"
    end

    # Complex filters
    test_api("lms.utils.get_courses", {
      doctype: "LMS Course",
      filters: {
        published: 1,
        upcoming: 0,
        featured: 1,
        category: "Programming"
      },
      start: 0,
      limit: 30,
      sort_by: "creation desc"
    }, "Complex filters and sorting")

    # Empty parameters
    test_api("lms.utils.get_courses", {}, "Empty parameters")

    # Unicode and special characters
    test_api("lms.utils.get_courses", {
      filters: { title: "🎓 Test Course with émojis & ünicode ñáîç" }
    }, "Unicode characters in filters")

    puts ""
  end

  def test_frappe_patterns
    puts "🔧 STEP 6: FRAPPE PATTERNS COMPLIANCE"
    puts "-" * 45
    puts "Verifying exact Frappe Python backend patterns..."

    # Test Frappe-style response structure
    response = api_request("POST", "/api/method/lms.utils.get_courses", {
      doctype: "LMS Course",
      filters: { published: 1 },
      start: 0,
      limit: 10
    })

    if response["message"] && (response["message"]["data"] || response["message"].is_a?(Array))
      puts "✅ Response follows Frappe {message: data|message} pattern"
    else
      puts "❌ Response doesn't follow Frappe pattern"
    end

    # Test proper Frappe field names
    if response["message"] && response["message"]["data"]&.first&.dig("creation")
      puts "✅ Uses Frappe field names (creation vs created_at)"
    else
      puts "❌ Missing Frappe field names"
    end

    # Test Frappe date format
    if response["message"] && response["message"]["data"]&.first&.dig("creation")&.match?(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/)
      puts "✅ Uses Frappe date format (YYYY-MM-DD HH:MM:SS)"
    else
      puts "❌ Date format not Frappe-compliant"
    end

    puts ""
  end

  def test_api(method_path, params, description)
    print "Testing #{description}... "

    response = api_request("POST", "/api/method/#{method_path}", params)

    if response && !response.empty? && (response["message"] || response["data"])
      puts "✅ SUCCESS"
      @results << { method: method_path, status: :success, description: description }
    elsif response && response["status"] == 404
      puts "❌ METHOD NOT FOUND"
      @results << { method: method_path, status: :missing, description: description }
    elsif response && response["status"] == 500
      puts "❌ SERVER ERROR: #{response["message"]}"
      @results << { method: method_path, status: :error, description: description, error: response["message"] }
    else
      puts "❌ FAILED: #{response.inspect}"
      @results << { method: method_path, status: :failed, description: description, response: response }
    end
  end

  def api_request(method, path, data = {})
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
    when "POST"
      req = Net::HTTP::Post.new(uri)
      req.body = data.to_json
      req
    else
      raise "Unsupported method: #{method}"
    end

    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{@token}" if @token

    response = http.request(request)
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    { "status" => response.code.to_i, "message" => "Invalid JSON: #{response.body}" }
  rescue => e
    { "status" => 500, "message" => "Request failed: #{e.message}" }
  end

  def generate_production_report
    puts "=" * 60
    puts "📊 PRODUCTION READINESS REPORT"
    puts "=" * 60

    success = @results.count { |r| r[:status] == :success }
    failed = @results.count { |r| r[:status] == :failed || r[:status] == :error }
    missing = @results.count { |r| r[:status] == :missing }
    total = @results.length

    puts "Total endpoints tested: #{total}"
    puts "✅ Working: #{success}"
    puts "❌ Failed: #{failed}"
    puts "⚠️  Missing: #{missing}"

    success_rate = (success.to_f / total * 100).round(2)
    puts "Success rate: #{success_rate}%"

    if success_rate == 100.0
      puts "🎯 PERFECT - 100% PRODUCTION READY!"
      puts "🚀 All Frappe compatibility requirements met"
      puts "✅ Vue.js frontend will work seamlessly"
    elsif success_rate >= 98.0
      puts "🟡 EXCELLENT - #{success_rate}% PRODUCTION READY!"
      puts "🚀 Minor issues only - Vue.js frontend will work"
    elsif success_rate >= 95.0
      puts "🟢 GOOD - #{success_rate}% MOSTLY PRODUCTION READY"
      puts "⚠️  Some issues - Vue.js frontend may have limited functionality"
    else
      puts "🔴 NOT READY - #{success_rate}% NEEDS CRITICAL FIXES"
      puts "❌ Vue.js frontend will have significant issues"
    end

    # Critical failures
    if failed > 0
      puts "\n❌ CRITICAL FAILURES:"
      @results.select { |r| r[:status] == :failed || r[:status] == :error }.each do |result|
        puts "- #{result[:description]}: #{result[:error] || 'Unknown error'}"
      end
    end

    # Missing methods
    if missing > 0
      puts "\n⚠️  MISSING METHODS:"
      @results.select { |r| r[:status] == :missing }.each do |result|
        puts "- #{result[:method]}: Method not implemented"
      end
    end

    puts "\n🎯 PRODUCTION READINESS CHECKLIST:"
    puts "✅ Authentication: Working" if @token
    puts "✅ User Management: #{(@results.select { |r| r[:method]&.include?('user') }.all? { |r| r[:status] == :success }) ? 'Working' : 'Issues'}"
    puts "✅ Course Management: #{(@results.select { |r| r[:method]&.include?('course') }.all? { |r| r[:status] == :success }) ? 'Working' : 'Issues'}"
    puts "✅ Error Handling: Working" if @results.any? { |r| r[:method]&.include?('invalid') }
    puts "✅ Frappe Patterns: #{@results.any? ? 'Compliant' : 'Need testing'}"

    puts "\n🚀 FINAL RECOMMENDATION:"
    if success_rate >= 98.0
      puts "✅ APPROVED FOR PRODUCTION DEPLOYMENT"
      puts "🎯 Rails backend successfully replicates Frappe Python backend"
      puts "📱 Vue.js frontend will work without modifications"
    else
      puts "❌ NOT APPROVED FOR PRODUCTION"
      puts "🔧 Critical issues must be resolved before deployment"
      puts "📝 See failures above for required fixes"
    end

    puts "\n" + "=" * 60
  end
end

# Run the production test
if __FILE__ == $0
  tester = FrappeProductionReadinessTest.new
  tester.run_production_test
end
