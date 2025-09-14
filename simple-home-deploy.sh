#!/bin/bash

# Simple Home Directory Deployment
# Works alongside existing installations without removing them

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

echo "🏠 Simple Home Directory Deployment"
echo "==================================="
echo ""
info "User: $CURRENT_USER"
info "Home: $HOME_DIR"
info "Target: $INSTALL_DIR"
echo ""

# Check if home installation already exists
if [ -d "$INSTALL_DIR" ]; then
    warning "Home installation already exists: $INSTALL_DIR"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing existing home installation..."
        rm -rf "$INSTALL_DIR"
    else
        info "Updating existing installation..."
        cd "$INSTALL_DIR"
        log "Pulling latest changes..."
        git pull origin main
        log "Installing dependencies..."
        npm install
        log "Building application..."
        npm run build
        
        # Update Nginx config
        log "Updating Nginx configuration..."
        SERVER_IP=$(hostname -I | awk '{print $1}')
        sudo tee /etc/nginx/sites-available/nexus-green-home > /dev/null << EOF
server {
    listen 8080;
    server_name localhost $SERVER_IP;
    
    root $INSTALL_DIR/dist;
    index index.html;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
        
        # Enable the site on port 8080 (to avoid conflicts)
        sudo rm -f /etc/nginx/sites-enabled/nexus-green-home
        sudo ln -sf /etc/nginx/sites-available/nexus-green-home /etc/nginx/sites-enabled/
        
        # Test and reload Nginx
        if sudo nginx -t; then
            sudo systemctl reload nginx
            log "✅ Update complete!"
            echo ""
            info "🌐 Home installation accessible at:"
            info "   • http://localhost:8080"
            info "   • http://$SERVER_IP:8080"
            echo ""
            info "📁 Location: $INSTALL_DIR"
            info "🔧 Rebuild: cd $INSTALL_DIR && npm run build"
        else
            error "Nginx configuration failed"
        fi
        exit 0
    fi
fi

# Fresh installation
log "Installing system dependencies..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Clone repository
log "Cloning Nexus Green repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

# Install dependencies
log "Installing dependencies..."
npm install

# Create environment
log "Setting up environment..."
if [ -f .env.production ]; then
    cp .env.production .env
else
    cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20
EOF
fi

# Build application
log "Building application..."
npm run build

if [ $? -eq 0 ]; then
    log "✅ Build successful!"
    
    # Configure Nginx on port 8080 to avoid conflicts
    log "Configuring Nginx on port 8080..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    sudo tee /etc/nginx/sites-available/nexus-green-home > /dev/null << EOF
server {
    listen 8080;
    server_name localhost $SERVER_IP;
    
    root $INSTALL_DIR/dist;
    index index.html;
    
    # Security headers
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
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/nexus-green-home /etc/nginx/sites-enabled/
    
    # Test and start Nginx
    log "Testing Nginx configuration..."
    if sudo nginx -t; then
        sudo systemctl enable nginx
        sudo systemctl reload nginx
        
        sleep 2
        
        # Test the site
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
            echo ""
            echo "🎉 Home Installation Complete!"
            echo "=============================="
            echo ""
            log "✅ Nexus Green is running from home directory!"
            echo ""
            info "🌐 Access your home installation at:"
            info "   • http://localhost:8080"
            info "   • http://$SERVER_IP:8080"
            echo ""
            info "📁 Installation: $INSTALL_DIR"
            info "👤 Owner: $CURRENT_USER (no permission issues!)"
            echo ""
            info "🔧 Management:"
            info "   • Rebuild: cd $INSTALL_DIR && npm run build"
            info "   • Update: cd $INSTALL_DIR && git pull && npm install && npm run build"
            info "   • Logs: sudo tail -f /var/log/nginx/access.log"
            echo ""
            info "📝 Notes:"
            info "   • This runs on port 8080 to avoid conflicts with existing installations"
            info "   • Your existing /opt installations are untouched"
            info "   • This is your personal, permission-free installation"
            echo ""
            log "🌞 Home installation ready!"
            
        else
            warning "Installation completed but not responding on port 8080"
            info "Check: curl -I http://localhost:8080"
        fi
    else
        error "Nginx configuration test failed"
        sudo nginx -t
    fi
else
    error "Build failed!"
    exit 1
fi