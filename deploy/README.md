# 🚀 SolarNexus Production Deployment

This directory contains all the scripts and configurations needed to deploy SolarNexus to production.

## 📋 Quick Start

### 1. Initial Production Deployment

```bash
# On your production server (13.245.249.110)
sudo ./production-deploy.sh
```

This script will:
- Install all system dependencies (Docker, nginx, certbot)
- Clone the SolarNexus repository
- Build Docker images
- Deploy all services with health checks
- Set up systemd service
- Configure log rotation

### 2. Using Docker Compose (Alternative)

```bash
# Copy environment template
cp ../.env.production.template /opt/solarnexus/.env.production

# Edit with your API keys
nano /opt/solarnexus/.env.production

# Deploy core services
docker-compose -f docker-compose.production.yml up -d

# Deploy with monitoring
docker-compose -f docker-compose.production.yml --profile monitoring up -d
```

## 🔧 Management Scripts

### Start Services
```bash
sudo ./start-services.sh
# OR
sudo systemctl start solarnexus
```

### Stop Services
```bash
sudo ./stop-services.sh
# OR
sudo systemctl stop solarnexus
```

### Update Deployment
```bash
sudo ./update-deployment.sh
```

## 📁 File Structure

```
deploy/
├── production-deploy.sh      # Main deployment script
├── docker-compose.production.yml  # Docker Compose configuration
├── start-services.sh         # Start all services
├── stop-services.sh          # Stop all services
├── update-deployment.sh      # Zero-downtime updates
└── README.md                # This file
```

## 🐳 Docker Services

### Core Services
- **solarnexus-postgres**: PostgreSQL database
- **solarnexus-redis**: Redis cache
- **solarnexus-backend**: Node.js API server
- **solarnexus-frontend**: React web application
- **solarnexus-nginx**: Reverse proxy

### Monitoring Services (Optional)
- **solarnexus-prometheus**: Metrics collection
- **solarnexus-grafana**: Dashboard and visualization
- **solarnexus-alertmanager**: Alert management
- **solarnexus-node-exporter**: System metrics
- **solarnexus-postgres-exporter**: Database metrics
- **solarnexus-redis-exporter**: Cache metrics

## 🌐 Network Configuration

All services run on the `solarnexus-network` Docker network:

- **Frontend**: Port 8080 → 80 (internal)
- **Backend**: Port 3000 → 3000 (internal)
- **Database**: Port 5432 (internal only)
- **Redis**: Port 6379 (internal only)
- **Nginx**: Ports 80, 443 (external)

## 💾 Data Persistence

### Docker Volumes
- `solarnexus_postgres_data`: Database data
- `solarnexus_redis_data`: Cache data
- `solarnexus_ssl_certs`: SSL certificates

### Host Directories
- `/opt/solarnexus/app`: Application code
- `/opt/solarnexus/logs`: Application logs
- `/opt/solarnexus/backups`: Database backups
- `/opt/solarnexus/secrets`: API keys and secrets
- `/var/log/solarnexus`: System logs

## ⚙️ Environment Configuration

### Required Environment Variables

```bash
# Database
DATABASE_URL="postgresql://solarnexus:PASSWORD@postgres:5432/solarnexus"
POSTGRES_USER="solarnexus"
POSTGRES_PASSWORD="secure_password"
POSTGRES_DB="solarnexus"

# Security
JWT_SECRET="your_jwt_secret"
JWT_EXPIRES_IN="24h"

# Solar Data APIs
SOLAX_API_TOKEN="your_solax_token"
OPENWEATHER_API_KEY="your_openweather_key"

# Email Configuration
EMAIL_USER="alerts@nexus.gonxt.tech"
EMAIL_PASS="your_app_password"

# Optional
MUNICIPAL_RATE_API_KEY="your_municipal_api_key"
MUNICIPAL_RATE_ENDPOINT="https://api.municipal.com/rates"
```

## 🔒 Security Configuration

### SSL/TLS Setup
```bash
# Run SSL setup script
sudo ../scripts/setup-ssl.sh
```

### API Keys Management
```bash
# Run API keys setup script
sudo ../scripts/setup-production-keys.sh
```

## 📊 Monitoring Setup

### Deploy Monitoring Stack
```bash
# Deploy with monitoring profile
docker-compose -f docker-compose.production.yml --profile monitoring up -d

# OR use monitoring setup script
sudo ../scripts/setup-monitoring.sh
```

### Access Monitoring
- **Grafana**: http://your-server:3001 (admin/password)
- **Prometheus**: http://your-server:9090
- **Alertmanager**: http://your-server:9093

## 💾 Backup Configuration

### Setup Automated Backups
```bash
sudo ../scripts/setup-backup.sh
```

### Manual Backup
```bash
# Database backup
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > backup.sql

# Full system backup
tar -czf solarnexus-backup.tar.gz /opt/solarnexus
```

## 🔄 Update Process

### Zero-Downtime Updates
```bash
sudo ./update-deployment.sh
```

This performs:
1. Creates backup before update
2. Pulls latest code from repository
3. Builds new Docker images
4. Rolling update of services
5. Health checks and verification
6. Rollback on failure

### Manual Update
```bash
# Pull latest code
cd /opt/solarnexus/app
git pull origin main

# Rebuild images
docker build -t solarnexus-backend:latest -f backend/Dockerfile backend/
docker build -t solarnexus-frontend:latest -f frontend/Dockerfile frontend/

# Restart services
sudo ./stop-services.sh
sudo ./start-services.sh
```

## 🧪 Health Checks

### Service Health
```bash
# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check specific service
docker logs solarnexus-backend
```

### Endpoint Testing
```bash
# Backend health
curl http://localhost:3000/health

# Frontend health
curl http://localhost:8080/health

# Full system test
curl -I http://your-domain.com
```

## 🚨 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check logs
docker logs solarnexus-backend
docker logs solarnexus-postgres

# Check disk space
df -h
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
docker exec solarnexus-postgres pg_isready -U solarnexus

# Check environment variables
docker exec solarnexus-backend env | grep DATABASE_URL
```

#### SSL Certificate Issues
```bash
# Check certificate validity
openssl x509 -in /etc/nginx/ssl/solarnexus.crt -text -noout

# Renew Let's Encrypt certificate
sudo certbot renew
```

### Log Locations
- Application logs: `/opt/solarnexus/logs/`
- System logs: `/var/log/solarnexus/`
- Docker logs: `docker logs <container-name>`
- Nginx logs: `/var/log/nginx/`

## 📞 Support

### Emergency Procedures
1. **Service Down**: Run health checks, restart affected services
2. **Database Issues**: Check backups, restore if necessary
3. **SSL Expiry**: Renew certificates, restart nginx
4. **High Load**: Check monitoring, scale services if needed

### Maintenance Schedule
- **Daily**: Automated backups, log rotation
- **Weekly**: Security updates, performance review
- **Monthly**: Full system backup, certificate renewal check
- **Quarterly**: Security audit, dependency updates

## 🎯 Production Checklist

Before going live:
- [ ] All environment variables configured
- [ ] SSL certificate installed and valid
- [ ] Monitoring and alerting configured
- [ ] Backup procedures tested
- [ ] Health checks passing
- [ ] Domain DNS configured
- [ ] Firewall rules configured
- [ ] Security headers enabled
- [ ] Rate limiting configured
- [ ] Log rotation configured

---

**🎉 SolarNexus is ready for production!**

For additional help, check the main documentation in `../PRODUCTION_SETUP.md` or contact the development team.