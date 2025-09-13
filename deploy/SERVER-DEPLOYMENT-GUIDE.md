# 🚀 SolarNexus Server Deployment Guide

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ or CentOS 8+
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: Minimum 20GB free space
- **CPU**: 2+ cores recommended

### Required Software
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Git**: Latest version
- **curl**: For health checks

## 🛠️ Installation Methods

### Method 1: One-Command Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-clean-install.sh | sudo bash
```

### Method 2: Manual Installation

1. **Download the installation script:**
   ```bash
   wget https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-clean-install.sh
   chmod +x server-clean-install.sh
   ```

2. **Run the installation:**
   ```bash
   sudo ./server-clean-install.sh
   ```

## 🔧 Configuration

### Environment Variables

1. **Copy the environment template:**
   ```bash
   cd /opt/solarnexus/deploy
   cp .env.server.template .env
   ```

2. **Edit the configuration:**
   ```bash
   nano .env
   ```

3. **Update these critical values:**
   ```bash
   # Database
   POSTGRES_PASSWORD=your_secure_database_password_here
   
   # JWT Secrets
   JWT_SECRET=your_super_secure_jwt_secret_key_here_minimum_32_characters
   JWT_REFRESH_SECRET=your_super_secure_refresh_secret_key_here_minimum_32_characters
   
   # SolaX Database
   SOLAX_DB_HOST=your_solax_db_host
   SOLAX_DB_USER=your_solax_db_user
   SOLAX_DB_PASSWORD=your_solax_db_password
   
   # Domain Configuration
   FRONTEND_URL=https://your-domain.com
   DOMAIN=your-domain.com
   SERVER_IP=your_server_ip
   ```

### SSL Configuration (Optional)

If you have SSL certificates:

1. **Place certificates in the correct location:**
   ```bash
   sudo mkdir -p /etc/nginx/ssl
   sudo cp your-domain.com.crt /etc/nginx/ssl/
   sudo cp your-domain.com.key /etc/nginx/ssl/
   sudo chmod 600 /etc/nginx/ssl/*
   ```

2. **Update environment variables:**
   ```bash
   SSL_CERT_PATH=/etc/nginx/ssl/your-domain.com.crt
   SSL_KEY_PATH=/etc/nginx/ssl/your-domain.com.key
   ```

## 🚀 Starting Services

### Start All Services
```bash
cd /opt/solarnexus/deploy
docker compose -f docker-compose.production.yml up -d
```

### Check Service Status
```bash
docker compose -f docker-compose.production.yml ps
```

### View Logs
```bash
# All services
docker compose -f docker-compose.production.yml logs

# Specific service
docker compose -f docker-compose.production.yml logs frontend
docker compose -f docker-compose.production.yml logs backend
```

## 🔄 Updates

### Automatic Update
```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-update.sh | sudo bash
```

### Manual Update
```bash
cd /opt/solarnexus
git pull origin main
cd deploy
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d --build
```

## 🧪 Health Checks

### Frontend Health Check
```bash
curl -I http://localhost:80
# Expected: HTTP/1.1 200 OK
```

### Backend Health Check
```bash
curl -I http://localhost:3000/health
# Expected: HTTP/1.1 200 OK
```

### Database Health Check
```bash
docker exec solarnexus-postgres pg_isready -U solarnexus
# Expected: accepting connections
```

## 🔧 Management Commands

### Stop Services
```bash
cd /opt/solarnexus/deploy
docker compose -f docker-compose.production.yml down
```

### Restart Services
```bash
cd /opt/solarnexus/deploy
docker compose -f docker-compose.production.yml restart
```

### View Service Status
```bash
cd /opt/solarnexus/deploy
docker compose -f docker-compose.production.yml ps
```

### Access Database
```bash
docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus
```

### Access Redis
```bash
docker exec -it solarnexus-redis redis-cli
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :3000

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
```

#### 2. Database Connection Issues
```bash
# Check database logs
docker compose -f docker-compose.production.yml logs postgres

# Restart database
docker compose -f docker-compose.production.yml restart postgres
```

#### 3. Frontend Not Loading
```bash
# Check frontend logs
docker compose -f docker-compose.production.yml logs frontend

# Rebuild frontend
docker compose -f docker-compose.production.yml up -d --build frontend
```

#### 4. Backend API Errors
```bash
# Check backend logs
docker compose -f docker-compose.production.yml logs backend

# Check environment variables
docker exec solarnexus-backend env | grep -E "(DATABASE_URL|JWT_SECRET)"
```

### Log Locations
- **Application Logs**: `docker compose logs [service]`
- **System Logs**: `/var/log/syslog`
- **Docker Logs**: `/var/lib/docker/containers/`

## 🔒 Security Considerations

### Firewall Configuration
```bash
# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block direct database access from outside
sudo ufw deny 5432/tcp
sudo ufw deny 6379/tcp
```

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update SolarNexus
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-update.sh | sudo bash
```

### Backup Strategy
```bash
# Database backup
docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > backup_$(date +%Y%m%d).sql

# Full backup
tar -czf solarnexus_backup_$(date +%Y%m%d).tar.gz /opt/solarnexus
```

## 📊 Monitoring

### Service Status Dashboard
```bash
# Create a simple status check script
cat > /opt/solarnexus/status.sh << 'EOF'
#!/bin/bash
echo "=== SolarNexus Status ==="
echo "Frontend: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:80)"
echo "Backend: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)"
echo "Database: $(docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1 && echo "OK" || echo "ERROR")"
echo "Redis: $(docker exec solarnexus-redis redis-cli ping 2>/dev/null || echo "ERROR")"
echo "========================="
EOF
chmod +x /opt/solarnexus/status.sh
```

### Automated Health Checks
```bash
# Add to crontab for regular health checks
echo "*/5 * * * * /opt/solarnexus/status.sh >> /var/log/solarnexus-health.log" | sudo crontab -
```

## 🆘 Support

### Getting Help
1. **Check Logs**: Always start with service logs
2. **GitHub Issues**: Report bugs at https://github.com/Reshigan/SolarNexus/issues
3. **Documentation**: Refer to this guide and README.md

### Useful Commands Reference
```bash
# Quick status check
cd /opt/solarnexus && ./status.sh

# Full service restart
cd /opt/solarnexus/deploy && docker compose -f docker-compose.production.yml restart

# Clean reinstall
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-clean-install.sh | sudo bash

# Update only
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-update.sh | sudo bash
```

---

## 🎉 Success!

Your SolarNexus application should now be running at:
- **Web Interface**: http://your-server-ip:80
- **API Endpoints**: http://your-server-ip:3000
- **Health Check**: http://your-server-ip:3000/health

For production use, configure your domain and SSL certificates for secure HTTPS access.