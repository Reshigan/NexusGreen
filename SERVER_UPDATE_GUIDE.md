# 🚀 NexusGreen Server Update Guide

## 🔧 **Database Connection Issue Fixed**

**Issue Resolved**: PostgreSQL connection error - "database nexususer does not exist"

### ✅ **Fixes Applied**

1. **Docker Compose Service Name**: Fixed API connection to use correct service name `nexus-db`
2. **Database Connection Retry**: Added intelligent retry logic with exponential backoff
3. **Health Check Enhancement**: Improved health endpoints with database connectivity testing
4. **Connection Pool Optimization**: Enhanced PostgreSQL connection pool settings

---

## 📋 **How to Update Your Server**

### **Method 1: Quick Update (Recommended)**
```bash
# Navigate to your NexusGreen directory
cd /root/NexusGreen

# Pull latest changes from GitHub
git pull origin main

# Rebuild and restart services
docker-compose down
docker-compose up -d --build

# Check service status
docker-compose ps
```

### **Method 2: Fresh Deployment**
```bash
# Backup existing data (optional)
docker-compose exec nexus-db pg_dump -U nexususer nexusgreen > backup_$(date +%Y%m%d_%H%M%S).sql

# Remove old deployment
cd /root
rm -rf NexusGreen

# Fresh clone and deploy
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen
./deploy-production-complete.sh
```

---

## 🔍 **Verification Steps**

### **1. Check Service Status**
```bash
docker-compose ps
```
**Expected Output:**
```
NAME                IMAGE               STATUS
nexus-api           nexusgreen_api      Up (healthy)
nexus-db            postgres:15-alpine  Up (healthy)
nexus-green         nexusgreen_frontend Up (healthy)
```

### **2. Test Database Connection**
```bash
# Check API health
curl http://localhost:3001/health

# Expected response:
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2025-09-14T20:30:00.000Z"
}
```

### **3. Test Application Access**
```bash
# Test frontend
curl -I http://localhost:8080

# Expected: HTTP/1.1 200 OK
```

### **4. Check Logs**
```bash
# API logs (should show successful database connection)
docker-compose logs nexus-api

# Expected to see:
# ✅ Database connected successfully
# 🚀 Nexus Green API server running on port 3001

# Database logs (should show ready to accept connections)
docker-compose logs nexus-db

# Expected to see:
# database system is ready to accept connections
```

---

## 🛠️ **Troubleshooting**

### **If Services Don't Start**
```bash
# Check detailed logs
docker-compose logs -f

# Restart specific service
docker-compose restart nexus-api

# Rebuild specific service
docker-compose up -d --build nexus-api
```

### **If Database Connection Still Fails**
```bash
# Check database is running
docker-compose exec nexus-db psql -U nexususer -d nexusgreen -c "SELECT 1;"

# Reset database (WARNING: This will delete all data)
docker-compose down -v
docker-compose up -d
```

### **If Frontend Doesn't Load**
```bash
# Check nginx logs
docker-compose logs nexus-green

# Rebuild frontend
docker-compose up -d --build nexus-green
```

---

## 📊 **What's Fixed**

### **Database Connection Issues**
- ✅ **Service Name Mismatch**: Fixed `nexus-green-db` → `nexus-db` in connection string
- ✅ **Connection Retry Logic**: Added 10 retry attempts with exponential backoff
- ✅ **Connection Pool**: Optimized PostgreSQL connection settings
- ✅ **Health Checks**: Enhanced health endpoints with database testing

### **API Improvements**
- ✅ **Startup Reliability**: Server waits for database before starting
- ✅ **Error Handling**: Better error messages and logging
- ✅ **Health Monitoring**: Comprehensive health check endpoints
- ✅ **Graceful Shutdown**: Proper cleanup on service termination

### **Build Issues**
- ✅ **Terser Dependency**: Added missing terser for Vite production builds
- ✅ **Docker Optimization**: Improved multi-stage build process
- ✅ **Service Dependencies**: Proper service startup order

---

## 🎯 **Expected Results After Update**

### **Service Status**
- 🟢 **Database**: PostgreSQL running with initialized schema and data
- 🟢 **API**: Node.js server connected to database with retry logic
- 🟢 **Frontend**: React application serving modern dashboard
- 🟢 **Health Checks**: All services reporting healthy status

### **Application Features**
- 🌟 **Dashboard**: Modern UI with animations and real-time data
- 📊 **Analytics**: Energy generation charts and financial tracking
- 🔔 **Alerts**: Alert management system with resolution tracking
- 👥 **Users**: Authentication system with role-based access
- 🏢 **Installations**: 10 solar installations with 90 days of data

### **Performance Metrics**
- ⚡ **Frontend Load**: < 3 seconds initial load
- ⚡ **API Response**: < 2 seconds average response time
- ⚡ **Database Queries**: Optimized with proper indexing
- ⚡ **Health Checks**: < 1 second response time

---

## 🔄 **Maintenance Commands**

### **Regular Monitoring**
```bash
# Check service health
curl http://localhost:3001/api/health

# Monitor resource usage
docker stats

# View recent logs
docker-compose logs --tail=50 -f
```

### **Database Maintenance**
```bash
# Backup database
docker-compose exec nexus-db pg_dump -U nexususer nexusgreen > backup.sql

# Check database size
docker-compose exec nexus-db psql -U nexususer -d nexusgreen -c "
  SELECT pg_size_pretty(pg_database_size('nexusgreen')) as database_size;"

# View table statistics
docker-compose exec nexus-db psql -U nexususer -d nexusgreen -c "
  SELECT schemaname,tablename,n_tup_ins,n_tup_upd,n_tup_del 
  FROM pg_stat_user_tables ORDER BY n_tup_ins DESC;"
```

### **Log Management**
```bash
# Clear old logs
docker system prune -f

# Rotate logs
docker-compose logs --no-log-prefix > nexusgreen_$(date +%Y%m%d).log
```

---

## 🎉 **Success Confirmation**

After updating, you should be able to:

1. **Access Dashboard**: http://your-server-ip:8080
2. **Login**: admin@nexusgreen.energy / NexusGreen2024!
3. **View Data**: See 10 solar installations with realistic data
4. **Check Health**: http://your-server-ip:3001/api/health returns healthy status
5. **Monitor Logs**: All services show successful startup and operation

---

## 📞 **Support**

If you encounter any issues after the update:

1. **Check Logs**: `docker-compose logs -f`
2. **Verify Status**: `docker-compose ps`
3. **Test Health**: `curl http://localhost:3001/health`
4. **Restart Services**: `docker-compose restart`

The platform is now production-ready with robust error handling and connection reliability! 🌞

---

*Update Guide for NexusGreen v6.0.0 - Database Connection Issues Resolved*