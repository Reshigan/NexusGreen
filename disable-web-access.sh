#!/bin/bash

# =============================================================================
# NEXUS GREEN - DISABLE WEB ACCESS SCRIPT
# =============================================================================
# This script disables the web access setup for security after support is complete
# Usage: sudo ./disable-web-access.sh
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

echo ""
echo "================================================================================"
echo -e "${YELLOW}🔒 NEXUS GREEN - DISABLE WEB ACCESS${NC}"
echo "================================================================================"
echo ""

print_warning "This will disable remote web access for security."
echo -n "Are you sure you want to continue? (y/N): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled."
    exit 0
fi

print_status "Disabling web access..."

# Stop and disable the web terminal service
if systemctl is-active --quiet nexus-web-access; then
    print_status "Stopping web terminal service..."
    systemctl stop nexus-web-access
    print_success "✅ Web terminal service stopped"
fi

if systemctl is-enabled --quiet nexus-web-access; then
    print_status "Disabling web terminal service..."
    systemctl disable nexus-web-access
    print_success "✅ Web terminal service disabled"
fi

# Remove the systemd service file
if [ -f "/etc/systemd/system/nexus-web-access.service" ]; then
    print_status "Removing service file..."
    rm -f /etc/systemd/system/nexus-web-access.service
    systemctl daemon-reload
    print_success "✅ Service file removed"
fi

# Remove Nginx configuration
if [ -f "/etc/nginx/sites-enabled/nexus-web-access" ]; then
    print_status "Removing Nginx configuration..."
    rm -f /etc/nginx/sites-enabled/nexus-web-access
    rm -f /etc/nginx/sites-available/nexus-web-access
    nginx -t && systemctl reload nginx
    print_success "✅ Nginx configuration removed"
fi

# Remove firewall rule for web terminal port
WEB_ACCESS_PORT=7681
print_status "Removing firewall rule for port $WEB_ACCESS_PORT..."
ufw delete allow $WEB_ACCESS_PORT 2>/dev/null || true
print_success "✅ Firewall rule removed"

# Secure credentials file (don't delete, just secure it)
if [ -f "/etc/ttyd-credentials" ]; then
    print_status "Securing credentials file..."
    chmod 600 /etc/ttyd-credentials
    print_success "✅ Credentials file secured"
fi

# Remove ttyd binary (optional)
echo -n "Remove ttyd binary? (y/N): "
read -r remove_ttyd
if [[ "$remove_ttyd" =~ ^[Yy]$ ]]; then
    if [ -f "/usr/local/bin/ttyd" ]; then
        rm -f /usr/local/bin/ttyd
        print_success "✅ ttyd binary removed"
    fi
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}🔒 WEB ACCESS SUCCESSFULLY DISABLED${NC}"
echo "================================================================================"
echo ""
echo -e "${BLUE}✅ Actions completed:${NC}"
echo "- Web terminal service stopped and disabled"
echo "- Service file removed"
echo "- Nginx configuration removed"
echo "- Firewall rule removed for port $WEB_ACCESS_PORT"
echo "- Credentials file secured"
echo ""
echo -e "${YELLOW}📋 Security Status:${NC}"
echo "- Remote web access is now disabled"
echo "- SSH access remains available"
echo "- NexusGreen application ports remain open (80, 443, 3001, 8080)"
echo "- Credentials file preserved at /etc/ttyd-credentials (secured)"
echo ""
echo -e "${GREEN}🛡️  Your server is now secure from remote web access.${NC}"
echo ""