# 🚀 SolarNexus Production Deployment Guide

## Server: 13.244.63.26 | Domain: nexus.gonxt.tech

This guide provides step-by-step instructions for deploying SolarNexus to production.

## 📋 Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04+ or compatible Linux distribution
- **RAM**: Minimum 4GB (8GB recommended)
- **CPU**: 2+ cores (4+ recommended)
- **Storage**: 50GB+ available disk space
- **Network**: Ports 80, 443, 3000, 8080 accessible

### Domain Configuration
- Domain: `nexus.gonxt.tech` pointing to `13.244.63.26`
- Subdomain: `www.nexus.gonxt.tech` (optional)
- SSL certificate ready or Let's Encrypt setup

## 🚀 Quick Production Deployment

### Step 1: Connect to Production Server

```bash
# SSH into your production server
ssh root@13.244.63.26
# or
ssh your-user@13.244.63.26
```

### Step 2: Run One-Command Deployment

```bash
# Clone and deploy SolarNexus
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/production-deploy.sh | sudo bash
```

**OR** Manual deployment:

```bash
# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Run production deployment
sudo ./deploy/production-deploy.sh
```

### Step 3: Configure API Keys

```bash
# Run API keys configuration
sudo ./scripts/setup-production-keys.sh
```

You'll be prompted to enter:
- **SolaX API Token**: Get from https://www.solaxcloud.com/
- **OpenWeatherMap API Key**: Get from https://openweathermap.org/api
- **Email Credentials**: For automated alerts
- **Municipal Rate API**: Optional for dynamic pricing

### Step 4: Set Up SSL Certificate

```bash
# Run SSL setup (choose Let's Encrypt for production)
sudo ./scripts/setup-ssl.sh
```

Options:
1. **Let's Encrypt** (Recommended) - Free, auto-renewing
2. **Manual Certificate** - Upload your own certificates
3. **Self-signed** - For testing only

### Step 5: Deploy Monitoring

```bash
# Set up comprehensive monitoring
sudo ./scripts/setup-monitoring.sh
```

This deploys:
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Alertmanager**: Email alerts for issues

### Step 6: Configure Backups

```bash
# Set up automated backups
sudo ./scripts/setup-backup.sh
```

Configures:
- **Daily database backups** (30-day retention)
- **Weekly full system backups** (7-day retention)
- **Monthly backup verification**

## 🐳 Docker Compose Deployment (Alternative)

### Step 1: Prepare Environment

```bash
# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Copy environment template
sudo cp .env.production.template /opt/solarnexus/.env.production

# Configure environment variables
sudo nano /opt/solarnexus/.env.production
```

### Step 2: Deploy Core Services

```bash
cd deploy/

# Deploy core services
sudo docker-compose -f docker-compose.production.yml up -d

# Deploy with monitoring
sudo docker-compose -f docker-compose.production.yml --profile monitoring up -d
```

### Step 3: Verify Deployment

```bash
# Check service status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:8080/health
```

## ⚙️ Environment Configuration

### Required Environment Variables

Create `/opt/solarnexus/.env.production` with:

```bash
# Database Configuration
DATABASE_URL="postgresql://solarnexus:SECURE_PASSWORD@solarnexus-postgres:5432/solarnexus"
POSTGRES_USER="solarnexus"
POSTGRES_PASSWORD="SECURE_PASSWORD"
POSTGRES_DB="solarnexus"

# Redis Configuration
REDIS_URL="redis://solarnexus-redis:6379"

# Security
JWT_SECRET="SECURE_JWT_SECRET_64_CHARS_MINIMUM"
JWT_EXPIRES_IN="24h"
BCRYPT_ROUNDS="12"

# Solar Data APIs
SOLAX_API_TOKEN="YOUR_SOLAX_API_TOKEN"
SOLAX_API_BASE_URL="https://www.solaxcloud.com:9443/proxy/api/getRealtimeInfo.do"

# Weather API
OPENWEATHER_API_KEY="YOUR_OPENWEATHER_API_KEY"
OPENWEATHER_BASE_URL="https://api.openweathermap.org/data/2.5"

# Email Configuration
EMAIL_HOST="smtp.gmail.com"
EMAIL_PORT="587"
EMAIL_SECURE="false"
EMAIL_USER="alerts@nexus.gonxt.tech"
EMAIL_PASS="YOUR_APP_PASSWORD"

# Municipal Rate API (Optional)
MUNICIPAL_RATE_API_KEY="YOUR_MUNICIPAL_API_KEY"
MUNICIPAL_RATE_ENDPOINT="https://api.municipal.com/rates"

# Application Configuration
NODE_ENV="production"
PORT="3000"
API_BASE_URL="https://nexus.gonxt.tech/api"
FRONTEND_URL="https://nexus.gonxt.tech"

# CORS Configuration
CORS_ORIGIN="https://nexus.gonxt.tech,https://www.nexus.gonxt.tech"
CORS_CREDENTIALS="true"

# Rate Limiting
RATE_LIMIT_WINDOW_MS="900000"
RATE_LIMIT_MAX_REQUESTS="100"
AUTH_RATE_LIMIT_MAX="5"

# Security Headers
SECURITY_HEADERS_ENABLED="true"
HSTS_MAX_AGE="31536000"
CSP_ENABLED="true"
FORCE_HTTPS="true"
```

## 🔧 Service Management

### Start/Stop Services

```bash
# Using systemd (recommended)
sudo systemctl start solarnexus
sudo systemctl stop solarnexus
sudo systemctl restart solarnexus
sudo systemctl status solarnexus

# Using deployment scripts
sudo ./deploy/start-services.sh
sudo ./deploy/stop-services.sh

# Using Docker Compose
cd deploy/
sudo docker-compose -f docker-compose.production.yml up -d
sudo docker-compose -f docker-compose.production.yml down
```

### View Logs

```bash
# Service logs
docker logs solarnexus-backend
docker logs solarnexus-frontend
docker logs solarnexus-postgres
docker logs solarnexus-redis
docker logs solarnexus-nginx

# System logs
tail -f /var/log/solarnexus/deployment.log
tail -f /var/log/solarnexus/backup-database.log

# Real-time logs
docker logs -f solarnexus-backend
```

### Health Checks

```bash
# Backend API health
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

## 🔄 Updates and Maintenance

### Zero-Downtime Updates

```bash
# Automated update with rollback capability
sudo ./deploy/update-deployment.sh
```

### Manual Updates

```bash
# Pull latest code
cd /opt/solarnexus/app
git pull origin main

# Rebuild images
docker build -t solarnexus-backend:latest -f backend/Dockerfile backend/
docker build -t solarnexus-frontend:latest -f frontend/Dockerfile frontend/

# Restart services
sudo ./deploy/stop-services.sh
sudo ./deploy/start-services.sh
```

### Database Migrations

```bash
# Run database migrations
docker exec solarnexus-backend npx prisma migrate deploy

# Generate Prisma client
docker exec solarnexus-backend npx prisma generate
```

## 💾 Backup and Recovery

### Manual Backups

```bash
# Database backup
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > backup.sql
gzip backup.sql

# Full system backup
tar -czf solarnexus-backup-$(date +%Y%m%d).tar.gz /opt/solarnexus
```

### Restore Database

```bash
# List available backups
ls -la /opt/solarnexus/backups/database/

# Restore from backup
sudo ./scripts/restore-database.sh solarnexus_db_20240101_120000.sql.gz
```

### Backup Management

```bash
# Interactive backup manager
sudo ./scripts/backup-manager.sh

# Verify backup integrity
sudo ./scripts/verify-backups.sh
```

## 📊 Monitoring and Alerting

### Access Monitoring Dashboards

- **Grafana**: http://13.244.63.26:3001 (admin/generated_password)
- **Prometheus**: http://13.244.63.26:9090
- **Alertmanager**: http://13.244.63.26:9093

### Configure Alerts

Edit `/opt/solarnexus/monitoring/alertmanager/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@nexus.gonxt.tech'
  smtp_auth_username: 'alerts@nexus.gonxt.tech'
  smtp_auth_password: 'YOUR_APP_PASSWORD'

route:
  receiver: 'admin-email'

receivers:
  - name: 'admin-email'
    email_configs:
      - to: 'admin@nexus.gonxt.tech'
        subject: 'SolarNexus Alert: {{ .GroupLabels.alertname }}'
```

## 🔒 Security Hardening

### Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Backend API (optional)
sudo ufw allow 8080/tcp  # Frontend (optional)
```

### SSL Certificate Management

```bash
# Check certificate status
sudo certbot certificates

# Renew certificates manually
sudo certbot renew

# Test auto-renewal
sudo certbot renew --dry-run
```

### Security Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
```

## 🌐 Domain and DNS Configuration

### DNS Records

Configure these DNS records for `nexus.gonxt.tech`:

```
Type    Name    Value           TTL
A       @       13.244.63.26    300
A       www     13.244.63.26    300
CNAME   api     nexus.gonxt.tech 300
```

### Nginx Configuration

The deployment automatically configures Nginx with:
- HTTP to HTTPS redirect
- SSL/TLS termination
- Reverse proxy to backend API
- Static file serving
- Security headers
- Rate limiting

## 🧪 Testing and Validation

### Functional Testing

```bash
# Test user registration
curl -X POST https://nexus.gonxt.tech/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","role":"customer"}'

# Test login
curl -X POST https://nexus.gonxt.tech/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test solar data endpoint
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://nexus.gonxt.tech/api/solar/sites
```

### Performance Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test API performance
ab -n 1000 -c 10 https://nexus.gonxt.tech/api/health

# Test frontend performance
ab -n 100 -c 5 https://nexus.gonxt.tech/
```

## 🚨 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker
sudo systemctl start docker

# Check disk space
df -h

# Check memory usage
free -h

# Check logs
docker logs solarnexus-backend
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
docker exec solarnexus-postgres pg_isready -U solarnexus

# Check environment variables
docker exec solarnexus-backend env | grep DATABASE_URL

# Restart database
docker restart solarnexus-postgres
```

#### SSL Certificate Issues
```bash
# Check certificate validity
openssl x509 -in /etc/nginx/ssl/solarnexus.crt -text -noout

# Check certificate expiry
openssl x509 -in /etc/nginx/ssl/solarnexus.crt -noout -dates

# Renew Let's Encrypt certificate
sudo certbot renew --force-renewal
```

### Log Analysis

```bash
# Check application errors
grep -i error /opt/solarnexus/logs/*.log

# Check system errors
grep -i error /var/log/syslog

# Check nginx errors
tail -f /var/log/nginx/error.log

# Check Docker container logs
docker logs --since=1h solarnexus-backend
```

## 📞 Support and Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor service health
- Check backup completion
- Review error logs

**Weekly:**
- Update system packages
- Review performance metrics
- Check SSL certificate status

**Monthly:**
- Security audit
- Backup verification
- Performance optimization review

### Emergency Contacts

- **System Administrator**: admin@nexus.gonxt.tech
- **Development Team**: dev@nexus.gonxt.tech
- **Infrastructure Support**: ops@nexus.gonxt.tech

### Support Resources

- **Repository**: https://github.com/Reshigan/SolarNexus
- **Documentation**: https://github.com/Reshigan/SolarNexus/tree/main/docs
- **Issues**: https://github.com/Reshigan/SolarNexus/issues

---

## ✅ Deployment Verification Checklist

- [ ] All services running and healthy
- [ ] SSL certificate installed and valid
- [ ] API endpoints responding correctly
- [ ] Frontend loading properly
- [ ] Database connections working
- [ ] Monitoring dashboards accessible
- [ ] Backup procedures configured
- [ ] Email alerts configured
- [ ] Domain DNS configured correctly
- [ ] Security headers enabled
- [ ] Rate limiting active
- [ ] Log rotation configured

**🎉 SolarNexus is ready for production!**

Access your platform at: **https://nexus.gonxt.tech**