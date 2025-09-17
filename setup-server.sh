#!/bin/bash

# NexusGreen Server Setup Script
# This script prepares a fresh server for NexusGreen deployment

set -e

echo "🔧 Setting up server for NexusGreen deployment..."

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
print_status "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    print_success "Docker installed successfully"
else
    print_success "Docker is already installed"
fi

# Install Docker Compose (standalone)
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose is already installed"
fi

# Create nexusgreen user (optional)
if ! id "nexusgreen" &>/dev/null; then
    print_status "Creating nexusgreen user..."
    useradd -m -s /bin/bash nexusgreen
    usermod -aG docker nexusgreen
    print_success "User 'nexusgreen' created and added to docker group"
else
    print_success "User 'nexusgreen' already exists"
fi

# Setup firewall (UFW)
print_status "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3001/tcp  # Backend API (optional, for direct access)
print_success "Firewall configured"

# Create application directory
print_status "Creating application directory..."
mkdir -p /opt/nexusgreen
chown nexusgreen:nexusgreen /opt/nexusgreen
print_success "Application directory created at /opt/nexusgreen"

# Display system information
echo
print_success "🎉 Server setup completed!"
echo
echo "📋 System Information:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   Docker: $(docker --version)"
echo "   Docker Compose: $(docker-compose --version)"
echo "   Application Directory: /opt/nexusgreen"
echo "   Application User: nexusgreen"
echo
echo "🚀 Next Steps:"
echo "   1. Copy NexusGreen files to /opt/nexusgreen"
echo "   2. Switch to nexusgreen user: sudo su - nexusgreen"
echo "   3. Run deployment: cd /opt/nexusgreen && ./deploy.sh"
echo
print_status "Server setup script completed successfully!"