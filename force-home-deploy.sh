#!/bin/bash

# Force Home Directory Deployment
# Bypasses existing installations and creates working home deployment

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

echo "🚀 Force Home Directory Deployment"
echo "=================================="
echo ""
info "This will create a working Nexus Green installation in your home directory"
info "It will NOT touch your existing /opt installations"
echo ""
info "User: $CURRENT_USER"
info "Target: $INSTALL_DIR"
info "Port: 8080 (to avoid conflicts)"
echo ""

# Remove existing home installation without asking
if [ -d "$INSTALL_DIR" ]; then
    log "Removing existing home installation..."
    rm -rf "$INSTALL_DIR"
fi

# Install dependencies quickly
log "Installing system dependencies..."
sudo apt update -qq >/dev/null 2>&1
sudo apt install -y curl git nginx nodejs npm >/dev/null 2>&1

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - >/dev/null 2>&1
    sudo apt-get install -y nodejs >/dev/null 2>&1
fi

# Clone and setup
log "Cloning repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR" >/dev/null 2>&1
cd "$INSTALL_DIR"

log "Installing dependencies..."
npm install >/dev/null 2>&1

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

log "Building application..."
npm run build >/dev/null 2>&1

if [ $? -eq 0 ]; then
    log "✅ Build successful!"
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Create Nginx config for port 8080
    log "Configuring Nginx on port 8080..."
    sudo tee /etc/nginx/sites-available/nexus-green-home >/dev/null << EOF
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
    
    # Enable site
    sudo rm -f /etc/nginx/sites-enabled/nexus-green-home
    sudo ln -sf /etc/nginx/sites-available/nexus-green-home /etc/nginx/sites-enabled/
    
    # Test and reload Nginx
    if sudo nginx -t >/dev/null 2>&1; then
        sudo systemctl reload nginx >/dev/null 2>&1
        
        sleep 2
        
        # Test the site
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
            echo ""
            echo "🎉 SUCCESS! Home Installation Complete!"
            echo "======================================="
            echo ""
            log "✅ Nexus Green is running from your home directory!"
            echo ""
            info "🌐 Access at:"
            info "   • http://localhost:8080"
            info "   • http://$SERVER_IP:8080"
            echo ""
            info "📁 Location: $INSTALL_DIR"
            info "👤 Owner: $CURRENT_USER"
            info "🔧 No permission issues!"
            echo ""
            info "🛠️ Commands:"
            info "   cd $INSTALL_DIR"
            info "   npm run build    # Rebuild"
            info "   git pull && npm install && npm run build    # Update"
            echo ""
            info "📝 This installation:"
            info "   • Runs on port 8080 (no conflicts)"
            info "   • Doesn't touch your /opt installations"
            info "   • Is owned by you (no permission issues)"
            info "   • Can be easily updated and maintained"
            echo ""
            log "🌞 Ready to use!"
            
        else
            warning "Built successfully but not responding"
            info "Try: curl -I http://localhost:8080"
        fi
    else
        error "Nginx configuration failed"
        sudo nginx -t
    fi
else
    error "Build failed!"
    exit 1
fi