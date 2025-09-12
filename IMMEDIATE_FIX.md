# 🚨 Immediate Fix for Container Conflicts

## Quick Manual Commands

Run these commands immediately on your server:

```bash
# Stop and remove conflicting containers
docker stop solarnexus-postgres solarnexus-redis 2>/dev/null || true
docker rm -f solarnexus-postgres solarnexus-redis 2>/dev/null || true

# Remove containers by the specific IDs from your error
docker stop e12c483b0a99 37034414f920 2>/dev/null || true
docker rm -f e12c483b0a99 37034414f920 2>/dev/null || true

# Clean up any remaining SolarNexus containers
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

# Go to your SolarNexus directory
cd /root/SolarNexus

# Stop Docker Compose services
docker-compose -f deploy/docker-compose.compatible.yml down --remove-orphans

# Recreate volumes
docker volume rm postgres_data redis_data 2>/dev/null || true
docker volume create postgres_data
docker volume create redis_data

# Start services again
docker-compose -f deploy/docker-compose.compatible.yml up -d
```

## Alternative: Use the Fix Script

```bash
# Download and run the fix script
curl -o fix-container-conflict.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/fix-container-conflict.sh
chmod +x fix-container-conflict.sh
sudo ./fix-container-conflict.sh
```

## What Happened

The clean install script created containers manually, but then Docker Compose tried to create containers with the same names. This caused the conflict.

## Expected Result

After running the fix:
- ✅ All conflicting containers removed
- ✅ Fresh containers created by Docker Compose
- ✅ Services running without name conflicts
- ✅ PostgreSQL on port 5432
- ✅ Redis on port 6379
- ✅ Backend and frontend starting

## Verify It's Working

```bash
# Check containers
docker ps

# Test services
docker exec solarnexus-postgres pg_isready -U solarnexus
docker exec solarnexus-redis redis-cli ping
curl http://localhost:3000/health
```

---

**The fix script handles everything automatically and should resolve the container name conflicts immediately.**