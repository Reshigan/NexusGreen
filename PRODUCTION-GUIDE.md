# SolarNexus Production Deployment Guide

## 🚀 Quick Start - Bulletproof Installation

### Prerequisites
- Ubuntu 22.04 LTS on AWS EC2
- Root access or sudo privileges
- Domain name (optional, for SSL)
- At least 2GB RAM and 10GB disk space

### One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/production-install.sh | sudo bash
```

This script will:
- ✅ Install all dependencies (Docker, Node.js, PostgreSQL, Redis, Nginx)
- ✅ Configure security (firewall, fail2ban)
- ✅ Set up application with proper permissions
- ✅ Create systemd services
- ✅ Configure automated backups
- ✅ Perform health checks
- ✅ Set up monitoring

## 🔒 SSL/HTTPS Setup (Optional)

After installation, set up SSL for your domain:

```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/setup-ssl.sh | sudo bash -s yourdomain.com admin@yourdomain.com
```

## 📊 System Management

### Service Management

```bash
# Check status
systemctl status solarnexus-backend solarnexus-frontend

# View logs
journalctl -u solarnexus-backend -f
journalctl -u solarnexus-frontend -f

# Restart services
systemctl restart solarnexus-backend
systemctl restart solarnexus-frontend

# Stop/Start services
systemctl stop solarnexus-backend solarnexus-frontend
systemctl start solarnexus-backend solarnexus-frontend
```

### Monitoring

```bash
# Run health check
/opt/solarnexus/monitor.sh

# Start continuous monitoring
/opt/solarnexus/monitor.sh --continuous

# Generate system report
/opt/solarnexus/monitor.sh --report
```

### Backup Management

```bash
# Manual backup
/usr/local/bin/solarnexus-backup.sh

# View backups
ls -la /var/backups/solarnexus/

# Restore from backup (example)
sudo -u postgres psql -d solarnexus < /var/backups/solarnexus/database_YYYYMMDD_HHMMSS.sql
```

## 🔧 Configuration Files

### Application Configuration
- **Main Config**: `/opt/solarnexus/.env.production`
- **Nginx Config**: `/opt/solarnexus/nginx.conf`
- **Systemd Services**: `/etc/systemd/system/solarnexus-*.service`

### Log Files
- **Application Logs**: `/var/log/solarnexus/`
- **System Logs**: `journalctl -u solarnexus-backend`
- **Nginx Logs**: `/var/log/solarnexus/nginx-*.log`

### Data Directories
- **Application**: `/opt/solarnexus/`
- **Database**: `/var/lib/postgresql/`
- **Uploads**: `/var/lib/solarnexus/uploads/`
- **Backups**: `/var/backups/solarnexus/`

## 🛡️ Security Features

### Firewall Configuration
```bash
# Check firewall status
ufw status

# Allow additional ports (if needed)
ufw allow 8080/tcp comment "Custom port"

# Block specific IP
ufw deny from 192.168.1.100
```

### SSL Certificate Management
```bash
# Check certificate status
certbot certificates

# Renew certificates manually
certbot renew

# Test renewal process
certbot renew --dry-run
```

### Security Hardening
- ✅ Non-root application user
- ✅ Proper file permissions
- ✅ Firewall configured
- ✅ Fail2ban protection
- ✅ Security headers in Nginx
- ✅ SSL/TLS encryption
- ✅ Database access restrictions

## 📈 Performance Optimization

### Database Optimization
```bash
# Check database performance
sudo -u postgres psql -d solarnexus -c "
SELECT schemaname,tablename,attname,n_distinct,correlation 
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY n_distinct DESC;
"

# Analyze database
sudo -u postgres psql -d solarnexus -c "ANALYZE;"

# Vacuum database
sudo -u postgres psql -d solarnexus -c "VACUUM ANALYZE;"
```

### Redis Optimization
```bash
# Check Redis info
redis-cli info

# Monitor Redis commands
redis-cli monitor

# Check memory usage
redis-cli info memory
```

### System Performance
```bash
# Check system resources
htop
iotop
nethogs

# Check disk usage
df -h
du -sh /opt/solarnexus/*

# Check memory usage
free -h
```

## 🔄 Updates and Maintenance

### Application Updates
```bash
cd /opt/solarnexus
sudo -u solarnexus git pull origin main
sudo -u solarnexus npm ci --only=production
sudo -u solarnexus npm run build
systemctl restart solarnexus-backend solarnexus-frontend
```

### System Updates
```bash
# Update system packages
apt update && apt upgrade -y

# Update Docker
apt update && apt install docker-ce docker-ce-cli containerd.io

# Update Node.js (if needed)
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
```

### Database Maintenance
```bash
# Database backup before maintenance
pg_dump -U solarnexus -h localhost solarnexus > backup_before_maintenance.sql

# Update database statistics
sudo -u postgres psql -d solarnexus -c "ANALYZE;"

# Reindex database (if needed)
sudo -u postgres psql -d solarnexus -c "REINDEX DATABASE solarnexus;"
```

## 🚨 Troubleshooting

### Common Issues

#### Backend Service Won't Start
```bash
# Check logs
journalctl -u solarnexus-backend -n 50

# Check configuration
cat /opt/solarnexus/.env.production

# Test database connection
sudo -u postgres psql -d solarnexus -c "SELECT 1;"

# Test Redis connection
redis-cli ping
```

#### Frontend Not Loading
```bash
# Check Nginx status
systemctl status solarnexus-frontend

# Check Nginx configuration
nginx -t -c /opt/solarnexus/nginx.conf

# Check build files
ls -la /opt/solarnexus/dist/

# Rebuild frontend
cd /opt/solarnexus
sudo -u solarnexus npm run build
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
systemctl status postgresql

# Check database connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Reset database password
sudo -u postgres psql -c "ALTER USER solarnexus PASSWORD 'SolarNexus2024!';"
```

#### High Resource Usage
```bash
# Check processes
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10

# Check disk usage
df -h
du -sh /var/log/* | sort -hr

# Clean up logs
journalctl --vacuum-time=7d
find /var/log -name "*.log" -mtime +7 -delete
```

### Emergency Recovery

#### Service Recovery
```bash
# Stop all services
systemctl stop solarnexus-backend solarnexus-frontend

# Check for port conflicts
netstat -tulpn | grep :5000
netstat -tulpn | grep :3000

# Restart services
systemctl start solarnexus-backend
sleep 10
systemctl start solarnexus-frontend
```

#### Database Recovery
```bash
# Restore from backup
sudo -u postgres psql -d solarnexus < /var/backups/solarnexus/database_LATEST.sql

# Reset database if corrupted
sudo -u postgres dropdb solarnexus
sudo -u postgres createdb solarnexus -O solarnexus
sudo -u postgres psql -d solarnexus < /opt/solarnexus/database/migration.sql
```

## 📞 Support and Monitoring

### Health Check URLs
- **Backend Health**: `http://YOUR_IP:5000/health`
- **Frontend Health**: `http://YOUR_IP:3000/health`
- **Full System Check**: `/opt/solarnexus/monitor.sh`

### Log Monitoring
```bash
# Real-time log monitoring
tail -f /var/log/solarnexus/*.log

# Error monitoring
journalctl -u solarnexus-backend -p err -f
journalctl -u solarnexus-frontend -p err -f
```

### Performance Monitoring
```bash
# System resources
watch -n 1 'free -h && echo && df -h && echo && uptime'

# Application metrics
curl -s http://localhost:5000/metrics 2>/dev/null || echo "Metrics endpoint not available"
```

## 🎯 Production Checklist

### Pre-Deployment
- [ ] Server meets minimum requirements (2GB RAM, 10GB disk)
- [ ] Domain name configured (if using SSL)
- [ ] Firewall rules reviewed
- [ ] Backup strategy planned

### Post-Deployment
- [ ] All services running (`systemctl status solarnexus-*`)
- [ ] Health checks passing (`/opt/solarnexus/monitor.sh`)
- [ ] SSL certificate installed (if applicable)
- [ ] Monitoring configured
- [ ] Backup tested
- [ ] Performance baseline established

### Ongoing Maintenance
- [ ] Weekly health checks
- [ ] Monthly system updates
- [ ] Quarterly security review
- [ ] Regular backup verification
- [ ] Performance monitoring
- [ ] Log rotation and cleanup

## 📋 Default Credentials

### Application Access
- **URL**: `http://YOUR_IP:3000` (or `https://YOUR_DOMAIN`)
- **Admin Email**: `admin@solarnexus.com`
- **Admin Password**: `admin123` (⚠️ Change immediately in production!)

### Database Access
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `solarnexus`
- **Username**: `solarnexus`
- **Password**: `SolarNexus2024!`

### System Access
- **Application User**: `solarnexus`
- **Application Directory**: `/opt/solarnexus`
- **Log Directory**: `/var/log/solarnexus`

---

## 🆘 Emergency Contacts

For critical issues:
1. Check system logs: `journalctl -xe`
2. Run health check: `/opt/solarnexus/monitor.sh`
3. Review this guide's troubleshooting section
4. Contact system administrator

**Remember**: Always test changes in a staging environment before applying to production!