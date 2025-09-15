#!/bin/bash
# Check backend connectivity and database status

echo "🔍 Checking Backend Connectivity and Database Status..."

# Check container status
echo "=== Container Status ==="
sudo docker-compose -f docker-compose.public.yml ps

# Check API health
echo -e "\n=== API Health Check ==="
echo "Testing API health endpoint..."
API_HEALTH=$(curl -s -w "%{http_code}" http://localhost/api/health -o /tmp/api_response.json)
echo "API Health Status Code: $API_HEALTH"
if [ -f /tmp/api_response.json ]; then
    echo "API Response:"
    cat /tmp/api_response.json
    echo ""
fi

# Check database connection
echo -e "\n=== Database Connection Test ==="
echo "Testing database connectivity..."
sudo docker exec nexus-api sh -c 'curl -s http://localhost:3001/api/health' || echo "Direct API container test failed"

# Check database tables
echo -e "\n=== Database Tables Check ==="
echo "Checking if database is seeded..."
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "\dt" 2>/dev/null || echo "Database connection failed"

# Check for data in key tables
echo -e "\n=== Data Verification ==="
echo "Checking for existing data..."

echo "Companies count:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT COUNT(*) FROM companies;" 2>/dev/null || echo "Companies table not found"

echo "Projects count:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT COUNT(*) FROM projects;" 2>/dev/null || echo "Projects table not found"

echo "Sites count:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT COUNT(*) FROM sites;" 2>/dev/null || echo "Sites table not found"

echo "Users count:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "Users table not found"

# Check API endpoints
echo -e "\n=== API Endpoints Test ==="
echo "Testing key API endpoints..."

endpoints=(
    "/api/auth/login"
    "/api/companies"
    "/api/projects"
    "/api/sites"
    "/api/users"
    "/api/dashboard/overview"
)

for endpoint in "${endpoints[@]}"; do
    echo -n "Testing $endpoint: "
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost$endpoint)
    if [ "$status" = "200" ] || [ "$status" = "401" ] || [ "$status" = "403" ]; then
        echo "✅ $status (OK)"
    else
        echo "❌ $status (Issue)"
    fi
done

# Check logs for errors
echo -e "\n=== Recent API Logs ==="
echo "Last 20 lines of API logs:"
sudo docker logs nexus-api --tail 20

echo -e "\n=== Recent Database Logs ==="
echo "Last 10 lines of database logs:"
sudo docker logs nexus-db --tail 10

# Test frontend to backend connectivity
echo -e "\n=== Frontend to Backend Test ==="
echo "Testing if frontend can reach backend..."
sudo docker exec nexus-green sh -c 'curl -s -w "Status: %{http_code}\n" http://nexus-api:3001/api/health' || echo "Frontend cannot reach backend"

echo -e "\n🔍 Connectivity Analysis Complete!"
echo -e "\n📋 Next Steps:"
echo "1. If API health fails: Check API container logs"
echo "2. If database is empty: Run database seeding script"
echo "3. If endpoints return 500: Check database connection"
echo "4. If frontend can't reach backend: Check docker network"