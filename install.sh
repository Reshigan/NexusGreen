#!/bin/bash

# SolarNexus Simple Installation Script
# Run this from the SolarNexus directory

set -e

echo "🚀 SolarNexus Simple Installation"
echo "================================="
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.simple.yml" ] || [ ! -f "package.json" ]; then
    echo "❌ Error: Please run this script from the SolarNexus root directory"
    echo "   Make sure you have docker-compose.simple.yml and package.json"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available"
    exit 1
fi

# Use docker compose or docker-compose
DOCKER_COMPOSE="docker compose"
if ! docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
fi

echo "🧹 Step 1: Cleaning up any existing containers..."
$DOCKER_COMPOSE -f docker-compose.simple.yml down --remove-orphans 2>/dev/null || true
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

echo "⚙️  Step 2: Setting up environment..."
if [ ! -f ".env" ]; then
    echo "   Creating .env file from template..."
    cp .env.simple .env
    echo "   ✅ Created .env file (you can customize it later)"
else
    echo "   ✅ Using existing .env file"
fi

echo "📁 Step 3: Creating required directories..."
mkdir -p uploads logs backups
echo "   ✅ Created directories"

echo "🐳 Step 4: Building and starting services..."
echo "   This may take a few minutes on first run..."
$DOCKER_COMPOSE -f docker-compose.simple.yml up -d --build

echo "⏳ Step 5: Waiting for services to start..."
echo "   Waiting 30 seconds for all services to initialize..."
sleep 30

echo "🧪 Step 6: Health check..."
echo ""

# Check Frontend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    echo "   ✅ Frontend: http://localhost:80 (Ready)"
else
    echo "   ⚠️  Frontend: http://localhost:80 (Starting...)"
fi

# Check Backend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health | grep -q "200"; then
    echo "   ✅ Backend: http://localhost:3000 (Ready)"
else
    echo "   ⚠️  Backend: http://localhost:3000 (Starting...)"
fi

# Check Database
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo "   ✅ Database: PostgreSQL (Ready)"
else
    echo "   ❌ Database: PostgreSQL (Error)"
fi

# Check Redis
if docker exec solarnexus-redis redis-cli -a redis_secure_password_2024 ping >/dev/null 2>&1; then
    echo "   ✅ Cache: Redis (Ready)"
else
    echo "   ❌ Cache: Redis (Error)"
fi

echo ""
echo "📊 Container Status:"
$DOCKER_COMPOSE -f docker-compose.simple.yml ps

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "🌐 Your SolarNexus application is running at:"
echo "   • Web App: http://localhost:80"
echo "   • API: http://localhost:3000"
echo "   • Health Check: http://localhost:3000/health"
echo ""
echo "🔧 Useful Commands:"
echo "   • View logs: docker-compose -f docker-compose.simple.yml logs"
echo "   • Stop: docker-compose -f docker-compose.simple.yml down"
echo "   • Restart: docker-compose -f docker-compose.simple.yml restart"
echo "   • Update: git pull && docker-compose -f docker-compose.simple.yml up -d --build"
echo ""
echo "📝 Configuration:"
echo "   • Edit .env file to customize settings"
echo "   • Logs are in ./logs directory"
echo "   • Uploads are in ./uploads directory"
echo ""
echo "🚀 Ready to use SolarNexus!"