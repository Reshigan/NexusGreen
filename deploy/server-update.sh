#!/bin/bash

# SolarNexus Server Update Script
# Version: 2.1.0
# Updated: 2025-09-13

set -e

INSTALL_DIR="/opt/solarnexus"

echo "🔄 SolarNexus Server Update"
echo "=========================="

# Check if SolarNexus is installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ SolarNexus not found at $INSTALL_DIR"
    echo "Please run the clean install script first."
    exit 1
fi

cd "$INSTALL_DIR"

echo ""
echo "🛑 STEP 1: Stopping services..."
cd deploy
docker compose -f docker-compose.production.yml down
echo "✅ Services stopped"

echo ""
echo "📥 STEP 2: Pulling latest code..."
cd ..
git fetch origin
git reset --hard origin/main
echo "✅ Code updated"

echo ""
echo "🏗️  STEP 3: Rebuilding and starting services..."
cd deploy
docker compose -f docker-compose.production.yml up -d --build
echo "✅ Services rebuilt and started"

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

echo ""
echo "🧪 STEP 4: Testing services..."

# Test Frontend
if curl -f -s http://localhost:80 > /dev/null; then
    echo "  Frontend: ✅ Ready (http://localhost:80)"
else
    echo "  Frontend: ❌ Not responding"
fi

# Test Backend
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "  Backend: ✅ Ready (http://localhost:3000)"
else
    echo "  Backend: ❌ Not responding"
fi

echo ""
echo "📊 Service Status:"
docker compose -f docker-compose.production.yml ps

echo ""
echo "🎉 SolarNexus update completed successfully!"
echo ""
echo "🌐 Access your application:"
echo "  • Web Interface: http://localhost:80"
echo "  • API Endpoints: http://localhost:3000"
echo "  • Health Check: http://localhost:3000/health"