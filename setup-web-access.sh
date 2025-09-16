#!/bin/bash

# =============================================================================
# NEXUS GREEN - WEB ACCESS SETUP SCRIPT
# =============================================================================
# This script sets up secure web access for remote assistance with production deployment
# Compatible with: Ubuntu 20.04+ on AWS EC2
# Usage: sudo ./setup-web-access.sh
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get the actual user (not root when using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" = "root" ]; then
    ACTUAL_USER="ubuntu"  # Default for AWS EC2
fi

print_status "Setting up web access for user: $ACTUAL_USER"

# =============================================================================
# STEP 1: SYSTEM UPDATES AND DEPENDENCIES
# =============================================================================

print_status "Step 1: Installing system dependencies..."

# Update system
apt update -y

# Install required packages
apt install -y \
    curl \
    wget \
    unzip \
    nginx \
    nodejs \
    npm \
    python3 \
    python3-pip \
    tmux \
    htop \
    git \
    ufw \
    certbot \
    python3-certbot-nginx

print_success "✅ System dependencies installed"

# =============================================================================
# STEP 2: INSTALL TTYD (WEB TERMINAL)
# =============================================================================

print_status "Step 2: Installing ttyd web terminal..."

# Download and install ttyd
TTYD_VERSION="1.7.3"
wget -O /tmp/ttyd.tar.gz "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"
chmod +x /tmp/ttyd.x86_64
mv /tmp/ttyd.x86_64 /usr/local/bin/ttyd

print_success "✅ ttyd web terminal installed"

# =============================================================================
# STEP 3: CREATE WEB ACCESS USER AND SECURITY
# =============================================================================

print_status "Step 3: Setting up web access security..."

# Generate random password for web access
WEB_ACCESS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
WEB_ACCESS_PORT=7681

# Create web access credentials file
cat > /etc/ttyd-credentials << EOF
# Web Access Credentials for NexusGreen Production Support
# Generated: $(date)
Username: nexus-support
Password: $WEB_ACCESS_PASSWORD
Port: $WEB_ACCESS_PORT
Access URL: https://$(curl -s ifconfig.me):$WEB_ACCESS_PORT
EOF

chmod 600 /etc/ttyd-credentials

print_success "✅ Web access credentials generated"

# =============================================================================
# STEP 4: CONFIGURE FIREWALL
# =============================================================================

print_status "Step 4: Configuring firewall..."

# Enable UFW if not already enabled
ufw --force enable

# Allow SSH (important!)
ufw allow ssh
ufw allow 22

# Allow HTTP and HTTPS
ufw allow 80
ufw allow 443

# Allow web terminal port
ufw allow $WEB_ACCESS_PORT

# Allow NexusGreen application ports
ufw allow 3001  # API
ufw allow 8080  # Frontend

print_success "✅ Firewall configured"

# =============================================================================
# STEP 5: CREATE SYSTEMD SERVICE FOR WEB TERMINAL
# =============================================================================

print_status "Step 5: Creating web terminal service..."

# Create systemd service file
cat > /etc/systemd/system/nexus-web-access.service << EOF
[Unit]
Description=NexusGreen Web Access Terminal
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd -p $WEB_ACCESS_PORT -c nexus-support:$WEB_ACCESS_PASSWORD -t fontSize=14 -t theme={"background":"#1e1e1e","foreground":"#d4d4d4"} bash
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable nexus-web-access
systemctl start nexus-web-access

print_success "✅ Web terminal service created and started"

# =============================================================================
# STEP 6: NGINX REVERSE PROXY (OPTIONAL SSL)
# =============================================================================

print_status "Step 6: Setting up Nginx reverse proxy..."

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)

# Create Nginx configuration for web access
cat > /etc/nginx/sites-available/nexus-web-access << EOF
server {
    listen 80;
    server_name $PUBLIC_IP;
    
    location /terminal {
        proxy_pass http://127.0.0.1:$WEB_ACCESS_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
    
    location /nexus-status {
        return 200 "NexusGreen Web Access Ready\\nTime: \$time_iso8601\\nServer: $PUBLIC_IP";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/nexus-web-access /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

print_success "✅ Nginx reverse proxy configured"

# =============================================================================
# STEP 7: CREATE ACCESS INFORMATION FILE
# =============================================================================

print_status "Step 7: Creating access information..."

# Create comprehensive access information
cat > /home/$ACTUAL_USER/nexus-web-access-info.txt << EOF
================================================================================
NEXUS GREEN - WEB ACCESS INFORMATION
================================================================================
Generated: $(date)
Server: $PUBLIC_IP
User: $ACTUAL_USER

🌐 WEB TERMINAL ACCESS:
Direct Access: http://$PUBLIC_IP:$WEB_ACCESS_PORT
Via Nginx:     http://$PUBLIC_IP/terminal
Username:      nexus-support
Password:      $WEB_ACCESS_PASSWORD

🔧 SYSTEM STATUS:
Status Check:  http://$PUBLIC_IP/nexus-status

🚀 NEXUS GREEN APPLICATION:
Frontend:      http://$PUBLIC_IP:8080
API:           http://$PUBLIC_IP:3001
API Health:    http://$PUBLIC_IP:3001/api/health

📋 USEFUL COMMANDS FOR REMOTE SUPPORT:
- Check services:     sudo systemctl status nexus-web-access
- View logs:          sudo journalctl -u nexus-web-access -f
- Restart terminal:   sudo systemctl restart nexus-web-access
- Check firewall:     sudo ufw status
- Docker status:      docker ps
- NexusGreen logs:    docker-compose logs -f

🔒 SECURITY NOTES:
- Web terminal runs with root privileges for deployment assistance
- Access is password protected
- Firewall is configured to allow necessary ports
- Session will timeout after inactivity

📞 SUPPORT WORKFLOW:
1. Share the web terminal URL and credentials with support
2. Support can access terminal directly via browser
3. Support can run deployment scripts and troubleshoot issues
4. Monitor progress via docker-compose logs
5. Disable access when support is complete

🛡️ TO DISABLE WEB ACCESS AFTER SUPPORT:
sudo systemctl stop nexus-web-access
sudo systemctl disable nexus-web-access
sudo ufw delete allow $WEB_ACCESS_PORT

================================================================================
EOF

# Set proper ownership
chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/nexus-web-access-info.txt

print_success "✅ Access information created"

# =============================================================================
# STEP 8: FINAL VERIFICATION AND INSTRUCTIONS
# =============================================================================

print_status "Step 8: Final verification..."

# Check if services are running
if systemctl is-active --quiet nexus-web-access; then
    print_success "✅ Web terminal service is running"
else
    print_error "❌ Web terminal service failed to start"
    systemctl status nexus-web-access
fi

if systemctl is-active --quiet nginx; then
    print_success "✅ Nginx is running"
else
    print_error "❌ Nginx failed to start"
fi

# Test web access
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WEB_ACCESS_PORT" | grep -q "200\|101"; then
    print_success "✅ Web terminal is accessible"
else
    print_warning "⚠️  Web terminal may not be fully ready yet"
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}🎉 NEXUS GREEN WEB ACCESS SETUP COMPLETE!${NC}"
echo "================================================================================"
echo ""
echo -e "${BLUE}📋 ACCESS INFORMATION:${NC}"
echo -e "Web Terminal: ${YELLOW}http://$PUBLIC_IP:$WEB_ACCESS_PORT${NC}"
echo -e "Via Nginx:    ${YELLOW}http://$PUBLIC_IP/terminal${NC}"
echo -e "Username:     ${YELLOW}nexus-support${NC}"
echo -e "Password:     ${YELLOW}$WEB_ACCESS_PASSWORD${NC}"
echo ""
echo -e "${BLUE}📁 Full details saved to:${NC} /home/$ACTUAL_USER/nexus-web-access-info.txt"
echo ""
echo -e "${GREEN}✅ Ready for remote production deployment assistance!${NC}"
echo ""
echo -e "${YELLOW}🔒 SECURITY REMINDER:${NC}"
echo "- Disable web access after support is complete"
echo "- Monitor access logs for security"
echo "- Change password if needed: edit /etc/ttyd-credentials"
echo ""
echo "================================================================================"

# Display the credentials one more time
echo ""
echo -e "${RED}🔑 IMPORTANT - SAVE THESE CREDENTIALS:${NC}"
cat /etc/ttyd-credentials
echo ""