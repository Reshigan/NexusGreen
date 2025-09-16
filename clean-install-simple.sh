#!/bin/bash

# NexusGreen Clean Production Installation Script
# Simple version without special characters

set -e

echo "NexusGreen Clean Production Installation"
echo "========================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script should not be run as root. Please run as ubuntu user."
   exit 1
fi

echo "WARNING: This will completely clean your server and reinstall everything!"
echo "WARNING: This includes stopping all Docker containers, removing images, and resetting nginx."
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo "Starting clean installation process..."

# Step 1: Stop and remove all Docker containers and images
echo "Cleaning up existing Docker containers and images..."
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

echo "Docker completely removed"

# Step 2: Stop and remove nginx
echo "Removing existing nginx installation..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true
sudo apt remove -y nginx nginx-common nginx-core 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

# Remove nginx directories
sudo rm -rf /etc/nginx 2>/dev/null || true
sudo rm -rf /var/log/nginx 2>/dev/null || true
sudo rm -rf /var/www 2>/dev/null || true

echo "Nginx completely removed"

# Step 3: Clean up any remaining processes on ports
echo "Freeing up ports 80 and 443..."
sudo fuser -k 80/tcp 2>/dev/null || true
sudo fuser -k 443/tcp 2>/dev/null || true
sudo fuser -k 3000/tcp 2>/dev/null || true
sudo fuser -k 3001/tcp 2>/dev/null || true
sudo fuser -k 5432/tcp 2>/dev/null || true

echo "Ports freed"

# Step 4: Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 5: Install required packages
echo "Installing required packages..."
sudo apt install -y curl wget git ufw net-tools

# Step 6: Configure firewall
echo "Configuring firewall..."
sudo ufw --force reset
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "Firewall configured"

# Step 7: Install Docker fresh
echo "Installing Docker from scratch..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Wait for Docker to be ready
sleep 10

echo "Docker installed and started"

# Step 8: Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
if ! docker-compose --version; then
    echo "ERROR: Docker Compose installation failed"
    exit 1
fi

echo "Docker Compose installed"

# Step 9: Clean up any existing NexusGreen directory
echo "Cleaning up existing NexusGreen installation..."
cd ~
sudo rm -rf NexusGreen 2>/dev/null || true
sudo rm -rf nexus-green 2>/dev/null || true

# Step 10: Clone fresh repository with fixes
echo "Cloning NexusGreen repository with latest fixes..."
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Get the latest fixes from the PR branch
git fetch origin fix-production-deployment
git checkout fix-production-deployment

echo "Repository cloned with latest fixes"

# Step 11: Make scripts executable
chmod +x deploy-aws-t4g.sh
chmod +x test-deployment.sh
chmod +x install-production.sh

# Step 12: Verify no port conflicts
echo "Verifying ports are free..."
if sudo netstat -tlnp | grep -E ':80|:443|:3000|:3001|:5432'; then
    echo "WARNING: Some ports may still be in use. Attempting to free them..."
    sudo fuser -k 80/tcp 2>/dev/null || true
    sudo fuser -k 443/tcp 2>/dev/null || true
    sudo fuser -k 3000/tcp 2>/dev/null || true
    sudo fuser -k 3001/tcp 2>/dev/null || true
    sudo fuser -k 5432/tcp 2>/dev/null || true
    sleep 5
fi

echo "Ports verified as free"

# Step 13: Deploy the application
echo "Deploying NexusGreen application..."
./deploy-aws-t4g.sh

# Step 14: Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 45

# Step 15: Test the deployment
echo "Testing deployment..."
./test-deployment.sh

# Step 16: Install certbot for SSL
echo "Installing certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

echo "Certbot installed"

# Final status check
echo "Final deployment status check..."
docker-compose ps

echo ""
echo "SUCCESS: Clean NexusGreen installation completed successfully!"
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
echo "SUCCESS: Your NexusGreen solar platform is ready!"

# Show test credentials
echo ""
echo "Quick Reference - Test Credentials:"
echo "Email: admin@nexusgreen.energy"
echo "Password: NexusGreen2024!"
echo ""
echo "See TEST_CREDENTIALS.md for all available test accounts and data."