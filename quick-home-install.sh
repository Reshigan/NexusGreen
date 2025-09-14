#!/bin/bash

# Quick Nexus Green Home Installation
# One-line installer for home directory deployment

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Get installation directory
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

echo "🏠 Nexus Green Quick Home Installation"
echo "Installing to: $INSTALL_DIR"
echo ""

# Parse command line arguments
COMMAND=${1:-install}

case $COMMAND in
    "clean-install")
        log "Performing clean installation..."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        sudo rm -rf /opt/nexus-green /opt/solarnexus 2>/dev/null || true
        ;;
    "install")
        log "Performing standard installation..."
        ;;
    *)
        echo "Usage: $0 [install|clean-install]"
        exit 1
        ;;
esac

# Install system dependencies
log "Installing system dependencies..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm >/dev/null 2>&1

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - >/dev/null 2>&1
    sudo apt-get install -y nodejs >/dev/null 2>&1
fi

# Clone repository
if [ ! -d "$INSTALL_DIR" ]; then
    log "Cloning Nexus Green repository..."
    git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR" >/dev/null 2>&1
else
    log "Updating existing repository..."
    cd "$INSTALL_DIR"
    git pull origin main >/dev/null 2>&1
fi

cd "$INSTALL_DIR"

# Install dependencies and build
log "Installing dependencies..."
npm install >/dev/null 2>&1

log "Creating environment configuration..."
if [ -f .env.production ]; then
    cp .env.production .env
else
    cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
EOF
fi

log "Building application..."
npm run build >/dev/null 2>&1

# Create www-data user if needed
if ! id "www-data" &>/dev/null; then
    log "Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data >/dev/null 2>&1
fi

# Configure Nginx
log "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/nexus-green >/dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $(hostname -I | awk '{print $1}');
    
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
sudo rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/solarnexus /etc/nginx/sites-enabled/nexus-green
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Test and start Nginx
log "Testing Nginx configuration..."
if sudo nginx -t >/dev/null 2>&1; then
    sudo systemctl enable nginx >/dev/null 2>&1
    sudo systemctl restart nginx >/dev/null 2>&1
    
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        echo ""
        echo "🎉 Installation Complete!"
        echo ""
        echo "✅ Nexus Green is now running at:"
        echo "   • http://nexus.gonxt.tech"
        echo "   • http://localhost"
        echo "   • http://$(hostname -I | awk '{print $1}')"
        echo ""
        echo "📁 Installed in: $INSTALL_DIR"
        echo "🔧 To rebuild: cd $INSTALL_DIR && npm run build"
        echo "🔄 To update: cd $INSTALL_DIR && git pull && npm install && npm run build"
        echo ""
        echo "🔒 Next: Set up SSL with 'sudo certbot --nginx -d nexus.gonxt.tech'"
        echo ""
        echo "🌞 Nexus Green v4.0.0 is ready!"
    else
        warning "Installation completed but site not responding"
    fi
else
    error "Nginx configuration failed"
    sudo nginx -t
    exit 1
fi