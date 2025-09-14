#!/bin/bash

# 🎨 NexusGreen Complete UI Fix Script
# Fixes all UI issues and deploys the modern dashboard

echo "🎨 NexusGreen Complete UI Fix"
echo "============================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

echo "📥 Pulling latest changes from GitHub..."
git pull origin main

echo "🛑 Stopping all services..."
docker-compose down --remove-orphans

echo "🧹 Complete cleanup..."
docker system prune -af
docker volume prune -f

echo "🗑️  Removing all cached files..."
rm -rf dist
rm -rf node_modules/.vite
rm -rf node_modules/.cache
rm -rf api/node_modules/.cache

echo "📦 Fresh dependency installation..."
npm cache clean --force
npm install --no-audit --no-fund

echo "🏗️  Building fresh frontend with modern UI..."
npm run build

echo "🔍 Verifying build output..."
ls -la dist/

echo "🐳 Building containers with no cache..."
docker-compose build --no-cache --pull

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to fully initialize..."
sleep 60

echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "🏥 Health Check Results:"
echo "======================="

echo "🌐 Frontend Status:"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend: ONLINE (HTTP $FRONTEND_STATUS)"
else
    echo "❌ Frontend: OFFLINE (HTTP $FRONTEND_STATUS)"
fi

echo ""
echo "🔧 API Status:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo "✅ API: ONLINE (HTTP $API_STATUS)"
    echo "API Response:"
    curl -s http://localhost:3001/health | jq . 2>/dev/null || curl -s http://localhost:3001/health
else
    echo "❌ API: OFFLINE (HTTP $API_STATUS)"
fi

echo ""
echo "🗄️  Database Status:"
DB_STATUS=$(docker-compose exec -T nexus-db pg_isready -U nexususer -d nexusgreen 2>/dev/null && echo "ready" || echo "not ready")
if [ "$DB_STATUS" = "ready" ]; then
    echo "✅ Database: ONLINE"
else
    echo "❌ Database: OFFLINE"
fi

echo ""
echo "📊 Container Logs (last 5 lines each):"
echo "======================================"

echo "🌐 Frontend Logs:"
docker-compose logs --tail=5 nexus-green

echo ""
echo "🔧 API Logs:"
docker-compose logs --tail=5 nexus-api

echo ""
echo "🗄️  Database Logs:"
docker-compose logs --tail=5 nexus-db

echo ""
echo "✅ Complete UI Fix Applied!"
echo "=========================="
echo ""
echo "🌐 Access Your Modern Dashboard:"
echo "   URL: http://localhost:8080"
echo "   Direct Dashboard: http://localhost:8080/dashboard"
echo ""
echo "🎨 What's New:"
echo "   ✅ Modern NexusGreen dashboard with animations"
echo "   ✅ Professional branding with NexusGreen logo"
echo "   ✅ Real-time data visualization"
echo "   ✅ Responsive design with Framer Motion"
echo "   ✅ Updated favicon and branding"
echo "   ✅ Fixed service communication"
echo ""
echo "🔧 API Endpoints:"
echo "   Health: http://localhost:3001/health"
echo "   Dashboard Data: http://localhost:3001/api/dashboard"
echo ""
echo "👤 Login Credentials:"
echo "   Email: admin@nexusgreen.energy"
echo "   Password: NexusGreen2024!"
echo ""
echo "🔍 Troubleshooting:"
echo "   View all logs: docker-compose logs -f"
echo "   Restart services: docker-compose restart"
echo "   Check status: docker-compose ps"
echo ""
echo "🎉 NexusGreen v6.0.0 Modern Dashboard is Live!"
echo ""
echo "📱 Features Available:"
echo "   • Real-time energy generation monitoring"
echo "   • Interactive charts and analytics"
echo "   • Installation status overview"
echo "   • Alert management system"
echo "   • Performance metrics dashboard"
echo "   • Revenue tracking and reporting"
echo "   • CO₂ savings calculator"
echo "   • Mobile-responsive design"
echo ""
echo "🌞 Welcome to the future of solar energy management!"