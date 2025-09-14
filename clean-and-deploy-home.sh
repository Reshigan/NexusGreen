#!/bin/bash

# Complete System Cleanup and Home Directory Deployment
# Removes all old installations and deploys fresh in home directory

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Get current user and directories
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

echo "🧹 Complete System Cleanup and Home Deployment"
echo "=============================================="
echo ""
info "Current user: $CURRENT_USER"
info "Home directory: $HOME_DIR"
info "Target installation: $INSTALL_DIR"
echo ""

# Function to safely remove directory
safe_remove() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        warning "Found $name installation: $dir"
        echo "Contents:"
        ls -la "$dir" 2>/dev/null | head -5
        echo ""
        read -p "Remove $name installation? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Removing $name installation..."
            if [[ "$dir" == /opt/* ]] || [[ "$dir" == /root/* ]]; then
                sudo rm -rf "$dir"
            else
                rm -rf "$dir"
            fi
            success "$name installation removed"
        else
            warning "Keeping $name installation"
        fi
        echo ""
    fi
}

# 1. COMPREHENSIVE CLEANUP
log "🔍 Scanning for existing installations..."
echo ""

# Check common installation locations
LOCATIONS=(
    "/opt/nexus-green:System Nexus Green"
    "/opt/solarnexus:System SolarNexus"
    "/opt/NexusGreen:System NexusGreen"
    "/root/nexus-green:Root Nexus Green"
    "/root/solarnexus:Root SolarNexus"
    "/root/NexusGreen:Root NexusGreen"
    "$HOME_DIR/solarnexus:Home SolarNexus"
    "$HOME_DIR/SolarNexus:Home SolarNexus"
    "$HOME_DIR/NexusGreen:Home NexusGreen"
)

for location in "${LOCATIONS[@]}"; do
    dir="${location%%:*}"
    name="${location##*:}"
    safe_remove "$dir" "$name"
done

# 2. CLEAN NGINX CONFIGURATIONS
log "🔧 Cleaning Nginx configurations..."
NGINX_CONFIGS=(
    "/etc/nginx/sites-enabled/solarnexus"
    "/etc/nginx/sites-available/solarnexus"
    "/etc/nginx/sites-enabled/nexus-green"
    "/etc/nginx/sites-available/nexus-green"
    "/etc/nginx/sites-enabled/default"
)

for config in "${NGINX_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        warning "Removing Nginx config: $config"
        sudo rm -f "$config"
    fi
done

# 3. CLEAN SYSTEMD SERVICES (if any)
log "🔧 Cleaning systemd services..."
SERVICES=(
    "nexus-green"
    "solarnexus"
    "nexus-green-api"
)

for service in "${SERVICES[@]}"; do
    if systemctl list-units --full -all | grep -Fq "$service.service"; then
        warning "Stopping and disabling service: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
        sudo rm -f "/etc/systemd/system/$service.service"
    fi
done

sudo systemctl daemon-reload 2>/dev/null || true

# 4. CLEAN DOCKER CONTAINERS (if any)
if command -v docker &> /dev/null; then
    log "🐳 Cleaning Docker containers..."
    CONTAINERS=$(sudo docker ps -a --filter "name=nexus" --filter "name=solar" -q 2>/dev/null || true)
    if [ ! -z "$CONTAINERS" ]; then
        warning "Stopping and removing Docker containers..."
        sudo docker stop $CONTAINERS 2>/dev/null || true
        sudo docker rm $CONTAINERS 2>/dev/null || true
    fi
    
    IMAGES=$(sudo docker images --filter "reference=*nexus*" --filter "reference=*solar*" -q 2>/dev/null || true)
    if [ ! -z "$IMAGES" ]; then
        warning "Removing Docker images..."
        sudo docker rmi $IMAGES 2>/dev/null || true
    fi
fi

# 5. CLEAN PROCESS LOCKS
log "🔒 Cleaning process locks..."
sudo pkill -f "nexus-green" 2>/dev/null || true
sudo pkill -f "solarnexus" 2>/dev/null || true

# 6. INSTALL SYSTEM DEPENDENCIES
log "📦 Installing system dependencies..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm certbot python3-certbot-nginx

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "📦 Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Create www-data user if needed
if ! id "www-data" &>/dev/null; then
    log "👤 Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
fi

# 7. FRESH HOME INSTALLATION
log "🏠 Starting fresh home directory installation..."
echo ""

# Remove existing home installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    warning "Found existing home installation: $INSTALL_DIR"
    read -p "Remove existing home installation? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        success "Existing home installation removed"
    else
        error "Cannot proceed with existing installation"
        exit 1
    fi
fi

# Clone fresh repository
log "📥 Cloning fresh Nexus Green repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Set proper ownership (should already be correct, but ensure it)
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

# Install dependencies
log "📦 Installing Node.js dependencies..."
npm install

# Set up environment
log "⚙️ Setting up environment configuration..."
if [ -f .env.production ]; then
    cp .env.production .env
    success "Environment configured from .env.production"
else
    log "Creating production environment file..."
    cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20
EOF
    success "Production environment file created"
fi

# Build application
log "🔨 Building production application..."
npm run build

if [ $? -eq 0 ]; then
    success "Build completed successfully!"
    
    # Show build stats
    BUILD_SIZE=$(du -sh dist/ | cut -f1)
    FILE_COUNT=$(find dist/ -type f | wc -l)
    info "Build size: $BUILD_SIZE"
    info "Files: $FILE_COUNT"
else
    error "Build failed!"
    exit 1
fi

# 8. CONFIGURE NGINX FOR HOME DIRECTORY
log "🌐 Configuring Nginx for home directory..."

# Get server IP for configuration
SERVER_IP=$(hostname -I | awk '{print $1}')

sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $SERVER_IP;
    
    root $INSTALL_DIR/dist;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Cache control
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json
        application/xml
        text/xml
        image/svg+xml;
    
    # Main location
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Static assets with long-term caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # API proxy for backend services
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Security: Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|conf|sql|md)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Test Nginx configuration
log "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
    success "Nginx configuration is valid!"
    
    # Start/restart Nginx
    log "🚀 Starting Nginx service..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Wait for service to start
    sleep 3
    
    # Test site accessibility
    log "🧪 Testing site accessibility..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        success "Site is responding successfully!"
        
        # 9. FINAL SUCCESS REPORT
        echo ""
        echo "🎉 DEPLOYMENT COMPLETE!"
        echo "======================"
        echo ""
        success "Nexus Green v4.0.0 is now running!"
        echo ""
        info "🌐 Access your site at:"
        info "   • http://nexus.gonxt.tech"
        info "   • http://localhost"
        info "   • http://$SERVER_IP"
        echo ""
        info "📁 Installation details:"
        info "   • Location: $INSTALL_DIR"
        info "   • Owner: $CURRENT_USER"
        info "   • Build size: $BUILD_SIZE"
        info "   • Files: $FILE_COUNT"
        echo ""
        info "🔧 Management commands:"
        info "   • Rebuild: cd $INSTALL_DIR && npm run build"
        info "   • Update: cd $INSTALL_DIR && git pull && npm install && npm run build"
        info "   • Logs: sudo tail -f /var/log/nginx/access.log"
        info "   • Status: sudo systemctl status nginx"
        echo ""
        info "🔒 Next steps:"
        info "   • Test the site: curl -I http://nexus.gonxt.tech"
        info "   • Set up SSL: sudo certbot --nginx -d nexus.gonxt.tech"
        info "   • Monitor logs: sudo tail -f /var/log/nginx/access.log"
        echo ""
        success "🌞 Nexus Green is ready for production!"
        
    else
        warning "Site built successfully but not responding"
        info "Check Nginx status: sudo systemctl status nginx"
        info "Check site files: ls -la $INSTALL_DIR/dist/"
    fi
else
    error "Nginx configuration test failed!"
    sudo nginx -t
    exit 1
fi

echo ""
log "✨ Clean deployment completed successfully!"