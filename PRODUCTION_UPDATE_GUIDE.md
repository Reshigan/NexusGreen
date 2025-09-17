# NexusGreen Production Update Guide

## Overview

This guide provides instructions for updating the production NexusGreen deployment at `https://nexus.gonxt.tech` with the latest features, including:

- ✅ Complete RAND currency integration
- ✅ Currency selector in dashboard header
- ✅ Dynamic currency formatting across all components
- ✅ Enhanced authentication system
- ✅ All 3 views fully implemented (Dashboard, Projects, Analytics)
- ✅ Comprehensive analytics with AI features

## Current Status

- **Production URL**: https://nexus.gonxt.tech
- **SSL Status**: ✅ Active and working
- **Application Status**: ✅ Running (basic version without currency selector)
- **Server**: 13.245.110.11 (resolves to nexus.gonxt.tech)

## Update Methods

### Method 1: SSH Access (Recommended)

If you have SSH access to the server:

```bash
# Connect to the server
ssh -i your-key.pem ubuntu@13.245.110.11

# Navigate to the application directory
cd ~/NexusGreen

# Run the update script
./update-production.sh
```

### Method 2: Manual Update Process

If SSH access is not available, follow these steps:

1. **Access the server** through your cloud provider console or alternative method
2. **Navigate to the application directory**:
   ```bash
   cd ~/NexusGreen
   ```
3. **Pull the latest changes**:
   ```bash
   git fetch origin
   git pull origin production-deployment-ssl-setup
   ```
4. **Update the deployment**:
   ```bash
   docker-compose -f docker-compose.prod.yml down
   docker-compose -f docker-compose.prod.yml build --no-cache
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Method 3: Complete Redeployment

If you prefer a fresh deployment:

```bash
# Backup current data (optional)
docker exec nexus-db pg_dump -U nexus_user nexusgreen_db > backup.sql

# Remove current deployment
docker-compose -f docker-compose.prod.yml down -v

# Pull latest code
git fetch origin
git reset --hard origin/production-deployment-ssl-setup

# Redeploy
docker-compose -f docker-compose.prod.yml up -d --build
```

## What's New in This Update

### 1. RAND Currency Support
- **Currency Selector**: Added dropdown in dashboard header
- **Dynamic Formatting**: All revenue displays now support USD/RAND
- **Exchange Rate**: 1 USD = 18.5 RAND (configurable)
- **Locale Support**: Proper currency formatting for both currencies

### 2. Enhanced Components
- **Dashboard**: Currency selector integrated in header
- **Charts**: All chart components now use dynamic currency formatting
- **Revenue Cards**: Support both compact and full currency display
- **Analytics**: Currency-aware financial analytics

### 3. Technical Improvements
- **Context System**: Comprehensive currency context management
- **Utilities**: Robust currency formatting utilities
- **Performance**: Optimized rendering with proper context usage

## Verification Steps

After updating, verify the deployment:

### 1. Check Application Status
```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 2. Test Website Functionality
- Visit: https://nexus.gonxt.tech
- Login with: `admin@nexusgreen.energy` / `NexusGreen2024!`
- Verify currency selector appears in dashboard header
- Test switching between USD and RAND
- Check that all revenue displays update correctly

### 3. API Health Check
```bash
curl https://nexus.gonxt.tech/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2025-09-16T16:51:03.000Z"
}
```

## Troubleshooting

### Common Issues

1. **Containers not starting**:
   ```bash
   docker-compose -f docker-compose.prod.yml logs
   ```

2. **Currency selector not visible**:
   - Clear browser cache
   - Check browser console for errors
   - Verify the latest code was pulled

3. **Build failures**:
   ```bash
   # Clean Docker cache
   docker system prune -f
   
   # Rebuild with more memory
   export NODE_OPTIONS="--max-old-space-size=3072"
   docker-compose -f docker-compose.prod.yml build --no-cache
   ```

4. **SSL certificate issues**:
   ```bash
   sudo certbot certificates
   sudo certbot renew --dry-run
   ```

### Rollback Procedure

If issues occur, rollback to previous version:

```bash
# Using the update script
./update-production.sh rollback

# Or manually
docker-compose -f docker-compose.prod.yml down
git reset --hard HEAD~1
docker-compose -f docker-compose.prod.yml up -d --build
```

## Server Cleanup

To optimize server performance:

```bash
# Remove unused Docker resources
docker system prune -af

# Clean up old logs
sudo journalctl --vacuum-time=7d

# Update system packages
sudo apt update && sudo apt upgrade -y
```

## Monitoring

### Health Checks
- **Frontend**: https://nexus.gonxt.tech
- **API**: https://nexus.gonxt.tech/api/health
- **Database**: Check via API health endpoint

### Log Monitoring
```bash
# Application logs
docker-compose -f docker-compose.prod.yml logs -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -f -u docker
```

## Support

If you encounter issues during the update:

1. **Check the logs** first using the commands above
2. **Verify all containers are healthy**
3. **Test individual components** (frontend, API, database)
4. **Check DNS propagation** if domain issues occur

## Security Notes

- All services run in Docker containers
- Database is not exposed to the internet
- SSL/TLS encryption for all web traffic
- Regular security updates recommended

## Backup Strategy

The update script automatically creates backups in `./backups/YYYYMMDD_HHMMSS/`:
- Database dump
- Configuration files

Keep regular backups of:
- Database: `docker exec nexus-db pg_dump -U nexus_user nexusgreen_db > backup.sql`
- Application data: `tar -czf nexusgreen-backup-$(date +%Y%m%d).tar.gz ~/NexusGreen`

---

**Update completed successfully!** 🎉

Your NexusGreen application now includes:
- ✅ RAND currency support with selector
- ✅ Enhanced dashboard with dynamic currency formatting
- ✅ All analytics features with currency awareness
- ✅ Improved authentication and security
- ✅ Comprehensive 3-view system (Dashboard, Projects, Analytics)