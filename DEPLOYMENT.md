# SolarNexus Final Production Deployment Guide

## 🚀 Complete, Error-Free Deployment Solution

This guide provides a complete, production-ready deployment solution for SolarNexus with zero configuration required. The deployment has been thoroughly tested and includes all necessary fixes for common Docker and nginx issues.

## 📋 Quick Start

### Prerequisites

- **Operating System**: Ubuntu 20.04+ or similar Linux distribution
- **Docker**: Version 20.10+ with Docker Compose
- **System Requirements**: 
  - Minimum 4GB RAM
  - 5GB free disk space
  - Root/sudo access

### One-Command Deployment

```bash
# Download and run the final deployment script
curl -o deploy-final.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy-final.sh
chmod +x deploy-final.sh
sudo ./deploy-final.sh
```

That's it! The script will handle everything automatically.

## 📁 Deployment Files Overview

### Core Files

- **`deploy-final.sh`** - Complete deployment script with error handling
- **`docker-compose.final.yml`** - Production Docker Compose configuration
- **`Dockerfile.final`** - Optimized frontend Dockerfile with nginx fixes
- **`nginx.conf`** - Production nginx configuration with API proxy

### Generated Files

- **`.env`** - Environment configuration with secure passwords
- **`status.sh`** - Check service status
- **`start.sh`** - Start all services
- **`stop.sh`** - Stop all services
- **`logs.sh`** - View service logs

## 🔧 Manual Deployment Steps

If you prefer to deploy manually:

### 1. Clone Repository

```bash
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus
```

### 2. Create Environment Configuration

```bash
# Copy example environment file
cp .env.example .env

# Edit with your settings (optional - secure defaults will be generated)
nano .env
```

### 3. Create Required Directories

```bash
mkdir -p data/{postgres,redis} uploads logs backups database/init
chmod 755 data/{postgres,redis} uploads logs backups database/init
```

### 4. Start Services

```bash
# Start database services first
docker-compose -f docker-compose.final.yml up -d postgres redis

# Wait for databases to be ready (about 30 seconds)
sleep 30

# Start backend and frontend
docker-compose -f docker-compose.final.yml up -d --build backend frontend
```

### 5. Verify Deployment

```bash
# Check service status
docker-compose -f docker-compose.final.yml ps

# Test endpoints
curl http://localhost/health        # Frontend health check
curl http://localhost:3000/health   # Backend health check
```

## 🌐 Service Access

After successful deployment:

- **SolarNexus Portal**: http://localhost/
- **Backend API**: http://localhost:3000/
- **Health Checks**: http://localhost/health

## 🔐 Security Features

### Built-in Security

- **Non-root containers** - All services run as non-root users
- **Secure passwords** - Auto-generated strong passwords
- **Security headers** - Comprehensive HTTP security headers
- **Network isolation** - Services communicate via private network
- **File permissions** - Proper file and directory permissions

### Environment Variables

Key security settings in `.env`:

```bash
# Database Security
POSTGRES_PASSWORD=auto_generated_secure_password
REDIS_PASSWORD=auto_generated_secure_password

# JWT Security
JWT_SECRET=auto_generated_jwt_secret
JWT_REFRESH_SECRET=auto_generated_refresh_secret

# API Security
API_RATE_LIMIT=100
CORS_ORIGIN=http://localhost
```

## 📊 Service Management

### Status Monitoring

```bash
# Quick status check
./status.sh

# Detailed service status
docker-compose -f docker-compose.final.yml ps

# Health check all services
curl http://localhost/health && echo " - Frontend OK"
curl http://localhost:3000/health && echo " - Backend OK"
```

### Log Management

```bash
# View all logs
docker-compose -f docker-compose.final.yml logs -f

# View specific service logs
./logs.sh frontend
./logs.sh backend
./logs.sh postgres
./logs.sh redis

# View recent logs only
docker-compose -f docker-compose.final.yml logs --tail=100 -f
```

### Service Control

```bash
# Start all services
./start.sh

# Stop all services
./stop.sh

# Restart specific service
docker-compose -f docker-compose.final.yml restart backend

# Rebuild and restart service
docker-compose -f docker-compose.final.yml up -d --build frontend
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use

```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :3000

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
sudo systemctl stop nginx
```

#### 2. Docker Permission Issues

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker-compose -f docker-compose.final.yml up -d
```

#### 3. Database Connection Issues

```bash
# Check database status
docker-compose -f docker-compose.final.yml ps postgres

# View database logs
docker-compose -f docker-compose.final.yml logs postgres

# Restart database
docker-compose -f docker-compose.final.yml restart postgres
```

#### 4. Frontend Not Loading

```bash
# Check nginx configuration
docker exec solarnexus-frontend nginx -t

# View frontend logs
docker-compose -f docker-compose.final.yml logs frontend

# Rebuild frontend
docker-compose -f docker-compose.final.yml up -d --build frontend
```

### Health Check Commands

```bash
# Test all endpoints
echo "Testing Frontend..." && curl -f http://localhost/health
echo "Testing Backend..." && curl -f http://localhost:3000/health
echo "Testing Database..." && docker exec solarnexus-postgres pg_isready -U solarnexus
echo "Testing Redis..." && docker exec solarnexus-redis redis-cli ping
```

## 📈 Performance Optimization

### Production Optimizations Included

- **Gzip compression** - Reduces bandwidth usage
- **Static asset caching** - 1-year cache for static files
- **Multi-stage builds** - Smaller Docker images
- **Health checks** - Automatic service monitoring
- **Resource limits** - Prevents resource exhaustion

### Monitoring Setup

```bash
# View resource usage
docker stats

# Monitor disk usage
df -h
du -sh data/

# Check memory usage
free -h
```

## 🔄 Updates and Maintenance

### Updating SolarNexus

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose -f docker-compose.final.yml up -d --build

# Clean up old images
docker image prune -f
```

### Backup and Restore

```bash
# Backup database
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > backup_$(date +%Y%m%d).sql

# Backup uploaded files
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/

# Restore database
docker exec -i solarnexus-postgres psql -U solarnexus solarnexus < backup_20240101.sql
```

## 🆘 Support and Issues

### Getting Help

1. **Check logs first**: Use `./logs.sh [service]` to identify issues
2. **Verify system requirements**: Ensure Docker and system requirements are met
3. **Review this guide**: Most common issues are covered in troubleshooting
4. **GitHub Issues**: Report bugs at https://github.com/Reshigan/SolarNexus/issues

### Reporting Issues

When reporting issues, please include:

- Operating system and version
- Docker and Docker Compose versions
- Complete error messages from logs
- Steps to reproduce the issue
- Output of `docker-compose -f docker-compose.final.yml ps`

## 🎯 Production Checklist

Before going live:

- [ ] Change default passwords in `.env`
- [ ] Configure proper domain names
- [ ] Set up SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Configure automated backups
- [ ] Review and adjust resource limits
- [ ] Test disaster recovery procedures

## 📝 Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | auto-generated | PostgreSQL password |
| `REDIS_PASSWORD` | auto-generated | Redis password |
| `JWT_SECRET` | auto-generated | JWT signing secret |
| `FRONTEND_PORT` | 80 | Frontend port |
| `BACKEND_PORT` | 3000 | Backend port |
| `LOG_LEVEL` | info | Logging level |
| `API_RATE_LIMIT` | 100 | API rate limit |

### Docker Compose Services

| Service | Port | Description |
|---------|------|-------------|
| `postgres` | 5432 | PostgreSQL database |
| `redis` | 6379 | Redis cache |
| `backend` | 3000 | Node.js API server |
| `frontend` | 80 | React app with nginx |

## 🏆 Success Indicators

Your deployment is successful when:

- ✅ All services show "healthy" status
- ✅ Frontend loads at http://localhost/
- ✅ Health checks return "healthy"
- ✅ No error messages in logs
- ✅ Database connections work
- ✅ API endpoints respond correctly

---

**🌟 Congratulations! You now have a fully functional SolarNexus deployment!**

For additional support, visit: https://github.com/Reshigan/SolarNexus