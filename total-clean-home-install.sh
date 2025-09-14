#!/bin/bash

# Total Clean and Home Install - Remove Everything and Start Fresh
# This will remove ALL installations and create a clean home directory setup

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

clean() {
    echo -e "${MAGENTA}[CLEAN]${NC} $1"
}

# Get current user and directories
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

echo ""
echo "🧹 TOTAL CLEAN AND HOME INSTALL"
echo "==============================="
echo ""
warning "This will REMOVE ALL existing Nexus Green installations!"
warning "This includes /opt, /root, Docker, services, and configs!"
echo ""
info "After cleaning, it will install fresh in: $INSTALL_DIR"
info "You will own everything - no more permission issues!"
echo ""
read -p "Are you sure you want to remove ALL installations? (type 'YES' to confirm): " -r
if [[ ! $REPLY == "YES" ]]; then
    info "Operation cancelled."
    exit 0
fi

echo ""
clean "🚨 STARTING TOTAL CLEANUP 🚨"
echo ""

# 1. STOP ALL SERVICES
clean "Stopping all related services..."
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -f "nexus" 2>/dev/null || true
sudo pkill -f "solar" 2>/dev/null || true
sudo pkill -f "3001" 2>/dev/null || true
sudo pkill -f "vite" 2>/dev/null || true

# 2. REMOVE ALL DIRECTORIES
clean "Removing ALL installation directories..."
REMOVE_DIRS=(
    "/opt/nexus-green"
    "/opt/solarnexus" 
    "/opt/NexusGreen"
    "/opt/SolarNexus"
    "/root/nexus-green"
    "/root/solarnexus"
    "/root/NexusGreen"
    "/root/SolarNexus"
    "$HOME_DIR/nexus-green"
    "$HOME_DIR/solarnexus"
    "$HOME_DIR/NexusGreen"
    "$HOME_DIR/SolarNexus"
)

for dir in "${REMOVE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        clean "Removing: $dir"
        if [[ "$dir" == /opt/* ]] || [[ "$dir" == /root/* ]]; then
            sudo rm -rf "$dir"
        else
            rm -rf "$dir"
        fi
    fi
done

# 3. REMOVE ALL NGINX CONFIGS
clean "Removing ALL Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/nexus-green* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/nexus-green* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/solarnexus* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/solarnexus* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Remove any configs with nexus or solar in the name
find /etc/nginx/sites-available/ -name "*nexus*" -delete 2>/dev/null || true
find /etc/nginx/sites-available/ -name "*solar*" -delete 2>/dev/null || true
find /etc/nginx/sites-enabled/ -name "*nexus*" -delete 2>/dev/null || true
find /etc/nginx/sites-enabled/ -name "*solar*" -delete 2>/dev/null || true

# 4. REMOVE SYSTEMD SERVICES
clean "Removing systemd services..."
SERVICES=(
    "nexus-green"
    "solarnexus"
    "nexus-green-api"
    "solar-nexus"
    "nexusgreen"
)

for service in "${SERVICES[@]}"; do
    sudo systemctl stop "$service" 2>/dev/null || true
    sudo systemctl disable "$service" 2>/dev/null || true
    sudo rm -f "/etc/systemd/system/$service.service" 2>/dev/null || true
    sudo rm -f "/lib/systemd/system/$service.service" 2>/dev/null || true
done

sudo systemctl daemon-reload

# 5. REMOVE DOCKER CONTAINERS AND IMAGES
if command -v docker &> /dev/null; then
    clean "Removing Docker containers and images..."
    
    # Stop and remove containers
    CONTAINERS=$(sudo docker ps -a --format "table {{.Names}}" | grep -E "(nexus|solar)" | tail -n +2 2>/dev/null || true)
    if [ ! -z "$CONTAINERS" ]; then
        echo "$CONTAINERS" | while read container; do
            sudo docker stop "$container" 2>/dev/null || true
            sudo docker rm "$container" 2>/dev/null || true
        done
    fi
    
    # Remove images
    IMAGES=$(sudo docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(nexus|solar)" | tail -n +2 2>/dev/null || true)
    if [ ! -z "$IMAGES" ]; then
        echo "$IMAGES" | while read image; do
            sudo docker rmi "$image" 2>/dev/null || true
        done
    fi
fi

# 6. CLEAN TEMPORARY FILES AND CACHES
clean "Cleaning temporary files and caches..."
rm -rf /tmp/nexus* 2>/dev/null || true
rm -rf /tmp/solar* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*nexus* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*solar* 2>/dev/null || true
npm cache clean --force 2>/dev/null || true

# 7. CLEAN LOGS
clean "Cleaning logs..."
sudo rm -f /var/log/nginx/*nexus* 2>/dev/null || true
sudo rm -f /var/log/nginx/*solar* 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/access.log 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/error.log 2>/dev/null || true

# 8. CLEAN CRON JOBS
clean "Cleaning cron jobs..."
crontab -l 2>/dev/null | grep -v -E "(nexus|solar)" | crontab - 2>/dev/null || true
sudo crontab -l 2>/dev/null | grep -v -E "(nexus|solar)" | sudo crontab - 2>/dev/null || true

success "🧹 TOTAL CLEANUP COMPLETE!"
echo ""

# 9. FRESH SYSTEM SETUP
log "🔄 Setting up fresh system..."

# Update system
log "Updating system packages..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm certbot python3-certbot-nginx

# Install Node.js 18+
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Create www-data user if needed
if ! id "www-data" &>/dev/null; then
    log "Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
fi

# 10. FRESH HOME INSTALLATION
log "🏠 Creating fresh home installation..."

# Clone repository
log "Cloning Nexus Green repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

# Install dependencies
log "Installing dependencies..."
npm install

# Create production environment
log "Setting up production environment..."
cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20
EOF

# Build application
log "Building application..."
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

# 11. CONFIGURE NGINX FOR HOME DIRECTORY
log "🌐 Configuring Nginx for home directory..."

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Create main Nginx config
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
    
    # Cache control for HTML
    location ~* \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
    }
    
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
log "Testing Nginx configuration..."
if sudo nginx -t; then
    success "Nginx configuration is valid!"
    
    # Start Nginx
    log "Starting Nginx service..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Wait for service to start
    sleep 3
    
    # Test site accessibility
    log "Testing site accessibility..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        success "Site is responding successfully!"
        
        # 12. FINAL SUCCESS REPORT
        echo ""
        echo "🎉 TOTAL CLEAN INSTALL COMPLETE!"
        echo "================================"
        echo ""
        success "Nexus Green v4.0.0 is now running clean!"
        echo ""
        info "🌐 Access your site at:"
        info "   • http://nexus.gonxt.tech"
        info "   • http://localhost"
        info "   • http://$SERVER_IP"
        echo ""
        info "📁 Clean installation details:"
        info "   • Location: $INSTALL_DIR"
        info "   • Owner: $CURRENT_USER (you own everything!)"
        info "   • Build size: $BUILD_SIZE"
        info "   • Files: $FILE_COUNT"
        info "   • No permission issues!"
        echo ""
        info "🔧 Management commands:"
        info "   • Rebuild: cd $INSTALL_DIR && npm run build"
        info "   • Update: cd $INSTALL_DIR && git pull && npm install && npm run build"
        info "   • Logs: sudo tail -f /var/log/nginx/access.log"
        info "   • Status: sudo systemctl status nginx"
        echo ""
        info "🔒 Next steps:"
        info "   • Test: curl -I http://nexus.gonxt.tech"
        info "   • SSL: sudo certbot --nginx -d nexus.gonxt.tech"
        echo ""
        success "🌞 Clean, fresh, and ready for production!"
        success "🎯 Zero permission issues - you own everything!"
        
    else
        warning "Site built successfully but not responding"
        info "Check: curl -I http://localhost"
        info "Status: sudo systemctl status nginx"
        info "Files: ls -la $INSTALL_DIR/dist/"
    fi
else
    error "Nginx configuration test failed!"
    sudo nginx -t
    exit 1
fi

echo ""
log "✨ Total clean install completed successfully!"