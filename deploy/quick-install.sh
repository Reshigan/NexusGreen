#!/bin/bash

# SolarNexus Quick Install - No Prompts
# For existing SolarNexus directory structure

echo "🚀 SolarNexus Quick Install (No Prompts)"
echo "========================================"

# Check if we're in the right place
if [ ! -f "docker-compose.production.yml" ] && [ ! -f "deploy/docker-compose.production.yml" ]; then
    echo "❌ Please run from SolarNexus root or deploy directory"
    exit 1
fi

# Go to deploy directory
if [ -f "deploy/docker-compose.production.yml" ]; then
    cd deploy
fi

echo "🛑 Cleaning up existing containers..."
docker compose -f docker-compose.production.yml down 2>/dev/null || true
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

echo "🐳 Creating volumes..."
docker volume create postgres_data 2>/dev/null || true
docker volume create redis_data 2>/dev/null || true

echo "🏗️  Building and starting services..."
docker compose -f docker-compose.production.yml up -d --build

echo "⏳ Waiting for services..."
sleep 20

echo "🧪 Health Check:"
curl -I http://localhost:80 2>/dev/null | head -1 || echo "Frontend: Starting..."
curl -I http://localhost:3000/health 2>/dev/null | head -1 || echo "Backend: Starting..."

echo ""
echo "✅ Done! Check http://localhost:80"