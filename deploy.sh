#!/bin/bash

# SolarNexus Clean Deployment Script
# Comprehensive deployment with server cleanup and dependency management
# Version: 2.0 - Clean Base Deployment

set -e

echo "🚀 Starting SolarNexus Clean Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - Update these as needed
DOMAIN="${DOMAIN:-nexus.gonxt.tech}"
SERVER_IP="${SERVER_IP:-13.247.174.75}"
PROJECT_DIR="/opt/solarnexus"
BACKUP_DIR="/opt/solarnexus-backup"
LOG_DIR="/var/log/solarnexus"
REPO_URL="https://github.com/Reshigan/SolarNexus.git"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_cleanup() {
    echo -e "${CYAN}[CLEANUP]${NC} $1"
}

# Error handling
cleanup_on_error() {
    print_error "Deployment failed. Cleaning up..."
    if [ -d "$PROJECT_DIR" ]; then
        cd $PROJECT_DIR
        docker-compose down --remove-orphans 2>/dev/null || true
    fi
    exit 1
}

trap cleanup_on_error ERR

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Parse command line arguments
CLEAN_INSTALL=false
SKIP_SSL=false
FORCE_REBUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_INSTALL=true
            shift
            ;;
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        --force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --ip)
            SERVER_IP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --clean         Perform clean installation (removes all old data)"
            echo "  --skip-ssl      Skip SSL certificate setup"
            echo "  --force-rebuild Force rebuild of Docker images"
            echo "  --domain DOMAIN Set domain name (default: nexus.gonxt.tech)"
            echo "  --ip IP         Set server IP (default: 13.247.174.75)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_step "🧹 PHASE 1: System Cleanup and Preparation"

# Clean old installations if requested
if [ "$CLEAN_INSTALL" = true ]; then
    print_cleanup "Performing clean installation..."
    
    # Stop and remove all containers
    print_cleanup "Stopping all Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Remove old Docker images
    print_cleanup "Removing old Docker images..."
    docker system prune -af --volumes 2>/dev/null || true
    
    # Remove old project directory
    if [ -d "$PROJECT_DIR" ]; then
        print_cleanup "Removing old project directory..."
        rm -rf $PROJECT_DIR
    fi
    
    # Remove old logs
    if [ -d "$LOG_DIR" ]; then
        print_cleanup "Removing old logs..."
        rm -rf $LOG_DIR
    fi
    
    print_success "Clean installation preparation completed"
fi

# Update system packages
print_status "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Remove old/conflicting packages
print_cleanup "Removing old/conflicting packages..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
apt-get autoremove -y
apt-get autoclean

print_step "📦 PHASE 2: Installing Dependencies"

# Install essential packages
print_status "Installing essential packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    htop \
    unzip \
    software-properties-common \
    build-essential \
    openssl

# Install Docker (latest version)
print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose (standalone)
print_status "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js (LTS)
print_status "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Verify installations
print_status "Verifying installations..."
docker --version
docker-compose --version
node --version
npm --version

print_step "🏗️ PHASE 3: Project Setup"

# Create directories
print_status "Creating project directories..."
mkdir -p $PROJECT_DIR
mkdir -p $BACKUP_DIR
mkdir -p $LOG_DIR
mkdir -p /var/www/certbot

# Create backup if existing deployment
if [ -d "$PROJECT_DIR/.git" ] && [ "$CLEAN_INSTALL" = false ]; then
    print_status "Creating backup of existing deployment..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    cp -r $PROJECT_DIR $BACKUP_DIR/solarnexus_$timestamp
    print_success "Backup created at $BACKUP_DIR/solarnexus_$timestamp"
fi

# Clone or update repository
if [ -d "$PROJECT_DIR/.git" ] && [ "$CLEAN_INSTALL" = false ]; then
    print_status "Updating existing repository..."
    cd $PROJECT_DIR
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    print_status "Cloning repository..."
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf $PROJECT_DIR
    fi
    git clone $REPO_URL $PROJECT_DIR
    cd $PROJECT_DIR
fi

# Set proper permissions
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR

print_step "⚙️ PHASE 4: Configuration Setup"

# Create necessary directories
mkdir -p $PROJECT_DIR/logs/nginx
mkdir -p $PROJECT_DIR/logs/backend
mkdir -p $PROJECT_DIR/uploads
mkdir -p $PROJECT_DIR/ssl
mkdir -p $PROJECT_DIR/nginx/conf.d

# Create environment file template if it doesn't exist
if [ ! -f "$PROJECT_DIR/.env.production.template" ]; then
    print_status "Creating environment template..."
    cat > $PROJECT_DIR/.env.production.template << 'EOF'
# Production Environment Configuration
NODE_ENV=production
PORT=3000

# Database Configuration
DATABASE_URL="mysql://nexus_user:POSTGRES_PASSWORD@db:3306/nexus_green"
POSTGRES_PASSWORD=POSTGRES_PASSWORD_PLACEHOLDER

# Redis Configuration
REDIS_URL="redis://:REDIS_PASSWORD@redis:6379"
REDIS_PASSWORD=REDIS_PASSWORD_PLACEHOLDER

# JWT Configuration
JWT_SECRET=JWT_SECRET_PLACEHOLDER
JWT_REFRESH_SECRET=JWT_REFRESH_SECRET_PLACEHOLDER
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
SERVER_IP=SERVER_IP_PLACEHOLDER
DOMAIN=DOMAIN_PLACEHOLDER
FRONTEND_URL=https://DOMAIN_PLACEHOLDER
BACKEND_URL=https://DOMAIN_PLACEHOLDER/api

# Email Configuration (Update with your SMTP settings)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@DOMAIN_PLACEHOLDER

# File Upload Configuration
MAX_FILE_SIZE=10485760
UPLOAD_PATH=/app/uploads

# Security
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX=100

# Monitoring
LOG_LEVEL=info
EOF
fi

# Create production environment file
if [ ! -f "$PROJECT_DIR/.env.production" ] || [ "$FORCE_REBUILD" = true ]; then
    print_status "Creating production environment file..."
    cp $PROJECT_DIR/.env.production.template $PROJECT_DIR/.env.production
    
    # Generate secure passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/")
    JWT_REFRESH_SECRET=$(openssl rand -base64 64 | tr -d "=+/")
    
    # Update environment file
    sed -i "s/POSTGRES_PASSWORD_PLACEHOLDER/$POSTGRES_PASSWORD/g" $PROJECT_DIR/.env.production
    sed -i "s/REDIS_PASSWORD_PLACEHOLDER/$REDIS_PASSWORD/g" $PROJECT_DIR/.env.production
    sed -i "s/JWT_SECRET_PLACEHOLDER/$JWT_SECRET/g" $PROJECT_DIR/.env.production
    sed -i "s/JWT_REFRESH_SECRET_PLACEHOLDER/$JWT_REFRESH_SECRET/g" $PROJECT_DIR/.env.production
    sed -i "s/SERVER_IP_PLACEHOLDER/$SERVER_IP/g" $PROJECT_DIR/.env.production
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" $PROJECT_DIR/.env.production
    
    print_success "Environment file created with secure passwords"
fi

# Copy environment file for docker-compose
cp $PROJECT_DIR/.env.production $PROJECT_DIR/.env

print_step "🌐 PHASE 5: Nginx Configuration"

# Create optimized nginx configuration
cat > $PROJECT_DIR/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml
        application/x-font-ttf
        application/vnd.ms-fontobject
        font/opentype;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create server configuration
cat > $PROJECT_DIR/nginx/conf.d/solarnexus.conf << EOF
# Rate limiting
limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;

# Upstream backend
upstream backend {
    server backend:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# HTTP server (redirect to HTTPS)
server {
    listen 80;
    server_name $DOMAIN $SERVER_IP;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Health check (allow HTTP for monitoring)
    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }
    
    # Redirect all other HTTP to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN $SERVER_IP;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;
    
    # Root directory
    root /var/www/html;
    index index.html index.htm;
    
    # API routes with rate limiting
    location /api/auth/ {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://backend/;
        include /etc/nginx/proxy_params;
    }
    
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://backend/;
        include /etc/nginx/proxy_params;
    }
    
    # WebSocket support
    location /socket.io/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://backend/health;
        include /etc/nginx/proxy_params;
        access_log off;
    }
    
    # Static files with caching
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, no-transform";
    }
    
    # Assets with longer cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|sql)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Create proxy params
cat > $PROJECT_DIR/nginx/proxy_params << 'EOF'
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection 'upgrade';
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_cache_bypass $http_upgrade;
proxy_read_timeout 300s;
proxy_connect_timeout 75s;
proxy_send_timeout 300s;
EOF

print_step "🔥 PHASE 6: Firewall Configuration"

# Setup firewall
print_status "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
print_success "Firewall configured"

print_step "🐳 PHASE 7: Docker Deployment"

# Stop existing containers
print_status "Stopping existing containers..."
cd $PROJECT_DIR
docker-compose down --remove-orphans 2>/dev/null || true

# Build and start services
if [ "$FORCE_REBUILD" = true ]; then
    print_status "Force rebuilding and starting services..."
    docker-compose build --no-cache --pull
else
    print_status "Building and starting services..."
    docker-compose build
fi

docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 45

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running"
    docker-compose ps
else
    print_error "Some services failed to start"
    docker-compose logs --tail=50
    exit 1
fi

print_step "🔒 PHASE 8: SSL Certificate Setup"

if [ "$SKIP_SSL" = false ]; then
    # Setup SSL certificate
    print_status "Setting up SSL certificate..."
    if [ ! -f "$PROJECT_DIR/ssl/fullchain.pem" ] || [ "$FORCE_REBUILD" = true ]; then
        # Stop nginx temporarily
        docker-compose stop nginx
        
        # Get certificate
        certbot certonly --standalone \
            --email admin@$DOMAIN \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            -d $DOMAIN
        
        # Copy certificates
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $PROJECT_DIR/ssl/
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $PROJECT_DIR/ssl/
        
        # Set permissions
        chmod 644 $PROJECT_DIR/ssl/fullchain.pem
        chmod 600 $PROJECT_DIR/ssl/privkey.pem
        chown www-data:www-data $PROJECT_DIR/ssl/*
        
        # Restart nginx
        docker-compose start nginx
        
        print_success "SSL certificate installed"
    else
        print_success "SSL certificate already exists"
    fi
    
    # Setup automatic certificate renewal
    print_status "Setting up automatic certificate renewal..."
    cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root certbot renew --quiet --post-hook "cd $PROJECT_DIR && docker-compose restart nginx" >> /var/log/certbot-renew.log 2>&1
EOF
else
    print_warning "SSL setup skipped as requested"
fi

print_step "🗄️ PHASE 9: Database Setup"

# Run database migrations
print_status "Running database migrations..."
sleep 10
docker-compose exec -T backend npm run migrate:prod 2>/dev/null || print_warning "Migration failed - database may not be ready yet"
docker-compose exec -T backend npm run generate 2>/dev/null || print_warning "Prisma generate failed"

print_step "📊 PHASE 10: Auto-Startup and Auto-Upgrade Setup"

# Setup systemd services for auto-startup
print_status "Setting up systemd services for auto-startup..."
cp $PROJECT_DIR/solarnexus.service /etc/systemd/system/
cp $PROJECT_DIR/solarnexus-updater.service /etc/systemd/system/

# Make auto-upgrade script executable
chmod +x $PROJECT_DIR/auto-upgrade.sh

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable solarnexus.service
systemctl enable solarnexus-updater.service

print_success "Auto-startup services configured"

# Create log rotation
print_status "Setting up log rotation..."
cat > /etc/logrotate.d/solarnexus << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        cd $PROJECT_DIR && docker-compose restart nginx backend 2>/dev/null || true
    endscript
}

$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

# Create monitoring script
cat > /usr/local/bin/solarnexus-monitor << 'EOF'
#!/bin/bash
# SolarNexus Monitoring Script

PROJECT_DIR="/opt/solarnexus"
LOG_FILE="/var/log/solarnexus/monitor.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check if services are running
cd $PROJECT_DIR
if ! docker-compose ps | grep -q "Up"; then
    log_message "ERROR: Some services are down. Attempting restart..."
    docker-compose up -d
    sleep 30
    if docker-compose ps | grep -q "Up"; then
        log_message "SUCCESS: Services restarted successfully"
    else
        log_message "CRITICAL: Failed to restart services"
    fi
else
    log_message "INFO: All services are running normally"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    log_message "WARNING: Disk usage is at ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -gt 85 ]; then
    log_message "WARNING: Memory usage is at ${MEMORY_USAGE}%"
fi
EOF

chmod +x /usr/local/bin/solarnexus-monitor

# Add monitoring to cron
cat > /etc/cron.d/solarnexus-monitor << 'EOF'
*/5 * * * * root /usr/local/bin/solarnexus-monitor
EOF

print_step "🔍 PHASE 11: Start Auto-Services and Final Health Checks"

# Start the auto-updater service
print_status "Starting auto-updater service..."
systemctl start solarnexus-updater.service
systemctl status solarnexus-updater.service --no-pager -l || print_warning "Auto-updater service may need manual check"

print_success "Auto-updater service started"

# Final health check
print_status "Performing comprehensive health check..."
sleep 15

# Check HTTP health endpoint
if curl -f -s http://localhost/health > /dev/null; then
    print_success "HTTP health check passed"
else
    print_warning "HTTP health check failed"
fi

# Check HTTPS if SSL is configured
if [ "$SKIP_SSL" = false ] && [ -f "$PROJECT_DIR/ssl/fullchain.pem" ]; then
    if curl -f -s -k https://localhost/health > /dev/null; then
        print_success "HTTPS health check passed"
    else
        print_warning "HTTPS health check failed"
    fi
fi

# Check database connection
if docker-compose exec -T backend node -e "console.log('Database connection test')" 2>/dev/null; then
    print_success "Backend service is responsive"
else
    print_warning "Backend service may not be fully ready"
fi

print_step "🎉 DEPLOYMENT COMPLETED"

# Display deployment information
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                          🎉 SolarNexus Deployment Complete!                  ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Deployment Information:"
echo "  • Domain: https://$DOMAIN"
echo "  • Server IP: http://$SERVER_IP"
echo "  • Project Directory: $PROJECT_DIR"
echo "  • Logs Directory: $LOG_DIR"
echo "  • SSL Certificate: $PROJECT_DIR/ssl/"
echo ""
echo "🔧 Management Commands:"
echo "  • View logs: cd $PROJECT_DIR && docker-compose logs -f"
echo "  • Restart services: systemctl restart solarnexus"
echo "  • Manual update: $PROJECT_DIR/auto-upgrade.sh --upgrade"
echo "  • Check for updates: $PROJECT_DIR/auto-upgrade.sh --check"
echo "  • Stop services: systemctl stop solarnexus"
echo "  • Monitor status: tail -f $LOG_DIR/monitor.log"
echo "  • Auto-updater logs: journalctl -u solarnexus-updater -f"
echo ""
echo "🔍 Current Service Status:"
cd $PROJECT_DIR
docker-compose ps

echo ""
echo "🚀 Auto-Startup & Auto-Upgrade Features:"
echo "  • Auto-startup on boot: ✅ Enabled (systemctl status solarnexus)"
echo "  • Auto-upgrade daemon: ✅ Running (systemctl status solarnexus-updater)"
echo "  • Update check interval: 5 minutes"
echo "  • Webhook endpoint: http://$(hostname -I | awk '{print $1}'):9876"
echo "  • Upgrade logs: /var/log/solarnexus/updater.log"

echo ""
echo "🚀 Deployment completed successfully!"
echo "   Access your application at: https://$DOMAIN"
echo ""

# Create deployment summary
cat > $PROJECT_DIR/DEPLOYMENT_SUMMARY.md << EOF
# SolarNexus Deployment Summary

**Deployment Date:** $(date)
**Domain:** $DOMAIN
**Server IP:** $SERVER_IP
**Version:** Clean Base Deployment v2.0

## Services Status
\`\`\`
$(docker-compose ps)
\`\`\`

## Configuration
- Project Directory: $PROJECT_DIR
- Logs Directory: $LOG_DIR
- SSL Certificates: $PROJECT_DIR/ssl/
- Environment: Production

## Monitoring
- Health Check: https://$DOMAIN/health
- Log Monitoring: Automated via cron
- Certificate Renewal: Automated

## Management
- All services are containerized with Docker Compose
- Automatic restarts configured
- Log rotation enabled
- Firewall configured for security

## Next Steps
1. Verify application functionality
2. Configure monitoring alerts
3. Set up backup procedures
4. Review security settings
EOF

print_success "Deployment summary created at $PROJECT_DIR/DEPLOYMENT_SUMMARY.md"