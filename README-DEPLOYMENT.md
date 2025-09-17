# NexusGreen Single Server Deployment Guide

This guide provides step-by-step instructions for deploying NexusGreen on a single server using Docker Compose.

## 🏗️ Architecture Overview

The simplified single-server architecture includes:

- **Frontend**: React application served by nginx with API proxying
- **Backend**: Node.js API server with authentication and dashboard endpoints
- **Database**: PostgreSQL with persistent data storage
- **Reverse Proxy**: nginx handles routing and serves static files

## 📋 Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- Minimum 2GB RAM, 2 CPU cores
- 20GB available disk space
- Root or sudo access
- Internet connection for downloading dependencies

## 🚀 Quick Deployment

### Option 1: Automated Setup (Recommended)

1. **Prepare the server:**
   ```bash
   sudo ./setup-server.sh
   ```

2. **Deploy NexusGreen:**
   ```bash
   ./deploy.sh
   ```

3. **Access the application:**
   - Frontend: http://your-server-ip
   - Backend API: http://your-server-ip:3001

### Option 2: Manual Setup

1. **Install Docker and Docker Compose:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Clone and deploy:**
   ```bash
   git clone <repository-url>
   cd NexusGreen
   sudo docker-compose up --build -d
   ```

## 🔧 Configuration

### Environment Variables

The deployment uses the following default configuration:

```yaml
# Database
POSTGRES_DB: nexusgreen
POSTGRES_USER: nexusgreen
POSTGRES_PASSWORD: nexusgreen123

# Backend
NODE_ENV: production
DB_HOST: postgres
DB_PORT: 5432
```

### Port Configuration

- **80**: Frontend (nginx)
- **3001**: Backend API
- **5432**: PostgreSQL (internal)

### Custom Configuration

To customize the deployment, edit `docker-compose.yml`:

```yaml
services:
  postgres:
    environment:
      POSTGRES_PASSWORD: your-secure-password
  
  backend:
    environment:
      - DB_PASSWORD=your-secure-password
```

## 👤 Default User Accounts

The system comes with pre-configured test accounts:

**Administrator:**
- Username: `admin`
- Password: `admin123`
- Email: `admin@nexusgreen.com`

**Standard User:**
- Username: `user`
- Password: `user123`
- Email: `user@nexusgreen.com`

## 🔍 Service Management

### View Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f frontend
docker-compose logs -f backend
docker-compose logs -f postgres
```

### Restart Services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart backend
```

### Stop Services
```bash
docker-compose down
```

### Update Deployment
```bash
docker-compose pull
docker-compose up -d
```

## 🔒 Security Considerations

### Production Deployment

For production use, consider these security enhancements:

1. **Change default passwords:**
   ```bash
   # Edit docker-compose.yml
   POSTGRES_PASSWORD: your-secure-password
   ```

2. **Enable HTTPS:**
   - Use a reverse proxy like nginx or Traefik
   - Obtain SSL certificates (Let's Encrypt recommended)

3. **Firewall configuration:**
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

4. **Database security:**
   - Use strong passwords
   - Restrict database access to backend only
   - Regular backups

## 🔧 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check logs
docker-compose logs
```

**Database connection issues:**
```bash
# Check database status
docker-compose exec postgres pg_isready -U nexusgreen

# Reset database
docker-compose down -v
docker-compose up -d
```

**Frontend not loading:**
```bash
# Check nginx configuration
docker-compose exec frontend nginx -t

# Rebuild frontend
docker-compose build frontend
docker-compose up -d frontend
```

**API not responding:**
```bash
# Check backend health
curl http://localhost:3001/api/health

# Restart backend
docker-compose restart backend
```

### Health Checks

The deployment includes health checks for all services:

```bash
# Check all service health
docker-compose ps

# Manual health checks
curl http://localhost/health          # Frontend
curl http://localhost:3001/api/health # Backend
```

## 📊 Monitoring

### Resource Usage
```bash
# Container resource usage
docker stats

# Disk usage
docker system df
```

### Log Management
```bash
# Rotate logs
docker-compose logs --tail=100 > nexusgreen.log

# Clean old logs
docker system prune -f
```

## 🔄 Backup and Recovery

### Database Backup
```bash
# Create backup
docker-compose exec postgres pg_dump -U nexusgreen nexusgreen > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U nexusgreen nexusgreen < backup.sql
```

### Full System Backup
```bash
# Stop services
docker-compose down

# Backup data volumes
docker run --rm -v nexusgreen_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .

# Restart services
docker-compose up -d
```

## 🚀 Scaling Considerations

For high-traffic deployments, consider:

1. **Load balancing**: Use nginx or HAProxy
2. **Database scaling**: PostgreSQL read replicas
3. **Caching**: Redis for session storage
4. **CDN**: For static asset delivery
5. **Container orchestration**: Kubernetes for multi-server deployments

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review service logs: `docker-compose logs`
3. Verify system requirements are met
4. Check firewall and network configuration

## 📝 Version Information

- **Frontend**: React 18+ with Vite
- **Backend**: Node.js 18+ with Express
- **Database**: PostgreSQL 15
- **Proxy**: nginx (Alpine)
- **Container Runtime**: Docker 20.10+
- **Orchestration**: Docker Compose 2.0+