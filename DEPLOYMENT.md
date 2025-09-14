# SolarNexus AWS Deployment Guide

## Server Information
- **IP Address**: 13.245.249.110
- **Domain**: nexus.gonxt.tech
- **OS**: Ubuntu 20.04+ (recommended)

## Quick Deployment

### 1. Connect to Server
```bash
ssh root@13.245.249.110
# or
ssh root@nexus.gonxt.tech
```

### 2. Run Deployment Script
```bash
# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git /opt/solarnexus
cd /opt/solarnexus

# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The deployment script will automatically:
- Install Docker, Docker Compose, Node.js, and Nginx
- Configure firewall (UFW)
- Set up SSL certificates with Let's Encrypt
- Create secure environment variables
- Build and start all services
- Configure log rotation and monitoring

## Manual Deployment Steps

If you prefer manual deployment or need to troubleshoot:

### 1. System Requirements
```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw htop unzip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### 2. Clone and Setup Project
```bash
# Create project directory
mkdir -p /opt/solarnexus
cd /opt/solarnexus

# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git .

# Set permissions
chown -R www-data:www-data /opt/solarnexus
chmod -R 755 /opt/solarnexus

# Create necessary directories
mkdir -p logs/nginx logs/backend uploads ssl
```

### 3. Environment Configuration
```bash
# Copy production environment template
cp .env.production.template .env.production

# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
JWT_REFRESH_SECRET=$(openssl rand -base64 64)

# Update environment file
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env.production
sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" .env.production
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env.production
sed -i "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" .env.production

# Copy for docker-compose
cp .env.production .env
```

### 4. Configure Firewall
```bash
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### 5. Build and Start Services
```bash
# Build and start all services
docker-compose build --no-cache
docker-compose up -d

# Check service status
docker-compose ps
docker-compose logs -f
```

### 6. SSL Certificate Setup
```bash
# Stop nginx temporarily
docker-compose stop nginx

# Get SSL certificate
certbot certonly --standalone \
    --email admin@nexus.gonxt.tech \
    --agree-tos \
    --no-eff-email \
    -d nexus.gonxt.tech

# Copy certificates to project
cp /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem ssl/
cp /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem ssl/

# Set permissions
chmod 644 ssl/fullchain.pem
chmod 600 ssl/privkey.pem

# Restart nginx
docker-compose start nginx
```

### 7. Database Setup
```bash
# Run database migrations
docker-compose exec backend npm run prisma:migrate:deploy
docker-compose exec backend npm run prisma:generate
```

## Service Architecture

### Services Overview
- **Frontend**: React application served by Nginx
- **Backend**: Node.js/Express API server
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Reverse Proxy**: Nginx with SSL termination

### Port Configuration
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS (main application)
- **3000**: Backend API (internal)
- **5432**: PostgreSQL (internal)
- **6379**: Redis (internal)

### Docker Network
All services run on a custom bridge network `solarnexus-network` with subnet `172.20.0.0/16`.

## Management Commands

### Service Management
```bash
cd /opt/solarnexus

# View service status
docker-compose ps

# View logs
docker-compose logs -f
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart services
docker-compose restart
docker-compose restart backend

# Stop all services
docker-compose down

# Update deployment
git pull origin main
docker-compose up -d --build
```

### Database Management
```bash
# Access database
docker-compose exec postgres psql -U solarnexus -d solarnexus

# Backup database
docker-compose exec postgres pg_dump -U solarnexus solarnexus > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
docker-compose exec -T postgres psql -U solarnexus -d solarnexus < backup.sql

# Run migrations
docker-compose exec backend npm run prisma:migrate:deploy
```

### SSL Certificate Management
```bash
# Check certificate expiry
certbot certificates

# Renew certificates manually
certbot renew --dry-run

# Auto-renewal is configured via cron:
# 0 12 * * * root certbot renew --quiet --post-hook "cd /opt/solarnexus && docker-compose restart nginx"
```

### Log Management
```bash
# View application logs
tail -f /opt/solarnexus/logs/backend/app.log
tail -f /opt/solarnexus/logs/nginx/access.log
tail -f /opt/solarnexus/logs/nginx/error.log

# Log rotation is configured automatically
# Logs are rotated daily and kept for 52 days
```

## Monitoring and Health Checks

### Health Endpoints
- **Application**: `https://nexus.gonxt.tech/health`
- **API**: `https://nexus.gonxt.tech/api/health`

### Service Health Checks
```bash
# Check all services
docker-compose ps

# Check individual service health
docker-compose exec backend curl -f http://localhost:3000/health
docker-compose exec postgres pg_isready -U solarnexus -d solarnexus
docker-compose exec redis redis-cli ping
```

### System Monitoring
```bash
# System resources
htop
df -h
free -h

# Docker resources
docker system df
docker stats

# Network status
netstat -tlnp
```

## Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Check memory
free -h

# Restart Docker daemon
systemctl restart docker
```

#### SSL Certificate Issues
```bash
# Check certificate status
certbot certificates

# Test certificate renewal
certbot renew --dry-run

# Manual certificate renewal
certbot renew --force-renewal
```

#### Database Connection Issues
```bash
# Check database status
docker-compose exec postgres pg_isready -U solarnexus -d solarnexus

# Check database logs
docker-compose logs postgres

# Reset database (WARNING: This will delete all data)
docker-compose down -v
docker-compose up -d
```

#### Performance Issues
```bash
# Check system resources
htop
iotop
nethogs

# Check Docker resources
docker stats

# Optimize Docker
docker system prune -a
```

### Log Locations
- **Application Logs**: `/opt/solarnexus/logs/`
- **Nginx Logs**: `/opt/solarnexus/logs/nginx/`
- **Docker Logs**: `docker-compose logs`
- **System Logs**: `/var/log/syslog`

## Security Considerations

### Firewall Configuration
- Only ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) are open
- All other ports are blocked by default

### SSL/TLS Configuration
- TLS 1.2 and 1.3 only
- Strong cipher suites
- HSTS headers enabled
- Security headers configured

### Environment Variables
- All sensitive data stored in environment variables
- Secure random passwords generated automatically
- Database and Redis passwords are unique and strong

### Regular Maintenance
- Keep system packages updated
- Monitor SSL certificate expiry
- Regular database backups
- Log monitoring and rotation

## Backup Strategy

### Automated Backups
Create a backup script at `/opt/backup-solarnexus.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/solarnexus"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose exec -T postgres pg_dump -U solarnexus solarnexus > $BACKUP_DIR/db_$DATE.sql

# Files backup
tar -czf $BACKUP_DIR/files_$DATE.tar.gz -C /opt/solarnexus uploads logs ssl .env.production

# Keep only last 30 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/backup-solarnexus.sh
```

## Support

For deployment issues or questions:
1. Check the logs: `docker-compose logs -f`
2. Verify service status: `docker-compose ps`
3. Check system resources: `htop`, `df -h`
4. Review this documentation
5. Check GitHub issues: https://github.com/Reshigan/SolarNexus/issues

## Updates

To update the deployment:
```bash
cd /opt/solarnexus
git pull origin main
docker-compose up -d --build
```

For major updates, consider running the deployment script again:
```bash
./deploy.sh
```