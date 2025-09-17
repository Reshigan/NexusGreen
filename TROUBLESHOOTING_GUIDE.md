# NexusGreen - Troubleshooting Guide

## 🚨 Common Issues & Solutions

This guide documents all the issues we've encountered during development and their solutions. Use this as a reference for debugging and resolving problems.

## 🐳 Docker & Deployment Issues

### Issue: Docker Daemon Not Running
**Symptoms:**
- `docker: Cannot connect to the Docker daemon`
- `docker-compose` commands fail

**Solution:**
```bash
# Start Docker daemon
sudo dockerd > /tmp/docker.log 2>&1 &

# Wait for Docker to initialize
sleep 5

# Verify Docker is running
sudo docker run hello-world
```

### Issue: Docker Compose Services Not Starting
**Symptoms:**
- Services fail to start
- Container exits immediately
- Port binding errors

**Diagnosis:**
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Check Docker daemon logs
tail -f /tmp/docker.log
```

**Common Solutions:**
1. **Port conflicts:** Change ports in docker-compose.yml
2. **Missing environment variables:** Check .env file
3. **Build failures:** Run `docker-compose build --no-cache`
4. **Permission issues:** Check file permissions and ownership

### Issue: Database Connection Failures
**Symptoms:**
- Backend cannot connect to PostgreSQL
- `ECONNREFUSED` errors
- Authentication failures

**Solution:**
```bash
# Check database container status
docker-compose logs database

# Verify database is accepting connections
docker-compose exec database pg_isready -U nexusgreen

# Check database credentials
docker-compose exec database psql -U nexusgreen -d nexusgreen -c "\dt"
```

**Common Causes:**
1. **Wrong credentials:** Verify POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
2. **Database not ready:** Add health checks and depends_on conditions
3. **Network issues:** Ensure services are on same Docker network

## 🔐 Authentication Issues

### Issue: Login Not Working
**Symptoms:**
- Login form submits but fails
- "Invalid credentials" errors
- Token not being set

**Diagnosis:**
```bash
# Check backend logs
docker-compose logs backend

# Test API endpoint directly
curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusgreen.com","password":"admin123"}'
```

**Common Solutions:**
1. **Password hashing mismatch:** Ensure consistent bcryptjs usage
2. **Database user not found:** Check user creation in init.sql
3. **CORS issues:** Verify CORS configuration in backend
4. **API endpoint routing:** Check nginx proxy configuration

### Issue: JWT Token Problems
**Symptoms:**
- Token not being stored
- "Unauthorized" errors on protected routes
- Token expiration issues

**Solution:**
```javascript
// Check token in browser localStorage
console.log(localStorage.getItem('token'));

// Verify token format and expiration
// Use jwt.io to decode and inspect token
```

**Common Causes:**
1. **Token not being saved:** Check frontend token storage logic
2. **Token format issues:** Verify JWT signing and verification
3. **Expired tokens:** Implement token refresh mechanism
4. **Missing Authorization header:** Check API request headers

## 🌐 Frontend Issues

### Issue: React App Not Loading
**Symptoms:**
- Blank page or loading spinner
- JavaScript errors in console
- Build files not found

**Diagnosis:**
```bash
# Check frontend container logs
docker-compose logs frontend

# Verify build files exist
docker-compose exec frontend ls -la /usr/share/nginx/html

# Check nginx configuration
docker-compose exec frontend cat /etc/nginx/conf.d/default.conf
```

**Common Solutions:**
1. **Build failures:** Check Vite build process and dependencies
2. **nginx configuration:** Verify static file serving and API proxy
3. **Missing dependencies:** Ensure all npm packages are installed
4. **TypeScript errors:** Fix compilation errors in React components

### Issue: API Calls Failing
**Symptoms:**
- Network errors in browser console
- CORS errors
- 404 errors for API endpoints

**Solution:**
```bash
# Test API endpoints directly
curl http://localhost/api/health

# Check nginx proxy configuration
docker-compose exec frontend cat /etc/nginx/conf.d/default.conf

# Verify backend is responding
curl http://backend:3001/api/health
```

**Common Causes:**
1. **CORS configuration:** Check backend CORS settings
2. **Proxy routing:** Verify nginx API proxy configuration
3. **Backend not running:** Check backend container status
4. **Wrong API URLs:** Verify frontend API configuration

### Issue: Charts Not Rendering
**Symptoms:**
- Empty chart containers
- Chart.js errors in console
- Data not displaying

**Solution:**
```javascript
// Check data format
console.log('Chart data:', chartData);

// Verify Chart.js configuration
console.log('Chart options:', chartOptions);

// Check for missing Chart.js components
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js';
```

**Common Causes:**
1. **Missing Chart.js components:** Register required Chart.js components
2. **Data format issues:** Ensure data matches Chart.js expected format
3. **Container sizing:** Check chart container dimensions
4. **Responsive issues:** Verify responsive chart configuration

## 🗄️ Database Issues

### Issue: Database Schema Not Created
**Symptoms:**
- Tables don't exist
- SQL errors about missing tables
- Empty database

**Solution:**
```bash
# Check if init.sql was executed
docker-compose logs database | grep "init.sql"

# Manually run initialization
docker-compose exec database psql -U nexusgreen -d nexusgreen -f /docker-entrypoint-initdb.d/init.sql

# Verify tables exist
docker-compose exec database psql -U nexusgreen -d nexusgreen -c "\dt"
```

**Common Causes:**
1. **init.sql not mounted:** Check volume mapping in docker-compose.yml
2. **SQL syntax errors:** Verify init.sql syntax
3. **Permission issues:** Check file permissions on init.sql
4. **Database already initialized:** PostgreSQL only runs init scripts on empty database

### Issue: Sample Data Missing
**Symptoms:**
- Empty tables
- No test users
- Dashboard shows no data

**Solution:**
```bash
# Check if data was inserted
docker-compose exec database psql -U nexusgreen -d nexusgreen -c "SELECT COUNT(*) FROM users;"

# Manually insert sample data
docker-compose exec database psql -U nexusgreen -d nexusgreen -c "
INSERT INTO users (email, password_hash, name) 
VALUES ('admin@nexusgreen.com', '\$2a\$10\$hash...', 'Admin User');
"
```

**Common Causes:**
1. **init.sql incomplete:** Ensure all INSERT statements are included
2. **Foreign key constraints:** Check table creation order
3. **Data type mismatches:** Verify data types in INSERT statements
4. **Constraint violations:** Check for unique constraint violations

## 🔧 Backend API Issues

### Issue: API Endpoints Not Responding
**Symptoms:**
- 404 errors for API calls
- Server not starting
- Express.js errors

**Diagnosis:**
```bash
# Check backend logs
docker-compose logs backend

# Test backend directly
curl http://localhost:3001/api/health

# Check if backend is listening
docker-compose exec backend netstat -tlnp | grep 3001
```

**Common Solutions:**
1. **Port binding issues:** Verify backend is listening on correct port
2. **Route configuration:** Check Express.js route definitions
3. **Middleware errors:** Verify middleware configuration
4. **Environment variables:** Check required environment variables

### Issue: Database Query Errors
**Symptoms:**
- SQL syntax errors
- Connection pool errors
- Query timeout errors

**Solution:**
```javascript
// Add query logging
console.log('Executing query:', query, params);

// Check connection pool status
console.log('Pool status:', pool.totalCount, pool.idleCount);

// Add error handling
try {
  const result = await pool.query(query, params);
  return result.rows;
} catch (error) {
  console.error('Database query error:', error);
  throw error;
}
```

**Common Causes:**
1. **SQL syntax errors:** Verify query syntax and parameters
2. **Connection pool exhaustion:** Implement proper connection management
3. **Long-running queries:** Add query timeouts and optimization
4. **Database locks:** Check for deadlocks and long transactions

## 🌐 Network & Connectivity Issues

### Issue: Services Cannot Communicate
**Symptoms:**
- Backend cannot reach database
- Frontend cannot reach backend
- DNS resolution errors

**Solution:**
```bash
# Check Docker network
docker network ls
docker network inspect nexusgreen_default

# Test service connectivity
docker-compose exec backend ping database
docker-compose exec frontend ping backend

# Check service discovery
docker-compose exec backend nslookup database
```

**Common Causes:**
1. **Network configuration:** Verify Docker Compose network settings
2. **Service names:** Use correct service names for internal communication
3. **Port configuration:** Check internal vs external port mappings
4. **Firewall issues:** Verify firewall rules and port access

### Issue: External Access Problems
**Symptoms:**
- Cannot access application from browser
- Connection refused errors
- Timeout errors

**Solution:**
```bash
# Check port bindings
docker-compose ps

# Test local access
curl http://localhost
curl http://localhost/api/health

# Check if ports are listening
netstat -tlnp | grep :80
netstat -tlnp | grep :3001
```

**Common Causes:**
1. **Port mapping:** Verify docker-compose.yml port mappings
2. **Firewall blocking:** Check firewall rules for required ports
3. **Service binding:** Ensure services bind to 0.0.0.0, not localhost
4. **Load balancer issues:** Check nginx configuration and upstream servers

## 🔍 Debugging Techniques

### Container Debugging
```bash
# Access container shell
docker-compose exec [service] /bin/sh

# View container logs
docker-compose logs -f [service]

# Check container resource usage
docker stats

# Inspect container configuration
docker inspect [container-name]
```

### Application Debugging
```bash
# Backend debugging
docker-compose exec backend node --inspect-brk=0.0.0.0:9229 server.js

# Database debugging
docker-compose exec database psql -U nexusgreen -d nexusgreen

# Frontend debugging (browser dev tools)
# Check Network tab for API calls
# Check Console for JavaScript errors
# Check Application tab for localStorage/sessionStorage
```

### Log Analysis
```bash
# View all logs
docker-compose logs

# Follow specific service logs
docker-compose logs -f backend

# Search logs for errors
docker-compose logs | grep -i error

# Export logs for analysis
docker-compose logs > application.log
```

## 🚀 Performance Issues

### Issue: Slow Application Response
**Symptoms:**
- Long page load times
- Slow API responses
- Database query timeouts

**Diagnosis:**
```bash
# Check container resource usage
docker stats

# Monitor database performance
docker-compose exec database pg_stat_activity

# Check network latency
docker-compose exec frontend ping backend
```

**Solutions:**
1. **Database optimization:** Add indexes, optimize queries
2. **Caching:** Implement Redis or in-memory caching
3. **Resource allocation:** Increase container memory/CPU limits
4. **Code optimization:** Profile and optimize application code

### Issue: High Memory Usage
**Symptoms:**
- Containers being killed (OOMKilled)
- System running out of memory
- Slow performance

**Solution:**
```bash
# Check memory usage
docker stats --no-stream

# Set memory limits in docker-compose.yml
services:
  backend:
    mem_limit: 512m
    memswap_limit: 512m
```

## 📋 Health Check Procedures

### System Health Verification
```bash
# Check all services are running
docker-compose ps

# Verify health endpoints
curl http://localhost/api/health

# Check database connectivity
docker-compose exec database pg_isready -U nexusgreen

# Test authentication
curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusgreen.com","password":"admin123"}'
```

### Automated Health Monitoring
```bash
#!/bin/bash
# health-check.sh

echo "Checking NexusGreen system health..."

# Check Docker Compose services
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Some services are not running"
    docker-compose ps
    exit 1
fi

# Check API health
if ! curl -f http://localhost/api/health > /dev/null 2>&1; then
    echo "❌ API health check failed"
    exit 1
fi

# Check database
if ! docker-compose exec -T database pg_isready -U nexusgreen > /dev/null 2>&1; then
    echo "❌ Database health check failed"
    exit 1
fi

echo "✅ All systems healthy"
```

## 📞 Getting Help

### Log Collection for Support
```bash
# Collect all logs
mkdir -p logs
docker-compose logs > logs/all-services.log
docker-compose logs frontend > logs/frontend.log
docker-compose logs backend > logs/backend.log
docker-compose logs database > logs/database.log

# System information
docker version > logs/docker-version.log
docker-compose version > logs/compose-version.log
uname -a > logs/system-info.log
```

### Useful Commands Reference
```bash
# Complete system restart
docker-compose down && docker-compose up -d

# Rebuild and restart
docker-compose down && docker-compose build --no-cache && docker-compose up -d

# Reset database (WARNING: destroys data)
docker-compose down -v && docker-compose up -d

# View real-time logs
docker-compose logs -f

# Execute commands in containers
docker-compose exec [service] [command]
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-09-17  
**Maintained By:** Development Team  
**Contact:** openhands@all-hands.dev