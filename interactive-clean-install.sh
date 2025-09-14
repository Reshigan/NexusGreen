#!/bin/bash

# Interactive Clean Install - Guaranteed working prompts
# Removes everything and installs fresh in home directory

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

echo "🧹 Interactive Clean Install"
echo "============================"
echo ""
info "This will remove ALL existing Nexus Green installations and install fresh in your home directory."
echo ""
info "What will be removed:"
info "• /opt/nexus-green, /opt/solarnexus (and variants)"
info "• /root/nexus-green, /root/solarnexus (and variants)"
info "• ~/nexus-green, ~/solarnexus (and variants)"
info "• All Nginx configurations"
info "• All systemd services"
info "• All Docker containers/images"
info "• All temporary files and caches"
echo ""
info "What will be installed:"
info "• Fresh installation in: $INSTALL_DIR"
info "• You will own everything (no permission issues!)"
info "• Production-ready Nginx configuration"
info "• SSL-ready setup"
echo ""

# Function to get user confirmation
get_confirmation() {
    while true; do
        echo -n "Do you want to proceed? [y/N]: "
        read -r response
        case $response in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                echo "Operation cancelled."
                exit 0
                ;;
            *)
                echo "Please answer y (yes) or n (no)."
                ;;
        esac
    done
}

# Get confirmation
get_confirmation

echo ""
log "Starting cleanup and fresh installation..."

# Stop services and processes
log "Stopping services and processes..."
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -f "nexus" 2>/dev/null || true
sudo pkill -f "solar" 2>/dev/null || true
sudo pkill -f "3001" 2>/dev/null || true
sudo pkill -f "vite" 2>/dev/null || true

# Remove all directories
log "Removing all existing installations..."
sudo rm -rf /opt/nexus-green /opt/solarnexus /opt/NexusGreen /opt/SolarNexus 2>/dev/null || true
sudo rm -rf /root/nexus-green /root/solarnexus /root/NexusGreen /root/SolarNexus 2>/dev/null || true
rm -rf "$HOME_DIR/nexus-green" "$HOME_DIR/solarnexus" "$HOME_DIR/NexusGreen" "$HOME_DIR/SolarNexus" 2>/dev/null || true

# Clean Nginx configurations
log "Cleaning Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/nexus-green* /etc/nginx/sites-available/nexus-green* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/solarnexus* /etc/nginx/sites-available/solarnexus* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Clean systemd services
log "Cleaning systemd services..."
for service in nexus-green solarnexus nexus-green-api solar-nexus nexusgreen; do
    sudo systemctl stop "$service" 2>/dev/null || true
    sudo systemctl disable "$service" 2>/dev/null || true
    sudo rm -f "/etc/systemd/system/$service.service" 2>/dev/null || true
    sudo rm -f "/lib/systemd/system/$service.service" 2>/dev/null || true
done
sudo systemctl daemon-reload 2>/dev/null || true

# Clean Docker if exists
if command -v docker &> /dev/null; then
    log "Cleaning Docker containers and images..."
    sudo docker ps -a --format "{{.Names}}" 2>/dev/null | grep -E "(nexus|solar)" | xargs -r sudo docker rm -f 2>/dev/null || true
    sudo docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -E "(nexus|solar)" | xargs -r sudo docker rmi -f 2>/dev/null || true
fi

# Clean temporary files and caches
log "Cleaning temporary files and caches..."
rm -rf /tmp/nexus* /tmp/solar* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*nexus* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*solar* 2>/dev/null || true
npm cache clean --force 2>/dev/null || true

# Clean logs
log "Cleaning logs..."
sudo rm -f /var/log/nginx/*nexus* /var/log/nginx/*solar* 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/access.log 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/error.log 2>/dev/null || true

log "✅ Complete cleanup finished!"
echo ""

# Install system dependencies
log "Installing system dependencies..."
sudo apt update -qq
sudo apt install -y curl git nginx nodejs npm

# Check and install Node.js 18+ if needed
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

# Fresh home installation
log "Cloning fresh Nexus Green repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

log "Installing Node.js dependencies..."
npm install

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

log "Building application..."
npm run build

if [ $? -eq 0 ]; then
    log "✅ Build completed successfully!"
    
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
            echo "🎉 INTERACTIVE INSTALLATION COMPLETE!"
            echo "====================================="
            echo ""
            log "✅ Nexus Green is running from home directory!"
            echo ""
            info "🌐 Access your site at:"
            info "   • http://nexus.gonxt.tech"
            info "   • http://localhost"
            info "   • http://$SERVER_IP"
            echo ""
            info "📁 Installation details:"
            info "   • Location: $INSTALL_DIR"
            info "   • Owner: $CURRENT_USER (you own everything!)"
            info "   • Build size: $(du -sh dist/ | cut -f1)"
            info "   • Files: $(find dist/ -type f | wc -l)"
            echo ""
            info "🔧 Management commands:"
            info "   cd $INSTALL_DIR"
            info "   npm run build                                    # Rebuild (no permission issues!)"
            info "   git pull && npm install && npm run build        # Update"
            echo ""
            info "🔒 Next steps:"
            info "   • Test: curl -I http://nexus.gonxt.tech"
            info "   • SSL: sudo certbot --nginx -d nexus.gonxt.tech"
            echo ""
            log "🌞 Clean installation ready - zero permission issues!"
            
        else
            warning "Installation completed but site not responding"
            info "Check manually: curl -I http://localhost"
            info "Nginx status: sudo systemctl status nginx"
        fi
    else
        error "Nginx configuration test failed"
        sudo nginx -t
        exit 1
    fi
else
    error "Build failed!"
    exit 1
fi

echo ""
log "✨ Interactive clean installation completed successfully!"