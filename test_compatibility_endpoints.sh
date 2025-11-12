#!/bin/bash

# Comprehensive Frappe Compatibility API Test Script
# Tests all endpoints systematically and reports results

BASE_URL="http://localhost:3000"
ALT_URL="http://localhost:3001"
TEST_EMAIL="testuser@example.com"
TEST_PASSWORD="password123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

test_endpoint() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local headers="$5"
    local expected_pattern="$6"

    ((TOTAL_TESTS++))
    log_info "Testing $test_name..."

    # Build curl command
    local curl_cmd="curl -s -w '\nHTTP_CODE:%{http_code}' -X $method"

    if [ -n "$headers" ]; then
        curl_cmd="$curl_cmd -H '$headers'"
    fi

    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi

    curl_cmd="$curl_cmd '$BASE_URL$endpoint'"

    # Execute request
    local response=$(eval $curl_cmd)
    local http_code=$(echo "$response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
    local body=$(echo "$response" | sed -e 's/HTTP_CODE:[0-9]*$//')

    # Check response
    if [ "$http_code" = "200" ] && [[ "$body" =~ $expected_pattern ]]; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name (HTTP $http_code)"
        echo "  Response: $body"
        return 1
    fi
}

# Setup - ensure server is running
echo "🚀 Testing Frappe Compatibility API Endpoints"
echo "=============================================="

# Check if server is running on either port
if curl -s "$BASE_URL" > /dev/null; then
    echo "✅ Server is running at $BASE_URL"
    ACTIVE_URL="$BASE_URL"
elif curl -s "$ALT_URL" > /dev/null; then
    echo "✅ Server is running at $ALT_URL"
    ACTIVE_URL="$ALT_URL"
    BASE_URL="$ALT_URL"
else
    echo "❌ Server not running at $BASE_URL or $ALT_URL"
    echo "Please start the Rails server: rails server -p 3000 -e test"
    exit 1
fi
echo ""

# 1. Authentication Tests
echo "🔐 AUTHENTICATION TESTS"
echo "======================="

# First create a test user via signup
log_info "Creating test user..."
signup_response=$(curl -s -X POST "$BASE_URL/api/signup" \
    -H "Content-Type: application/json" \
    -d "{\"signup_email\": \"$TEST_EMAIL\", \"full_name\": \"Test User\", \"password\": \"$TEST_PASSWORD\"}")

if [[ "$signup_response" =~ "successfully created" ]] || [[ "$signup_response" =~ "Already Registered" ]]; then
    log_success "Test user created/exists"
else
    log_warning "Signup response: $signup_response"
fi

# Test login
login_response=$(curl -s -X POST "$BASE_URL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"usr\": \"$TEST_EMAIL\", \"pwd\": \"$TEST_PASSWORD\"}")

if [[ "$login_response" =~ "token" ]]; then
    TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    log_success "Login successful"
else
    log_error "Login failed"
    echo "  Response: $login_response"
    exit 1
fi

# Test logout
test_endpoint "Logout" \
    "POST" \
    "/api/logout" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Re-login for subsequent tests
login_response=$(curl -s -X POST "$BASE_URL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"usr\": \"$TEST_EMAIL\", \"pwd\": \"$TEST_PASSWORD\"}")
TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo ""

# 2. LMS API Methods
echo "📚 LMS API METHODS"
echo "=================="

# Basic user info
test_endpoint "Get User Info" \
    "POST" \
    "/api/method/lms.api.get_user_info" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get all users
test_endpoint "Get All Users" \
    "POST" \
    "/api/method/lms.api.get_all_users" \
    '{"limit": 10}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get notifications
test_endpoint "Get Notifications" \
    "POST" \
    "/api/method/lms.api.get_notifications" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get branding
test_endpoint "Get Branding" \
    "POST" \
    "/api/method/lms.api.get_branding" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get LMS setting
test_endpoint "Get LMS Setting" \
    "POST" \
    "/api/method/lms.api.get_lms_setting" \
    '{"field": "allow_guest_access"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

echo ""

# 3. LMS Utils Methods
echo "🛠️  LMS UTILS METHODS"
echo "===================="

# Get my courses
test_endpoint "Get My Courses" \
    "POST" \
    "/api/method/lms.utils.get_my_courses" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get courses with filters
test_endpoint "Get Courses with Filters" \
    "POST" \
    "/api/method/lms.utils.get_courses" \
    '{"filters": {"published": 1}, "limit": 10, "offset": 0}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get course completion data
test_endpoint "Get Course Completion Data" \
    "POST" \
    "/api/method/lms.utils.get_course_completion_data" \
    '{"course": "1"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get course progress distribution
test_endpoint "Get Course Progress Distribution" \
    "POST" \
    "/api/method/lms.utils.get_course_progress_distribution" \
    '{"course": "1"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get tags
test_endpoint "Get Tags" \
    "POST" \
    "/api/method/lms.utils.get_tags" \
    '{"course": "1"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get reviews
test_endpoint "Get Reviews" \
    "POST" \
    "/api/method/lms.utils.get_reviews" \
    '{"course": "1"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get my batches
test_endpoint "Get My Batches" \
    "POST" \
    "/api/method/lms.utils.get_my_batches" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get batches with filters
test_endpoint "Get Batches with Filters" \
    "POST" \
    "/api/method/lms.utils.get_batches" \
    '{"filters": {"published": 1}, "limit": 10}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get upcoming evals
test_endpoint "Get Upcoming Evaluations" \
    "POST" \
    "/api/method/lms.utils.get_upcoming_evals" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get streak info
test_endpoint "Get Streak Info" \
    "POST" \
    "/api/method/lms.utils.get_streak_info" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get my live classes
test_endpoint "Get My Live Classes" \
    "POST" \
    "/api/method/lms.utils.get_my_live_classes" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Get heatmap data
test_endpoint "Get Heatmap Data" \
    "POST" \
    "/api/method/lms.utils.get_heatmap_data" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "message"

# Save current lesson
test_endpoint "Save Current Lesson" \
    "POST" \
    "/api/method/lms.utils.save_current_lesson" \
    '{"course": "1", "lesson": "lesson-123"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

echo ""

# 4. Frappe Client Methods
echo "🔌 FRAPPE CLIENT METHODS"
echo "========================"

# Frappe client get
test_endpoint "Frappe Client Get" \
    "POST" \
    "/api/method/frappe.client.get" \
    '{"doctype": "User", "filters": {"email": "'$TEST_EMAIL'"}}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Frappe client get count
test_endpoint "Frappe Client Get Count" \
    "POST" \
    "/api/method/frappe.client.get_count" \
    '{"doctype": "Course"}' \
    "Authorization: Bearer $TOKEN" \
    "message"

# Frappe client get list
test_endpoint "Frappe Client Get List" \
    "POST" \
    "/api/method/frappe.client.get_list" \
    '{"doctype": "Course", "filters": {"published": 1}}' \
    "Authorization: Bearer $TOKEN" \
    "message"

echo ""

# 5. Error Handling Tests
echo "⚠️  ERROR HANDLING TESTS"
echo "======================="

# Test invalid method
test_endpoint "Invalid Method" \
    "POST" \
    "/api/method/lms.api.invalid_method" \
    "" \
    "Authorization: Bearer $TOKEN" \
    "error"

# Test unauthorized access
test_endpoint "Unauthorized Access" \
    "POST" \
    "/api/method/lms.api.get_user_info" \
    "" \
    "" \
    "Not authenticated"

# Test invalid JSON
test_endpoint "Invalid JSON" \
    "POST" \
    "/api/method/lms.api.get_user_info" \
    '{invalid json}' \
    "Authorization: Bearer $TOKEN" \
    "error"

echo ""

# 6. Performance Tests
echo "⚡ PERFORMANCE TESTS"
echo "==================="

# Test response time for simple endpoint
log_info "Testing response time for get_user_info..."
start_time=$(date +%s%N)
response=$(curl -s -X POST "$BASE_URL/api/method/lms.api.get_user_info" \
    -H "Authorization: Bearer $TOKEN")
end_time=$(date +%s%N)
response_time=$((($end_time - $start_time) / 1000000))

if [ $response_time -lt 500 ]; then
    log_success "Response time: ${response_time}ms (< 500ms)"
else
    log_warning "Response time: ${response_time}ms (>= 500ms)"
fi

echo ""

# 7. Summary
echo "📊 TEST SUMMARY"
echo "==============="

success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo "Total tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Success rate: ${success_rate}%"

if [ $success_rate -eq 100 ]; then
    echo -e "${GREEN}🎯 ALL TESTS PASSED - 100% COMPATIBILITY!${NC}"
elif [ $success_rate -ge 90 ]; then
    echo -e "${YELLOW}🟡 EXCELLENT COMPATIBILITY - 90%+ WORKING!${NC}"
elif [ $success_rate -ge 80 ]; then
    echo -e "${YELLOW}🟢 GOOD COMPATIBILITY - 80%+ WORKING!${NC}"
else
    echo -e "${RED}🔴 NEEDS IMPROVEMENTS${NC}"
fi

echo ""

# 8. Next Steps
echo "🔧 NEXT STEPS"
echo "============="

if [ $FAILED_TESTS -gt 0 ]; then
    echo "Failed tests need investigation:"
    echo "1. Check Rails logs: tail -f log/test.log"
    echo "2. Run individual failing tests"
    echo "3. Fix implementation issues"
    echo ""
fi

echo "To run individual endpoint tests:"
echo "curl -X POST $BASE_URL/api/method/[method_name] \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer \$TOKEN' \\"
echo "  -d '{\"param\": \"value\"}'"

echo ""
echo "🎉 Testing completed!"
