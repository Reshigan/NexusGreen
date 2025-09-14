#!/bin/bash

# Docker Production Install for Nexus Green
# Complete Docker-based production deployment

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

header() {
    echo -e "${CYAN}$1${NC}"
}

echo ""
header "🐳 Nexus Green Docker Production Install"
header "========================================"
echo ""
info "This will deploy Nexus Green using Docker for a clean, reliable production setup"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Get current user info
CURRENT_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$CURRENT_USER)
INSTALL_DIR="$USER_HOME/nexus-green-docker"

info "User: $CURRENT_USER"
info "Install directory: $INSTALL_DIR"
echo ""

# 1. SYSTEM CLEANUP
header "🧹 System Cleanup"
log "Stopping existing services..."
systemctl stop nginx 2>/dev/null || true
pkill -f "nexus" 2>/dev/null || true
pkill -f "solar" 2>/dev/null || true

log "Removing old installations..."
rm -rf /opt/nexus-green /opt/solarnexus /root/nexus-green 2>/dev/null || true
rm -rf $USER_HOME/nexus-green $USER_HOME/solarnexus 2>/dev/null || true

log "Cleaning nginx configs..."
rm -f /etc/nginx/sites-enabled/nexus-green* /etc/nginx/sites-available/nexus-green* 2>/dev/null || true

log "Stopping existing Docker containers..."
docker stop nexus-green-prod 2>/dev/null || true
docker rm nexus-green-prod 2>/dev/null || true

echo ""

# 2. INSTALL DOCKER
header "🐳 Docker Installation"
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    apt update -qq
    apt install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update -qq
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start Docker
    systemctl enable docker
    systemctl start docker
    
    # Add user to docker group
    usermod -aG docker $CURRENT_USER
    
    log "Docker installed successfully"
else
    log "Docker already installed"
    systemctl start docker
fi

# Install docker-compose if not available
if ! command -v docker-compose &> /dev/null; then
    log "Installing docker-compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo ""

# 3. CLONE AND SETUP
header "📁 Repository Setup"
log "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

log "Cloning Nexus Green repository..."
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/Reshigan/NexusGreen.git .
fi

# Ensure proper ownership
chown -R $CURRENT_USER:$CURRENT_USER "$INSTALL_DIR"

echo ""

# 4. DOCKER BUILD AND DEPLOY
header "🚀 Docker Build and Deploy"
log "Building Docker image..."
docker build -t nexus-green:latest .

log "Creating Docker network..."
docker network create nexus-green-network 2>/dev/null || true

log "Creating directories for volumes..."
mkdir -p docker/logs docker/ssl
chown -R $CURRENT_USER:$CURRENT_USER docker/

log "Starting Docker container..."
docker-compose up -d

echo ""

# 5. WAIT FOR STARTUP
header "⏳ Waiting for Application Startup"
log "Waiting for container to be ready..."
sleep 10

# Check container status
if docker ps | grep -q "nexus-green-prod"; then
    log "Container is running"
else
    error "Container failed to start"
    echo ""
    info "Container logs:"
    docker logs nexus-green-prod
    exit 1
fi

echo ""

# 6. HEALTH CHECK AND TESTING
header "🔍 Health Check and Testing"
log "Checking application health..."

# Wait for application to be ready
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/health | grep -q "200"; then
        log "Health check passed"
        break
    fi
    if [ $i -eq 30 ]; then
        warning "Health check timeout - but container is running"
        break
    fi
    sleep 2
done

# Test main site
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    log "✅ Main site responding successfully!"
else
    warning "Main site returning HTTP $HTTP_CODE"
fi

echo ""

# 7. SUCCESS REPORT
header "🎉 Docker Installation Complete!"
echo ""
log "✅ Nexus Green is running in Docker!"
echo ""
info "🌐 Access your site at:"
info "   • http://nexus.gonxt.tech"
info "   • http://localhost"
info "   • http://$(hostname -I | awk '{print $1}')"
echo ""
info "🐳 Docker details:"
info "   • Container: nexus-green-prod"
info "   • Image: nexus-green:latest"
info "   • Network: nexus-green-network"
info "   • Logs: docker logs nexus-green-prod"
echo ""
info "📁 Installation details:"
info "   • Location: $INSTALL_DIR"
info "   • Owner: $CURRENT_USER"
info "   • Config: docker-compose.yml"
echo ""
info "🔧 Management commands:"
info "   cd $INSTALL_DIR"
info "   docker-compose logs -f                    # View logs"
info "   docker-compose restart                    # Restart"
info "   docker-compose down && docker-compose up -d    # Rebuild"
info "   docker-compose ps                         # Status"
echo ""
info "🔄 Update process:"
info "   cd $INSTALL_DIR"
info "   git pull origin main"
info "   docker-compose down"
info "   docker build -t nexus-green:latest ."
info "   docker-compose up -d"
echo ""
info "🔒 Next steps:"
info "   • Test: curl -I http://nexus.gonxt.tech"
info "   • SSL: Configure SSL certificates in docker/ssl/"
info "   • Monitor: docker-compose logs -f"
echo ""
log "🌞 Docker production deployment ready!"

# Show container status
echo ""
info "📊 Current status:"
docker-compose ps

echo ""
log "✨ Docker installation completed successfully!"