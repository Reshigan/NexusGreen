#!/bin/bash

# Nexus Green Home Installation Script
# Installs in user's home directory to avoid permission issues

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

log "🏠 Installing Nexus Green in home directory..."
info "User: $CURRENT_USER"
info "Home: $HOME_DIR"
info "Install path: $INSTALL_DIR"

# Check for existing installations and clean up
log "Checking for existing installations..."
if [ -d "/opt/nexus-green" ]; then
    warning "Found installation in /opt/nexus-green"
    read -p "Remove /opt/nexus-green installation? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing /opt/nexus-green..."
        sudo rm -rf /opt/nexus-green
    fi
fi

if [ -d "/opt/solarnexus" ]; then
    warning "Found old installation in /opt/solarnexus"
    read -p "Remove /opt/solarnexus installation? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing /opt/solarnexus..."
        sudo rm -rf /opt/solarnexus
    fi
fi

if [ -d "$INSTALL_DIR" ]; then
    warning "Found existing installation in $INSTALL_DIR"
    read -p "Remove existing home installation? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
fi

# Install system dependencies
log "Installing system dependencies..."
sudo apt update
sudo apt install -y curl git nginx nodejs npm

# Install Node.js 18+ if needed
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
if [ "$NODE_VERSION" -lt 18 ]; then
    log "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Clone the repository
log "Cloning Nexus Green repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Install dependencies
log "Installing Node.js dependencies..."
npm install

# Set up environment
log "Setting up environment configuration..."
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

# Build the application
log "Building application..."
npm run build

# Create www-data user if needed
if ! id "www-data" &>/dev/null; then
    log "Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
fi

# Configure Nginx
log "Configuring Nginx..."
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

# Remove old configurations and enable new one
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Test and reload Nginx
log "Testing Nginx configuration..."
if sudo nginx -t; then
    log "Reloading Nginx..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Test the site
    sleep 2
    log "Testing site accessibility..."
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        log "🎉 Installation successful!"
        echo ""
        log "✅ Nexus Green is now accessible at:"
        log "   - http://nexus.gonxt.tech"
        log "   - http://localhost"
        log "   - http://$(hostname -I | awk '{print $1}')"
        echo ""
        log "📁 Installation directory: $INSTALL_DIR"
        log "🔧 To rebuild: cd $INSTALL_DIR && npm run build"
        log "🔄 To update: cd $INSTALL_DIR && git pull && npm install && npm run build"
        echo ""
        log "🔒 Next steps:"
        log "   1. Test the site: curl -I http://nexus.gonxt.tech"
        log "   2. Set up SSL: sudo certbot --nginx -d nexus.gonxt.tech"
        echo ""
        log "🌞 Nexus Green v4.0.0 is ready for production!"
        
    else
        warning "Installation completed but site not responding"
        log "Check Nginx status: sudo systemctl status nginx"
        log "Check site files: ls -la $INSTALL_DIR/dist/"
    fi
else
    error "Nginx configuration test failed!"
    sudo nginx -t
    exit 1
fi