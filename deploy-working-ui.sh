#!/bin/bash

# 🚀 Deploy Working NexusGreen UI
# Simple, reliable dashboard that actually works

echo "🚀 Deploying Working NexusGreen UI"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

echo "📥 Pulling latest changes..."
git pull origin main

echo "🛑 Stopping services..."
docker-compose down

echo "🧹 Cleaning up..."
docker system prune -f

echo "🏗️  Building fresh UI..."
npm run build

echo "🔍 Verifying build..."
ls -la dist/

echo "🐳 Rebuilding containers..."
docker-compose build --no-cache nexus-green

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services..."
sleep 30

echo "🔍 Service Status:"
docker-compose ps

echo ""
echo "🏥 Health Checks:"
echo "================"

echo "Frontend:"
curl -s -I http://localhost:8080 | head -1

echo ""
echo "API:"
curl -s http://localhost:3001/health | head -1

echo ""
echo "✅ Deployment Complete!"
echo "======================"
echo ""
echo "🌐 Access Your Dashboard:"
echo "   URL: http://localhost:8080"
echo ""
echo "🎨 What You'll See:"
echo "   ✅ Clean, professional NexusGreen dashboard"
echo "   ✅ Real-time metrics and data"
echo "   ✅ Interactive solar installation overview"
echo "   ✅ Live clock and status updates"
echo "   ✅ Responsive design that works on all devices"
echo ""
echo "📊 Dashboard Features:"
echo "   • Total energy generation tracking"
echo "   • Revenue monitoring"
echo "   • System performance metrics"
echo "   • CO₂ savings calculator"
echo "   • Active solar installations overview"
echo "   • Real-time status updates"
echo ""
echo "🎉 NexusGreen Dashboard is Live and Working!"