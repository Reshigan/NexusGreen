# 🔧 SolarNexus Troubleshooting Guide

## 🚨 Quick Solutions for Immediate Issues

### Frontend Not Starting (TradeAI/SolarNexus)

**Symptoms:**
- Backend is healthy but frontend doesn't respond
- Port 80 not accessible
- Frontend container exits or restarts

**Quick Fixes:**
```bash
# 1. Check container status
docker ps -a

# 2. Check frontend logs
docker logs tradeai_frontend  # or solarnexus-frontend

# 3. Restart frontend container
docker restart tradeai_frontend

# 4. Rebuild frontend
docker-compose up -d --build frontend

# 5. Check if port 80 is blocked
sudo ufw status
```

### Installation Directory Conflicts

**Error:** `fatal: destination path '.' already exists and is not an empty directory`

**Solution:**
```bash
# Use the fix script
sudo ./fix-installation.sh

# Or manually remove and reinstall
sudo rm -rf /home/ubuntu/SolarNexus
```

### Docker Package Conflicts

**Error:** `Conflict. The container name is already in use`

**Solution:**
```bash
# Use the Docker fix script
sudo ./fix-docker.sh

# Or manually fix
sudo apt-get remove -y containerd.io docker-ce docker-ce-cli
sudo apt-get install -y docker.io docker-compose
```

## Common Deployment Issues and Solutions

### 1. Missing Environment Variables

**Error:**
```
WARN[0000] The "REACT_APP_API_URL" variable is not set. Defaulting to a blank string.
```

**Solution:**
```bash
# Create environment file with all required variables
cp .env.production.template /opt/solarnexus/.env.production

# Edit the file with your actual values
nano /opt/solarnexus/.env.production

# Ensure these variables are set:
REACT_APP_API_URL="https://nexus.gonxt.tech/api"
REACT_APP_ENVIRONMENT="production"
REACT_APP_VERSION="1.0.0"
```

### 2. Docker Compose Version Warning

**Error:**
```
WARN[0000] /opt/tradeai/docker-compose.production.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion
```

**Solution:**
The warning is harmless but can be fixed by removing the version line from docker-compose.yml. Our SolarNexus docker-compose.production.yml file has been updated to remove this obsolete attribute.

### 3. Missing Migration File

**Error:**
```
Error: Cannot find module '/app/src/migrations/index.js'
```

**Solution:**
We've created the missing migration file. If you encounter this error:

```bash
# Ensure the migration file exists
ls -la /workspace/project/SolarNexus/solarnexus-backend/src/migrations/index.js

# If missing, create it manually or run:
mkdir -p /opt/solarnexus/app/solarnexus-backend/src/migrations
```

### 4. Database Connection Issues

**Error:**
```
❌ Database connection failed: connection refused
```

**Solution:**
```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs solarnexus-postgres

# Restart PostgreSQL if needed
docker restart solarnexus-postgres

# Wait for database to be ready
docker exec solarnexus-postgres pg_isready -U solarnexus
```

### 5. Backend Build Context Issues

**Error:**
```
ERROR: failed to solve: failed to read dockerfile: open /var/lib/docker/tmp/buildkit-mount.../backend/Dockerfile: no such file or directory
```

**Solution:**
The Docker Compose file has been updated to use the correct build context:
```yaml
backend:
  build:
    context: ../solarnexus-backend  # Updated path
    dockerfile: Dockerfile
```

### 6. Frontend Build Issues

**Error:**
```
ERROR: failed to build frontend: REACT_APP_API_URL not found
```

**Solution:**
```bash
# Ensure environment variables are passed to build
docker-compose -f docker-compose.production.yml build --build-arg REACT_APP_API_URL=https://nexus.gonxt.tech/api frontend

# Or set in environment file
echo "REACT_APP_API_URL=https://nexus.gonxt.tech/api" >> /opt/solarnexus/.env.production
```

### 7. Port Conflicts

**Error:**
```
ERROR: for solarnexus-backend  Cannot start service backend: driver failed programming external connectivity on endpoint solarnexus-backend: Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Solution:**
```bash
# Check what's using the port
sudo netstat -tlnp | grep :3000

# Kill the process using the port
sudo kill -9 <PID>

# Or change the port in docker-compose.yml
ports:
  - "3001:3000"  # Use different external port
```

### 8. SSL Certificate Issues

**Error:**
```
nginx: [emerg] cannot load certificate "/etc/nginx/ssl/solarnexus.crt": BIO_new_file() failed
```

**Solution:**
```bash
# Run SSL setup script
sudo ./scripts/setup-ssl.sh

# Or create self-signed certificate for testing
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/solarnexus.key \
  -out /etc/nginx/ssl/solarnexus.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=nexus.gonxt.tech"
```

### 9. Permission Issues

**Error:**
```
ERROR: Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Restart session or run
newgrp docker

# Or run with sudo
sudo docker-compose -f docker-compose.production.yml up -d
```

### 10. Memory Issues

**Error:**
```
ERROR: Service 'backend' failed to build: executor failed running [/bin/sh -c npm install]: exit code: 137
```

**Solution:**
```bash
# Check available memory
free -h

# Increase Docker memory limit
# Edit /etc/docker/daemon.json
{
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc"
    }
  },
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  }
}

# Restart Docker
sudo systemctl restart docker
```

## 🔍 Diagnostic Commands

### Check Service Status
```bash
# All containers
docker ps -a

# Specific service logs
docker logs solarnexus-backend
docker logs solarnexus-frontend
docker logs solarnexus-postgres
docker logs solarnexus-redis

# Follow logs in real-time
docker logs -f solarnexus-backend
```

### Health Checks
```bash
# Backend health
curl http://localhost:3000/health

# Frontend health
curl http://localhost:8080/health

# Database health
docker exec solarnexus-postgres pg_isready -U solarnexus

# Redis health
docker exec solarnexus-redis redis-cli ping
```

### Resource Usage
```bash
# Container resource usage
docker stats

# System resources
htop
df -h
free -h
```

### Network Issues
```bash
# Check Docker networks
docker network ls

# Inspect network
docker network inspect solarnexus-network

# Test connectivity between containers
docker exec solarnexus-backend ping solarnexus-postgres
```

## 🚨 Emergency Recovery

### Complete Reset
```bash
# Stop all services
sudo ./deploy/stop-services.sh

# Remove all containers
docker rm -f $(docker ps -aq --filter "name=solarnexus")

# Remove volumes (WARNING: This deletes all data)
docker volume rm solarnexus_postgres_data solarnexus_redis_data

# Clean up images
docker image prune -f

# Restart deployment
sudo ./deploy/production-deploy.sh
```

### Database Recovery
```bash
# Restore from backup
sudo ./scripts/restore-database.sh /opt/solarnexus/backups/database/latest.sql.gz

# Or recreate database
docker exec -it solarnexus-postgres psql -U solarnexus -c "DROP DATABASE IF EXISTS solarnexus;"
docker exec -it solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;"
docker exec solarnexus-backend node src/migrations/index.js
```

## 📞 Getting Help

### Log Collection
```bash
# Collect all logs
mkdir -p /tmp/solarnexus-logs
docker logs solarnexus-backend > /tmp/solarnexus-logs/backend.log 2>&1
docker logs solarnexus-frontend > /tmp/solarnexus-logs/frontend.log 2>&1
docker logs solarnexus-postgres > /tmp/solarnexus-logs/postgres.log 2>&1
docker logs solarnexus-redis > /tmp/solarnexus-logs/redis.log 2>&1
cp /var/log/solarnexus/* /tmp/solarnexus-logs/ 2>/dev/null || true

# Create archive
tar -czf solarnexus-logs-$(date +%Y%m%d_%H%M%S).tar.gz -C /tmp solarnexus-logs
```

### System Information
```bash
# System info
uname -a
docker --version
docker-compose --version
free -h
df -h
```

### Contact Support
- **GitHub Issues**: https://github.com/Reshigan/SolarNexus/issues
- **Email**: support@nexus.gonxt.tech
- **Documentation**: https://github.com/Reshigan/SolarNexus/tree/main/docs

---

## ✅ Prevention Checklist

Before deployment:
- [ ] All environment variables configured
- [ ] Docker and Docker Compose installed
- [ ] Sufficient system resources (4GB+ RAM, 50GB+ disk)
- [ ] Ports 80, 443, 3000, 8080 available
- [ ] Domain DNS configured
- [ ] SSL certificates ready or Let's Encrypt configured
- [ ] Database backup strategy in place

After deployment:
- [ ] All services healthy
- [ ] API endpoints responding
- [ ] Frontend loading correctly
- [ ] Database connections working
- [ ] SSL certificate valid
- [ ] Monitoring configured
- [ ] Backup procedures tested

**Remember: Always backup your data before making changes!**