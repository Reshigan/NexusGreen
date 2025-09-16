#!/bin/bash

# NexusGreen Production Installation Script
# For Ubuntu 22.04 on AWS t4g.medium instances
# Installs Docker, pulls latest code, and deploys with fixes

set -e

echo "🚀 NexusGreen Production Installation Script"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as ubuntu user."
   exit 1
fi

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_error "This script is designed for Ubuntu. Detected: $(lsb_release -d | cut -f2)"
    exit 1
fi

print_status "Starting NexusGreen production installation..."

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_success "Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
print_success "Firewall configured"

# Clone or update repository
if [ -d "NexusGreen" ]; then
    print_status "Updating existing NexusGreen repository..."
    cd NexusGreen
    git fetch origin
    git checkout main
    git pull origin main
    # Merge the fixes from the PR branch
    git fetch origin fix-production-deployment
    git merge origin/fix-production-deployment
else
    print_status "Cloning NexusGreen repository..."
    git clone https://github.com/Reshigan/NexusGreen.git
    cd NexusGreen
    # Get the latest fixes
    git fetch origin fix-production-deployment
    git checkout fix-production-deployment
fi

print_success "Repository ready with latest fixes"

# Make scripts executable
chmod +x deploy-aws-t4g.sh
chmod +x test-deployment.sh

# Stop any existing containers
print_status "Stopping any existing containers..."
docker-compose down 2>/dev/null || true

# Deploy the application
print_status "Deploying NexusGreen application..."
./deploy-aws-t4g.sh

# Wait for services to be ready
print_status "Waiting for services to initialize..."
sleep 30

# Test the deployment
print_status "Testing deployment..."
./test-deployment.sh

# Configure SSL certificate
print_status "Setting up SSL certificate..."
print_warning "You will need to configure the SSL certificate manually."
echo ""
echo "To set up SSL for nexus.gonxt.tech, run:"
echo "  sudo certbot --nginx"
echo "  Select option 1 (reinstall existing certificate)"
echo ""

# Final status check
print_status "Checking final deployment status..."
docker-compose ps

echo ""
print_success "🎉 NexusGreen installation completed!"
echo ""
echo "Next steps:"
echo "1. Configure SSL certificate: sudo certbot --nginx"
echo "2. Test HTTPS access: curl https://nexus.gonxt.tech/health"
echo "3. Monitor logs: docker-compose logs -f nexus-api"
echo ""
echo "Application URLs:"
echo "- HTTP:  http://$(curl -s ifconfig.me)/"
echo "- HTTPS: https://nexus.gonxt.tech/ (after SSL setup)"
echo "- API:   https://nexus.gonxt.tech/api-health"
echo ""
echo "Troubleshooting:"
echo "- View logs: docker-compose logs -f [service-name]"
echo "- Restart services: docker-compose restart"
echo "- Test deployment: ./test-deployment.sh"
echo ""
print_success "Installation complete! 🚀"