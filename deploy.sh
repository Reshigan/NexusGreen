#!/bin/bash

# SolarNexus Deployment Script
# For AWS server deployment at 13.245.249.110 (nexus.gonxt.tech)

set -e

echo "🚀 Starting SolarNexus deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="nexus.gonxt.tech"
SERVER_IP="13.245.249.110"
PROJECT_DIR="/opt/solarnexus"
BACKUP_DIR="/opt/solarnexus-backup"

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
print_status "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    htop \
    unzip

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_success "Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose already installed"
fi

# Install Node.js (for any additional tooling)
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    print_success "Node.js installed successfully"
else
    print_success "Node.js already installed"
fi

# Create project directory
print_status "Setting up project directory..."
mkdir -p $PROJECT_DIR
mkdir -p $BACKUP_DIR
mkdir -p /var/log/solarnexus

# Create backup if existing deployment
if [ -d "$PROJECT_DIR/.git" ]; then
    print_status "Creating backup of existing deployment..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    cp -r $PROJECT_DIR $BACKUP_DIR/solarnexus_$timestamp
    print_success "Backup created at $BACKUP_DIR/solarnexus_$timestamp"
fi

# Clone or update repository
if [ -d "$PROJECT_DIR/.git" ]; then
    print_status "Updating existing repository..."
    cd $PROJECT_DIR
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    print_status "Cloning repository..."
    git clone https://github.com/Reshigan/SolarNexus.git $PROJECT_DIR
    cd $PROJECT_DIR
fi

# Set proper permissions
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR

# Create necessary directories
mkdir -p $PROJECT_DIR/logs/nginx
mkdir -p $PROJECT_DIR/logs/backend
mkdir -p $PROJECT_DIR/uploads
mkdir -p $PROJECT_DIR/ssl

# Create environment file if it doesn't exist
if [ ! -f "$PROJECT_DIR/.env.production" ]; then
    print_status "Creating production environment file..."
    cp $PROJECT_DIR/.env.production.template $PROJECT_DIR/.env.production
    
    # Generate secure passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 64)
    JWT_REFRESH_SECRET=$(openssl rand -base64 64)
    
    # Update environment file
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" $PROJECT_DIR/.env.production
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" $PROJECT_DIR/.env.production
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" $PROJECT_DIR/.env.production
    sed -i "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" $PROJECT_DIR/.env.production
    sed -i "s/SERVER_IP=.*/SERVER_IP=$SERVER_IP/" $PROJECT_DIR/.env.production
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/" $PROJECT_DIR/.env.production
    
    print_success "Environment file created with secure passwords"
fi

# Copy environment file for docker-compose
cp $PROJECT_DIR/.env.production $PROJECT_DIR/.env

# Setup Nginx configuration
print_status "Setting up Nginx configuration..."
mkdir -p $PROJECT_DIR/nginx/conf.d

# Create main nginx.conf
cat > $PROJECT_DIR/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
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

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

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
        image/svg+xml;

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create server configuration
cat > $PROJECT_DIR/nginx/conf.d/solarnexus.conf << EOF
# Upstream backend
upstream backend {
    server backend:3000;
}

# HTTP server (redirect to HTTPS)
server {
    listen 80;
    server_name $DOMAIN $SERVER_IP;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all HTTP to HTTPS
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
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Root directory
    root /var/www/html;
    index index.html index.htm;
    
    # API routes
    location /api/ {
        proxy_pass http://backend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
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
    }
    
    # Health check
    location /health {
        proxy_pass http://backend/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static files
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Assets with longer cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

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

# Stop existing containers if running
print_status "Stopping existing containers..."
cd $PROJECT_DIR
docker-compose down --remove-orphans || true

# Build and start services
print_status "Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running"
else
    print_error "Some services failed to start"
    docker-compose logs
    exit 1
fi

# Setup SSL certificate
print_status "Setting up SSL certificate..."
if [ ! -f "$PROJECT_DIR/ssl/fullchain.pem" ]; then
    # Stop nginx temporarily
    docker-compose stop nginx
    
    # Get certificate
    certbot certonly --standalone \
        --email admin@$DOMAIN \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    # Copy certificates
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $PROJECT_DIR/ssl/
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $PROJECT_DIR/ssl/
    
    # Set permissions
    chmod 644 $PROJECT_DIR/ssl/fullchain.pem
    chmod 600 $PROJECT_DIR/ssl/privkey.pem
    
    # Restart nginx
    docker-compose start nginx
    
    print_success "SSL certificate installed"
else
    print_success "SSL certificate already exists"
fi

# Setup automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root certbot renew --quiet --post-hook "cd $PROJECT_DIR && docker-compose restart nginx"
EOF

# Run database migrations
print_status "Running database migrations..."
docker-compose exec -T backend npm run prisma:migrate:deploy || true
docker-compose exec -T backend npm run prisma:generate || true

# Create log rotation
print_status "Setting up log rotation..."
cat > /etc/logrotate.d/solarnexus << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        cd $PROJECT_DIR && docker-compose restart nginx backend
    endscript
}
EOF

# Final health check
print_status "Performing final health check..."
sleep 10

if curl -f -s http://localhost/health > /dev/null; then
    print_success "Health check passed"
else
    print_warning "Health check failed, but deployment may still be successful"
fi

# Display deployment information
echo ""
echo "🎉 SolarNexus deployment completed!"
echo ""
echo "📋 Deployment Information:"
echo "  • Domain: https://$DOMAIN"
echo "  • Server IP: http://$SERVER_IP"
echo "  • Project Directory: $PROJECT_DIR"
echo "  • Logs Directory: $PROJECT_DIR/logs"
echo "  • SSL Certificate: $PROJECT_DIR/ssl/"
echo ""
echo "🔧 Management Commands:"
echo "  • View logs: cd $PROJECT_DIR && docker-compose logs -f"
echo "  • Restart services: cd $PROJECT_DIR && docker-compose restart"
echo "  • Update deployment: cd $PROJECT_DIR && git pull && docker-compose up -d --build"
echo "  • Stop services: cd $PROJECT_DIR && docker-compose down"
echo ""
echo "🔍 Service Status:"
docker-compose ps

print_success "Deployment script completed successfully!"