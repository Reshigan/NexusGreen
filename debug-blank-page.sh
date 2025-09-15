#!/bin/bash
# Debug script for blank page issue

echo "🔍 Debugging blank page issue..."

echo "=== 1. Testing Frontend Response ==="
echo "Frontend HTML (first 50 lines):"
curl -s http://localhost | head -50

echo -e "\n=== 2. Testing API Response ==="
echo "API Health:"
curl -s http://localhost/api/health || echo "API health check failed"

echo -e "\nAPI Auth endpoint:"
curl -s http://localhost/api/auth/login -X POST -H "Content-Type: application/json" -d '{}' || echo "API auth endpoint failed"

echo -e "\n=== 3. Container Logs ==="
echo "Frontend container logs (last 20 lines):"
sudo docker-compose -f docker-compose.public.yml logs --tail=20 nexus-green

echo -e "\nAPI container logs (last 20 lines):"
sudo docker-compose -f docker-compose.public.yml logs --tail=20 nexus-api

echo -e "\n=== 4. Environment Variables Check ==="
echo "Frontend container environment:"
sudo docker-compose -f docker-compose.public.yml exec nexus-green env | grep VITE

echo -e "\n=== 5. File System Check ==="
echo "Frontend files in container:"
sudo docker-compose -f docker-compose.public.yml exec nexus-green ls -la /usr/share/nginx/html/

echo -e "\n=== 6. Nginx Configuration ==="
echo "Nginx config:"
sudo docker-compose -f docker-compose.public.yml exec nexus-green cat /etc/nginx/conf.d/default.conf

echo -e "\n=== 7. Network Connectivity ==="
echo "Internal network test (frontend to API):"
sudo docker-compose -f docker-compose.public.yml exec nexus-green curl -s http://nexus-api:3001/health || echo "Internal API connection failed"

echo -e "\n=== 8. Database Connection ==="
echo "Database connection test:"
sudo docker-compose -f docker-compose.public.yml exec nexus-api node -e "
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgresql://nexususer:nexuspass123@nexus-db:5432/nexusgreen'
});
pool.query('SELECT NOW()', (err, res) => {
  if (err) console.log('DB Error:', err.message);
  else console.log('DB Connected:', res.rows[0]);
  process.exit(0);
});
" 2>/dev/null || echo "Database connection test failed"

echo -e "\n=== 9. Build Information ==="
echo "Build artifacts:"
sudo docker-compose -f docker-compose.public.yml exec nexus-green find /usr/share/nginx/html -name "*.js" -o -name "*.css" -o -name "index.html" | head -10

echo -e "\n🎯 Summary:"
echo "- Containers running: $(sudo docker-compose -f docker-compose.public.yml ps --format 'table {{.Name}}\t{{.Status}}' | grep -c 'Up')/3"
echo "- Health check: $(curl -s http://localhost/health)"
echo "- Frontend accessible: $(curl -s -o /dev/null -w '%{http_code}' http://localhost)"
echo "- API accessible: $(curl -s -o /dev/null -w '%{http_code}' http://localhost/api/health)"