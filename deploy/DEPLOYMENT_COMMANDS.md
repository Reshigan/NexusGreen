# 🚀 SolarNexus Production Deployment Commands

## Server: 13.244.63.26 | Domain: nexus.gonxt.tech

### 📋 Quick Reference Commands

## 1️⃣ One-Command Production Deployment

```bash
# SSH to production server
ssh root@13.244.63.26

# One-command deployment
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/production-deploy.sh | sudo bash
```

## 2️⃣ Manual Step-by-Step Deployment

```bash
# 1. Clone repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# 2. Run production deployment
sudo ./deploy/production-deploy.sh

# 3. Configure API keys
sudo ./scripts/setup-production-keys.sh

# 4. Set up SSL certificate
sudo ./scripts/setup-ssl.sh

# 5. Deploy monitoring
sudo ./scripts/setup-monitoring.sh

# 6. Configure backups
sudo ./scripts/setup-backup.sh
```

## 3️⃣ Docker Compose Deployment

```bash
# Clone and prepare
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Copy environment template
sudo cp .env.production.template /opt/solarnexus/.env.production

# Edit environment variables
sudo nano /opt/solarnexus/.env.production

# Deploy core services
cd deploy/
sudo docker-compose -f docker-compose.production.yml up -d

# Deploy with monitoring
sudo docker-compose -f docker-compose.production.yml --profile monitoring up -d
```

## 🔧 Service Management Commands

### Start Services
```bash
# Using systemd
sudo systemctl start solarnexus

# Using scripts
sudo ./deploy/start-services.sh

# Using Docker Compose
cd deploy/
sudo docker-compose -f docker-compose.production.yml up -d
```

### Stop Services
```bash
# Using systemd
sudo systemctl stop solarnexus

# Using scripts
sudo ./deploy/stop-services.sh

# Using Docker Compose
cd deploy/
sudo docker-compose -f docker-compose.production.yml down
```

### Restart Services
```bash
# Using systemd
sudo systemctl restart solarnexus

# Manual restart
sudo ./deploy/stop-services.sh
sudo ./deploy/start-services.sh
```

## 📊 Health Check Commands

```bash
# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Backend health
curl http://localhost:3000/health
curl https://nexus.gonxt.tech/api/health

# Frontend health
curl http://localhost:8080/health
curl https://nexus.gonxt.tech/health

# Database health
docker exec solarnexus-postgres pg_isready -U solarnexus

# Redis health
docker exec solarnexus-redis redis-cli ping
```

## 📝 Log Commands

```bash
# View service logs
docker logs solarnexus-backend
docker logs solarnexus-frontend
docker logs solarnexus-postgres
docker logs solarnexus-redis
docker logs solarnexus-nginx

# Follow logs in real-time
docker logs -f solarnexus-backend

# System logs
tail -f /var/log/solarnexus/deployment.log
tail -f /var/log/solarnexus/backup-database.log
```

## 🔄 Update Commands

```bash
# Zero-downtime update
sudo ./deploy/update-deployment.sh

# Manual update
cd /opt/solarnexus/app
git pull origin main
docker build -t solarnexus-backend:latest -f backend/Dockerfile backend/
docker build -t solarnexus-frontend:latest -f frontend/Dockerfile frontend/
sudo ./deploy/stop-services.sh
sudo ./deploy/start-services.sh
```

## 💾 Backup Commands

```bash
# Interactive backup manager
sudo ./scripts/backup-manager.sh

# Manual database backup
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > backup.sql
gzip backup.sql

# Restore database
sudo ./scripts/restore-database.sh backup-file.sql.gz

# Verify backups
sudo ./scripts/verify-backups.sh

# Full system backup
tar -czf solarnexus-backup-$(date +%Y%m%d).tar.gz /opt/solarnexus
```

## 🔒 Security Commands

```bash
# Configure firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check SSL certificate
sudo certbot certificates
openssl x509 -in /etc/nginx/ssl/solarnexus.crt -text -noout

# Renew SSL certificate
sudo certbot renew

# Update system
sudo apt update && sudo apt upgrade -y
```

## 📊 Monitoring Commands

```bash
# Start monitoring stack
sudo systemctl start solarnexus-monitoring
# OR
sudo /opt/solarnexus/monitoring/start-monitoring.sh

# Access monitoring
# Grafana: http://13.244.63.26:3001
# Prometheus: http://13.244.63.26:9090
# Alertmanager: http://13.244.63.26:9093

# Check monitoring status
docker ps | grep -E "(prometheus|grafana|alertmanager)"
```

## 🧪 Testing Commands

```bash
# Test API endpoints
curl -X POST https://nexus.gonxt.tech/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","role":"customer"}'

# Performance test
ab -n 1000 -c 10 https://nexus.gonxt.tech/api/health

# SSL test
openssl s_client -connect nexus.gonxt.tech:443 -servername nexus.gonxt.tech
```

## 🚨 Troubleshooting Commands

```bash
# Check Docker daemon
sudo systemctl status docker
sudo systemctl start docker

# Check disk space
df -h

# Check memory usage
free -h

# Check network connectivity
ping nexus.gonxt.tech
nslookup nexus.gonxt.tech

# Check ports
netstat -tlnp | grep -E "(80|443|3000|8080|5432|6379)"

# Check processes
ps aux | grep -E "(node|nginx|postgres|redis)"

# Restart all services
sudo systemctl restart solarnexus
```

## 📁 Important File Locations

```bash
# Application files
/opt/solarnexus/app/                    # Main application
/opt/solarnexus/.env.production         # Environment variables
/opt/solarnexus/secrets/                # API keys and secrets
/opt/solarnexus/backups/                # Backup files
/opt/solarnexus/logs/                   # Application logs

# System files
/var/log/solarnexus/                    # System logs
/etc/nginx/ssl/                         # SSL certificates
/etc/systemd/system/solarnexus.service  # Systemd service
/etc/cron.d/solarnexus-backups         # Backup schedule

# Docker volumes
solarnexus_postgres_data                # Database data
solarnexus_redis_data                   # Cache data
```

## 🌐 Access URLs

```bash
# Production URLs
https://nexus.gonxt.tech                # Main application
https://nexus.gonxt.tech/api/health     # API health check
https://nexus.gonxt.tech/health         # Frontend health check

# Monitoring URLs (internal)
http://13.244.63.26:3001               # Grafana dashboard
http://13.244.63.26:9090               # Prometheus metrics
http://13.244.63.26:9093               # Alertmanager

# Development URLs (if needed)
http://13.244.63.26:3000               # Backend API
http://13.244.63.26:8080               # Frontend app
```

## 📞 Emergency Commands

```bash
# Emergency stop all services
docker stop $(docker ps -q --filter "name=solarnexus")

# Emergency restart
sudo reboot

# Emergency backup
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > emergency-backup-$(date +%Y%m%d_%H%M%S).sql

# Check system resources
top
htop
iotop
```

## ✅ Verification Commands

```bash
# Verify deployment
curl -I https://nexus.gonxt.tech
curl https://nexus.gonxt.tech/api/health | jq .

# Verify SSL
curl -I https://nexus.gonxt.tech | grep -i "strict-transport-security"

# Verify services
systemctl status solarnexus
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify backups
ls -la /opt/solarnexus/backups/database/
sudo ./scripts/verify-backups.sh

# Verify monitoring
curl http://localhost:9090/-/healthy
curl http://localhost:3001/api/health
```

---

## 🎯 Quick Deployment Summary

1. **SSH to server**: `ssh root@13.244.63.26`
2. **One-command deploy**: `curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/production-deploy.sh | sudo bash`
3. **Configure API keys**: `sudo ./scripts/setup-production-keys.sh`
4. **Setup SSL**: `sudo ./scripts/setup-ssl.sh`
5. **Deploy monitoring**: `sudo ./scripts/setup-monitoring.sh`
6. **Configure backups**: `sudo ./scripts/setup-backup.sh`
7. **Verify**: `curl https://nexus.gonxt.tech/api/health`

**🎉 SolarNexus is ready at https://nexus.gonxt.tech**