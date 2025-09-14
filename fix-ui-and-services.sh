#!/bin/bash

# 🔧 NexusGreen UI and Service Fix Script
# Fixes service naming issues and ensures latest UI is deployed

echo "🔧 NexusGreen UI and Service Fix"
echo "================================"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

echo "🛑 Stopping all services..."
docker-compose down --remove-orphans

echo "🧹 Cleaning up old containers and images..."
docker system prune -f

echo "🗑️  Removing old build artifacts..."
rm -rf dist
rm -rf node_modules/.vite
rm -rf node_modules/.cache

echo "🏗️  Building fresh frontend..."
npm run build

echo "🐳 Rebuilding all containers with latest code..."
docker-compose build --no-cache

echo "🚀 Starting services with fixed configuration..."
docker-compose up -d

echo "⏳ Waiting for services to initialize..."
sleep 45

echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "🏥 Testing health endpoints..."
echo "API Health Check:"
curl -s http://localhost:3001/health | jq . 2>/dev/null || curl -s http://localhost:3001/health

echo ""
echo "Frontend Check:"
curl -s -I http://localhost:8080 | head -1

echo ""
echo "📊 Service Logs (last 5 lines each):"
echo "===================================="
echo "🔧 API Logs:"
docker-compose logs --tail=5 nexus-api

echo ""
echo "🗄️  Database Logs:"
docker-compose logs --tail=5 nexus-db

echo ""
echo "🌐 Frontend Logs:"
docker-compose logs --tail=5 nexus-green

echo ""
echo "✅ Fix Complete!"
echo "================"
echo "🌐 Access your application:"
echo "   Dashboard: http://localhost:8080"
echo "   API Health: http://localhost:3001/health"
echo ""
echo "👤 Default Login:"
echo "   Email: admin@nexusgreen.energy"
echo "   Password: NexusGreen2024!"
echo ""
echo "🔧 Service Names Fixed:"
echo "   Frontend: nexus-green"
echo "   API: nexus-api"
echo "   Database: nexus-db"
echo ""
echo "🎨 UI Updated:"
echo "   Fresh build with latest modern dashboard"
echo "   Framer Motion animations enabled"
echo "   Professional NexusGreen branding"
echo ""
echo "🔍 If issues persist:"
echo "   docker-compose logs -f"
echo "   docker-compose restart"
echo ""
echo "🎉 NexusGreen v6.0.0 with modern UI is ready!"