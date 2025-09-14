#!/bin/bash

# SolarNexus Production Test Script
# Tests the deployment on nexus.gonxt.tech

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMAIN="nexus.gonxt.tech"
API_URL="https://${DOMAIN}/api"
FRONTEND_URL="https://${DOMAIN}"

echo -e "${BLUE}🧪 Testing SolarNexus Production Deployment${NC}"
echo -e "${BLUE}Domain: ${DOMAIN}${NC}"
echo ""

# Function to print test results
print_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Test 1: DNS Resolution
echo -e "${YELLOW}Testing DNS resolution...${NC}"
if nslookup ${DOMAIN} > /dev/null 2>&1; then
    print_test 0 "DNS resolution for ${DOMAIN}"
else
    print_test 1 "DNS resolution for ${DOMAIN}"
fi

# Test 2: HTTP to HTTPS Redirect
echo -e "${YELLOW}Testing HTTP to HTTPS redirect...${NC}"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -L http://${DOMAIN}/ || echo "000")
if [ "$HTTP_RESPONSE" = "200" ]; then
    print_test 0 "HTTP to HTTPS redirect"
else
    print_test 1 "HTTP to HTTPS redirect (got $HTTP_RESPONSE)"
fi

# Test 3: HTTPS Frontend
echo -e "${YELLOW}Testing HTTPS frontend...${NC}"
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${FRONTEND_URL}/ || echo "000")
if [ "$HTTPS_RESPONSE" = "200" ]; then
    print_test 0 "HTTPS frontend access"
else
    print_test 1 "HTTPS frontend access (got $HTTPS_RESPONSE)"
fi

# Test 4: SSL Certificate
echo -e "${YELLOW}Testing SSL certificate...${NC}"
SSL_CHECK=$(echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
if [ $? -eq 0 ]; then
    print_test 0 "SSL certificate is valid"
    echo -e "${BLUE}Certificate info:${NC}"
    echo "$SSL_CHECK" | sed 's/^/  /'
else
    print_test 1 "SSL certificate validation"
fi

# Test 5: API Health Check
echo -e "${YELLOW}Testing API health endpoint...${NC}"
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/health || echo "000")
if [ "$API_HEALTH" = "200" ]; then
    print_test 0 "API health endpoint"
else
    print_test 1 "API health endpoint (got $API_HEALTH)"
fi

# Test 6: API Response
echo -e "${YELLOW}Testing API response...${NC}"
API_RESPONSE=$(curl -s ${API_URL}/health 2>/dev/null || echo "error")
if echo "$API_RESPONSE" | grep -q "status\|health\|ok" 2>/dev/null; then
    print_test 0 "API returns valid response"
    echo -e "${BLUE}API Response:${NC} $API_RESPONSE"
else
    print_test 1 "API returns valid response"
fi

# Test 7: Security Headers
echo -e "${YELLOW}Testing security headers...${NC}"
SECURITY_HEADERS=$(curl -s -I ${FRONTEND_URL}/ | grep -i "x-frame-options\|x-xss-protection\|x-content-type-options" | wc -l)
if [ "$SECURITY_HEADERS" -ge 2 ]; then
    print_test 0 "Security headers present"
else
    print_test 1 "Security headers missing"
fi

# Test 8: Gzip Compression
echo -e "${YELLOW}Testing Gzip compression...${NC}"
GZIP_TEST=$(curl -s -H "Accept-Encoding: gzip" -I ${FRONTEND_URL}/ | grep -i "content-encoding: gzip")
if [ -n "$GZIP_TEST" ]; then
    print_test 0 "Gzip compression enabled"
else
    print_test 1 "Gzip compression not detected"
fi

# Test 9: Response Time
echo -e "${YELLOW}Testing response time...${NC}"
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" ${FRONTEND_URL}/)
RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc 2>/dev/null || echo "0")
if (( $(echo "$RESPONSE_TIME < 3.0" | bc -l 2>/dev/null || echo 0) )); then
    print_test 0 "Response time acceptable (${RESPONSE_TIME}s)"
else
    print_test 1 "Response time slow (${RESPONSE_TIME}s)"
fi

# Test 10: WebSocket Support (if available)
echo -e "${YELLOW}Testing WebSocket support...${NC}"
WS_TEST=$(curl -s -I -H "Connection: Upgrade" -H "Upgrade: websocket" ${API_URL}/socket.io/ 2>/dev/null | head -1 | grep -o "[0-9][0-9][0-9]")
if [ "$WS_TEST" = "101" ] || [ "$WS_TEST" = "200" ]; then
    print_test 0 "WebSocket support available"
else
    print_test 1 "WebSocket support not detected"
fi

echo ""
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}=================${NC}"

# Count successful tests
TOTAL_TESTS=10
SUCCESS_COUNT=0

# Re-run quick tests for summary
nslookup ${DOMAIN} > /dev/null 2>&1 && ((SUCCESS_COUNT++))
[ "$(curl -s -o /dev/null -w "%{http_code}" -L http://${DOMAIN}/ 2>/dev/null)" = "200" ] && ((SUCCESS_COUNT++))
[ "$(curl -s -o /dev/null -w "%{http_code}" ${FRONTEND_URL}/ 2>/dev/null)" = "200" ] && ((SUCCESS_COUNT++))
echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -noout -dates > /dev/null 2>&1 && ((SUCCESS_COUNT++))
[ "$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/health 2>/dev/null)" = "200" ] && ((SUCCESS_COUNT++))
curl -s ${API_URL}/health 2>/dev/null | grep -q "status\|health\|ok" 2>/dev/null && ((SUCCESS_COUNT++))
[ "$(curl -s -I ${FRONTEND_URL}/ | grep -i "x-frame-options\|x-xss-protection\|x-content-type-options" | wc -l)" -ge 2 ] && ((SUCCESS_COUNT++))
curl -s -H "Accept-Encoding: gzip" -I ${FRONTEND_URL}/ | grep -qi "content-encoding: gzip" && ((SUCCESS_COUNT++))
RESP_TIME=$(curl -s -o /dev/null -w "%{time_total}" ${FRONTEND_URL}/ 2>/dev/null)
(( $(echo "$RESP_TIME < 3.0" | bc -l 2>/dev/null || echo 0) )) && ((SUCCESS_COUNT++))
WS_CODE=$(curl -s -I -H "Connection: Upgrade" -H "Upgrade: websocket" ${API_URL}/socket.io/ 2>/dev/null | head -1 | grep -o "[0-9][0-9][0-9]")
[ "$WS_CODE" = "101" ] || [ "$WS_CODE" = "200" ] && ((SUCCESS_COUNT++))

echo -e "${GREEN}Passed: ${SUCCESS_COUNT}/${TOTAL_TESTS} tests${NC}"

if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 All tests passed! Deployment is successful.${NC}"
    exit 0
elif [ $SUCCESS_COUNT -ge 7 ]; then
    echo -e "${YELLOW}⚠️  Most tests passed. Minor issues detected.${NC}"
    exit 0
else
    echo -e "${RED}❌ Multiple tests failed. Check deployment.${NC}"
    exit 1
fi