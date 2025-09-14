#!/bin/bash

# Complete Build and Deploy Script for Nexus Green
# Handles permissions, build, and deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

log "🚀 Starting complete build and deployment for Nexus Green..."

# Get current user
CURRENT_USER=$(whoami)
log "Current user: $CURRENT_USER"

# Navigate to project directory
cd /opt/nexus-green

# Fix ownership and permissions
log "Fixing ownership and permissions..."
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/nexus-green/
chmod -R 755 /opt/nexus-green/

# Remove problematic dist directory
log "Cleaning existing build..."
rm -rf dist/
rm -rf node_modules/.vite/ 2>/dev/null || true

# Clean npm cache
log "Cleaning npm cache..."
npm cache clean --force

# Install dependencies
log "Installing dependencies..."
npm install

# Create environment file
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
    
    # Set proper permissions for Nginx
    log "Setting Nginx permissions..."
    sudo chown -R www-data:www-data dist/
    sudo chmod -R 755 dist/
    
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
            log "Site is accessible at:"
            log "  - http://nexus.gonxt.tech"
            log "  - http://localhost"
            
            # Show site status
            echo ""
            log "Site status:"
            curl -I http://localhost 2>/dev/null | head -1 || echo "Local test failed"
            
        else
            warning "Site build successful but not responding on localhost"
            log "Check Nginx status: sudo systemctl status nginx"
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