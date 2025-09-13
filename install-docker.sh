#!/bin/bash

# SolarNexus Docker Installation Script
# This script installs Docker and Docker Compose on Ubuntu/Debian systems

set -e

echo "🐳 Installing Docker for SolarNexus..."
echo "=================================="

# Update package index
echo "📦 Updating package index..."
sudo apt-get update

# Install prerequisites
echo "🔧 Installing prerequisites..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "🔑 Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "📋 Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "📦 Updating package index with Docker repository..."
sudo apt-get update

# Install Docker Engine
echo "🐳 Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
echo "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (optional, requires logout/login)
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose (standalone version as backup)
echo "🔧 Installing Docker Compose standalone..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
echo "✅ Verifying Docker installation..."
sudo docker --version
sudo docker compose version || sudo docker-compose --version

echo ""
echo "🎉 Docker installation completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Log out and log back in (or run 'newgrp docker') to use Docker without sudo"
echo "2. Run the SolarNexus deployment script:"
echo "   sudo ./deploy-final.sh"
echo ""
echo "🔍 Test Docker installation:"
echo "   sudo docker run hello-world"