# 🌞 NexusGreen Production Installation Guide

Complete guide for installing NexusGreen in production with SSL, demo data, and full automation.

## 🚀 Quick Installation

### One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/NexusGreen/main/install-solarnexus.sh | bash
```

This will:
- ✅ Install all dependencies (Docker, nginx, certbot)
- ✅ Configure SSL certificate with Let's Encrypt
- ✅ Set up South African timezone (SAST)
- ✅ Deploy complete NexusGreen application
- ✅ Seed demo data with GonXT Solar Solutions
- ✅ Configure production-grade security

## 📋 Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04+ (recommended)
- **RAM**: Minimum 2GB, recommended 4GB+
- **Storage**: Minimum 20GB available space
- **Network**: Internet connection required

### Domain & DNS
- Domain name pointing to your server (e.g., nexus.gonxt.tech)
- DNS A record configured
- Ports 80 and 443 accessible from internet

### Access Requirements
- SSH access to server
- User with sudo privileges
- Root access not required (script uses sudo)

## 🛠️ Manual Installation

If you prefer manual installation or need to customize the process:

### Step 1: Download Deployment Script

```bash
wget https://raw.githubusercontent.com/Reshigan/NexusGreen/main/production-deploy.sh
chmod +x production-deploy.sh
```

### Step 2: Configure Environment (Optional)

```bash
export DOMAIN="your-domain.com"
export EMAIL="your-email@domain.com"
```

### Step 3: Run Deployment

```bash
sudo ./production-deploy.sh
```

## 🔧 Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAIN` | nexus.gonxt.tech | Your domain name |
| `EMAIL` | reshigan@gonxt.tech | Email for SSL certificate |
| `DEMO_ADMIN_EMAIL` | admin@gonxt.tech | Demo admin email |
| `DEMO_ADMIN_PASSWORD` | Demo2024! | Demo admin password |
| `DEMO_USER_EMAIL` | user@gonxt.tech | Demo user email |
| `DEMO_USER_PASSWORD` | Demo2024! | Demo user password |

### Custom Configuration

```bash
export DOMAIN="mydomain.com"
export EMAIL="admin@mydomain.com"
export DEMO_ADMIN_EMAIL="admin@mydomain.com"
export DEMO_ADMIN_PASSWORD="MySecurePassword123!"
sudo -E ./production-deploy.sh
```

## 🌐 Post-Installation

### Access Your Installation

- **URL**: https://your-domain.com
- **Admin Login**: admin@gonxt.tech / Demo2024!
- **User Login**: user@gonxt.tech / Demo2024!

### Demo Company Data

The installation includes demo data for **GonXT Solar Solutions**:
- Sample solar projects
- Customer records
- Installation data
- Financial reports

## 🛠️ Management Commands

### Docker Management

```bash
# View running containers
cd /opt/solarnexus && sudo docker compose ps

# View logs
cd /opt/solarnexus && sudo docker compose logs

# Restart services
cd /opt/solarnexus && sudo docker compose restart

# Update application
cd /opt/solarnexus && git pull && sudo docker compose up -d --build
```

### SSL Certificate Management

```bash
# Check certificate status
sudo certbot certificates

# Renew certificates (automatic via cron)
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

### Nginx Management

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# View access logs
sudo tail -f /var/log/nginx/access.log
```

## 📁 Important File Locations

| Component | Location |
|-----------|----------|
| Application | `/opt/solarnexus` |
| Nginx Config | `/etc/nginx/sites-available/solarnexus` |
| SSL Certificates | `/etc/letsencrypt/live/your-domain` |
| Docker Compose | `/opt/solarnexus/docker-compose.yml` |
| Environment File | `/opt/solarnexus/.env` |
| Application Logs | `docker compose logs` |
| Nginx Logs | `/var/log/nginx/` |

## 🔍 Troubleshooting

### Common Issues

#### 1. SSL Certificate Failed
```bash
# Check DNS resolution
nslookup your-domain.com

# Verify ports are open
sudo ufw status
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Manual SSL fix
sudo /opt/solarnexus/fix-ssl-nginx-issue.sh your-domain.com your-email@domain.com
```

#### 2. Docker Installation Failed
```bash
# Manual Docker fix
sudo /opt/solarnexus/fix-docker-installation.sh
```

#### 3. Timezone Issues
```bash
# Manual timezone fix
sudo /opt/solarnexus/fix-timezone-issue.sh
```

#### 4. Application Not Starting
```bash
# Check container status
cd /opt/solarnexus && sudo docker compose ps

# View detailed logs
cd /opt/solarnexus && sudo docker compose logs backend
cd /opt/solarnexus && sudo docker compose logs frontend
cd /opt/solarnexus && sudo docker compose logs postgres
```

#### 5. Database Connection Issues
```bash
# Check PostgreSQL container
cd /opt/solarnexus && sudo docker compose logs postgres

# Connect to database
cd /opt/solarnexus && sudo docker compose exec postgres psql -U solarnexus_user -d solarnexus_db
```

### Health Checks

```bash
# Backend health
curl http://localhost:5000/health

# Frontend accessibility
curl -I http://localhost:3000

# SSL certificate check
curl -I https://your-domain.com

# Database connectivity
cd /opt/solarnexus && sudo docker compose exec backend npm run db:test
```

## 🔒 Security Features

### Included Security Measures

- **SSL/TLS**: Let's Encrypt certificates with auto-renewal
- **Security Headers**: HSTS, CSP, X-Frame-Options, etc.
- **Rate Limiting**: API and login endpoint protection
- **Firewall**: UFW configured for essential ports only
- **Container Security**: Non-root containers, minimal images
- **Database Security**: Isolated network, strong passwords

### Security Headers Applied

```
Strict-Transport-Security: max-age=63072000
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: [Comprehensive CSP policy]
```

## 📊 Performance Optimization

### Included Optimizations

- **Gzip Compression**: Enabled for all text content
- **Static Asset Caching**: 1-year cache for static files
- **Database Connection Pooling**: Optimized PostgreSQL settings
- **Container Resource Limits**: Proper memory and CPU limits
- **Nginx Optimization**: Worker processes and connection tuning

## 🔄 Updates and Maintenance

### Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update NexusGreen application
cd /opt/solarnexus
git pull
sudo docker compose up -d --build

# Update SSL certificates (automatic)
sudo certbot renew
```

### Backup Procedures

```bash
# Database backup
cd /opt/solarnexus
sudo docker compose exec postgres pg_dump -U solarnexus_user solarnexus_db > backup_$(date +%Y%m%d).sql

# Full application backup
sudo tar -czf solarnexus_backup_$(date +%Y%m%d).tar.gz /opt/solarnexus
```

## 📞 Support

### Getting Help

1. **Check Logs**: Always start with application and nginx logs
2. **Run Health Checks**: Use the provided health check commands
3. **Review Configuration**: Verify environment variables and settings
4. **Community Support**: Check GitHub issues and discussions

### Reporting Issues

When reporting issues, please include:
- Server OS and version
- Error messages from logs
- Steps to reproduce
- Configuration details (without sensitive data)

## 🎉 Success!

Your NexusGreen installation should now be running at:
**https://your-domain.com**

Login with:
- **Admin**: admin@gonxt.tech / Demo2024!
- **User**: user@gonxt.tech / Demo2024!

Welcome to NexusGreen! 🌞