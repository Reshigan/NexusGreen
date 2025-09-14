#!/bin/bash

# Check and Continue Installation
# Checks current status and continues/completes the installation

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

# Get current user and directories
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

echo "🔍 Checking Installation Status"
echo "==============================="
echo ""
info "Current user: $CURRENT_USER"
info "Home directory: $HOME_DIR"
info "Target installation: $INSTALL_DIR"
echo ""

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ]; then
    log "Installation directory exists: $INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Check if it's a git repository
    if [ -d ".git" ]; then
        log "Git repository found"
        
        # Check if node_modules exists
        if [ -d "node_modules" ]; then
            log "Dependencies already installed"
        else
            log "Installing dependencies..."
            npm install
        fi
        
        # Check if dist directory exists
        if [ -d "dist" ]; then
            log "Build directory exists"
            BUILD_SIZE=$(du -sh dist/ | cut -f1)
            FILE_COUNT=$(find dist/ -type f | wc -l)
            info "Build size: $BUILD_SIZE, Files: $FILE_COUNT"
        else
            log "Building application..."
            npm run build
        fi
        
    else
        warning "Directory exists but not a git repository - removing and reinstalling"
        cd "$HOME_DIR"
        rm -rf "$INSTALL_DIR"
        log "Cloning fresh repository..."
        git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
        log "Installing dependencies..."
        npm install
        log "Building application..."
        npm run build
    fi
else
    log "Creating fresh installation..."
    git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    log "Installing dependencies..."
    npm install
    log "Building application..."
    npm run build
fi

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR" 2>/dev/null || true

# Create environment file
log "Setting up environment..."
cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20
EOF

# Check if build was successful
if [ -d "dist" ] && [ "$(find dist/ -name "*.html" | wc -l)" -gt 0 ]; then
    log "✅ Build successful!"
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Configure Nginx
    log "Configuring Nginx..."
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
    
    # Security: Deny sensitive files
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
    
    # Enable the site
    sudo rm -f /etc/nginx/sites-enabled/nexus-green
    sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/
    
    # Test and start Nginx
    log "Testing and starting Nginx..."
    if sudo nginx -t; then
        sudo systemctl enable nginx
        sudo systemctl restart nginx
        
        # Wait for service to start
        sleep 3
        
        # Test site accessibility
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
            echo ""
            echo "🎉 INSTALLATION COMPLETE!"
            echo "========================="
            echo ""
            log "✅ Nexus Green is running successfully!"
            echo ""
            info "🌐 Access your site at:"
            info "   • http://nexus.gonxt.tech"
            info "   • http://localhost"
            info "   • http://$SERVER_IP"
            echo ""
            info "📁 Installation details:"
            info "   • Location: $INSTALL_DIR"
            info "   • Owner: $CURRENT_USER"
            info "   • Build size: $(du -sh dist/ | cut -f1)"
            info "   • Files: $(find dist/ -type f | wc -l)"
            echo ""
            info "🔧 Management commands:"
            info "   cd $INSTALL_DIR"
            info "   npm run build                                    # Rebuild"
            info "   git pull && npm install && npm run build        # Update"
            echo ""
            info "🔒 Next steps:"
            info "   • Test: curl -I http://nexus.gonxt.tech"
            info "   • SSL: sudo certbot --nginx -d nexus.gonxt.tech"
            echo ""
            log "🌞 Installation ready and working!"
            
        else
            warning "Installation completed but site not responding"
            info "Checking status..."
            echo ""
            info "Nginx status:"
            sudo systemctl status nginx --no-pager -l
            echo ""
            info "Nginx test:"
            sudo nginx -t
            echo ""
            info "Files in dist:"
            ls -la "$INSTALL_DIR/dist/" | head -10
            echo ""
            info "Manual test: curl -I http://localhost"
        fi
    else
        error "Nginx configuration test failed"
        sudo nginx -t
        exit 1
    fi
else
    error "Build failed or incomplete!"
    info "Checking build directory..."
    ls -la "$INSTALL_DIR/" || true
    ls -la "$INSTALL_DIR/dist/" 2>/dev/null || echo "No dist directory found"
    exit 1
fi

echo ""
log "✨ Check and continue completed!"