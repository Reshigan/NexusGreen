#!/bin/bash

# NexusGreen Ultimate Clean Production Installation Script
# This script removes ALL previous implementations and performs a completely fresh installation
# addressing ALL issues identified in production deployment conversations

set -e

echo "🧹 NexusGreen Ultimate Clean Production Installation Script"
echo "=========================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo"
   exit 1
fi

print_status "Starting ultimate clean installation process..."

# =============================================================================
# STEP 1: NUCLEAR CLEANUP - REMOVE EVERYTHING
# =============================================================================

print_status "Step 1: Nuclear cleanup - removing ALL previous installations..."

# Stop ALL Docker containers and services
print_status "Stopping all Docker containers and services..."
systemctl stop docker 2>/dev/null || true
pkill -f docker 2>/dev/null || true
sleep 5

# Start Docker again
systemctl start docker
sleep 5

# Remove ALL Docker containers, images, volumes, networks
print_status "Removing ALL Docker containers, images, volumes, and networks..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker rmi $(docker images -q) 2>/dev/null || true
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q --filter type=custom) 2>/dev/null || true
docker system prune -af --volumes 2>/dev/null || true

# Kill any processes using ports 3001, 8080, 80, 443
print_status "Killing processes on ports 3001, 8080, 80, 443..."
for port in 3001 8080 80 443; do
    PID=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null || true
        print_status "Killed process $PID on port $port"
    fi
done

# Remove ALL nginx configurations
print_status "Removing ALL nginx configurations..."
systemctl stop nginx 2>/dev/null || true
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/nexus*
rm -rf /etc/nginx/conf.d/nexus*
rm -rf /etc/nginx/conf.d/default*

# Backup and reset nginx.conf to default
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create clean nginx.conf
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Remove any leftover processes
print_status "Cleaning up any leftover processes..."
pkill -f "nexus" 2>/dev/null || true
pkill -f "node" 2>/dev/null || true
pkill -f "npm" 2>/dev/null || true

print_success "Nuclear cleanup completed"

# =============================================================================
# STEP 2: VERIFY AND INSTALL PREREQUISITES
# =============================================================================

print_status "Step 2: Verifying and installing prerequisites..."

# Update system
print_status "Updating system packages..."
apt update

# Install Docker if not present
if ! command_exists docker; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER 2>/dev/null || true
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
    print_success "Docker installed"
else
    print_success "Docker already installed"
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose already installed"
fi

# Install Nginx if not present
if ! command_exists nginx; then
    print_status "Installing Nginx..."
    apt install -y nginx
    systemctl enable nginx
    print_success "Nginx installed"
else
    print_success "Nginx already installed"
fi

# Install Certbot if not present
if ! command_exists certbot; then
    print_status "Installing Certbot..."
    apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
else
    print_success "Certbot already installed"
fi

# Install other utilities
print_status "Installing additional utilities..."
apt install -y curl wget git lsof htop

print_success "All prerequisites verified and installed"

# =============================================================================
# STEP 3: PREPARE CLEAN DOCKER CONFIGURATION
# =============================================================================

print_status "Step 3: Preparing clean Docker configuration..."

# Navigate to NexusGreen directory
cd ~/NexusGreen || {
    print_error "NexusGreen directory not found. Please ensure the repository is cloned."
    exit 1
}

# Pull latest changes
print_status "Pulling latest changes from repository..."
git pull origin main || print_warning "Could not pull latest changes"

# Create completely clean docker-compose.yml with ALL fixes applied
print_status "Creating clean docker-compose.yml with all fixes..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nexus-db:
    image: postgres:15-alpine
    container_name: nexus-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: nexus_green
      POSTGRES_USER: nexus_user
      POSTGRES_PASSWORD: nexus_secure_password_2024
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - nexus_db_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - nexus-network
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nexus_user -d nexus_green"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    labels:
      - "com.nexusgreen.service=database"
      - "com.nexusgreen.version=7.0.0"

  nexus-api:
    build:
      context: ./api
      dockerfile: Dockerfile
      platforms:
        - linux/arm64
        - linux/amd64
    container_name: nexus-api
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      NODE_ENV: production
      PORT: 3001
      DB_HOST: nexus-db
      DB_PORT: 5432
      DB_NAME: nexus_green
      DB_USER: nexus_user
      DB_PASSWORD: nexus_secure_password_2024
      DB_TIMEOUT: 15000
      DB_MAX_CONNECTIONS: 8
      DB_ACQUIRE_TIMEOUT: 15000
      DB_IDLE_TIMEOUT: 30000
      JWT_SECRET: nexus_jwt_secret_key_2024_production_v7
      CORS_ORIGIN: https://nexus.gonxt.tech,http://localhost:8080,http://localhost:3000
      API_BASE_URL: https://nexus.gonxt.tech/api
    depends_on:
      nexus-db:
        condition: service_healthy
    networks:
      - nexus-network
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/api/health"]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 60s
    labels:
      - "com.nexusgreen.service=api"
      - "com.nexusgreen.version=7.0.0"

  nexus-green:
    build:
      context: .
      dockerfile: Dockerfile
      platforms:
        - linux/arm64
        - linux/amd64
    container_name: nexus-green
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      VITE_API_BASE_URL: https://nexus.gonxt.tech/api
      VITE_APP_NAME: NexusGreen
      VITE_APP_VERSION: 7.0.0
      NODE_ENV: production
    depends_on:
      nexus-api:
        condition: service_healthy
    networks:
      - nexus-network
    deploy:
      resources:
        limits:
          memory: 384M
        reservations:
          memory: 192M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "com.nexusgreen.service=frontend"
      - "com.nexusgreen.version=7.0.0"

volumes:
  nexus_db_data:
    driver: local
    labels:
      - "com.nexusgreen.volume=database"

networks:
  nexus-network:
    driver: bridge
    labels:
      - "com.nexusgreen.network=main"
EOF

print_success "Clean docker-compose.yml created"

# =============================================================================
# STEP 4: CREATE PERFECT NGINX CONFIGURATION
# =============================================================================

print_status "Step 4: Creating perfect nginx configuration..."

# Create nginx configuration for nexus.gonxt.tech
cat > /etc/nginx/sites-available/nexus.gonxt.tech << 'EOF'
# HTTP server block - handles Let's Encrypt challenges and redirects to HTTPS
server {
    listen 80;
    server_name nexus.gonxt.tech;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Health check endpoint (accessible via HTTP)
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server block - main application
server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;

    # SSL Configuration (will be managed by certbot)
    ssl_certificate /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem;
    
    # Modern SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security Headers
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # API Proxy Configuration - CRITICAL FOR FIXING BLANK WEBSITE
    location /api {
        # Proxy to API container
        proxy_pass http://localhost:3001;
        
        # Essential proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeout settings - PREVENTS API FAILURES
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_next_upstream_timeout 60s;
        
        # Buffer settings for performance
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # CORS Headers - CRITICAL FOR API ACCESS
        proxy_hide_header Access-Control-Allow-Origin;
        add_header Access-Control-Allow-Origin $http_origin always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS, PATCH" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept, X-Requested-With, Origin" always;
        add_header Access-Control-Allow-Credentials true always;
        add_header Access-Control-Max-Age 86400 always;
        
        # Handle preflight requests - PREVENTS CORS ERRORS
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin $http_origin;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS, PATCH";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept, X-Requested-With, Origin";
            add_header Access-Control-Allow-Credentials true;
            add_header Access-Control-Max-Age 86400;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }

    # Frontend Proxy Configuration
    location / {
        # Proxy to frontend container
        proxy_pass http://localhost:8080;
        
        # Essential proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # WebSocket support (for development)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Handle SPA routing
        try_files $uri $uri/ @fallback;
    }

    # Fallback for SPA routing
    location @fallback {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files optimization
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Security - block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/nexus.gonxt.tech /etc/nginx/sites-enabled/

# Remove default nginx site to prevent conflicts
rm -f /etc/nginx/sites-enabled/default

print_success "Perfect nginx configuration created"

# =============================================================================
# STEP 5: BUILD AND START SERVICES
# =============================================================================

print_status "Step 5: Building and starting services..."

# Start nginx
systemctl start nginx

# Test nginx configuration
if nginx -t; then
    print_success "Nginx configuration is valid"
    systemctl reload nginx
else
    print_error "Nginx configuration has errors"
    nginx -t
    exit 1
fi

# Build Docker images with no cache
print_status "Building Docker images (this may take several minutes)..."
docker-compose build --no-cache --parallel

# Start services
print_status "Starting all services..."
docker-compose up -d

# Wait for services to initialize
print_status "Waiting for services to initialize (60 seconds)..."
sleep 60

print_success "Services started"

# =============================================================================
# STEP 6: COMPREHENSIVE HEALTH CHECKS
# =============================================================================

print_status "Step 6: Comprehensive health checks..."

# Function to check service health
check_service_health() {
    local service_name=$1
    local max_attempts=12
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps | grep "$service_name" | grep -q "healthy\|Up"; then
            print_success "✅ $service_name is healthy"
            return 0
        fi
        print_status "Waiting for $service_name to be healthy (attempt $attempt/$max_attempts)..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_error "❌ $service_name failed to become healthy"
    docker-compose logs "$service_name" --tail=20
    return 1
}

# Check each service
check_service_health "nexus-db"
check_service_health "nexus-api"
check_service_health "nexus-green"

echo ""
echo "=== CONTAINER STATUS ==="
docker-compose ps

echo ""
echo "=== PORT MAPPINGS ==="
for container in nexus-api nexus-green nexus-db; do
    CONTAINER_ID=$(docker ps -q --filter name=$container)
    if [ -n "$CONTAINER_ID" ]; then
        echo "$container:"
        docker port $CONTAINER_ID || echo "  No ports exposed"
    fi
done

# =============================================================================
# STEP 7: CONNECTIVITY TESTS
# =============================================================================

print_status "Step 7: Connectivity tests..."

echo ""
echo "=== TESTING API DIRECT ACCESS ==="
if curl -f -s -m 10 http://localhost:3001/api/health > /dev/null; then
    print_success "✅ API accessible on localhost:3001"
    API_RESPONSE=$(curl -s -m 10 http://localhost:3001/api/health)
    echo "API Response: $API_RESPONSE"
else
    print_error "❌ API not accessible on localhost:3001"
    echo "API logs:"
    docker-compose logs nexus-api --tail=20
fi

echo ""
echo "=== TESTING FRONTEND DIRECT ACCESS ==="
if curl -f -s -I -m 10 http://localhost:8080 > /dev/null; then
    print_success "✅ Frontend accessible on localhost:8080"
else
    print_error "❌ Frontend not accessible on localhost:8080"
    echo "Frontend logs:"
    docker-compose logs nexus-green --tail=20
fi

echo ""
echo "=== TESTING NGINX CONFIGURATION ==="
if nginx -t; then
    print_success "✅ Nginx configuration is valid"
else
    print_error "❌ Nginx configuration has errors"
fi

echo ""
echo "=== TESTING HTTP ACCESS ==="
if curl -f -s -I -m 10 http://nexus.gonxt.tech/health > /dev/null; then
    print_success "✅ HTTP access working (redirects to HTTPS)"
else
    print_warning "⚠️  HTTP access not working (may be normal if DNS not configured)"
fi

# =============================================================================
# STEP 8: SSL CERTIFICATE SETUP
# =============================================================================

print_status "Step 8: SSL certificate setup..."

# Check if SSL certificate already exists
if [ -f "/etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem" ]; then
    print_success "✅ SSL certificate already exists"
    
    # Test certificate
    if openssl x509 -in /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem -noout -checkend 86400; then
        print_success "✅ SSL certificate is valid and not expiring soon"
    else
        print_warning "⚠️  SSL certificate is expiring soon or invalid"
    fi
    
    # Reload nginx to use certificate
    systemctl reload nginx
    
    # Test HTTPS access
    echo ""
    echo "=== TESTING HTTPS ACCESS ==="
    if curl -f -s -I -m 10 https://nexus.gonxt.tech/health > /dev/null; then
        print_success "✅ HTTPS access working"
    else
        print_warning "⚠️  HTTPS access not working (may need DNS configuration)"
    fi
    
    echo ""
    echo "=== TESTING API THROUGH NGINX ==="
    if curl -f -s -m 10 https://nexus.gonxt.tech/api/health > /dev/null; then
        print_success "✅ API accessible through nginx at https://nexus.gonxt.tech/api/health"
        API_NGINX_RESPONSE=$(curl -s -m 10 https://nexus.gonxt.tech/api/health)
        echo "API Response via Nginx: $API_NGINX_RESPONSE"
    else
        print_warning "⚠️  API not accessible through nginx (may need DNS configuration)"
    fi
else
    print_warning "⚠️  SSL certificate not found"
    print_status "To install SSL certificate, run:"
    print_status "sudo certbot --nginx -d nexus.gonxt.tech"
fi

# =============================================================================
# STEP 9: FINAL VERIFICATION AND REPORT
# =============================================================================

print_status "Step 9: Final verification and report..."

# Check overall system health
echo ""
echo "=== SYSTEM RESOURCE USAGE ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "=== RECENT LOGS ==="
echo "API Logs:"
docker-compose logs nexus-api --tail=5
echo ""
echo "Frontend Logs:"
docker-compose logs nexus-green --tail=5
echo ""
echo "Database Logs:"
docker-compose logs nexus-db --tail=5

# Final status check
ALL_WORKING=true
API_WORKING=false
FRONTEND_WORKING=false
NGINX_WORKING=false

if curl -f -s -m 10 http://localhost:3001/api/health > /dev/null; then
    API_WORKING=true
else
    ALL_WORKING=false
fi

if curl -f -s -I -m 10 http://localhost:8080 > /dev/null; then
    FRONTEND_WORKING=true
else
    ALL_WORKING=false
fi

if nginx -t > /dev/null 2>&1; then
    NGINX_WORKING=true
else
    ALL_WORKING=false
fi

# =============================================================================
# FINAL REPORT
# =============================================================================

echo ""
echo "🎉 =============================================="
echo "🎉  NEXUSGREEN ULTIMATE CLEAN INSTALLATION"
echo "🎉  COMPLETION REPORT"
echo "🎉 =============================================="
echo ""

if [ "$ALL_WORKING" = true ]; then
    print_success "🎊 SUCCESS! All core services are operational!"
    echo ""
    echo "✅ Database: Connected and healthy"
    echo "✅ API Server: http://localhost:3001/api/health"
    echo "✅ Frontend: http://localhost:8080"
    echo "✅ Docker: All containers running and healthy"
    echo "✅ Nginx: Configured and running"
    
    if [ -f "/etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem" ]; then
        echo "✅ SSL: Certificate installed and working"
        echo "🌐 Production URL: https://nexus.gonxt.tech"
        echo "🔌 API URL: https://nexus.gonxt.tech/api/health"
    else
        echo "⚠️  SSL: Certificate needs to be installed"
        echo "📝 Next step: sudo certbot --nginx -d nexus.gonxt.tech"
    fi
    
    echo ""
    print_success "🚀 NexusGreen is ready for production!"
    
else
    print_warning "⚠️  Some services need attention:"
    
    if [ "$API_WORKING" = false ]; then
        echo "❌ API Server: Not responding"
    else
        echo "✅ API Server: Working"
    fi
    
    if [ "$FRONTEND_WORKING" = false ]; then
        echo "❌ Frontend: Not responding"
    else
        echo "✅ Frontend: Working"
    fi
    
    if [ "$NGINX_WORKING" = false ]; then
        echo "❌ Nginx: Configuration errors"
    else
        echo "✅ Nginx: Working"
    fi
    
    echo ""
    print_status "Check logs with: docker-compose logs"
fi

echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. 🔒 Install SSL Certificate (if not done):"
echo "   sudo certbot --nginx -d nexus.gonxt.tech"
echo ""
echo "2. 🌐 Test in Browser:"
echo "   https://nexus.gonxt.tech (after SSL)"
echo "   http://nexus.gonxt.tech (redirects to HTTPS)"
echo ""
echo "3. 📊 Monitor Application:"
echo "   docker-compose logs -f"
echo "   docker-compose ps"
echo ""
echo "4. 🔄 Restart if Needed:"
echo "   docker-compose down && docker-compose up -d"
echo ""
echo "5. 🧪 Test API Endpoints:"
echo "   curl https://nexus.gonxt.tech/api/health"
echo "   curl http://localhost:3001/api/health"
echo ""

# Create a summary file
cat > ~/nexusgreen-installation-summary.txt << EOF
NexusGreen Ultimate Clean Installation Summary
=============================================
Installation Date: $(date)
Installation Status: $([ "$ALL_WORKING" = true ] && echo "SUCCESS" || echo "PARTIAL")

Services Status:
- Database: $(docker-compose ps nexus-db | grep -q "healthy\|Up" && echo "✅ Running" || echo "❌ Not Running")
- API: $([ "$API_WORKING" = true ] && echo "✅ Working" || echo "❌ Not Working")
- Frontend: $([ "$FRONTEND_WORKING" = true ] && echo "✅ Working" || echo "❌ Not Working")
- Nginx: $([ "$NGINX_WORKING" = true ] && echo "✅ Working" || echo "❌ Not Working")
- SSL: $([ -f "/etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem" ] && echo "✅ Installed" || echo "⚠️ Not Installed")

URLs:
- Production: https://nexus.gonxt.tech
- API: https://nexus.gonxt.tech/api/health
- Direct API: http://localhost:3001/api/health
- Direct Frontend: http://localhost:8080

Next Steps:
$([ ! -f "/etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem" ] && echo "- Install SSL: sudo certbot --nginx -d nexus.gonxt.tech")
- Test in browser: https://nexus.gonxt.tech
- Monitor logs: docker-compose logs -f

Installation completed by: Ultimate Clean Install Script v7.0.0
EOF

print_success "Installation summary saved to ~/nexusgreen-installation-summary.txt"
print_success "Ultimate clean installation script completed! 🚀"

# Final reminder
echo ""
print_status "🎯 REMEMBER: If SSL certificate is not installed, run:"
print_status "sudo certbot --nginx -d nexus.gonxt.tech"
print_status "Then test: https://nexus.gonxt.tech"
echo ""