#!/bin/bash

# SolarNexus Docker Fix Script
# Resolves Docker package conflicts on Ubuntu

set -e

echo "🔧 SolarNexus Docker Fix"
echo "========================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   echo "Run: sudo $0"
   exit 1
fi

echo "🧹 Removing conflicting Docker packages..."

# Stop Docker services
systemctl stop docker 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true

# Remove conflicting packages
apt-get remove -y \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    2>/dev/null || true

# Clean up
apt-get autoremove -y
apt-get autoclean

echo "📦 Installing Ubuntu Docker packages..."

# Update package list
apt-get update -qq

# Install Ubuntu's Docker packages
apt-get install -y \
    docker.io \
    docker-compose \
    containerd

echo "🚀 Starting Docker services..."

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu 2>/dev/null || true

echo "🧪 Testing Docker installation..."

# Test Docker
if docker --version; then
    echo "✅ Docker installed successfully"
else
    echo "❌ Docker installation failed"
    exit 1
fi

if docker-compose --version; then
    echo "✅ Docker Compose installed successfully"
else
    echo "❌ Docker Compose installation failed"
    exit 1
fi

echo ""
echo "✅ Docker fix completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Log out and log back in (or run: newgrp docker)"
echo "2. Test Docker: docker run hello-world"
echo "3. Continue with SolarNexus SSL installation"
echo ""