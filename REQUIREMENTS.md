# NexusGreen System Requirements

## Server Requirements

### Minimum System Requirements
- **OS**: Ubuntu 20.04 LTS or newer (recommended)
- **CPU**: 2 vCPUs
- **RAM**: 4GB
- **Storage**: 20GB SSD
- **Network**: 1Gbps connection

### Recommended System Requirements
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 4 vCPUs
- **RAM**: 8GB
- **Storage**: 50GB SSD
- **Network**: 1Gbps connection

### AWS Instance Recommendations
- **Minimum**: t3.medium (2 vCPU, 4GB RAM)
- **Recommended**: t3.large (2 vCPU, 8GB RAM)
- **Production**: c5.xlarge (4 vCPU, 8GB RAM)

## Software Dependencies

### System Packages
```bash
# Core system packages
curl
wget
git
unzip
htop

# Web server and SSL
nginx
certbot
python3-certbot-nginx

# Security
ufw (Uncomplicated Firewall)

# Container runtime
docker.io (or Docker CE)
docker-compose
```

### Docker Images
```yaml
# Application services
node:20-alpine          # Backend runtime
nginx:alpine           # Web server
postgres:15-alpine     # Database
redis:7-alpine         # Cache/sessions

# Build dependencies (temporary)
node:20                # For building frontend/backend
```

### Node.js Dependencies

#### Frontend (React/Vite)
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "axios": "^1.3.0",
    "lucide-react": "^0.263.1",
    "@radix-ui/react-*": "Various UI components",
    "tailwindcss": "^3.3.0",
    "typescript": "^5.0.0"
  },
  "devDependencies": {
    "vite": "^4.4.5",
    "@vitejs/plugin-react": "^4.0.3",
    "eslint": "^8.45.0",
    "prettier": "^3.0.0"
  }
}
```

#### Backend (Node.js/Express)
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "prisma": "^5.0.0",
    "@prisma/client": "^5.0.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.7.0",
    "nodemailer": "^6.9.0",
    "redis": "^4.6.0",
    "socket.io": "^4.7.0",
    "winston": "^3.10.0",
    "dotenv": "^16.3.0",
    "typescript": "^5.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/express": "^4.17.0",
    "ts-node": "^10.9.0",
    "nodemon": "^3.0.0"
  }
}
```

## Network Requirements

### Ports
- **22**: SSH access
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS (main application)
- **3000**: Backend API (internal only)
- **5432**: PostgreSQL (internal only)
- **6379**: Redis (internal only)

### Firewall Configuration
```bash
# Allow SSH, HTTP, and HTTPS only
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny everything else
```

### DNS Configuration
- **A Record**: nexus.gonxt.tech → [Your Server IP]
- **CNAME Record**: www.nexus.gonxt.tech → nexus.gonxt.tech (optional)
- **SSL Email**: reshigan@gonxt.tech

## SSL/TLS Requirements

### Certificate Authority
- Let's Encrypt (free, automated)
- Automatic renewal via certbot

### TLS Configuration
- **Protocols**: TLS 1.2, TLS 1.3
- **Cipher Suites**: Modern, secure ciphers only
- **HSTS**: Enabled with 1-year max-age
- **Certificate Transparency**: Enabled

## Database Requirements

### PostgreSQL Configuration
- **Version**: PostgreSQL 15+
- **Storage**: Minimum 5GB, recommended 20GB+
- **Connections**: Max 100 concurrent connections
- **Backup**: Daily automated backups
- **Replication**: Optional for high availability

### Redis Configuration
- **Version**: Redis 7+
- **Memory**: 512MB minimum, 2GB recommended
- **Persistence**: RDB snapshots enabled
- **Security**: Password authentication enabled

## Security Requirements

### Authentication
- JWT tokens with secure secrets
- Password hashing with bcrypt
- Session management via Redis
- Rate limiting on API endpoints

### Environment Variables
All sensitive configuration stored in environment variables:
```bash
# Database
DATABASE_URL
POSTGRES_PASSWORD

# Cache
REDIS_URL
REDIS_PASSWORD

# Authentication
JWT_SECRET
JWT_REFRESH_SECRET

# Email
EMAIL_HOST
EMAIL_USER
EMAIL_PASS

# External APIs
SOLAX_API_TOKEN
```

### File Permissions
```bash
# Application files
/opt/solarnexus: 755 (www-data:www-data)

# SSL certificates
/opt/solarnexus/ssl/*.pem: 644/600 (root:root)

# Environment files
/opt/solarnexus/.env*: 600 (www-data:www-data)

# Log files
/opt/solarnexus/logs: 755 (www-data:www-data)
```

## Monitoring Requirements

### Health Checks
- Application health endpoint: `/health`
- Database connectivity check
- Redis connectivity check
- SSL certificate expiry monitoring

### Logging
- Application logs: JSON format
- Access logs: Nginx combined format
- Error logs: Structured logging with Winston
- Log rotation: Daily, keep 30 days

### Backup Strategy
- Database: Daily PostgreSQL dumps
- Files: Daily tar.gz of uploads and configuration
- Retention: 30 days local, longer-term offsite recommended

## Performance Requirements

### Response Times
- **Static files**: < 100ms
- **API endpoints**: < 500ms
- **Database queries**: < 200ms
- **Page load**: < 2 seconds

### Throughput
- **Concurrent users**: 100+
- **API requests**: 1000+ per minute
- **Database connections**: 50+ concurrent

### Caching Strategy
- **Static assets**: 1 year browser cache
- **API responses**: Redis cache where appropriate
- **Database queries**: Connection pooling

## Development Requirements

### Local Development
```bash
# Required software
Node.js 20+
npm 10+
Docker 24+
Docker Compose 2+
Git 2.30+

# Optional but recommended
VS Code with extensions:
- TypeScript
- Prettier
- ESLint
- Docker
- GitLens
```

### Build Requirements
```bash
# Frontend build
npm install
npm run build
# Produces: dist/ directory

# Backend build
npm install
npm run build
# Produces: dist/ directory with compiled TypeScript
```

## Deployment Checklist

### Pre-deployment
- [ ] Server meets minimum requirements
- [ ] DNS records configured
- [ ] SSH access configured
- [ ] Firewall rules planned

### Deployment
- [ ] Run deployment script
- [ ] Verify all services start
- [ ] Test SSL certificate
- [ ] Verify database connectivity
- [ ] Test application functionality

### Post-deployment
- [ ] Configure monitoring
- [ ] Set up automated backups
- [ ] Configure log rotation
- [ ] Test disaster recovery procedures
- [ ] Document any customizations

## Troubleshooting

### Common Issues
1. **Out of disk space**: Monitor `/opt/solarnexus/logs` and Docker volumes
2. **Memory issues**: Check Docker container limits and system memory
3. **SSL certificate issues**: Verify DNS and Let's Encrypt rate limits
4. **Database connection issues**: Check PostgreSQL logs and connection limits
5. **Performance issues**: Monitor CPU, memory, and database query performance

### Diagnostic Commands
```bash
# System resources
htop
df -h
free -h

# Docker status
docker-compose ps
docker-compose logs -f
docker stats

# Service status
systemctl status nginx
systemctl status docker

# Network connectivity
netstat -tlnp
curl -I https://nexus.gonxt.tech
```

## Support and Maintenance

### Regular Maintenance Tasks
- **Weekly**: Review logs for errors
- **Monthly**: Update system packages
- **Quarterly**: Review security configurations
- **Annually**: Renew any manual certificates

### Update Procedures
1. Test updates in staging environment
2. Create backup before updates
3. Update during low-traffic periods
4. Monitor application after updates
5. Have rollback plan ready

### Emergency Contacts
- System Administrator: [Contact Info]
- Database Administrator: [Contact Info]
- Application Developer: [Contact Info]
- Hosting Provider Support: [Contact Info]