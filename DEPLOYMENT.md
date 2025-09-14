# 🚀 NexusGreen Server Deployment Guide

## Server Information
- **Repository**: https://github.com/Reshigan/NexusGreen.git
- **Branch**: main
- **Latest Version**: v6.0.0 with working dashboard

## Quick Deployment (Recommended)

### Step 1: Connect to Your Server
```bash
ssh root@your-server-ip
```

### Step 2: Navigate to NexusGreen Directory
```bash
cd /root/NexusGreen
```

### Step 3: Run the Deployment Script
```bash
./server-deploy.sh
```

That's it! The script will handle everything automatically.

---

## Manual Deployment (Alternative)

If you prefer to run commands manually:

### Step 1: Pull Latest Changes
```bash
git pull origin main
```

### Step 2: Stop Services
```bash
docker compose down --remove-orphans
```

### Step 3: Clean Up
```bash
docker system prune -f
rm -rf dist/
npm cache clean --force
```

### Step 4: Install & Build
```bash
npm install --no-audit --no-fund
npm run build
```

### Step 5: Deploy
```bash
docker compose build --no-cache
docker compose up -d
```

### Step 6: Verify
```bash
docker compose ps
curl http://localhost:80
```

---

## Access Your Dashboard

After deployment, access your dashboard at:
- **Public URL**: `http://your-server-ip:80`
- **Local URL**: `http://localhost:80`

## What You'll See

✅ **Professional NexusGreen Dashboard** featuring:
- Real-time energy generation metrics (2,847 kWh)
- Revenue tracking ($125,680)
- System performance (96.8%)
- CO₂ savings (1,247 kg)
- Interactive solar installation cards
- Live clock updates
- Mobile-responsive design

## Troubleshooting

### If Dashboard Shows Blank Page:
```bash
# Check container logs
docker compose logs -f nexus-green

# Restart services
docker compose restart

# Full re-deployment
./server-deploy.sh
```

### If Services Won't Start:
```bash
# Check status
docker compose ps

# View all logs
docker compose logs

# Check disk space
df -h
```

### If Build Fails:
```bash
# Clean everything
rm -rf node_modules/ dist/
npm cache clean --force
npm install
npm run build
```

## Port Information

- **Frontend**: Port 80 (maps to container port 8080)
- **API**: Port 3001
- **Database**: Port 5432

## Health Checks

- **Frontend**: `curl http://localhost:80`
- **API**: `curl http://localhost:3001/health`
- **Database**: `docker compose exec nexus-db pg_isready -U nexususer -d nexusgreen`

## Support

If you encounter any issues:
1. Check the deployment script output for error messages
2. Review container logs: `docker compose logs -f`
3. Verify all services are running: `docker compose ps`
4. Ensure ports 80 and 3001 are not blocked by firewall

---

🌞 **NexusGreen v6.0.0 - Professional Solar Energy Management Platform**