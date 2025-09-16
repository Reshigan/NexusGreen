# NexusGreen Production Deployment Guide

This guide covers the complete production deployment of NexusGreen with SSL support on AWS EC2.

## Server Requirements

- **Instance Type**: t4g.medium or higher (ARM64 recommended)
- **OS**: Amazon Linux 2023
- **Storage**: 20GB+ EBS volume
- **Security Groups**: 
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)

## Deployment Steps

### 1. Server Setup

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ec2-user@your-server-ip

# Clone the repository
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Run the production deployment script
chmod +x production-deploy.sh
./production-deploy.sh
```

### 2. DNS Configuration

Point your domain to the server IP:
```
A Record: nexus.gonxt.tech -> YOUR_SERVER_IP
```

### 3. SSL Certificate

The deployment script automatically sets up SSL using Let's Encrypt:
- Certificate is valid for 90 days
- Auto-renewal is configured via cron
- HTTPS redirect is automatically configured

### 4. Service Management

```bash
# Check container status
sudo docker-compose -f docker-compose.prod.yml ps

# View logs
sudo docker-compose -f docker-compose.prod.yml logs -f

# Restart services
sudo docker-compose -f docker-compose.prod.yml restart

# Update deployment
git pull origin main
sudo docker-compose -f docker-compose.prod.yml up -d --build
```

## Architecture

```
Internet → nginx (Host) → Docker Containers
                      ├── nexus-green (Frontend:8080)
                      ├── nexus-api (API:3001)
                      └── nexus-db (PostgreSQL:5432)
```

## URLs

- **Website**: https://nexus.gonxt.tech
- **API**: https://nexus.gonxt.tech/api
- **Health Check**: https://nexus.gonxt.tech/api/health

## Monitoring

### Health Checks
```bash
# API Health
curl https://nexus.gonxt.tech/api/health

# Frontend Health
curl https://nexus.gonxt.tech/

# Container Health
sudo docker-compose -f docker-compose.prod.yml ps
```

### Logs
```bash
# All services
sudo docker-compose -f docker-compose.prod.yml logs -f

# Specific service
sudo docker-compose -f docker-compose.prod.yml logs -f nexus-api

# nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Troubleshooting

### Common Issues

1. **Containers not starting**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml logs
   ```

2. **SSL certificate issues**
   ```bash
   sudo certbot certificates
   sudo certbot renew --dry-run
   ```

3. **nginx configuration issues**
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   ```

4. **Database connection issues**
   ```bash
   sudo docker-compose -f docker-compose.prod.yml exec nexus-db psql -U nexus_user -d nexusgreen_db
   ```

### Performance Optimization

1. **Enable nginx caching** (optional)
2. **Configure log rotation**
3. **Set up monitoring with CloudWatch**
4. **Configure backup for PostgreSQL data**

## Security

- All services run in Docker containers
- Database is not exposed to the internet
- SSL/TLS encryption for all web traffic
- Regular security updates via `yum update`

## Backup

```bash
# Database backup
sudo docker-compose -f docker-compose.prod.yml exec nexus-db pg_dump -U nexus_user nexusgreen_db > backup.sql

# Full application backup
tar -czf nexusgreen-backup-$(date +%Y%m%d).tar.gz /opt/nexusgreen
```

## Updates

```bash
# Pull latest changes
cd /opt/nexusgreen
git pull origin main

# Rebuild and restart
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Verify deployment
curl https://nexus.gonxt.tech/api/health
```

## Support

For issues or questions:
1. Check the logs first
2. Verify all containers are healthy
3. Test individual components
4. Check DNS propagation if domain issues occur