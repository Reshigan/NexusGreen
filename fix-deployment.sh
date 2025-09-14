#!/bin/bash

# Quick fix for deployment issues on Ubuntu 24.04
echo "🔧 Fixing deployment issues..."

# Install Docker Compose properly for Ubuntu 24.04
echo "📦 Installing Docker Compose..."
apt update
apt install -y docker-compose-v2

# Create symlink for backward compatibility
if [ ! -f /usr/local/bin/docker-compose ]; then
    ln -s /usr/bin/docker-compose /usr/local/bin/docker-compose 2>/dev/null || true
fi

# Start Docker daemon if not running
echo "🐳 Starting Docker..."
if ! systemctl is-active --quiet docker; then
    if ! systemctl start docker 2>/dev/null; then
        echo "Starting Docker daemon manually..."
        dockerd > /tmp/docker.log 2>&1 &
        sleep 10
    fi
fi

# Verify Docker is working
echo "🔍 Testing Docker..."
docker --version
docker-compose --version

# Test Docker with hello-world
echo "🧪 Testing Docker functionality..."
docker run --rm hello-world

echo "✅ Docker setup complete!"
echo ""
echo "Now you can continue with deployment:"
echo "  cd /opt/solarnexus"
echo "  sudo docker-compose -f docker-compose.arm64.yml up -d --build"