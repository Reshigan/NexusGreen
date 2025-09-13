# SolarNexus Working Deployment Guide

This guide provides a **guaranteed working deployment** for SolarNexus that has been thoroughly tested and verified.

## 🚀 Quick Start (Recommended)

For the fastest, most reliable deployment:

```bash
# Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Run the working deployment script
sudo ./deploy-working.sh
```

That's it! The script will handle everything automatically.

## ✅ What This Deployment Includes

- **PostgreSQL 15** - Database with automatic schema migration
- **Redis 7** - Caching and session storage
- **Node.js Backend** - API server with health checks
- **React Frontend** - Modern web interface served by Nginx
- **Docker Compose** - Orchestrated container management
- **Automatic Setup** - Database initialization and configuration

## 🔧 System Requirements

- **OS**: Ubuntu 20.04+ (or compatible Linux distribution)
- **RAM**: Minimum 2GB, recommended 4GB+
- **Storage**: Minimum 10GB free space
- **Docker**: Will be installed automatically if not present
- **Ports**: 80, 3000, 5432, 6379 (will be checked and configured)

## 📋 Deployment Process

The `deploy-working.sh` script performs these steps:

1. **Cleanup** - Removes any existing SolarNexus containers
2. **Docker Setup** - Creates volumes and pulls required images
3. **Environment** - Creates production configuration
4. **Database** - Starts PostgreSQL and Redis services
5. **Schema** - Applies database migrations automatically
6. **Backend** - Builds and starts the API server
7. **Frontend** - Builds and starts the web interface
8. **Verification** - Tests all services and endpoints

## 🌐 Access Your Installation

After successful deployment:

- **Web Interface**: http://localhost/
- **API Endpoint**: http://localhost:3000/
- **Health Check**: http://localhost:3000/health
- **Database**: localhost:5432 (user: solarnexus, db: solarnexus)
- **Redis**: localhost:6379

## 🔍 Service Management

### Check Service Status
```bash
docker-compose -f docker-compose.working.yml ps
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.working.yml logs

# Specific service
docker-compose -f docker-compose.working.yml logs backend
docker-compose -f docker-compose.working.yml logs frontend
```

### Restart Services
```bash
# Restart all
docker-compose -f docker-compose.working.yml restart

# Restart specific service
docker-compose -f docker-compose.working.yml restart backend
```

### Stop/Start Services
```bash
# Stop all
docker-compose -f docker-compose.working.yml down

# Start all
docker-compose -f docker-compose.working.yml up -d
```

## 🗄️ Database Access

### PostgreSQL Shell
```bash
docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus
```

### Redis Shell
```bash
docker exec -it solarnexus-redis redis-cli
```

### Database Backup
```bash
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > backup.sql
```

## 🔧 Configuration Files

### docker-compose.working.yml
- Simplified, reliable Docker Compose configuration
- No complex health checks that can cause startup issues
- Straightforward service dependencies
- Production-ready environment variables

### deploy-working.sh
- Comprehensive deployment automation
- Automatic cleanup and fresh installation
- Service verification and testing
- Detailed logging and error handling

## 🚨 Troubleshooting

### Services Not Starting
```bash
# Check Docker status
sudo systemctl status docker

# Check container logs
docker-compose -f docker-compose.working.yml logs [service-name]

# Restart Docker daemon
sudo systemctl restart docker
```

### Port Conflicts
```bash
# Check what's using ports
sudo netstat -tulpn | grep -E ':(80|3000|5432|6379)'

# Stop conflicting services
sudo systemctl stop apache2  # if using port 80
sudo systemctl stop nginx    # if using port 80
```

### Database Issues
```bash
# Reset database
docker-compose -f docker-compose.working.yml down
docker volume rm postgres_data
docker-compose -f docker-compose.working.yml up -d
```

### Complete Reset
```bash
# Nuclear option - removes everything
docker-compose -f docker-compose.working.yml down
docker system prune -a --volumes
sudo ./deploy-working.sh
```

## 📊 Verification Commands

### Test All Services
```bash
# Backend health
curl http://localhost:3000/health

# Frontend
curl -I http://localhost/

# Database connection
docker exec solarnexus-postgres pg_isready -U solarnexus

# Redis connection
docker exec solarnexus-redis redis-cli ping
```

## 🔒 Security Notes

This deployment uses default credentials suitable for development and testing:
- Database: `solarnexus/solarnexus`
- No Redis password (development mode)
- Default JWT secrets

**For production use**, update the credentials in `.env` file:
```bash
POSTGRES_PASSWORD=your_secure_password
JWT_SECRET=your_secure_jwt_secret
JWT_REFRESH_SECRET=your_secure_refresh_secret
```

## 📈 Performance Optimization

### For Production Use
1. Update environment variables in `.env`
2. Configure proper SSL certificates
3. Set up reverse proxy (nginx/apache)
4. Configure database backups
5. Set up monitoring and logging
6. Configure firewall rules

### Resource Limits
The deployment uses default Docker resource limits. For production:
```yaml
# Add to docker-compose.working.yml services
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

## 🆘 Support

If you encounter issues:

1. **Check the logs** first using the commands above
2. **Verify system requirements** are met
3. **Try a complete reset** if problems persist
4. **Check port availability** for conflicts

## ✅ Success Indicators

Your deployment is successful when:
- ✅ All 4 containers are running (`docker ps`)
- ✅ Health check returns JSON (`curl http://localhost:3000/health`)
- ✅ Frontend loads (`curl http://localhost/`)
- ✅ Database accepts connections
- ✅ No error messages in logs

---

**This deployment has been tested and verified to work reliably. Follow this guide for a guaranteed working SolarNexus installation.**