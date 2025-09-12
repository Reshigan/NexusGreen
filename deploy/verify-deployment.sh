#!/bin/bash

# SolarNexus Deployment Verification Script
# Verifies that all services are running correctly

set -e

echo "🔍 SolarNexus Deployment Verification"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:3000"
FRONTEND_URL="http://localhost:8080"
DOMAIN_URL="https://nexus.gonxt.tech"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        if [[ -n "$expected_result" ]]; then
            local result=$(eval "$test_command" 2>/dev/null)
            if [[ "$result" == *"$expected_result"* ]]; then
                echo -e "${GREEN}✅ PASS${NC}"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}❌ FAIL${NC} (Expected: $expected_result, Got: $result)"
                ((TESTS_FAILED++))
            fi
        else
            echo -e "${GREEN}✅ PASS${NC}"
            ((TESTS_PASSED++))
        fi
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to check service health
check_service_health() {
    local service_name="$1"
    local health_command="$2"
    
    echo -n "Checking $service_name health... "
    
    if eval "$health_command" &>/dev/null; then
        echo -e "${GREEN}✅ HEALTHY${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ UNHEALTHY${NC}"
        ((TESTS_FAILED++))
    fi
}

echo -e "\n${BLUE}🐳 Docker Container Status${NC}"
echo "=========================="

# Check if containers are running
containers=("solarnexus-postgres" "solarnexus-redis" "solarnexus-backend" "solarnexus-frontend" "solarnexus-nginx")

for container in "${containers[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{print $2}')
        echo -e "  ${container}: ${GREEN}✅ Running${NC} ($status)"
        ((TESTS_PASSED++))
    else
        echo -e "  ${container}: ${RED}❌ Not Running${NC}"
        ((TESTS_FAILED++))
    fi
done

echo -e "\n${BLUE}🔍 Service Health Checks${NC}"
echo "========================"

# Database health check
check_service_health "PostgreSQL Database" "docker exec solarnexus-postgres pg_isready -U solarnexus"

# Redis health check
check_service_health "Redis Cache" "docker exec solarnexus-redis redis-cli ping"

# Backend API health check
check_service_health "Backend API" "curl -s $BACKEND_URL/health"

# Frontend health check
check_service_health "Frontend App" "curl -s $FRONTEND_URL/health"

echo -e "\n${BLUE}🌐 API Endpoint Tests${NC}"
echo "===================="

# Test backend health endpoint
run_test "Backend Health Endpoint" "curl -s $BACKEND_URL/health" "healthy"

# Test backend API structure
run_test "Backend API Response" "curl -s $BACKEND_URL/api/health" ""

# Test frontend loading
run_test "Frontend Loading" "curl -s -o /dev/null -w '%{http_code}' $FRONTEND_URL" "200"

echo -e "\n${BLUE}🔒 Security Tests${NC}"
echo "================="

# Test HTTPS redirect (if nginx is configured)
if curl -s -I http://localhost | grep -q "Location.*https"; then
    echo -e "  HTTPS Redirect: ${GREEN}✅ ENABLED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  HTTPS Redirect: ${YELLOW}⚠️  NOT CONFIGURED${NC}"
fi

# Test security headers
if curl -s -I $BACKEND_URL | grep -q "X-Content-Type-Options"; then
    echo -e "  Security Headers: ${GREEN}✅ ENABLED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Security Headers: ${YELLOW}⚠️  PARTIAL${NC}"
fi

echo -e "\n${BLUE}💾 Data Persistence Tests${NC}"
echo "========================="

# Check Docker volumes
volumes=("solarnexus_postgres_data" "solarnexus_redis_data")
for volume in "${volumes[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo -e "  ${volume}: ${GREEN}✅ EXISTS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "  ${volume}: ${RED}❌ MISSING${NC}"
        ((TESTS_FAILED++))
    fi
done

echo -e "\n${BLUE}📊 Performance Tests${NC}"
echo "==================="

# Test API response time
response_time=$(curl -o /dev/null -s -w '%{time_total}' $BACKEND_URL/health)
if (( $(echo "$response_time < 2.0" | bc -l) )); then
    echo -e "  API Response Time: ${GREEN}✅ FAST${NC} (${response_time}s)"
    ((TESTS_PASSED++))
else
    echo -e "  API Response Time: ${YELLOW}⚠️  SLOW${NC} (${response_time}s)"
fi

# Test frontend response time
frontend_time=$(curl -o /dev/null -s -w '%{time_total}' $FRONTEND_URL)
if (( $(echo "$frontend_time < 3.0" | bc -l) )); then
    echo -e "  Frontend Response Time: ${GREEN}✅ FAST${NC} (${frontend_time}s)"
    ((TESTS_PASSED++))
else
    echo -e "  Frontend Response Time: ${YELLOW}⚠️  SLOW${NC} (${frontend_time}s)"
fi

echo -e "\n${BLUE}🔧 Configuration Tests${NC}"
echo "======================"

# Check environment variables
if docker exec solarnexus-backend env | grep -q "DATABASE_URL"; then
    echo -e "  Environment Variables: ${GREEN}✅ CONFIGURED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Environment Variables: ${RED}❌ MISSING${NC}"
    ((TESTS_FAILED++))
fi

# Check log files
if [[ -d "/opt/solarnexus/logs" ]]; then
    echo -e "  Log Directory: ${GREEN}✅ EXISTS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Log Directory: ${YELLOW}⚠️  MISSING${NC}"
fi

echo -e "\n${BLUE}📋 System Resources${NC}"
echo "==================="

# Check disk space
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $disk_usage -lt 80 ]]; then
    echo -e "  Disk Usage: ${GREEN}✅ OK${NC} (${disk_usage}%)"
else
    echo -e "  Disk Usage: ${YELLOW}⚠️  HIGH${NC} (${disk_usage}%)"
fi

# Check memory usage
memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [[ $memory_usage -lt 80 ]]; then
    echo -e "  Memory Usage: ${GREEN}✅ OK${NC} (${memory_usage}%)"
else
    echo -e "  Memory Usage: ${YELLOW}⚠️  HIGH${NC} (${memory_usage}%)"
fi

echo -e "\n${BLUE}🌐 External Connectivity${NC}"
echo "========================"

# Test domain connectivity (if configured)
if ping -c 1 nexus.gonxt.tech &>/dev/null; then
    echo -e "  Domain Connectivity: ${GREEN}✅ REACHABLE${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Domain Connectivity: ${YELLOW}⚠️  NOT CONFIGURED${NC}"
fi

# Test SSL certificate (if HTTPS is configured)
if openssl s_client -connect nexus.gonxt.tech:443 -servername nexus.gonxt.tech </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo -e "  SSL Certificate: ${GREEN}✅ VALID${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  SSL Certificate: ${YELLOW}⚠️  NOT CONFIGURED${NC}"
fi

# Final Results
echo -e "\n${BLUE}📊 Test Results Summary${NC}"
echo "======================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All tests passed! SolarNexus is ready for production.${NC}"
    
    echo -e "\n${BLUE}🌐 Access URLs:${NC}"
    echo "  • Frontend: http://localhost:8080"
    echo "  • Backend API: http://localhost:3000"
    echo "  • Health Check: http://localhost:3000/health"
    if ping -c 1 nexus.gonxt.tech &>/dev/null; then
        echo "  • Production: https://nexus.gonxt.tech"
    fi
    
    exit 0
elif [[ $TESTS_FAILED -lt 5 ]]; then
    echo -e "\n${YELLOW}⚠️  Some tests failed, but core functionality is working.${NC}"
    echo -e "${YELLOW}Check the failed tests above and refer to TROUBLESHOOTING.md${NC}"
    exit 1
else
    echo -e "\n${RED}❌ Multiple tests failed. Deployment needs attention.${NC}"
    echo -e "${RED}Please check the logs and refer to TROUBLESHOOTING.md${NC}"
    
    echo -e "\n${BLUE}🔧 Quick Diagnostics:${NC}"
    echo "  • Check logs: docker logs solarnexus-backend"
    echo "  • Check status: docker ps"
    echo "  • Restart services: sudo ./deploy/stop-services.sh && sudo ./deploy/start-services.sh"
    
    exit 2
fi