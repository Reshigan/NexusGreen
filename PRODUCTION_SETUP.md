# SolarNexus Production Setup Guide

## 🚀 Production Deployment Status

### ✅ Completed Components
- **Backend**: Node.js/Express with TypeScript - Running on port 3000
- **Frontend**: React with Nginx - Running on port 8080  
- **Database**: PostgreSQL with Prisma ORM - Running on port 5432
- **Cache**: Redis for session management - Running on port 6379
- **Reverse Proxy**: Nginx with SSL-ready config - Running on ports 80/443

### 🔧 Required Production Configuration

## 1. API Keys Configuration

### SolaX API Integration
```bash
# Set production SolaX API token
export SOLAX_API_TOKEN="your_production_solax_token_here"

# Update docker-compose.yml or restart containers with:
docker run -d --name solarnexus-backend \
  --network project_solarnexus-network \
  -p 3000:3000 \
  -e SOLAX_API_TOKEN="your_production_solax_token_here" \
  ppa-frontend-backend
```

### OpenWeatherMap API
```bash
# Get API key from: https://openweathermap.org/api
export OPENWEATHER_API_KEY="your_openweather_api_key_here"
```

### Municipal Rate APIs
Configure municipal electricity rate APIs for accurate tariff calculations:
```bash
export MUNICIPAL_RATE_API_KEY="your_municipal_api_key"
export MUNICIPAL_RATE_ENDPOINT="https://api.municipality.gov/rates"
```

## 2. Email Service Configuration

### Production Email Service (for O&M Alerts)
```bash
# Gmail/Google Workspace (recommended)
export EMAIL_USER="alerts@nexus.gonxt.tech"
export EMAIL_PASS="your_app_specific_password"
export EMAIL_HOST="smtp.gmail.com"
export EMAIL_PORT="587"

# Or use SendGrid/AWS SES for production
export SENDGRID_API_KEY="your_sendgrid_api_key"
```

### Email Templates
- System alerts and notifications
- Performance degradation warnings
- Maintenance reminders
- Monthly/quarterly reports

## 3. SSL Certificate Installation

### Let's Encrypt (Recommended)
```bash
# Install certbot
sudo apt update && sudo apt install certbot python3-certbot-nginx

# Generate certificate for nexus.gonxt.tech
sudo certbot --nginx -d nexus.gonxt.tech -d www.nexus.gonxt.tech

# Auto-renewal setup
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Manual Certificate Installation
```bash
# Copy certificates to nginx directory
sudo cp /path/to/certificate.crt /etc/nginx/ssl/solarnexus.crt
sudo cp /path/to/private.key /etc/nginx/ssl/solarnexus.key

# Update nginx configuration
sudo nginx -t && sudo systemctl reload nginx
```

## 4. Production Monitoring Setup

### Prometheus + Grafana Stack
```bash
# Deploy monitoring stack
docker run -d --name prometheus \
  --network project_solarnexus-network \
  -p 9090:9090 \
  prom/prometheus

docker run -d --name grafana \
  --network project_solarnexus-network \
  -p 3001:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD="secure_admin_password" \
  grafana/grafana
```

### Health Check Endpoints
- Backend: `http://localhost:3000/health`
- Frontend: `http://localhost:8080/health`
- Database: Connection monitoring via backend
- Redis: Connection monitoring via backend

### Alerting Rules
- System downtime alerts
- High CPU/Memory usage
- Database connection failures
- API rate limit warnings
- Solar data sync failures

## 5. Database Backup Strategy

### Automated PostgreSQL Backups
```bash
# Create backup script
cat > /opt/solarnexus/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/solarnexus/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="solarnexus_backup_${DATE}.sql"

# Create backup
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > "${BACKUP_DIR}/${BACKUP_FILE}"

# Compress backup
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

# Keep only last 30 days of backups
find "${BACKUP_DIR}" -name "*.gz" -mtime +30 -delete

# Upload to cloud storage (optional)
# aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}.gz" s3://solarnexus-backups/
EOF

chmod +x /opt/solarnexus/backup.sh

# Schedule daily backups
echo "0 2 * * * /opt/solarnexus/backup.sh" | crontab -
```

### Disaster Recovery
- Daily automated backups
- Weekly full system snapshots
- Cloud storage replication
- Recovery testing procedures

## 6. Security Hardening

### Environment Variables Security
```bash
# Use Docker secrets or external secret management
docker secret create solax_token /path/to/solax_token.txt
docker secret create db_password /path/to/db_password.txt
```

### Network Security
- Firewall configuration (UFW/iptables)
- VPN access for admin operations
- Rate limiting and DDoS protection
- Regular security updates

### Access Control
- SSH key-based authentication only
- Sudo access restrictions
- Application-level RBAC
- Audit logging

## 7. Performance Optimization

### Database Optimization
- Connection pooling (already configured)
- Query optimization and indexing
- Regular VACUUM and ANALYZE
- Performance monitoring

### Caching Strategy
- Redis for session management ✅
- API response caching
- Static asset optimization
- CDN integration (optional)

### Load Balancing
- Nginx reverse proxy ✅
- Multiple backend instances (if needed)
- Database read replicas (for scale)

## 8. Deployment Commands

### Full System Restart
```bash
cd /workspace/project/PPA-Frontend

# Stop all services
docker stop solarnexus-frontend solarnexus-backend solarnexus-nginx solarnexus-redis solarnexus-postgres

# Start with production configuration
docker-compose up -d

# Verify all services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Rolling Updates
```bash
# Update backend only
docker-compose build backend --no-cache
docker-compose up -d backend

# Update frontend only  
docker-compose build frontend --no-cache
docker-compose up -d frontend
```

## 9. Monitoring and Maintenance

### Daily Checks
- [ ] All services running and healthy
- [ ] Database connections stable
- [ ] Solar data sync operational
- [ ] Email alerts functioning
- [ ] SSL certificate validity

### Weekly Tasks
- [ ] Review system logs
- [ ] Check backup integrity
- [ ] Performance metrics review
- [ ] Security updates
- [ ] Capacity planning

### Monthly Tasks
- [ ] Full system backup test
- [ ] Security audit
- [ ] Performance optimization
- [ ] User access review
- [ ] Documentation updates

## 10. Support and Troubleshooting

### Log Locations
```bash
# Backend logs
docker logs solarnexus-backend --tail 100

# Frontend logs  
docker logs solarnexus-frontend --tail 100

# Database logs
docker logs solarnexus-postgres --tail 100

# Nginx logs
docker logs solarnexus-nginx --tail 100
```

### Common Issues
1. **Service won't start**: Check environment variables and network connectivity
2. **Database connection failed**: Verify credentials and network access
3. **SSL certificate issues**: Check certificate validity and nginx configuration
4. **High memory usage**: Review application logs and optimize queries
5. **Slow API responses**: Check database performance and caching

### Emergency Contacts
- System Administrator: admin@nexus.gonxt.tech
- Development Team: dev@nexus.gonxt.tech
- Infrastructure Support: ops@nexus.gonxt.tech

---

## 📊 Current System Status

**All Core Services Running Successfully:**
- ✅ Backend API (TypeScript/Node.js)
- ✅ Frontend Web App (React/Nginx)
- ✅ PostgreSQL Database
- ✅ Redis Cache
- ✅ Nginx Reverse Proxy

**Next Steps for Full Production:**
1. Configure production API keys
2. Set up email service
3. Install SSL certificate
4. Deploy monitoring
5. Implement backup strategy

**Repository**: https://github.com/Reshigan/PPA-Frontend
**Server**: 13.244.63.26
**Domain**: nexus.gonxt.tech (pending SSL)