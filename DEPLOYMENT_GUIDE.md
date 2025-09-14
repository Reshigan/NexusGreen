# SolarNexus Deployment Guide

## Overview

This guide covers the deployment of SolarNexus using the clean deployment script (`deploy.sh`). The script provides a comprehensive, automated deployment process with server cleanup, dependency management, and monitoring setup.

## Prerequisites

- Ubuntu 20.04+ or Debian 11+ server
- Root access (sudo privileges)
- Domain name pointing to your server (optional but recommended)
- Minimum 2GB RAM, 20GB disk space

## Quick Start

### Basic Deployment

```bash
# Download and run the deployment script
sudo ./deploy.sh
```

### Clean Installation (Recommended for first-time deployment)

```bash
# Perform a clean installation removing all old data
sudo ./deploy.sh --clean
```

### Custom Domain and IP

```bash
# Deploy with custom domain and IP
sudo ./deploy.sh --domain yourdomain.com --ip 1.2.3.4
```

## Deployment Options

| Option | Description |
|--------|-------------|
| `--clean` | Perform clean installation (removes all old data) |
| `--skip-ssl` | Skip SSL certificate setup |
| `--force-rebuild` | Force rebuild of Docker images |
| `--domain DOMAIN` | Set custom domain name |
| `--ip IP` | Set custom server IP |
| `--help` | Show help message |

## Deployment Phases

The deployment script executes in 11 phases:

### Phase 1: System Cleanup and Preparation
- Removes old installations (if `--clean` specified)
- Stops and removes old containers
- Cleans Docker system
- Updates system packages

### Phase 2: Installing Dependencies
- Installs essential packages
- Installs latest Docker and Docker Compose
- Installs Node.js LTS
- Verifies all installations

### Phase 3: Project Setup
- Creates project directories
- Backs up existing deployment
- Clones/updates repository
- Sets proper permissions

### Phase 4: Configuration Setup
- Creates environment files with secure passwords
- Generates JWT secrets
- Configures database connections

### Phase 5: Nginx Configuration
- Creates optimized Nginx configuration
- Sets up SSL-ready virtual hosts
- Configures rate limiting and security headers

### Phase 6: Firewall Configuration
- Configures UFW firewall
- Opens necessary ports (22, 80, 443)

### Phase 7: Docker Deployment
- Builds and starts all services
- Waits for services to be ready
- Verifies service status

### Phase 8: SSL Certificate Setup
- Obtains Let's Encrypt certificates
- Configures automatic renewal
- Sets up HTTPS redirects

### Phase 9: Database Setup
- Runs database migrations
- Generates Prisma client

### Phase 10: Monitoring and Logging Setup
- Configures log rotation
- Sets up health monitoring
- Creates monitoring cron jobs

### Phase 11: Final Health Checks
- Verifies HTTP/HTTPS endpoints
- Checks service responsiveness
- Creates deployment summary

## Post-Deployment

### Service Management

```bash
# View service status
cd /opt/solarnexus && docker-compose ps

# View logs
cd /opt/solarnexus && docker-compose logs -f

# Restart services
cd /opt/solarnexus && docker-compose restart

# Stop services
cd /opt/solarnexus && docker-compose down

# Update deployment
cd /opt/solarnexus && git pull && docker-compose up -d --build
```

### Monitoring

```bash
# View monitoring logs
tail -f /var/log/solarnexus/monitor.log

# Manual health check
curl https://yourdomain.com/health
```

### File Locations

| Component | Location |
|-----------|----------|
| Project Files | `/opt/solarnexus` |
| Logs | `/var/log/solarnexus` |
| SSL Certificates | `/opt/solarnexus/ssl/` |
| Backups | `/opt/solarnexus-backup/` |
| Environment Config | `/opt/solarnexus/.env.production` |

## Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   cd /opt/solarnexus
   docker-compose logs
   docker-compose down && docker-compose up -d
   ```

2. **SSL certificate issues**
   ```bash
   sudo ./deploy.sh --force-rebuild
   ```

3. **Database connection errors**
   ```bash
   cd /opt/solarnexus
   docker-compose restart db backend
   ```

4. **Port conflicts**
   ```bash
   sudo netstat -tulpn | grep :80
   sudo netstat -tulpn | grep :443
   ```

### Log Files

- Application logs: `/opt/solarnexus/logs/`
- System logs: `/var/log/solarnexus/`
- Nginx logs: `/opt/solarnexus/logs/nginx/`
- Docker logs: `docker-compose logs`

## Security Features

- Firewall configuration (UFW)
- SSL/TLS encryption with Let's Encrypt
- Security headers in Nginx
- Rate limiting for API endpoints
- Secure password generation
- File permission management

## Backup and Recovery

### Manual Backup

```bash
# Create backup
sudo cp -r /opt/solarnexus /opt/solarnexus-backup/manual-$(date +%Y%m%d_%H%M%S)

# Database backup
cd /opt/solarnexus
docker-compose exec db mysqldump -u root -p nexus_green > backup.sql
```

### Restore from Backup

```bash
# Stop services
cd /opt/solarnexus && docker-compose down

# Restore files
sudo cp -r /opt/solarnexus-backup/backup_name /opt/solarnexus

# Start services
cd /opt/solarnexus && docker-compose up -d
```

## Performance Optimization

### Nginx Optimizations
- Gzip compression enabled
- Static file caching
- Connection keep-alive
- Worker process optimization

### Docker Optimizations
- Multi-stage builds
- Layer caching
- Resource limits
- Health checks

## Maintenance

### Regular Tasks

1. **Weekly**: Check logs and service status
2. **Monthly**: Review disk space and performance
3. **Quarterly**: Update dependencies and security patches

### Automated Tasks

- **Auto-startup**: Services start automatically on boot
- **Auto-upgrade**: Monitors GitHub for updates every 5 minutes
- **Webhook support**: Instant deployments via GitHub webhooks
- **SSL certificate renewal**: Daily check with auto-renewal
- **Log rotation**: Daily log cleanup and archiving
- **Service health monitoring**: Every 5 minutes with auto-restart
- **System cleanup**: Weekly Docker cleanup and optimization
- **Backup creation**: Automatic backups before upgrades

### Auto-Management Commands

```bash
# Setup GitHub webhook for instant deployments
sudo ./setup-github-webhook.sh --server-ip YOUR_IP --token YOUR_GITHUB_TOKEN

# Manual upgrade operations
sudo ./auto-upgrade.sh --check          # Check for updates
sudo ./auto-upgrade.sh --upgrade        # Force upgrade
sudo ./auto-upgrade.sh --upgrade --dry-run  # Preview changes

# Comprehensive management
sudo ./manage-solarnexus.sh status      # System overview
sudo ./manage-solarnexus.sh health      # Health check
sudo ./manage-solarnexus.sh logs updater # View upgrade logs

# Service control
sudo systemctl status solarnexus        # Main service status
sudo systemctl status solarnexus-updater # Auto-updater status
sudo journalctl -u solarnexus-updater -f # Follow upgrade logs
```

## Support

For deployment issues:

1. Check the deployment logs
2. Review service status with `docker-compose ps`
3. Check individual service logs
4. Verify firewall and network configuration
5. Ensure domain DNS is properly configured

## Environment Variables

Key environment variables in `.env.production`:

```bash
NODE_ENV=production
DATABASE_URL=mysql://...
REDIS_URL=redis://...
JWT_SECRET=...
DOMAIN=yourdomain.com
SERVER_IP=1.2.3.4
```

## Updates and Maintenance

### Updating the Application

```bash
cd /opt/solarnexus
git pull origin main
docker-compose build --no-cache
docker-compose up -d
```

### Updating Dependencies

```bash
# Re-run deployment with force rebuild
sudo ./deploy.sh --force-rebuild
```

This deployment script provides a production-ready, secure, and monitored installation of SolarNexus with minimal manual intervention required.