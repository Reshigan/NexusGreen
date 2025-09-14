#!/bin/bash

# Nuclear Clean and Deploy - Complete System Reset
# Removes EVERYTHING and deploys fresh in home directory
# Use with caution - this removes all traces of previous installations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

nuclear() {
    echo -e "${MAGENTA}[NUCLEAR]${NC} $1"
}

# Get current user and directories
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$HOME_DIR/nexus-green"

echo ""
echo "☢️  NUCLEAR CLEAN AND DEPLOY ☢️"
echo "================================"
echo ""
nuclear "This will COMPLETELY REMOVE all traces of previous installations!"
nuclear "This includes /opt, /root, Docker containers, services, and configs!"
echo ""
warning "⚠️  This is a destructive operation!"
warning "⚠️  Make sure you have backups of any important data!"
echo ""
read -p "Are you absolutely sure you want to proceed? (type 'NUCLEAR' to confirm): " -r
if [[ ! $REPLY == "NUCLEAR" ]]; then
    info "Operation cancelled. Exiting safely."
    exit 0
fi

echo ""
nuclear "🚨 NUCLEAR CLEANUP INITIATED 🚨"
echo ""

# 1. NUCLEAR DIRECTORY CLEANUP
nuclear "💥 Removing ALL installation directories..."
NUKE_DIRS=(
    "/opt/nexus-green"
    "/opt/solarnexus" 
    "/opt/NexusGreen"
    "/opt/SolarNexus"
    "/root/nexus-green"
    "/root/solarnexus"
    "/root/NexusGreen"
    "/root/SolarNexus"
    "$HOME_DIR/nexus-green"
    "$HOME_DIR/solarnexus"
    "$HOME_DIR/NexusGreen"
    "$HOME_DIR/SolarNexus"
)

for dir in "${NUKE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        nuclear "Nuking: $dir"
        if [[ "$dir" == /opt/* ]] || [[ "$dir" == /root/* ]]; then
            sudo rm -rf "$dir"
        else
            rm -rf "$dir"
        fi
    fi
done

# 2. NUCLEAR NGINX CLEANUP
nuclear "🌐 Nuking ALL Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-available/nexus-green
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-available/solarnexus
sudo rm -f /etc/nginx/sites-enabled/default

# Remove any nginx configs with nexus or solar in the name
find /etc/nginx/sites-available/ -name "*nexus*" -delete 2>/dev/null || true
find /etc/nginx/sites-available/ -name "*solar*" -delete 2>/dev/null || true
find /etc/nginx/sites-enabled/ -name "*nexus*" -delete 2>/dev/null || true
find /etc/nginx/sites-enabled/ -name "*solar*" -delete 2>/dev/null || true

# 3. NUCLEAR SYSTEMD CLEANUP
nuclear "⚙️ Nuking systemd services..."
NUKE_SERVICES=(
    "nexus-green"
    "solarnexus"
    "nexus-green-api"
    "solar-nexus"
    "nexusgreen"
)

for service in "${NUKE_SERVICES[@]}"; do
    if systemctl list-units --full -all | grep -Fq "$service.service"; then
        nuclear "Stopping service: $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
    fi
    sudo rm -f "/etc/systemd/system/$service.service"
    sudo rm -f "/lib/systemd/system/$service.service"
done

sudo systemctl daemon-reload

# 4. NUCLEAR DOCKER CLEANUP
if command -v docker &> /dev/null; then
    nuclear "🐳 Nuking Docker containers and images..."
    
    # Stop and remove all containers with nexus or solar in name
    CONTAINERS=$(sudo docker ps -a --format "table {{.Names}}" | grep -E "(nexus|solar)" | tail -n +2 2>/dev/null || true)
    if [ ! -z "$CONTAINERS" ]; then
        echo "$CONTAINERS" | while read container; do
            nuclear "Stopping container: $container"
            sudo docker stop "$container" 2>/dev/null || true
            sudo docker rm "$container" 2>/dev/null || true
        done
    fi
    
    # Remove all images with nexus or solar in name
    IMAGES=$(sudo docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(nexus|solar)" | tail -n +2 2>/dev/null || true)
    if [ ! -z "$IMAGES" ]; then
        echo "$IMAGES" | while read image; do
            nuclear "Removing image: $image"
            sudo docker rmi "$image" 2>/dev/null || true
        done
    fi
fi

# 5. NUCLEAR PROCESS CLEANUP
nuclear "🔪 Killing ALL related processes..."
sudo pkill -f "nexus" 2>/dev/null || true
sudo pkill -f "solar" 2>/dev/null || true
sudo pkill -f "3001" 2>/dev/null || true
sudo pkill -f "vite" 2>/dev/null || true

# 6. NUCLEAR FILE CLEANUP
nuclear "🗑️ Removing temporary and cache files..."
rm -rf /tmp/nexus* 2>/dev/null || true
rm -rf /tmp/solar* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*nexus* 2>/dev/null || true
rm -rf ~/.npm/_cacache/content-v2/sha512/*solar* 2>/dev/null || true

# 7. NUCLEAR LOG CLEANUP
nuclear "📝 Cleaning logs..."
sudo rm -f /var/log/nginx/*nexus* 2>/dev/null || true
sudo rm -f /var/log/nginx/*solar* 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/access.log 2>/dev/null || true
sudo truncate -s 0 /var/log/nginx/error.log 2>/dev/null || true

# 8. NUCLEAR CRON CLEANUP
nuclear "⏰ Cleaning cron jobs..."
crontab -l 2>/dev/null | grep -v -E "(nexus|solar)" | crontab - 2>/dev/null || true
sudo crontab -l 2>/dev/null | grep -v -E "(nexus|solar)" | sudo crontab - 2>/dev/null || true

success "☢️ NUCLEAR CLEANUP COMPLETE ☢️"
echo ""

# 9. FRESH SYSTEM SETUP
log "🔄 Setting up fresh system..."

# Update system
log "📦 Updating system packages..."
sudo apt update -qq
sudo apt upgrade -y

# Install dependencies
log "📦 Installing fresh dependencies..."
sudo apt install -y curl git nginx nodejs npm certbot python3-certbot-nginx build-essential

# Install latest Node.js
log "📦 Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Create www-data user
if ! id "www-data" &>/dev/null; then
    log "👤 Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
fi

# 10. FRESH HOME INSTALLATION
log "🏠 Starting fresh home installation..."

# Clone repository
log "📥 Cloning fresh repository..."
git clone https://github.com/Reshigan/NexusGreen.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

# Install dependencies
log "📦 Installing dependencies..."
npm cache clean --force
npm install

# Create production environment
log "⚙️ Creating production environment..."
cat > .env << EOF
VITE_APP_NAME=Nexus Green
VITE_APP_VERSION=4.0.0
VITE_API_URL=http://localhost:3001
VITE_ENVIRONMENT=production
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20
EOF

# Build application
log "🔨 Building application..."
npm run build

# 11. CONFIGURE NGINX
log "🌐 Configuring Nginx..."
SERVER_IP=$(hostname -I | awk '{print $1}')

sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << EOF
server {
    listen 80;
    server_name nexus.gonxt.tech localhost $SERVER_IP;
    
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
    
    # Gzip
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
log "🧪 Testing Nginx..."
if sudo nginx -t; then
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    sleep 3
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        echo ""
        echo "🎉 NUCLEAR DEPLOYMENT COMPLETE! 🎉"
        echo "=================================="
        echo ""
        success "Nexus Green v4.0.0 is running fresh!"
        echo ""
        info "🌐 Access at:"
        info "   • http://nexus.gonxt.tech"
        info "   • http://localhost"
        info "   • http://$SERVER_IP"
        echo ""
        info "📁 Clean installation: $INSTALL_DIR"
        info "👤 Owner: $CURRENT_USER (no permission issues!)"
        echo ""
        info "🔧 Commands:"
        info "   • Rebuild: cd $INSTALL_DIR && npm run build"
        info "   • Update: cd $INSTALL_DIR && git pull && npm install && npm run build"
        echo ""
        success "🌞 Fresh, clean, and ready for production!"
    else
        warning "Built but not responding - check manually"
    fi
else
    error "Nginx test failed"
    sudo nginx -t
fi