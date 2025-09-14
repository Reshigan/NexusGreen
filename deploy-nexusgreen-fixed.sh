#!/bin/bash

# NexusGreen Production Deployment Script (Fixed for Docker permissions)
# Server: 13.247.192.38 | Domain: nexus.gonxt.tech
# Version: v6.3.0-nexusgreen-complete

set -e

echo "🚀 Starting NexusGreen Production Deployment..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Reshigan/NexusGreen.git"
APP_DIR="/opt/nexusgreen"
BACKUP_DIR="/opt/backups/nexusgreen-$(date +%Y%m%d-%H%M%S)"
DOCKER_COMPOSE_FILE="docker-compose.yml"

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
   print_error "This script should not be run as root for security reasons"
   print_status "Please run as ubuntu user: su ubuntu"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm get-docker.sh
fi

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    print_status "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    print_warning "User added to docker group. You need to log out and log back in, or run:"
    print_warning "newgrp docker"
    print_status "Running newgrp docker to apply group changes..."
    exec newgrp docker << EONG
        bash "$0" "$@"
EONG
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Test Docker access
if ! docker ps &> /dev/null; then
    print_error "Cannot access Docker. Trying to start Docker daemon..."
    sudo systemctl start docker
    sudo systemctl enable docker
    sleep 5
    
    if ! docker ps &> /dev/null; then
        print_error "Still cannot access Docker. Please check Docker installation."
        print_status "Try running: sudo systemctl status docker"
        exit 1
    fi
fi

print_status "Creating backup directory..."
sudo mkdir -p "$BACKUP_DIR"

# Backup existing application if it exists
if [ -d "$APP_DIR" ]; then
    print_status "Backing up existing application..."
    sudo cp -r "$APP_DIR" "$BACKUP_DIR/"
    print_success "Backup created at $BACKUP_DIR"
fi

# Create application directory
print_status "Setting up application directory..."
sudo mkdir -p "$APP_DIR"
sudo chown $USER:$USER "$APP_DIR"

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    print_status "Updating existing repository..."
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/main
    git pull origin main
else
    print_status "Cloning NexusGreen repository..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# Checkout the latest version
print_status "Checking out version v6.3.0-nexusgreen-complete..."
git checkout v6.3.0-nexusgreen-complete

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Remove old images to ensure fresh build
print_status "Cleaning up old Docker images..."
docker system prune -f || true

# Create necessary directories
print_status "Creating required directories..."
mkdir -p docker/ssl
mkdir -p docker/logs
mkdir -p database/data

# Set proper permissions
print_status "Setting permissions..."
sudo chown -R $USER:$USER "$APP_DIR"
chmod +x deploy-production.sh || true
chmod +x test-production.sh || true

# Build and start services
print_status "Building and starting NexusGreen services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 30

# Check service health
print_status "Checking service health..."
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running!"
else
    print_error "Some services failed to start. Check logs with: docker-compose logs"
    docker-compose logs
    exit 1
fi

# Display service status
echo ""
echo "🎉 NexusGreen Deployment Complete!"
echo "=================================="
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Access Points:"
echo "  • Main Application: https://nexus.gonxt.tech"
echo "  • API Endpoint: https://nexus.gonxt.tech/api"
echo "  • Health Check: https://nexus.gonxt.tech/health"

echo ""
echo "🔧 Management Commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Restart services: docker-compose restart"
echo "  • Stop services: docker-compose down"
echo "  • Update application: git pull && docker-compose up -d --build"

echo ""
echo "📈 New Features in v6.3.0:"
echo "  • Complete NexusGreen rebranding"
echo "  • Solax API refresh timer (60-90 min intervals)"
echo "  • Manual data refresh capability"
echo "  • Enhanced error handling and logging"

echo ""
echo "🔍 Troubleshooting:"
echo "  • Check logs: docker-compose logs [service-name]"
echo "  • Restart specific service: docker-compose restart [service-name]"
echo "  • View system resources: docker stats"

echo ""
print_success "NexusGreen is now running with the latest updates!"
print_status "The domain nexus.gonxt.tech should now show the new NexusGreen branding."

# Optional: Run health check
echo ""
print_status "Running health check..."
sleep 5
if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
    print_success "Health check passed - Application is responding"
else
    print_warning "Health check failed - Application may still be starting up"
    print_status "Wait a few more minutes and check manually: curl http://localhost:8080/health"
fi

echo ""
echo "🚀 Deployment completed successfully!"
echo "Visit https://nexus.gonxt.tech to see your updated NexusGreen platform!"