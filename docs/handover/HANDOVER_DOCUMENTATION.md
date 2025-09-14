# SolarNexus - Handover Documentation

## Executive Summary

This document provides comprehensive handover information for the SolarNexus solar energy management platform. It includes operational procedures, maintenance guidelines, troubleshooting information, and contact details necessary for ongoing system management and support.

## Project Handover Details

### Project Information
- **Project Name**: SolarNexus
- **Version**: 1.0.0
- **Handover Date**: January 15, 2024
- **Production URL**: https://nexus.gonxt.tech
- **Server**: AWS EC2 (13.245.249.110)
- **Repository**: https://github.com/Reshigan/SolarNexus

### Handover Scope
- ✅ Complete application deployment
- ✅ Production environment setup
- ✅ SSL certificate configuration
- ✅ Database setup and migrations
- ✅ Monitoring and logging
- ✅ Backup procedures
- ✅ Documentation and procedures
- ✅ Security configuration

## System Overview

### Architecture Summary
```
Internet → CloudFlare/CDN → Nginx → React Frontend
                                  ↓
                              Node.js API
                                  ↓
                    PostgreSQL ← → Redis Cache
                                  ↓
                            External APIs
                        (SolaX, Weather, Email)
```

### Key Components
1. **Frontend**: React 18 with TypeScript, built with Vite
2. **Backend**: Node.js 20 with Express and TypeScript
3. **Database**: PostgreSQL 15 with Prisma ORM
4. **Cache**: Redis 7 for sessions and caching
5. **Web Server**: Nginx reverse proxy with SSL
6. **Containerization**: Docker Compose orchestration

## Operational Procedures

### Daily Operations

#### System Health Checks
```bash
# Check all services status
docker-compose ps

# Check system resources
htop
df -h
free -h

# Check application logs
docker-compose logs -f --tail=100

# Check SSL certificate status
curl -I https://nexus.gonxt.tech
```

#### Performance Monitoring
```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s https://nexus.gonxt.tech

# Monitor database performance
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;"

# Check Redis performance
docker-compose exec redis redis-cli info stats
```

### Weekly Operations

#### Log Review
```bash
# Review error logs
grep -i error /opt/solarnexus/logs/*.log | tail -100

# Review access patterns
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -20

# Check for security issues
grep -i "failed\|denied\|blocked" /var/log/nginx/error.log
```

#### Database Maintenance
```bash
# Database statistics update
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "ANALYZE;"

# Check database size
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "
SELECT pg_size_pretty(pg_database_size('solarnexus'));"

# Vacuum database (if needed)
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "VACUUM ANALYZE;"
```

### Monthly Operations

#### Security Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose pull
docker-compose up -d

# Review SSL certificate expiry
certbot certificates
```

#### Performance Review
```bash
# Generate performance report
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables 
ORDER BY n_tup_ins + n_tup_upd + n_tup_del DESC;"
```

## Maintenance Procedures

### Application Updates

#### Code Deployment
```bash
# 1. Backup current version
cd /opt/solarnexus
tar -czf backup-$(date +%Y%m%d).tar.gz . --exclude=node_modules --exclude=.git

# 2. Pull latest changes
git pull origin main

# 3. Install dependencies (if package.json changed)
npm install
cd solarnexus-backend && npm install && cd ..

# 4. Build applications
npm run build
cd solarnexus-backend && npm run build && cd ..

# 5. Restart services
docker-compose restart

# 6. Verify deployment
curl -f https://nexus.gonxt.tech/health
```

#### Database Migrations
```bash
# Run database migrations
cd /opt/solarnexus/solarnexus-backend
npx prisma migrate deploy

# Verify migration status
npx prisma migrate status
```

### SSL Certificate Renewal
```bash
# Automatic renewal (runs via cron)
certbot renew --nginx --quiet

# Manual renewal (if needed)
certbot renew --nginx --force-renewal

# Test renewal process
certbot renew --nginx --dry-run
```

### Backup Procedures

#### Automated Backups
The system includes automated backup scripts that run daily:

```bash
# Database backup (daily at 2 AM)
0 2 * * * /opt/solarnexus/scripts/backup-database.sh

# File backup (daily at 3 AM)
0 3 * * * /opt/solarnexus/scripts/backup-files.sh

# Cleanup old backups (weekly)
0 4 * * 0 /opt/solarnexus/scripts/cleanup-backups.sh
```

#### Manual Backup
```bash
# Create manual backup
cd /opt/solarnexus
./scripts/manual-backup.sh

# Backup location
ls -la /opt/backups/solarnexus/
```

#### Backup Restoration
```bash
# Restore database from backup
docker-compose exec postgres psql -U solarnexus -d solarnexus < /opt/backups/solarnexus/db_20240115.sql

# Restore files from backup
tar -xzf /opt/backups/solarnexus/files_20240115.tar.gz -C /opt/solarnexus/

# Restart services after restoration
docker-compose restart
```

## Troubleshooting Guide

### Common Issues

#### Application Won't Start
```bash
# Check Docker services
docker-compose ps

# Check logs for errors
docker-compose logs backend
docker-compose logs postgres
docker-compose logs redis

# Common fixes
docker-compose down
docker-compose up -d

# If database issues
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "SELECT 1;"
```

#### High Memory Usage
```bash
# Check memory usage
free -h
docker stats

# Restart services if needed
docker-compose restart

# Check for memory leaks in logs
grep -i "memory\|heap" /opt/solarnexus/logs/*.log
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
docker-compose exec postgres pg_isready -U solarnexus

# Check connection limits
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "
SELECT count(*) as connections, state 
FROM pg_stat_activity 
GROUP BY state;"

# Restart database if needed
docker-compose restart postgres
```

#### SSL Certificate Issues
```bash
# Check certificate status
openssl x509 -in /etc/letsencrypt/live/nexus.gonxt.tech/cert.pem -text -noout

# Renew certificate
certbot renew --nginx --force-renewal

# Check Nginx configuration
nginx -t
systemctl reload nginx
```

### Performance Issues

#### Slow Response Times
```bash
# Check system load
uptime
iostat 1 5

# Check database performance
docker-compose exec postgres psql -U solarnexus -d solarnexus -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC;"

# Check Redis performance
docker-compose exec redis redis-cli --latency-history
```

#### High CPU Usage
```bash
# Identify high CPU processes
top -p $(pgrep -d',' node)

# Check application logs for errors
docker-compose logs backend | grep -i error

# Restart if necessary
docker-compose restart backend
```

### Security Issues

#### Suspicious Activity
```bash
# Check access logs for unusual patterns
tail -f /var/log/nginx/access.log | grep -E "(404|403|500)"

# Check for failed login attempts
grep -i "authentication failed" /opt/solarnexus/logs/*.log

# Block suspicious IPs (if needed)
ufw deny from <suspicious-ip>
```

#### Security Audit
```bash
# Check open ports
netstat -tlnp

# Check firewall status
ufw status verbose

# Review user accounts
cat /etc/passwd | grep -E "(bash|sh)$"
```

## Monitoring and Alerting

### Health Endpoints
- **Application Health**: https://nexus.gonxt.tech/health
- **API Health**: https://nexus.gonxt.tech/api/health
- **Database Health**: Internal monitoring

### Log Locations
```bash
# Application logs
/opt/solarnexus/logs/app.log
/opt/solarnexus/logs/error.log

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs
/var/log/syslog
/var/log/auth.log

# Docker logs
docker-compose logs [service-name]
```

### Monitoring Commands
```bash
# Real-time monitoring
watch -n 5 'docker-compose ps && echo "=== RESOURCES ===" && docker stats --no-stream'

# Log monitoring
tail -f /opt/solarnexus/logs/app.log | grep -i error

# Performance monitoring
iostat -x 1
```

## Configuration Management

### Environment Variables
```bash
# Production environment file
/opt/solarnexus/.env.production

# Key variables to monitor
DATABASE_URL
REDIS_URL
JWT_SECRET
SOLAX_API_TOKEN
EMAIL_SMTP_*
```

### Configuration Files
```bash
# Docker Compose
/opt/solarnexus/docker-compose.yml

# Nginx configuration
/etc/nginx/sites-available/solarnexus

# SSL certificates
/etc/letsencrypt/live/nexus.gonxt.tech/
```

### Database Configuration
```sql
-- Key database settings to monitor
SHOW max_connections;
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW maintenance_work_mem;
```

## Security Procedures

### Access Management
```bash
# SSH key management
ls -la ~/.ssh/authorized_keys

# User account review
sudo cat /etc/passwd | grep -v nologin

# Sudo access review
sudo cat /etc/sudoers.d/*
```

### Security Hardening
```bash
# Firewall status
ufw status verbose

# Fail2ban status (if installed)
fail2ban-client status

# Check for security updates
apt list --upgradable | grep -i security
```

### Incident Response
1. **Immediate Actions**
   - Isolate affected systems
   - Document the incident
   - Notify stakeholders

2. **Investigation**
   - Review logs for indicators
   - Check system integrity
   - Identify root cause

3. **Recovery**
   - Apply fixes or patches
   - Restore from backups if needed
   - Verify system integrity

4. **Post-Incident**
   - Update security measures
   - Document lessons learned
   - Update procedures

## Contact Information

### Technical Contacts

#### Primary Support
- **System Administrator**: [Name] - [Email] - [Phone]
- **Database Administrator**: [Name] - [Email] - [Phone]
- **Security Officer**: [Name] - [Email] - [Phone]

#### Development Team
- **Lead Developer**: [Name] - [Email] - [Phone]
- **DevOps Engineer**: [Name] - [Email] - [Phone]
- **QA Engineer**: [Name] - [Email] - [Phone]

#### Business Contacts
- **Product Owner**: [Name] - [Email] - [Phone]
- **Project Manager**: [Name] - [Email] - [Phone]
- **Business Analyst**: [Name] - [Email] - [Phone]

### Emergency Contacts
- **24/7 Support Hotline**: [Phone Number]
- **Emergency Email**: emergency@solarnexus.com
- **Escalation Manager**: [Name] - [Phone]

### Vendor Contacts
- **AWS Support**: [Account Details]
- **Domain Registrar**: [Contact Information]
- **SSL Certificate Provider**: Let's Encrypt (Automated)
- **Email Service Provider**: [Contact Information]

## Service Level Agreements

### Availability Targets
- **System Uptime**: 99.9% (8.76 hours downtime per year)
- **Planned Maintenance**: Maximum 4 hours per month
- **Emergency Response**: Within 1 hour
- **Issue Resolution**: Within 24 hours for critical issues

### Performance Targets
- **Page Load Time**: < 2 seconds
- **API Response Time**: < 500ms
- **Database Query Time**: < 200ms
- **SSL Certificate Renewal**: Automated, 30 days before expiry

### Backup and Recovery
- **Backup Frequency**: Daily automated backups
- **Backup Retention**: 30 days local, 90 days offsite
- **Recovery Time Objective (RTO)**: 4 hours
- **Recovery Point Objective (RPO)**: 24 hours

## Change Management

### Change Request Process
1. **Request Submission**: Submit change request with details
2. **Impact Assessment**: Evaluate risks and dependencies
3. **Approval**: Get approval from stakeholders
4. **Implementation**: Execute change during maintenance window
5. **Verification**: Test and verify change success
6. **Documentation**: Update documentation and procedures

### Maintenance Windows
- **Scheduled Maintenance**: First Sunday of each month, 2-6 AM UTC
- **Emergency Maintenance**: As needed with 2-hour notice
- **Notification**: Email notifications to stakeholders

### Rollback Procedures
```bash
# Quick rollback using Docker
docker-compose down
docker-compose up -d --scale backend=0
# Deploy previous version
docker-compose up -d

# Database rollback (if needed)
# Restore from backup taken before change
```

## Knowledge Transfer

### Key System Knowledge
1. **Architecture Understanding**: Multi-tier containerized application
2. **Data Flow**: Solar data ingestion → Processing → Analytics → Visualization
3. **Integration Points**: SolaX API, Weather APIs, Email services
4. **Security Model**: JWT authentication, role-based authorization
5. **Scaling Strategy**: Horizontal scaling with load balancing

### Critical Procedures
1. **Deployment Process**: Git → Build → Test → Deploy → Verify
2. **Backup Strategy**: Automated daily backups with 30-day retention
3. **Monitoring Approach**: Health checks, log analysis, performance metrics
4. **Security Practices**: Regular updates, access control, incident response

### Documentation Locations
- **Technical Docs**: `/opt/solarnexus/docs/`
- **Operational Procedures**: This document
- **API Documentation**: `/opt/solarnexus/docs/api/`
- **Deployment Guide**: `/opt/solarnexus/DEPLOYMENT.md`

## Training and Certification

### Required Skills
- **Linux System Administration**: Ubuntu/Debian management
- **Docker and Containerization**: Docker Compose, container management
- **Database Administration**: PostgreSQL administration and tuning
- **Web Server Management**: Nginx configuration and SSL management
- **Application Monitoring**: Log analysis and performance monitoring

### Recommended Training
- **Docker Certified Associate**: Container orchestration
- **PostgreSQL Administration**: Database management
- **AWS Solutions Architect**: Cloud infrastructure
- **Security+**: Information security practices

## Appendices

### Appendix A: Server Specifications
```
Server: AWS EC2 Instance
IP: 13.245.249.110
Domain: nexus.gonxt.tech
OS: Ubuntu 22.04 LTS
CPU: 4 vCPUs
RAM: 8GB
Storage: 50GB SSD
Network: 1Gbps
```

### Appendix B: Port Configuration
```
22: SSH
80: HTTP (redirects to HTTPS)
443: HTTPS
3000: Node.js API (internal)
5432: PostgreSQL (internal)
6379: Redis (internal)
```

### Appendix C: Backup Schedule
```
Daily 2:00 AM: Database backup
Daily 3:00 AM: File system backup
Weekly Sunday 4:00 AM: Cleanup old backups
Monthly 1st Sunday: Full system backup
```

### Appendix D: Monitoring Checklist
```
□ System resources (CPU, Memory, Disk)
□ Application health endpoints
□ Database connectivity and performance
□ SSL certificate expiry
□ Backup completion status
□ Log file sizes and rotation
□ Security alerts and access patterns
□ External API connectivity
```

---

*This handover documentation should be reviewed and updated quarterly or after any major system changes. Last updated: January 15, 2024*