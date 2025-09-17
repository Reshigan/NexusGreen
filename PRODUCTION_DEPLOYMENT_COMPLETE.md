# NexusGreen Production Deployment Guide

## 🚀 Complete Production Deployment with SSL

This guide provides step-by-step instructions for deploying the modernized NexusGreen multi-portal system to production server `13.245.181.202` with SSL configuration for `nexus.gonxt.tech`.

## 📋 Prerequisites

- SSH access to server 13.245.181.202 with provided PEM file
- Domain `nexus.gonxt.tech` pointing to server IP
- Ubuntu server with sudo privileges
- Node.js 18+ and npm installed on server

## 🏗️ System Architecture

The modernized system includes:
- ✅ 4 Complete Portals (Super Admin, Customer, Funder, O&M Provider)
- ✅ Modern UI with framer-motion animations
- ✅ Mobile-responsive design with glass morphism
- ✅ Role-based access control
- ✅ Comprehensive analytics
- ✅ API connectivity with fallback data

## 📦 Deployment Package Contents

```
nexusgreen-production-modernized/
├── dist/                          # Production build
├── server/                        # Backend server files
├── database/                      # Database schema and migrations
├── nginx/                         # Nginx configuration with SSL
├── ssl/                          # SSL certificate setup
├── scripts/                      # Deployment and maintenance scripts
└── docs/                         # Documentation
```

## 🔧 Step 1: Server Preparation

### Connect to Server
```bash
# Use the provided PEM file
ssh -i NEXUSAI.pem ubuntu@13.245.181.202

# Or use PPA-PEM.pem if the above doesn't work
ssh -i PPA-PEM.pem ubuntu@13.245.181.202
```

### Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx nodejs npm git curl
```

### Install Node.js 18+
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install PM2 for Process Management
```bash
sudo npm install -g pm2
```

## 🗄️ Step 2: Database Setup

### Install PostgreSQL
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Create Database and User
```bash
sudo -u postgres psql << EOF
CREATE DATABASE nexusgreen_prod;
CREATE USER nexusgreen WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE nexusgreen_prod TO nexusgreen;
ALTER USER nexusgreen CREATEDB;
\q
EOF
```

### Import Database Schema
```bash
# Copy the database schema from the deployment package
sudo -u postgres psql nexusgreen_prod < /path/to/database/schema.sql
```

## 📁 Step 3: Application Deployment

### Create Application Directory
```bash
sudo mkdir -p /var/www/nexusgreen
sudo chown -R ubuntu:ubuntu /var/www/nexusgreen
cd /var/www/nexusgreen
```

### Upload and Extract Application
```bash
# Upload the deployment package to the server
# Then extract it
tar -xzf nexusgreen-production-modernized.tar.gz
```

### Install Dependencies
```bash
cd /var/www/nexusgreen
npm install --production
```

### Configure Environment
```bash
cat > .env << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://nexusgreen:your_secure_password_here@localhost:5432/nexusgreen_prod
JWT_SECRET=your_jwt_secret_here_make_it_very_long_and_secure
CORS_ORIGIN=https://nexus.gonxt.tech
SSL_ENABLED=true
DOMAIN=nexus.gonxt.tech
EOF
```

## 🔒 Step 4: SSL Certificate Setup

### Obtain SSL Certificate with Certbot
```bash
# Stop nginx if running
sudo systemctl stop nginx

# Obtain certificate for nexus.gonxt.tech
sudo certbot certonly --standalone -d nexus.gonxt.tech

# The certificates will be saved to:
# /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem
# /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem
```

### Set up Auto-renewal
```bash
# Add to crontab for automatic renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx
```

## 🌐 Step 5: Nginx Configuration

### Create Nginx Configuration
```bash
sudo tee /etc/nginx/sites-available/nexusgreen << 'EOF'
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name nexus.gonxt.tech;
    return 301 https://$server_name$request_uri;
}

# HTTPS Configuration
server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem;
    
    # Modern SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Static Files
    location / {
        root /var/www/nexusgreen/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API Proxy
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # WebSocket Support
    location /ws {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

### Enable Site and Test Configuration
```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/nexusgreen /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## 🚀 Step 6: Start Application

### Create PM2 Ecosystem File
```bash
cat > /var/www/nexusgreen/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nexusgreen-prod',
    script: 'server/index.js',
    cwd: '/var/www/nexusgreen',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/nexusgreen/error.log',
    out_file: '/var/log/nexusgreen/out.log',
    log_file: '/var/log/nexusgreen/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};
EOF
```

### Create Log Directory
```bash
sudo mkdir -p /var/log/nexusgreen
sudo chown -R ubuntu:ubuntu /var/log/nexusgreen
```

### Start Application with PM2
```bash
cd /var/www/nexusgreen
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## 🧹 Step 7: Server Cleanup

### Remove Old Applications
```bash
# Stop any old processes
sudo pkill -f "node.*nexus" || true
sudo pkill -f "npm.*start" || true

# Remove old application directories
sudo rm -rf /var/www/html/nexus* || true
sudo rm -rf /opt/nexus* || true
sudo rm -rf /home/ubuntu/nexus* || true

# Clean up old nginx configurations
sudo rm -f /etc/nginx/sites-enabled/nexus* || true
sudo rm -f /etc/nginx/sites-available/nexus* || true
```

### Clean Package Cache
```bash
sudo apt autoremove -y
sudo apt autoclean
npm cache clean --force
```

### Update Firewall Rules
```bash
# Configure UFW firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

## 🔍 Step 8: Verification and Testing

### Check Services Status
```bash
# Check PM2 status
pm2 status

# Check Nginx status
sudo systemctl status nginx

# Check SSL certificate
sudo certbot certificates

# Test SSL configuration
curl -I https://nexus.gonxt.tech
```

### Test Application
```bash
# Test API endpoint
curl -k https://nexus.gonxt.tech/api/health

# Check logs
pm2 logs nexusgreen-prod --lines 50
```

### Performance Testing
```bash
# Test response times
curl -w "@curl-format.txt" -o /dev/null -s https://nexus.gonxt.tech

# Where curl-format.txt contains:
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n
```

## 📊 Step 9: Monitoring Setup

### Install Monitoring Tools
```bash
# Install htop for system monitoring
sudo apt install -y htop

# Setup log rotation
sudo tee /etc/logrotate.d/nexusgreen << 'EOF'
/var/log/nexusgreen/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        pm2 reloadLogs
    endscript
}
EOF
```

### Create Health Check Script
```bash
cat > /var/www/nexusgreen/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for NexusGreen

echo "=== NexusGreen Health Check ==="
echo "Date: $(date)"
echo

# Check PM2 status
echo "PM2 Status:"
pm2 jlist | jq -r '.[] | "\(.name): \(.pm2_env.status)"'
echo

# Check Nginx status
echo "Nginx Status:"
sudo systemctl is-active nginx
echo

# Check SSL certificate expiry
echo "SSL Certificate:"
echo | openssl s_client -servername nexus.gonxt.tech -connect nexus.gonxt.tech:443 2>/dev/null | openssl x509 -noout -dates
echo

# Check disk usage
echo "Disk Usage:"
df -h /var/www/nexusgreen
echo

# Check memory usage
echo "Memory Usage:"
free -h
echo

# Test application response
echo "Application Response:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}, Response Time: %{time_total}s\n" https://nexus.gonxt.tech
EOF

chmod +x /var/www/nexusgreen/health-check.sh
```

## 🔄 Step 10: Backup and Maintenance

### Create Backup Script
```bash
cat > /var/www/nexusgreen/backup.sh << 'EOF'
#!/bin/bash
# Backup script for NexusGreen

BACKUP_DIR="/var/backups/nexusgreen"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
sudo mkdir -p $BACKUP_DIR

# Backup database
sudo -u postgres pg_dump nexusgreen_prod | gzip > $BACKUP_DIR/database_$DATE.sql.gz

# Backup application files
tar -czf $BACKUP_DIR/application_$DATE.tar.gz -C /var/www nexusgreen

# Backup nginx configuration
sudo cp /etc/nginx/sites-available/nexusgreen $BACKUP_DIR/nginx_$DATE.conf

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.conf" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /var/www/nexusgreen/backup.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /var/www/nexusgreen/backup.sh") | crontab -
```

## 🚨 Troubleshooting

### Common Issues and Solutions

1. **SSL Certificate Issues**
   ```bash
   # Renew certificate manually
   sudo certbot renew --force-renewal
   sudo systemctl reload nginx
   ```

2. **Application Not Starting**
   ```bash
   # Check logs
   pm2 logs nexusgreen-prod
   
   # Restart application
   pm2 restart nexusgreen-prod
   ```

3. **Database Connection Issues**
   ```bash
   # Check PostgreSQL status
   sudo systemctl status postgresql
   
   # Test database connection
   psql -h localhost -U nexusgreen -d nexusgreen_prod -c "SELECT version();"
   ```

4. **High Memory Usage**
   ```bash
   # Restart application with memory limit
   pm2 restart nexusgreen-prod --max-memory-restart 1G
   ```

## 📈 Performance Optimization

### Enable HTTP/2 and Compression
Already configured in the Nginx setup above.

### Database Optimization
```sql
-- Connect to database and run these optimizations
\c nexusgreen_prod

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sites_project_id ON sites(project_id);

-- Update table statistics
ANALYZE;
```

### Application Caching
The application includes built-in caching for API responses and static assets.

## 🔐 Security Checklist

- ✅ SSL/TLS encryption enabled
- ✅ Security headers configured
- ✅ Firewall rules applied
- ✅ Database access restricted
- ✅ Regular security updates
- ✅ Log monitoring enabled
- ✅ Backup system configured

## 📞 Support

For issues or questions:
1. Check application logs: `pm2 logs nexusgreen-prod`
2. Check system logs: `sudo journalctl -u nginx -f`
3. Run health check: `/var/www/nexusgreen/health-check.sh`

## 🎉 Deployment Complete!

Your modernized NexusGreen multi-portal system is now live at:
**https://nexus.gonxt.tech**

### Features Available:
- 🏢 **Super Admin Portal**: Complete system management
- 👤 **Customer Portal**: Savings analysis and energy monitoring  
- 💰 **Funder Portal**: Investment tracking and ROI analysis
- 🔧 **O&M Provider Portal**: Operations and maintenance management
- 📱 **Mobile Responsive**: Optimized for all devices
- 🎨 **Modern UI**: Glass morphism and smooth animations
- 🔒 **Secure**: SSL encryption and security headers
- ⚡ **Fast**: Optimized performance and caching

The system is production-ready with comprehensive monitoring, backup, and security measures in place.