# 🔧 Container Configuration Fix Guide

## Problem
You're encountering a `'ContainerConfig'` KeyError when trying to start Docker containers:

```
ERROR: for solarnexus-redis  'ContainerConfig'
ERROR: for solarnexus-postgres  'ContainerConfig'
KeyError: 'ContainerConfig'
```

This is a known issue with Docker Compose version compatibility and corrupted container metadata.

## 🚀 Quick Solution

### Option 1: Automated Fix (Recommended)

```bash
# SSH to your server
ssh root@13.244.63.26

# Navigate to SolarNexus directory
cd /opt/solarnexus/app

# Pull latest fixes
git pull origin main

# Run the automated fix script
sudo ./deploy/fix-container-config.sh
```

### Option 2: Use Compatible Docker Compose File

```bash
# Stop current services
docker-compose -f deploy/docker-compose.production.yml down --remove-orphans

# Use the compatible version
docker-compose -f deploy/docker-compose.compatible.yml up -d --build
```

### Option 3: Manual Fix Steps

```bash
# 1. Stop all services
docker-compose -f deploy/docker-compose.production.yml down --remove-orphans

# 2. Remove problematic containers
docker rm -f $(docker ps -aq --filter "name=solarnexus")

# 3. Clean Docker system
docker system prune -f

# 4. Remove and recreate volumes
docker volume rm solarnexus_postgres_data solarnexus_redis_data
docker volume create solarnexus_postgres_data
docker volume create solarnexus_redis_data

# 5. Pull fresh images
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine

# 6. Start services
docker-compose -f deploy/docker-compose.compatible.yml up -d --build
```

## 🔍 Root Cause Analysis

This error typically occurs due to:

1. **Docker Compose Version Incompatibility**: Older Docker Compose versions (1.29.x) have issues with newer image metadata formats
2. **Corrupted Container Metadata**: Previous failed deployments can leave corrupted metadata
3. **Volume Mount Issues**: Existing volumes with incompatible metadata
4. **Image Cache Problems**: Cached images with missing or corrupted configuration data

## 🛠️ What the Fix Script Does

The `fix-container-config.sh` script performs these actions:

1. **Clean Shutdown**: Stops all services gracefully
2. **Container Cleanup**: Removes all SolarNexus containers
3. **System Cleanup**: Prunes dangling images and containers
4. **Volume Recreation**: Removes and recreates Docker volumes
5. **Fresh Images**: Pulls latest images to avoid metadata issues
6. **Compatibility Check**: Uses compatible Docker Compose format
7. **Service Validation**: Tests all services after restart

## 📋 Verification Steps

After running the fix, verify everything is working:

```bash
# Check container status
docker ps

# Test database
docker exec solarnexus-postgres pg_isready -U solarnexus

# Test Redis
docker exec solarnexus-redis redis-cli ping

# Test API
curl http://localhost:3000/health

# Run full verification
sudo ./deploy/verify-deployment.sh
```

## 🔄 Alternative Docker Compose Versions

We've provided two Docker Compose files:

### `docker-compose.production.yml`
- **For**: Docker Compose v2.0+
- **Features**: Latest syntax, advanced health checks
- **Use when**: You have newer Docker Compose

### `docker-compose.compatible.yml`
- **For**: Docker Compose v1.29+
- **Features**: Compatible syntax, basic health checks
- **Use when**: You have older Docker Compose (like your current setup)

## 🚨 If Problems Persist

### Check Docker Compose Version
```bash
docker-compose --version
```

### Update Docker Compose (if needed)
```bash
# Remove old version
sudo apt remove docker-compose

# Install newer version
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Check Docker Version
```bash
docker --version
```

### Complete System Reset (Last Resort)
```bash
# WARNING: This removes ALL Docker data
sudo ./deploy/stop-services.sh
docker system prune -a --volumes
sudo ./deploy/production-deploy.sh
```

## 📞 Support

If you're still experiencing issues:

1. **Check logs**: `docker-compose -f deploy/docker-compose.compatible.yml logs`
2. **System info**: `docker --version && docker-compose --version`
3. **Create issue**: https://github.com/Reshigan/SolarNexus/issues
4. **Email support**: support@nexus.gonxt.tech

## ✅ Expected Results

After the fix, you should see:
- ✅ All containers running without errors
- ✅ Database and Redis responding to health checks
- ✅ Backend API accessible at http://localhost:3000/health
- ✅ Frontend loading at http://localhost:8080
- ✅ No more 'ContainerConfig' errors

---

**The automated fix script is the most comprehensive solution and handles all edge cases automatically.**