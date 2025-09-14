#!/bin/bash

# Simple Clean Install - Remove all and install in home
# Simplified confirmation process

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

echo "🧹 Clean Install - Remove All and Install in Home"
echo "================================================="
echo ""
info "This will:"
info "• Remove ALL existing installations (/opt, /root, home)"
info "• Install fresh in: $INSTALL_DIR"
info "• You will own everything - no permission issues!"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Operation cancelled."
    exit 0
fi

echo ""
log "Starting cleanup and fresh install..."

# Stop services and processes
log "Stopping services..."
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -f "nexus" 2>/dev/null || true
sudo pkill -f "solar" 2>/dev/null || true
sudo pkill -f "3001" 2>/dev/null || true

# Remove directories
log "Removing old installations..."
sudo rm -rf /opt/nexus-green /opt/solarnexus /opt/NexusGreen /opt/SolarNexus 2>/dev/null || true
sudo rm -rf /root/nexus-green /root/solarnexus /root/NexusGreen /root/SolarNexus 2>/dev/null || true
rm -rf "$HOME_DIR/nexus-green" "$HOME_DIR/solarnexus" "$HOME_DIR/NexusGreen" "$HOME_DIR/SolarNexus" 2>/dev/null || true

# Clean Nginx configs
log "Cleaning Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/nexus-green* /etc/nginx/sites-available/nexus-green* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/solarnexus* /etc/nginx/sites-available/solarnexus* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Clean systemd services
log "Cleaning services..."
for service in nexus-green solarnexus nexus-green-api; do
    sudo systemctl stop "$service" 2>/dev/null || true
    sudo systemctl disable "$service" 2>/dev/null || true
    sudo rm -f "/etc/systemd/system/$service.service" 2>/dev/null || true
done
sudo systemctl daemon-reload 2>/dev/null || true

# Clean Docker if exists
if command -v docker &> /dev/null; then
    log "Cleaning Docker containers..."
    sudo docker ps -a --format "{{.Names}}" | grep -E "(nexus|solar)" | xargs -r sudo docker rm -f 2>/dev/null || true
    sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(nexus|solar)" | xargs -r sudo docker rmi -f 2>/dev/null || true
fi

# Clean temp files
log "Cleaning temporary files..."
rm -rf /tmp/nexus* /tmp/solar* 2>/dev/null || true
npm cache clean --force 2>/dev/null || true

log "✅ Cleanup complete!"
echo ""

# Install dependencies
log "Installing system dependencies..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm

# Install Node.js 18+ if needed
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

# Fresh installation
log "Cloning fresh repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

log "Installing dependencies..."
npm install

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
npm run build

if [ $? -eq 0 ]; then
    log "✅ Build successful!"
    
    # Configure Nginx
    log "Configuring Nginx..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    sudo tee /etc/nginx/sites-available/nexus-green >/dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $SERVER_IP;
    
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
    sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/
    
    # Test and start Nginx
    if sudo nginx -t; then
        sudo systemctl enable nginx
        sudo systemctl restart nginx
        
        sleep 2
        
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
            echo ""
            echo "🎉 SUCCESS! Clean Installation Complete!"
            echo "========================================"
            echo ""
            log "✅ Nexus Green is running from home directory!"
            echo ""
            info "🌐 Access at:"
            info "   • http://nexus.gonxt.tech"
            info "   • http://localhost"
            info "   • http://$SERVER_IP"
            echo ""
            info "📁 Location: $INSTALL_DIR"
            info "👤 Owner: $CURRENT_USER (you own everything!)"
            echo ""
            info "🔧 Commands:"
            info "   cd $INSTALL_DIR"
            info "   npm run build    # Rebuild (no permission issues!)"
            info "   git pull && npm install && npm run build    # Update"
            echo ""
            info "🔒 Next steps:"
            info "   • Test: curl -I http://nexus.gonxt.tech"
            info "   • SSL: sudo certbot --nginx -d nexus.gonxt.tech"
            echo ""
            log "🌞 Clean installation ready - zero permission issues!"
            
        else
            warning "Built but not responding - check manually"
        fi
    else
        error "Nginx configuration failed"
        sudo nginx -t
    fi
else
    error "Build failed!"
    exit 1
fi