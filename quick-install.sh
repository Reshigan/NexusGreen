#!/bin/bash

# SolarNexus One-Line Installer
# Usage: curl -sSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/quick-install.sh | bash

set -e

echo "🚀 SolarNexus Quick Installer"
echo "============================="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    echo "   Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available"
    echo "   Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Clone repository
echo "📥 Cloning SolarNexus repository..."
if [ -d "SolarNexus" ]; then
    echo "   Directory SolarNexus already exists. Updating..."
    cd SolarNexus
    git pull
else
    git clone https://github.com/Reshigan/SolarNexus.git
    cd SolarNexus
fi

echo "✅ Repository ready"

# Run the installer
echo "🚀 Starting installation..."
chmod +x install.sh
./install.sh

echo ""
echo "🎉 SolarNexus is now running!"
echo "   Open http://localhost:80 in your browser"