#!/bin/bash

# NexusGreen Production Testing Script
# Comprehensive frontend and backend testing
# Version: 6.0.0

set -e

echo "🧪 NexusGreen Production Testing Suite"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test configuration
API_BASE_URL="http://localhost:3001"
FRONTEND_URL="http://localhost:8080"
TEST_LOG="/tmp/nexusgreen-test-$(date +%Y%m%d-%H%M%S).log"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_test() {
    echo -e "${BLUE}[TEST]${NC} $1" | tee -a "$TEST_LOG"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$TEST_LOG"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$TEST_LOG"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

print_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1" | tee -a "$TEST_LOG"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    ((TOTAL_TESTS++))
    print_test "$test_name"
    
    if eval "$test_command"; then
        if [ "$expected_result" = "success" ] || [ -z "$expected_result" ]; then
            print_pass "$test_name"
            return 0
        else
            print_fail "$test_name - Expected failure but got success"
            return 1
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            print_pass "$test_name - Expected failure"
            return 0
        else
            print_fail "$test_name"
            return 1
        fi
    fi
}

# Function to test HTTP endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local timeout="${4:-10}"
    
    ((TOTAL_TESTS++))
    print_test "$name"
    
    local response
    local status_code
    
    response=$(curl -s -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")
    status_code="${response: -3}"
    
    if [ "$status_code" = "$expected_status" ]; then
        print_pass "$name (Status: $status_code)"
        return 0
    else
        print_fail "$name (Expected: $expected_status, Got: $status_code)"
        return 1
    fi
}

# Function to test JSON API endpoint
test_json_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local check_json="${4:-true}"
    
    ((TOTAL_TESTS++))
    print_test "$name"
    
    local response
    local status_code
    local content_type
    
    response=$(curl -s -w "%{http_code}|%{content_type}" --max-time 10 -H "Accept: application/json" "$url" 2>/dev/null || echo "000|")
    status_code=$(echo "$response" | cut -d'|' -f2)
    content_type=$(echo "$response" | cut -d'|' -f3)
    
    if [ "$status_code" = "$expected_status" ]; then
        if [ "$check_json" = "true" ] && [[ "$content_type" == *"application/json"* ]]; then
            print_pass "$name (Status: $status_code, JSON: ✓)"
            return 0
        elif [ "$check_json" = "false" ]; then
            print_pass "$name (Status: $status_code)"
            return 0
        else
            print_fail "$name (Status: $status_code, Expected JSON but got: $content_type)"
            return 1
        fi
    else
        print_fail "$name (Expected: $expected_status, Got: $status_code)"
        return 1
    fi
}

# Initialize test log
echo "NexusGreen Production Test Suite - $(date)" > "$TEST_LOG"
echo "=============================================" >> "$TEST_LOG"

print_section "INFRASTRUCTURE TESTS"

# Test Docker services
run_test "Docker daemon is running" "docker info > /dev/null 2>&1"
run_test "Docker Compose is available" "docker-compose --version > /dev/null 2>&1"

# Test containers
run_test "Database container is running" "docker-compose ps | grep -q 'nexus-db.*Up'"
run_test "API container is running" "docker-compose ps | grep -q 'nexus-api.*Up'"
run_test "Frontend container is running" "docker-compose ps | grep -q 'nexus-green.*Up'"

print_section "DATABASE TESTS"

# Test database connectivity
run_test "Database is accepting connections" "docker-compose exec -T nexus-db pg_isready -U nexususer"

# Test database schema
run_test "Companies table exists" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c '\dt companies' | grep -q companies"
run_test "Users table exists" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c '\dt users' | grep -q users"
run_test "Installations table exists" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c '\dt installations' | grep -q installations"
run_test "Energy generation table exists" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c '\dt energy_generation' | grep -q energy_generation"

# Test data integrity
run_test "Companies have data" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c 'SELECT COUNT(*) FROM companies;' | grep -q '[1-9]'"
run_test "Installations have data" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c 'SELECT COUNT(*) FROM installations;' | grep -q '[1-9]'"
run_test "Energy generation has data" "docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -c 'SELECT COUNT(*) FROM energy_generation;' | grep -q '[1-9]'"

print_section "BACKEND API TESTS"

# Wait for API to be ready
print_info "Waiting for API to be ready..."
sleep 15

# Basic API health tests
test_endpoint "API Health Check" "$API_BASE_URL/api/health" "200"
test_json_endpoint "API Health JSON Response" "$API_BASE_URL/api/health" "200"

# Authentication endpoints
test_endpoint "Login endpoint exists" "$API_BASE_URL/api/auth/login" "405"  # POST only, so GET should return 405

# Data endpoints
test_json_endpoint "Companies endpoint" "$API_BASE_URL/api/companies" "200"
test_json_endpoint "Installations endpoint" "$API_BASE_URL/api/installations" "200"
test_json_endpoint "Alerts endpoint" "$API_BASE_URL/api/alerts" "200"
test_json_endpoint "Dashboard metrics endpoint" "$API_BASE_URL/api/dashboard/metrics" "200"

# Test API response structure
print_test "API returns valid JSON structure"
((TOTAL_TESTS++))
response=$(curl -s "$API_BASE_URL/api/health" 2>/dev/null)
if echo "$response" | jq . > /dev/null 2>&1; then
    print_pass "API returns valid JSON structure"
else
    print_fail "API returns invalid JSON structure"
fi

print_section "FRONTEND TESTS"

# Wait for frontend to be ready
print_info "Waiting for frontend to be ready..."
sleep 10

# Basic frontend tests
test_endpoint "Frontend loads" "$FRONTEND_URL" "200"
test_endpoint "Frontend serves static assets" "$FRONTEND_URL/favicon.svg" "200"

# Test frontend content
print_test "Frontend contains NexusGreen branding"
((TOTAL_TESTS++))
if curl -s "$FRONTEND_URL" | grep -q "NexusGreen"; then
    print_pass "Frontend contains NexusGreen branding"
else
    print_fail "Frontend missing NexusGreen branding"
fi

print_test "Frontend loads modern UI components"
((TOTAL_TESTS++))
if curl -s "$FRONTEND_URL" | grep -q "dashboard\|login"; then
    print_pass "Frontend loads modern UI components"
else
    print_fail "Frontend missing expected UI components"
fi

print_section "INTEGRATION TESTS"

# Test API-Frontend integration
print_test "Frontend can reach API"
((TOTAL_TESTS++))
# This test checks if the frontend proxy is working
if curl -s "$FRONTEND_URL/api/health" | grep -q "status\|ok"; then
    print_pass "Frontend can reach API"
else
    print_fail "Frontend cannot reach API"
fi

print_section "PERFORMANCE TESTS"

# Test response times
print_test "API response time < 2 seconds"
((TOTAL_TESTS++))
start_time=$(date +%s.%N)
curl -s "$API_BASE_URL/api/health" > /dev/null
end_time=$(date +%s.%N)
response_time=$(echo "$end_time - $start_time" | bc)
if (( $(echo "$response_time < 2.0" | bc -l) )); then
    print_pass "API response time: ${response_time}s"
else
    print_fail "API response time too slow: ${response_time}s"
fi

print_test "Frontend response time < 3 seconds"
((TOTAL_TESTS++))
start_time=$(date +%s.%N)
curl -s "$FRONTEND_URL" > /dev/null
end_time=$(date +%s.%N)
response_time=$(echo "$end_time - $start_time" | bc)
if (( $(echo "$response_time < 3.0" | bc -l) )); then
    print_pass "Frontend response time: ${response_time}s"
else
    print_fail "Frontend response time too slow: ${response_time}s"
fi

print_section "SECURITY TESTS"

# Test security headers
print_test "API has security headers"
((TOTAL_TESTS++))
headers=$(curl -s -I "$API_BASE_URL/api/health")
if echo "$headers" | grep -q "X-Content-Type-Options\|X-Frame-Options"; then
    print_pass "API has security headers"
else
    print_fail "API missing security headers"
fi

# Test for common vulnerabilities
print_test "API doesn't expose sensitive information"
((TOTAL_TESTS++))
response=$(curl -s "$API_BASE_URL/api/health")
if ! echo "$response" | grep -qi "password\|secret\|key\|token"; then
    print_pass "API doesn't expose sensitive information"
else
    print_fail "API may be exposing sensitive information"
fi

print_section "DATA VALIDATION TESTS"

# Test data consistency
print_test "Installation data is consistent"
((TOTAL_TESTS++))
installations=$(curl -s "$API_BASE_URL/api/installations" | jq length 2>/dev/null || echo "0")
if [ "$installations" -gt 0 ]; then
    print_pass "Installation data is consistent ($installations installations)"
else
    print_fail "No installation data found"
fi

print_test "Energy generation data exists"
((TOTAL_TESTS++))
energy_count=$(docker-compose exec -T nexus-db psql -U nexususer -d nexusgreen -t -c 'SELECT COUNT(*) FROM energy_generation;' | tr -d ' \n')
if [ "$energy_count" -gt 1000 ]; then
    print_pass "Energy generation data exists ($energy_count records)"
else
    print_fail "Insufficient energy generation data ($energy_count records)"
fi

print_section "MONITORING TESTS"

# Test logging
run_test "Application logs are being generated" "docker-compose logs --tail=10 nexus-api | grep -q '.'"
run_test "Database logs are being generated" "docker-compose logs --tail=10 nexus-db | grep -q '.'"

# Test resource usage
print_test "Memory usage is reasonable"
((TOTAL_TESTS++))
memory_usage=$(docker stats --no-stream --format "table {{.MemPerc}}" | tail -n +2 | head -1 | tr -d '%')
if (( $(echo "$memory_usage < 80" | bc -l) )); then
    print_pass "Memory usage is reasonable (${memory_usage}%)"
else
    print_fail "Memory usage is high (${memory_usage}%)"
fi

print_section "FEATURE TESTS"

# Test modern UI features
print_test "Modern dashboard is accessible"
((TOTAL_TESTS++))
if curl -s "$FRONTEND_URL" | grep -q "dashboard\|NexusGreen"; then
    print_pass "Modern dashboard is accessible"
else
    print_fail "Modern dashboard not accessible"
fi

# Test API features
print_test "Real-time data endpoints work"
((TOTAL_TESTS++))
if curl -s "$API_BASE_URL/api/dashboard/metrics" | jq . > /dev/null 2>&1; then
    print_pass "Real-time data endpoints work"
else
    print_fail "Real-time data endpoints not working"
fi

print_section "TEST SUMMARY"

echo ""
echo "🧪 NexusGreen Production Test Results"
echo "====================================="
echo ""
echo "📊 Test Statistics:"
echo "  • Total Tests: $TOTAL_TESTS"
echo "  • Passed: $PASSED_TESTS"
echo "  • Failed: $FAILED_TESTS"
echo "  • Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"

echo ""
echo "📁 Test Log: $TEST_LOG"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    print_pass "🎉 ALL TESTS PASSED! NexusGreen is ready for production!"
    echo ""
    echo "✅ System Status: HEALTHY"
    echo "✅ Database: OPERATIONAL"
    echo "✅ API: FUNCTIONAL"
    echo "✅ Frontend: ACCESSIBLE"
    echo "✅ Integration: WORKING"
    echo "✅ Performance: ACCEPTABLE"
    echo "✅ Security: BASIC CHECKS PASSED"
    echo ""
    echo "🚀 NexusGreen v6.0.0 is production-ready!"
    exit 0
else
    echo ""
    print_fail "❌ SOME TESTS FAILED! Please review the issues above."
    echo ""
    echo "🔍 Troubleshooting Steps:"
    echo "1. Check service logs: docker-compose logs"
    echo "2. Verify all containers are running: docker-compose ps"
    echo "3. Check system resources: docker stats"
    echo "4. Review test log: $TEST_LOG"
    echo ""
    echo "⚠️  System may not be ready for production use."
    exit 1
fi