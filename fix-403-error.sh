#!/bin/bash

# Fix 403 Forbidden Error - Nginx Permission Fix
# Fixes permission issues when installation is in /root directory

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "🔧 Fix 403 Forbidden Error"
echo "=========================="
echo ""

# Get current user and directories
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

info "Current user: $CURRENT_USER"
info "Installation directory: $INSTALL_DIR"
echo ""

# Check if installation exists
if [ ! -d "$INSTALL_DIR" ]; then
    error "Installation directory not found: $INSTALL_DIR"
    exit 1
fi

if [ ! -d "$INSTALL_DIR/dist" ]; then
    error "Build directory not found: $INSTALL_DIR/dist"
    exit 1
fi

# Fix permissions
log "Fixing directory permissions..."
chmod -R 755 "$INSTALL_DIR"
chmod -R 644 "$INSTALL_DIR/dist"/*
chmod 755 "$INSTALL_DIR/dist"
find "$INSTALL_DIR/dist" -type d -exec chmod 755 {} \;

# Check nginx user
NGINX_USER=$(ps aux | grep nginx | grep -v root | head -1 | awk '{print $1}' || echo "www-data")
info "Nginx is running as user: $NGINX_USER"

# Option 1: Fix permissions for www-data access
log "Setting up permissions for nginx access..."

# Make sure www-data can access the path
chmod 755 /root
chmod -R 755 "$INSTALL_DIR"
chmod -R 644 "$INSTALL_DIR/dist"/*
find "$INSTALL_DIR/dist" -type d -exec chmod 755 {} \;

# Option 2: Alternative - Copy to /var/www if root access is problematic
if [ "$CURRENT_USER" = "root" ]; then
    warning "Running as root - creating alternative in /var/www for better nginx access"
    
    # Create /var/www/nexus-green as backup location
    sudo mkdir -p /var/www/nexus-green
    sudo cp -r "$INSTALL_DIR/dist"/* /var/www/nexus-green/
    sudo chown -R www-data:www-data /var/www/nexus-green
    sudo chmod -R 755 /var/www/nexus-green
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Create alternative Nginx config
    log "Creating alternative Nginx configuration..."
    sudo tee /etc/nginx/sites-available/nexus-green-alt >/dev/null << EOF
server {
    listen 8080;
    server_name nexus.gonxt.tech localhost $SERVER_IP;
    
    root /var/www/nexus-green;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
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
        text/xml;
    
    # Main location
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # API proxy
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
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Enable alternative site
    sudo ln -sf /etc/nginx/sites-available/nexus-green-alt /etc/nginx/sites-enabled/
    
    info "Alternative site created on port 8080 using /var/www/nexus-green"
fi

# Update main config to use proper permissions
log "Updating main Nginx configuration..."
SERVER_IP=$(hostname -I | awk '{print $1}')

sudo tee /etc/nginx/sites-available/nexus-green >/dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $SERVER_IP;
    
    root $INSTALL_DIR/dist;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
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
        text/xml;
    
    # Main location
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # API proxy
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
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test and reload Nginx
log "Testing Nginx configuration..."
if sudo nginx -t; then
    log "Reloading Nginx..."
    sudo systemctl reload nginx
    
    sleep 2
    
    # Test both ports
    echo ""
    info "Testing main site (port 80)..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log "✅ Main site working on port 80!"
        echo ""
        info "🌐 Access your site at:"
        info "   • http://nexus.gonxt.tech"
        info "   • http://localhost"
        info "   • http://$SERVER_IP"
    else
        warning "Main site still returning $HTTP_CODE"
    fi
    
    if [ -f "/etc/nginx/sites-enabled/nexus-green-alt" ]; then
        echo ""
        info "Testing alternative site (port 8080)..."
        HTTP_CODE_ALT=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
        if [ "$HTTP_CODE_ALT" = "200" ]; then
            log "✅ Alternative site working on port 8080!"
            echo ""
            info "🌐 Alternative access:"
            info "   • http://nexus.gonxt.tech:8080"
            info "   • http://localhost:8080"
            info "   • http://$SERVER_IP:8080"
        else
            warning "Alternative site returning $HTTP_CODE_ALT"
        fi
    fi
    
    echo ""
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE_ALT" = "200" ]; then
        log "🎉 403 Error Fixed! Site is now accessible!"
        echo ""
        info "📁 Installation details:"
        info "   • Main location: $INSTALL_DIR/dist"
        if [ -d "/var/www/nexus-green" ]; then
            info "   • Alternative location: /var/www/nexus-green"
        fi
        info "   • Permissions: Fixed for nginx access"
        echo ""
        info "🔧 If you need to rebuild:"
        info "   cd $INSTALL_DIR && npm run build"
        if [ -d "/var/www/nexus-green" ]; then
            info "   sudo cp -r $INSTALL_DIR/dist/* /var/www/nexus-green/"
        fi
    else
        error "Still having issues. Let's check more details:"
        echo ""
        info "Directory permissions:"
        ls -la "$INSTALL_DIR/dist/" | head -5
        echo ""
        info "Nginx error log:"
        sudo tail -5 /var/log/nginx/error.log
    fi
    
else
    error "Nginx configuration test failed"
    sudo nginx -t
fi

echo ""
log "✨ Permission fix completed!"