#!/bin/bash

# 🚀 NexusGreen Quick Server Update Script
# Handles npm build issues and updates server with latest fixes

echo "🚀 NexusGreen Quick Server Update"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

echo "📥 Pulling latest changes from GitHub..."
git pull origin main

echo "🧹 Cleaning up old containers and images..."
docker-compose down --remove-orphans
docker system prune -f

echo "🔧 Clearing npm cache and rebuilding..."
# Remove node_modules to force fresh install
rm -rf node_modules package-lock.json
rm -rf api/node_modules api/package-lock.json

echo "📦 Installing fresh dependencies..."
npm install --no-audit --no-fund
cd api && npm install --no-audit --no-fund && cd ..

echo "🏗️  Building and starting services..."
docker-compose up -d --build --force-recreate

echo "⏳ Waiting for services to start..."
sleep 30

echo "🔍 Checking service status..."
docker-compose ps

echo "🏥 Testing health endpoints..."
echo "API Health Check:"
curl -s http://localhost:3001/health | jq . || echo "API not responding yet"

echo ""
echo "Frontend Check:"
curl -s -I http://localhost:8080 | head -1 || echo "Frontend not responding yet"

echo ""
echo "📊 Service Logs (last 10 lines):"
echo "================================"
echo "API Logs:"
docker-compose logs --tail=10 nexus-api

echo ""
echo "Database Logs:"
docker-compose logs --tail=10 nexus-db

echo ""
echo "Frontend Logs:"
docker-compose logs --tail=10 nexus-green

echo ""
echo "✅ Update Complete!"
echo "==================="
echo "🌐 Access your application:"
echo "   Dashboard: http://localhost:8080"
echo "   API Health: http://localhost:3001/health"
echo ""
echo "👤 Default Login:"
echo "   Email: admin@nexusgreen.energy"
echo "   Password: NexusGreen2024!"
echo ""
echo "🔧 If issues persist, check logs with:"
echo "   docker-compose logs -f"
echo ""
echo "🎉 NexusGreen v6.0.0 is ready!"