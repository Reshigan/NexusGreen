#!/bin/bash

# SolarNexus Production Installation Script
# Version: 1.1.0
# Repository: https://github.com/Reshigan/SolarNexus
# 
# This script will install SolarNexus in production mode with:
# - SSL certificate (Let's Encrypt)
# - South African timezone
# - Demo data with GonXT Solar Solutions
# - Complete Docker environment
# - Nginx reverse proxy with security headers

echo "🌞 SolarNexus Production Installation Script v1.1.0"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_header() { echo -e "${CYAN}$1${NC}"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root directly."
    print_status "Please run as a user with sudo privileges:"
    print_status "curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/install-solarnexus.sh | bash"
    exit 1
fi

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    print_error "This script requires sudo privileges."
    print_status "Please ensure your user can run sudo commands."
    exit 1
fi

print_header "🔍 Pre-installation Checks"
echo ""

# Check Ubuntu version
if ! lsb_release -d | grep -q "Ubuntu"; then
    print_warning "This script is designed for Ubuntu. Other distributions may not work correctly."
fi

# Check system requirements
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

print_status "System Information:"
echo "  - OS: $(lsb_release -d | cut -f2)"
echo "  - RAM: ${TOTAL_RAM}GB"
echo "  - Available Disk: ${AVAILABLE_DISK}GB"
echo ""

if [[ $TOTAL_RAM -lt 2 ]]; then
    print_warning "Recommended minimum RAM is 2GB. Current: ${TOTAL_RAM}GB"
fi

if [[ $AVAILABLE_DISK -lt 20 ]]; then
    print_warning "Recommended minimum disk space is 20GB. Available: ${AVAILABLE_DISK}GB"
fi

# Check network connectivity
print_status "Checking network connectivity..."
if ! ping -c 1 google.com &> /dev/null; then
    print_error "No internet connection detected. Please check your network."
    exit 1
fi

if ! ping -c 1 github.com &> /dev/null; then
    print_error "Cannot reach GitHub. Please check your network."
    exit 1
fi

print_success "Pre-installation checks completed"
echo ""

# Get configuration from user
print_header "📋 Configuration Setup"
echo ""

# Domain configuration
read -p "Enter your domain name (default: nexus.gonxt.tech): " DOMAIN
DOMAIN=${DOMAIN:-nexus.gonxt.tech}

# Email for SSL certificate
read -p "Enter email for SSL certificate (default: reshigan@gonxt.tech): " EMAIL
EMAIL=${EMAIL:-reshigan@gonxt.tech}

# Confirm configuration
echo ""
print_status "Configuration Summary:"
echo "  - Domain: $DOMAIN"
echo "  - SSL Email: $EMAIL"
echo "  - Timezone: Africa/Johannesburg (SAST)"
echo "  - Demo Company: GonXT Solar Solutions"
echo "  - Admin Login: admin@gonxt.tech / Demo2024!"
echo "  - User Login: user@gonxt.tech / Demo2024!"
echo ""

read -p "Continue with installation? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    print_status "Installation cancelled."
    exit 0
fi

echo ""
print_header "🚀 Starting SolarNexus Installation"
echo ""

# Download the production deployment script
print_step "Downloading production deployment script..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if ! curl -fsSL -o production-deploy.sh "https://raw.githubusercontent.com/Reshigan/SolarNexus/main/production-deploy.sh"; then
    print_error "Failed to download deployment script from GitHub"
    exit 1
fi

chmod +x production-deploy.sh
print_success "Deployment script downloaded"

# Run the production deployment
print_step "Starting production deployment..."
echo ""
print_status "This will take several minutes. Please be patient..."
echo ""

# Export configuration for the deployment script
export DOMAIN="$DOMAIN"
export EMAIL="$EMAIL"

# Run the deployment script
if sudo -E ./production-deploy.sh; then
    echo ""
    print_success "🎉 SolarNexus installation completed successfully!"
    echo ""
    print_header "🌐 Access Information"
    echo ""
    print_status "Your SolarNexus installation is ready:"
    echo "  🔗 URL: https://$DOMAIN"
    echo "  👤 Admin: admin@gonxt.tech / Demo2024!"
    echo "  👤 User:  user@gonxt.tech / Demo2024!"
    echo ""
    print_header "🛠️ Management Commands"
    echo ""
    echo "  View logs:    cd /opt/solarnexus && sudo docker compose logs"
    echo "  Restart:      cd /opt/solarnexus && sudo docker compose restart"
    echo "  Update:       cd /opt/solarnexus && git pull && sudo docker compose up -d --build"
    echo "  SSL renewal:  sudo certbot renew"
    echo ""
    print_header "📁 Important Locations"
    echo ""
    echo "  Application:  /opt/solarnexus"
    echo "  Nginx config: /etc/nginx/sites-available/solarnexus"
    echo "  SSL certs:    /etc/letsencrypt/live/$DOMAIN"
    echo "  Logs:         /var/log/nginx/ and docker logs"
    echo ""
    print_success "Installation completed at: $(date)"
else
    echo ""
    print_error "❌ Installation failed!"
    echo ""
    print_status "Troubleshooting steps:"
    echo "1. Check the error messages above"
    echo "2. Ensure your domain DNS is pointing to this server"
    echo "3. Verify ports 80 and 443 are open"
    echo "4. Check system requirements (2GB RAM, 20GB disk)"
    echo ""
    print_status "For support, check the logs or contact support with the error details."
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo ""
print_header "🎊 Welcome to SolarNexus!"
echo ""
print_status "Thank you for installing SolarNexus. Visit https://$DOMAIN to get started!"