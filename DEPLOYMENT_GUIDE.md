# SolarNexus Production Deployment Guide

## Server Information
- **Server IP**: 13.247.192.38
- **Domain**: nexus.gonxt.tech
- **SSL Email**: reshigan@gonxt.tech
- **Platform**: AWS Single Server Deployment

## Quick Deployment

### 1. Connect to Your Server
```bash
ssh ubuntu@13.247.192.38
```

### 2. Run the Automated Deployment Script
```bash
# Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy-production.sh | bash
```

**OR** if you have the repository locally:
```bash
# Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Make the script executable and run it
chmod +x deploy-production.sh
./deploy-production.sh
```

### 3. Configure Environment Variables
After deployment, update the environment file:
```bash
cd /opt/solarnexus
sudo nano .env.production
```

**Important**: Update these values:
- `POSTGRES_PASSWORD`: Set a secure database password
- `REDIS_PASSWORD`: Set a secure Redis password
- `JWT_SECRET`: Generate with `openssl rand -base64 64`
- `JWT_REFRESH_SECRET`: Generate with `openssl rand -base64 64`
- `SESSION_SECRET`: Generate with `openssl rand -base64 32`
- `EMAIL_USER` and `EMAIL_PASS`: Your SMTP credentials

### 4. Restart Services
```bash
cd /opt/solarnexus
./restart.sh
```

## What the Deployment Script Does

### System Setup
- ✅ Updates system packages
- ✅ Installs Docker and Docker Compose
- ✅ Installs Node.js (for debugging)
- ✅ Installs Nginx (reverse proxy)
- ✅ Installs Certbot (SSL certificates)
- ✅ Configures firewall (UFW)
- ✅ Sets up fail2ban (security)

### Application Setup
- ✅ Creates application directory (`/opt/solarnexus`)
- ✅ Clones/updates repository
- ✅ Generates secure environment configuration
- ✅ Creates production Docker Compose setup
- ✅ Configures Nginx with SSL support
- ✅ Obtains Let's Encrypt SSL certificate
- ✅ Sets up automatic SSL renewal

### Management Scripts
The deployment creates these management scripts in `/opt/solarnexus`:

- **`start.sh`**: Start all services
- **`stop.sh`**: Stop all services  
- **`restart.sh`**: Restart all services
- **`update.sh`**: Pull latest code and restart
- **`logs.sh`**: View service logs
- **`status.sh`**: Check service status

## Manual Deployment Steps

If you prefer manual deployment, follow these steps:

### 1. System Prerequisites
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin

# Install Nginx
sudo apt install nginx

# Install Certbot
sudo apt install certbot python3-certbot-nginx
```

### 2. Application Setup
```bash
# Create application directory
sudo mkdir -p /opt/solarnexus
sudo chown $USER:$USER /opt/solarnexus

# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git /opt/solarnexus
cd /opt/solarnexus

# Copy environment template
cp .env.nexus.template .env.production
# Edit .env.production with your values
nano .env.production
```

### 3. Docker Services
```bash
# Build and start services
sudo docker compose -f docker-compose.production.yml --env-file .env.production build
sudo docker compose -f docker-compose.production.yml --env-file .env.production up -d
```

### 4. Nginx Configuration
```bash
# Create Nginx site configuration
sudo nano /etc/nginx/sites-available/solarnexus
# Copy the configuration from deploy-production.sh

# Enable the site
sudo ln -s /etc/nginx/sites-available/solarnexus /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### 5. SSL Certificate
```bash
# Obtain SSL certificate
sudo certbot --nginx -d nexus.gonxt.tech -d www.nexus.gonxt.tech --email reshigan@gonxt.tech --agree-tos --non-interactive

# Setup auto-renewal
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
```

## Service Architecture

### Docker Services
- **PostgreSQL**: Database (port 5432, internal only)
- **Redis**: Cache and sessions (port 6379, internal only)  
- **Backend**: Node.js API (port 3000, internal only)
- **Frontend**: React app (port 8080, internal only)

### Nginx Reverse Proxy
- **Port 80**: HTTP → HTTPS redirect
- **Port 443**: HTTPS with SSL
- **Routes**:
  - `/` → Frontend (React app)
  - `/api/` → Backend API
  - `/ws` → WebSocket connections

## Environment Configuration

### Required Environment Variables
```bash
# Database
POSTGRES_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password

# Security
JWT_SECRET=your_64_character_secret
JWT_REFRESH_SECRET=your_64_character_secret
SESSION_SECRET=your_32_character_secret

# Email (for notifications)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

### Optional Configuration
```bash
# External APIs
SOLAX_API_TOKEN=your_token
GOOGLE_ANALYTICS_ID=your_ga_id
SENTRY_DSN=your_sentry_dsn
```

## Management Commands

### Service Management
```bash
cd /opt/solarnexus

# Start services
./start.sh

# Stop services
./stop.sh

# Restart services
./restart.sh

# Update application
./update.sh

# View logs
./logs.sh

# Check status
./status.sh
```

### Manual Docker Commands
```bash
cd /opt/solarnexus

# View running containers
sudo docker compose -f docker-compose.production.yml ps

# View logs
sudo docker compose -f docker-compose.production.yml logs -f

# Restart specific service
sudo docker compose -f docker-compose.production.yml restart backend

# Rebuild and restart
sudo docker compose -f docker-compose.production.yml down
sudo docker compose -f docker-compose.production.yml build --no-cache
sudo docker compose -f docker-compose.production.yml up -d
```

## Monitoring and Maintenance

### Health Checks
- **Application**: https://nexus.gonxt.tech/health
- **API**: https://nexus.gonxt.tech/api/health
- **SSL Certificate**: `sudo certbot certificates`

### Log Files
- **Application logs**: `/opt/solarnexus/logs/`
- **Nginx logs**: `/var/log/nginx/`
- **Docker logs**: `sudo docker compose logs`

### Backup Recommendations
```bash
# Database backup
sudo docker exec solarnexus-postgres pg_dump -U solarnexus solarnexus > backup_$(date +%Y%m%d).sql

# Application files backup
tar -czf solarnexus_backup_$(date +%Y%m%d).tar.gz /opt/solarnexus
```

## Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check Docker status
sudo systemctl status docker

# Check service logs
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml logs

# Restart Docker
sudo systemctl restart docker
```

#### SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate manually
sudo certbot renew --dry-run

# Check Nginx configuration
sudo nginx -t
```

#### Database Connection Issues
```bash
# Check PostgreSQL container
sudo docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus

# Reset database password
# Update .env.production and restart services
```

### Performance Optimization

#### For High Traffic
```bash
# Increase Docker resources in docker-compose.production.yml
# Add more worker processes in Nginx
# Enable Redis caching
# Set up database connection pooling
```

## Security Considerations

### Firewall Rules
```bash
# Check current rules
sudo ufw status

# Allow only necessary ports
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Docker images
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml pull
sudo docker compose -f docker-compose.production.yml up -d
```

## Support

### Getting Help
- **Repository**: https://github.com/Reshigan/SolarNexus
- **Issues**: Create an issue on GitHub
- **Documentation**: Check the `/docs` folder

### Contact Information
- **Email**: reshigan@gonxt.tech
- **Domain**: nexus.gonxt.tech
- **Server**: 13.247.192.38

---

**Note**: This deployment guide assumes Ubuntu 20.04+ on AWS. Adjust commands as needed for other distributions or cloud providers.