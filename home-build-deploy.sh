#!/bin/bash

# Nexus Green Home Build and Deploy Script
# For installations in user's home directory

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Get current user and home directory
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

log "🚀 Building and deploying Nexus Green from home directory..."
info "User: $CURRENT_USER"
info "Install path: $INSTALL_DIR"

# Check if installation exists
if [ ! -d "$INSTALL_DIR" ]; then
    error "Nexus Green not found in $INSTALL_DIR"
    log "Please run the installation script first:"
    log "curl -fsSL https://raw.githubusercontent.com/Reshigan/NexusGreen/main/home-install.sh | bash"
    exit 1
fi

# Navigate to installation directory
cd "$INSTALL_DIR"

# Update from repository
log "Updating from repository..."
git pull origin main

# Clean previous build
log "Cleaning previous build..."
rm -rf dist/
rm -rf node_modules/.vite/ 2>/dev/null || true

# Clean npm cache
log "Cleaning npm cache..."
npm cache clean --force

# Install/update dependencies
log "Installing dependencies..."
npm install

# Set up environment
log "Setting up environment..."
if [ ! -f .env ]; then
    if [ -f .env.production ]; then
        cp .env.production .env
        log "Copied .env.production to .env"
    else
        log "Creating basic .env file..."
        cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
EOF
    fi
fi

# Build the application
log "Building application..."
npm run build

if [ $? -eq 0 ]; then
    log "✅ Build successful!"
    
    # Update Nginx configuration with current path
    log "Updating Nginx configuration..."
    sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $(hostname -I | awk '{print $1}');
    
    root $INSTALL_DIR/dist;
    index index.html;
    
    # Basic security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
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
    
    # API proxy (if backend is running)
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
    
    # Security: Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|conf)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Test Nginx configuration
    log "Testing Nginx configuration..."
    if sudo nginx -t; then
        log "Reloading Nginx..."
        sudo systemctl reload nginx
        
        # Test the site
        log "Testing site accessibility..."
        sleep 2
        
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
            log "🎉 Deployment successful!"
            echo ""
            log "✅ Nexus Green is accessible at:"
            log "   - http://nexus.gonxt.tech"
            log "   - http://localhost"
            log "   - http://$(hostname -I | awk '{print $1}')"
            echo ""
            log "📊 Build information:"
            log "   - Build size: $(du -sh dist/ | cut -f1)"
            log "   - Files: $(find dist/ -type f | wc -l) files"
            echo ""
            log "🔧 Management commands:"
            log "   - Rebuild: cd $INSTALL_DIR && npm run build"
            log "   - Update: cd $INSTALL_DIR && git pull && npm install && npm run build"
            log "   - Logs: sudo tail -f /var/log/nginx/access.log"
            
        else
            warning "Build successful but site not responding on localhost"
            log "Check Nginx status: sudo systemctl status nginx"
            log "Check build files: ls -la $INSTALL_DIR/dist/"
        fi
    else
        error "Nginx configuration test failed"
        sudo nginx -t
    fi
    
else
    error "Build failed!"
    exit 1
fi

log "🌞 Nexus Green deployment complete!"