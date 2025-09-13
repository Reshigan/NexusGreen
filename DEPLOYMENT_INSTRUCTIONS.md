# SolarNexus Deployment Instructions

## 🚀 Quick Start - Fixed Clean Install

The **clean-install.sh** script has been completely fixed to resolve Docker container conflicts and install in your current directory.

### ✅ What's Fixed

- **Container Conflicts**: Properly stops and removes existing containers before creating new ones
- **Directory Location**: Installs in `$(pwd)/SolarNexus` instead of hardcoded `/root/SolarNexus`
- **Docker Compose**: Uses docker-compose for reliable service management instead of manual docker run commands
- **Better Error Handling**: Comprehensive cleanup and error detection
- **Service Testing**: Proper health checks for all services

### 📋 Prerequisites

- Ubuntu/Debian Linux system
- Docker and Docker Compose installed
- Root/sudo access
- Internet connection

### 🛠️ Installation Steps

1. **Download the script**:
   ```bash
   curl -o clean-install.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/clean-install.sh
   chmod +x clean-install.sh
   ```

2. **Run the installation**:
   ```bash
   sudo ./clean-install.sh
   ```

3. **Follow the prompts**:
   - Type `YES` when prompted to confirm installation
   - Wait for the installation to complete (5-10 minutes)

### 📍 Installation Location

The script will create a `SolarNexus` directory in your current working directory:
```
/your/current/directory/
└── SolarNexus/
    ├── docker-compose.yml
    ├── .env
    ├── solarnexus-backend/
    ├── src/
    └── ... (all project files)
```

### 🎯 What Gets Installed

- **PostgreSQL Database** (port 5432)
- **Redis Cache** (port 6379)
- **Backend API** (port 3000)
- **Frontend React App** (served via Nginx on port 80)
- **Nginx Reverse Proxy** (port 80)

### 🔍 Verification

After installation, you should see:
```
✅ SolarNexus is ready for use!
🌟 Access your solar portal at: http://localhost/
🔧 API endpoint available at: http://localhost:3000/
```

### 🌐 Access Points

- **Frontend**: http://your-server-ip/
- **Backend API**: http://your-server-ip:3000/
- **Health Check**: http://your-server-ip/health
- **API Health**: http://your-server-ip:3000/health

## 🔧 Service Management

### Basic Commands

```bash
# Navigate to installation directory
cd SolarNexus

# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]
# Examples:
docker-compose logs backend
docker-compose logs frontend
docker-compose logs nginx

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build
```

### Individual Service Management

```bash
# Check specific service logs
docker-compose logs -f backend    # Follow backend logs
docker-compose logs -f frontend   # Follow frontend logs
docker-compose logs -f nginx      # Follow nginx logs

# Restart specific service
docker-compose restart backend
docker-compose restart frontend
docker-compose restart nginx
```

## 🗄️ Database Access

### PostgreSQL

```bash
# Connect to database
docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus

# Run SQL commands
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "SELECT COUNT(*) FROM users;"

# Backup database
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > backup.sql

# Restore database
docker exec -i solarnexus-postgres psql -U solarnexus -d solarnexus < backup.sql
```

### Redis

```bash
# Connect to Redis
docker exec -it solarnexus-redis redis-cli

# Check Redis status
docker exec solarnexus-redis redis-cli ping
```

## 🔍 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :80
   sudo netstat -tulpn | grep :3000
   
   # Stop conflicting services
   sudo systemctl stop apache2  # If Apache is running
   sudo systemctl stop nginx    # If system nginx is running
   ```

2. **Container Conflicts**
   ```bash
   # The script handles this automatically, but if needed:
   docker ps -a | grep solarnexus
   docker stop $(docker ps -q --filter "name=solarnexus")
   docker rm $(docker ps -aq --filter "name=solarnexus")
   ```

3. **Services Not Starting**
   ```bash
   # Check logs for errors
   docker-compose logs backend
   docker-compose logs frontend
   docker-compose logs nginx
   
   # Check system resources
   df -h          # Disk space
   free -h        # Memory
   docker system df  # Docker space usage
   ```

4. **Database Connection Issues**
   ```bash
   # Test database connectivity
   docker exec solarnexus-postgres pg_isready -U solarnexus
   
   # Check database logs
   docker-compose logs postgres
   ```

### Health Checks

```bash
# Test all endpoints
curl http://localhost/health          # Nginx health
curl http://localhost:3000/health     # Backend health
curl -I http://localhost/             # Frontend availability

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 📁 Important Files

- **Environment**: `SolarNexus/.env`
- **Docker Compose**: `SolarNexus/docker-compose.yml`
- **Backend Config**: `SolarNexus/solarnexus-backend/`
- **Frontend Source**: `SolarNexus/src/`

## 🔄 Updates and Maintenance

### Updating SolarNexus

```bash
cd SolarNexus

# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Backup and Restore

```bash
# Backup database
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > solarnexus-backup-$(date +%Y%m%d).sql

# Backup volumes
docker run --rm -v postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-data-backup.tar.gz -C /data .
docker run --rm -v redis_data:/data -v $(pwd):/backup alpine tar czf /backup/redis-data-backup.tar.gz -C /data .
```

## 🆘 Support

If you encounter issues:

1. Check the logs: `docker-compose logs [service]`
2. Verify all services are running: `docker-compose ps`
3. Test connectivity: `curl http://localhost/health`
4. Check system resources: `df -h && free -h`

## 🎉 Success Indicators

Your installation is successful when you see:

- ✅ All containers running: `docker ps` shows 5 solarnexus containers
- ✅ Frontend accessible: `curl http://localhost/` returns 200
- ✅ Backend healthy: `curl http://localhost:3000/health` returns JSON
- ✅ Database connected: Backend logs show successful database connection
- ✅ No error messages in: `docker-compose logs`

---

**🌟 Congratulations! SolarNexus is now running successfully!**