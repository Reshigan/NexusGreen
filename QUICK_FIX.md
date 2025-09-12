# 🚀 Quick Fix for Database Issues

## Problem
The error you're seeing indicates that the database schema is incomplete or the migration didn't run properly:

```
ERROR: relation "public.sites" does not exist at character 631
```

## Solution

### Option 1: Quick Database Reset (Recommended)

```bash
# SSH to your server
ssh root@13.244.63.26

# Navigate to SolarNexus directory
cd /opt/solarnexus/app

# Pull latest fixes
git pull origin main

# Run database reset script
sudo ./deploy/reset-database.sh
```

### Option 2: Manual Database Fix

```bash
# Stop backend service
docker stop solarnexus-backend

# Reset database
docker exec solarnexus-postgres psql -U solarnexus -c "DROP DATABASE IF EXISTS solarnexus;"
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;"

# Run migration
docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql

# Start backend service
docker start solarnexus-backend
```

### Option 3: Complete Redeployment

```bash
# Stop all services
sudo ./deploy/stop-services.sh

# Remove containers and volumes (WARNING: This deletes all data)
docker rm -f $(docker ps -aq --filter "name=solarnexus")
docker volume rm solarnexus_postgres_data solarnexus_redis_data

# Redeploy
sudo ./deploy/production-deploy.sh
```

## Verification

After running any of the above solutions, verify the fix:

```bash
# Check database tables
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "\dt"

# Test API health
curl http://localhost:3000/health

# Check backend logs
docker logs solarnexus-backend

# Run verification script
sudo ./deploy/verify-deployment.sh
```

## Expected Results

After the fix, you should see:
- ✅ Database with all required tables created
- ✅ Sample organization and admin user created
- ✅ Backend API responding to health checks
- ✅ No more "relation does not exist" errors

## Default Login Credentials

After the database reset, you can login with:
- **Email**: admin@nexus.gonxt.tech
- **Password**: admin123

## Need Help?

If you're still experiencing issues:

1. **Check logs**: `docker logs solarnexus-backend`
2. **Run diagnostics**: `sudo ./deploy/verify-deployment.sh`
3. **Review troubleshooting**: See `TROUBLESHOOTING.md`
4. **Contact support**: Create an issue at https://github.com/Reshigan/SolarNexus/issues

---

**The database reset script is the safest and most comprehensive solution. It will backup your existing data, reset the database, run migrations, and verify everything is working correctly.**