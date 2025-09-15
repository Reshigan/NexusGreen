#!/bin/bash

# Quick API debug script for AWS deployment
echo "🔍 NexusGreen API Debug"
echo "======================"

cd ~/NexusGreen || {
    echo "❌ NexusGreen directory not found!"
    exit 1
}

echo "📋 API Container Logs:"
echo "====================="
docker compose logs nexus-api

echo ""
echo "🐳 Container Status:"
echo "==================="
docker compose ps

echo ""
echo "🔌 API Health Check:"
echo "==================="
echo "Trying to connect to API..."
curl -v http://localhost:3001/health 2>&1 || echo "❌ API not responding"

echo ""
echo "📁 API Container Files:"
echo "======================"
echo "Checking if API files exist in container..."
docker compose exec nexus-api ls -la /app/ 2>/dev/null || echo "❌ Cannot access API container"

echo ""
echo "🔧 Quick Fixes:"
echo "=============="
echo "1. Restart API: docker compose restart nexus-api"
echo "2. Rebuild API: docker compose build nexus-api"
echo "3. Check API logs: docker compose logs -f nexus-api"