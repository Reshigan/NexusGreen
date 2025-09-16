#!/bin/bash

# NexusGreen Clean Production Installation Script
# Completely resets the server and installs from scratch
# For Ubuntu 22.04 on AWS t4g.medium instances

set -e

echo "NexusGreen Clean Production Installation"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_warning "This will completely clean your server and reinstall everything!"
print_warning "This includes stopping all Docker containers, removing images, and resetting nginx."
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Installation cancelled."
    exit 1
fi

print_status "Starting clean installation process..."

# Step 1: Stop and remove all Docker containers and images
print_status "Cleaning up existing Docker containers and images..."
sudo systemctl stop docker 2>/dev/null || true

# Kill any remaining Docker processes
sudo pkill -f docker 2>/dev/null || true
sudo pkill -f containerd 2>/dev/null || true

# Remove Docker completely
sudo apt remove -y docker docker-engine docker.io containerd runc docker-compose 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

# Remove Docker directories
sudo rm -rf /var/lib/docker 2>/dev/null || true
sudo rm -rf /var/lib/containerd 2>/dev/null || true
sudo rm -rf /etc/docker 2>/dev/null || true
sudo rm -rf ~/.docker 2>/dev/null || true

print_success "Docker completely removed"

# Step 2: Stop and remove nginx
print_status "Removing existing nginx installation..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true
sudo apt remove -y nginx nginx-common nginx-core 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

# Remove nginx directories
sudo rm -rf /etc/nginx 2>/dev/null || true
sudo rm -rf /var/log/nginx 2>/dev/null || true
sudo rm -rf /var/www 2>/dev/null || true

print_success "Nginx completely removed"

# Step 3: Clean up any remaining processes on port 80/443
print_status "Freeing up ports 80 and 443..."
sudo fuser -k 80/tcp 2>/dev/null || true
sudo fuser -k 443/tcp 2>/dev/null || true
sudo fuser -k 3000/tcp 2>/dev/null || true
sudo fuser -k 3001/tcp 2>/dev/null || true
sudo fuser -k 5432/tcp 2>/dev/null || true

print_success "Ports freed"

# Step 4: Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 5: Install required packages
print_status "Installing required packages..."
sudo apt install -y curl wget git ufw net-tools

# Step 6: Configure firewall
print_status "Configuring firewall..."
sudo ufw --force reset
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
print_success "Firewall configured"

# Step 7: Install Docker fresh
print_status "Installing Docker from scratch..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Wait for Docker to be ready
sleep 10

print_success "Docker installed and started"

# Step 8: Install Docker Compose
print_status "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
if ! docker-compose --version; then
    print_error "Docker Compose installation failed"
    exit 1
fi

print_success "Docker Compose installed"

# Step 9: Clean up any existing NexusGreen directory
print_status "Cleaning up existing NexusGreen installation..."
cd ~
sudo rm -rf NexusGreen 2>/dev/null || true
sudo rm -rf nexus-green 2>/dev/null || true

# Step 10: Clone fresh repository with fixes
print_status "Cloning NexusGreen repository with latest fixes..."
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Get the latest fixes from the PR branch
git fetch origin fix-production-deployment
git checkout fix-production-deployment

print_success "Repository cloned with latest fixes"

# Step 11: Make scripts executable
chmod +x deploy-aws-t4g.sh
chmod +x test-deployment.sh
chmod +x install-production.sh

# Step 12: Verify no port conflicts
print_status "Verifying ports are free..."
if sudo netstat -tlnp | grep -E ':80|:443|:3000|:3001|:5432'; then
    print_warning "Some ports may still be in use. Attempting to free them..."
    sudo fuser -k 80/tcp 2>/dev/null || true
    sudo fuser -k 443/tcp 2>/dev/null || true
    sudo fuser -k 3000/tcp 2>/dev/null || true
    sudo fuser -k 3001/tcp 2>/dev/null || true
    sudo fuser -k 5432/tcp 2>/dev/null || true
    sleep 5
fi

print_success "Ports verified as free"

# Step 13: Deploy the application
print_status "Deploying NexusGreen application..."
./deploy-aws-t4g.sh

# Step 14: Wait for services to initialize
print_status "Waiting for services to initialize..."
sleep 45

# Step 15: Test the deployment
print_status "Testing deployment..."
./test-deployment.sh

# Step 16: Install certbot for SSL
print_status "Installing certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

print_success "Certbot installed"

# Final status check
print_status "Final deployment status check..."
docker-compose ps

echo ""
print_success "Clean NexusGreen installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure SSL certificate:"
echo "   sudo certbot --nginx"
echo "   Select option 1 (reinstall existing certificate)"
echo ""
echo "2. Test your deployment:"
echo "   HTTP:  http://$(curl -s ifconfig.me)/"
echo "   HTTPS: https://nexus.gonxt.tech/ (after SSL setup)"
echo ""
echo "3. Login with test credentials:"
echo "   Email: admin@nexusgreen.energy"
echo "   Password: NexusGreen2024!"
echo ""
echo "4. Monitor services:"
echo "   docker-compose logs -f nexus-api"
echo "   docker-compose logs -f nexus-frontend"
echo ""
echo "Troubleshooting:"
echo "- View logs: docker-compose logs [service-name]"
echo "- Restart: docker-compose restart"
echo "- Test: ./test-deployment.sh"
echo ""
print_success "Your NexusGreen solar platform is ready!"

# Show test credentials
echo ""
print_status "Quick Reference - Test Credentials:"
echo "Email: admin@nexusgreen.energy"
echo "Password: NexusGreen2024!"
echo ""
echo "See TEST_CREDENTIALS.md for all available test accounts and data."