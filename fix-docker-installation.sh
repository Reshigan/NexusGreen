#!/bin/bash

# Fix Docker installation issues in production deployment
# This script handles Docker and Docker Compose installation on various Ubuntu systems

echo "🐳 Fixing Docker installation issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

print_step "Step 1: Removing any existing Docker installations..."
$SUDO apt remove -y docker docker-engine docker.io containerd runc docker-compose 2>/dev/null || true

print_step "Step 2: Updating package index..."
$SUDO apt update

print_step "Step 3: Installing prerequisites..."
$SUDO apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

print_step "Step 4: Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

print_step "Step 5: Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

print_step "Step 6: Updating package index with Docker repository..."
$SUDO apt update

print_step "Step 7: Installing Docker Engine and Docker Compose..."
# Try to install docker-compose-plugin first
if $SUDO apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    print_success "Docker and Docker Compose Plugin installed successfully"
    COMPOSE_CMD="docker compose"
else
    print_warning "docker-compose-plugin failed, trying alternative installation..."
    
    # Install Docker CE without the plugin
    $SUDO apt install -y docker-ce docker-ce-cli containerd.io
    
    # Install docker-compose as standalone binary
    print_status "Installing Docker Compose as standalone binary..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    $SUDO curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for compatibility
    $SUDO ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    COMPOSE_CMD="docker-compose"
    print_success "Docker and Docker Compose (standalone) installed successfully"
fi

print_step "Step 8: Starting and enabling Docker service..."
$SUDO systemctl start docker
$SUDO systemctl enable docker

print_step "Step 9: Adding current user to docker group..."
if [[ $EUID -ne 0 ]]; then
    $SUDO usermod -aG docker $USER
    print_warning "You may need to log out and back in for docker group changes to take effect"
fi

print_step "Step 10: Verifying Docker installation..."
$SUDO docker --version
if command -v docker-compose &> /dev/null; then
    docker-compose --version
    echo "export COMPOSE_CMD='docker-compose'" >> ~/.bashrc
elif docker compose version &> /dev/null 2>&1; then
    docker compose version
    echo "export COMPOSE_CMD='docker compose'" >> ~/.bashrc
fi

print_step "Step 11: Testing Docker installation..."
if $SUDO docker run --rm hello-world > /dev/null 2>&1; then
    print_success "Docker is working correctly!"
else
    print_error "Docker test failed"
    exit 1
fi

print_success "Docker installation completed successfully!"
print_status "Docker Compose command: $COMPOSE_CMD"

# Create a helper script for the deployment
cat > /tmp/docker-info.sh << 'EOF'
#!/bin/bash
# Docker information for deployment script

if command -v docker-compose &> /dev/null; then
    echo "COMPOSE_CMD=docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    echo "COMPOSE_CMD=docker compose"
else
    echo "COMPOSE_CMD=docker-compose"
fi
EOF

chmod +x /tmp/docker-info.sh

print_success "Docker installation fix completed!"
print_status "You can now continue with the production deployment."
print_status "The deployment script will automatically detect the correct Docker Compose command."