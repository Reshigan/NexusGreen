#!/bin/bash

# SolarNexus Local Clean Install Script
# Version: 2.1.0
# Updated: 2025-09-13
# For use in existing SolarNexus directory

set -e

echo "🧹 SolarNexus Local Clean Install"
echo "================================="
echo "⚠️  WARNING: This will completely remove all SolarNexus data and containers!"
echo "⚠️  This includes databases, volumes, and all configuration!"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.production.yml" ] && [ ! -f "deploy/docker-compose.production.yml" ]; then
    echo "❌ Error: docker-compose.production.yml not found!"
    echo "Please run this script from the SolarNexus root directory or deploy directory"
    exit 1
fi

# Determine working directory
if [ -f "docker-compose.production.yml" ]; then
    DEPLOY_DIR="."
    SOLARNEXUS_DIR=".."
elif [ -f "deploy/docker-compose.production.yml" ]; then
    DEPLOY_DIR="deploy"
    SOLARNEXUS_DIR="."
else
    echo "❌ Error: Cannot determine directory structure"
    exit 1
fi

echo "📁 Working from: $(pwd)"
echo "📁 Deploy directory: $DEPLOY_DIR"
echo ""

# Interactive confirmation when run directly, skip when piped
if [ -t 0 ]; then
    read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm
    if [ "$confirm" != "YES" ]; then
        echo "❌ Installation cancelled"
        exit 1
    fi
else
    echo "🤖 Running in non-interactive mode (piped input detected)"
    echo "⚠️  Proceeding with installation in 5 seconds..."
    echo "⚠️  Press Ctrl+C to cancel!"
    sleep 5
fi

echo ""
echo "🛑 STEP 1: Stopping and removing all SolarNexus services..."

cd "$DEPLOY_DIR"

# Stop and remove containers
echo "Stopping containers..."
docker compose -f docker-compose.production.yml down 2>/dev/null || true
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

# Remove images
echo "Removing images..."
docker rmi solarnexus-frontend:latest 2>/dev/null || true
docker rmi solarnexus-backend:latest 2>/dev/null || true

# Remove volumes
echo "Removing volumes..."
docker volume rm postgres_data 2>/dev/null || true
docker volume rm redis_data 2>/dev/null || true

# Remove networks
echo "Removing networks..."
docker network rm deploy_solarnexus-network 2>/dev/null || true

echo "✅ All SolarNexus Docker resources removed"

echo ""
echo "🐳 STEP 2: Creating Docker volumes..."
docker volume create postgres_data
docker volume create redis_data
echo "✅ Docker volumes created"

echo ""
echo "📦 STEP 3: Pulling Docker images..."
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:20-alpine
echo "✅ Docker images pulled"

echo ""
echo "🗄️  STEP 4: Starting database services..."
docker compose -f docker-compose.production.yml up -d postgres redis

echo "⏳ Waiting for database services to start..."
sleep 10

echo "🧪 Testing database services..."
# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo "  PostgreSQL: ✅ Ready"
else
    echo "  PostgreSQL: ❌ Not ready, waiting longer..."
    sleep 10
    if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
        echo "  PostgreSQL: ✅ Ready"
    else
        echo "  PostgreSQL: ❌ Failed to start"
        exit 1
    fi
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping >/dev/null 2>&1; then
    echo "  Redis: ✅ Ready"
else
    echo "  Redis: ❌ Failed to start"
    exit 1
fi

echo ""
echo "🗄️  STEP 5: Setting up database schema..."

# Check if database exists and apply migration
if [ -f "../solarnexus-backend/prisma/migrations/migration.sql" ]; then
    echo "✅ Found migration file, applying..."
    docker cp "../solarnexus-backend/prisma/migrations/migration.sql" solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo "✅ Database migration completed"
elif [ -f "migration.sql" ]; then
    echo "✅ Found migration file in deploy directory, applying..."
    docker cp "migration.sql" solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo "✅ Database migration completed"
else
    echo "⚠️  No migration file found, database will be initialized by backend"
fi

echo ""
echo "⚙️  STEP 6: Checking environment configuration..."
if [ ! -f ".env" ]; then
    if [ -f ".env.production" ]; then
        echo "✅ Copying .env.production to .env"
        cp .env.production .env
    else
        echo "⚠️  No .env file found, creating basic configuration..."
        cat > .env << 'EOF'
# Basic SolarNexus Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus_secure_password
DATABASE_URL=postgresql://solarnexus:solarnexus_secure_password@postgres:5432/solarnexus
JWT_SECRET=your_super_secure_jwt_secret_key_here_minimum_32_characters
REDIS_URL=redis://redis:6379
NODE_ENV=production
PORT=3000
VITE_API_URL=http://localhost:3000
CORS_ORIGIN=http://localhost:80,http://localhost:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
    fi
else
    echo "✅ Environment configuration exists"
fi

echo ""
echo "🏗️  STEP 7: Building application images..."

echo "Building backend image..."
docker compose -f docker-compose.production.yml build backend
echo "✅ Backend image built"

echo "Building frontend image..."
docker compose -f docker-compose.production.yml build frontend
echo "✅ Frontend image built"

echo ""
echo "🚀 STEP 8: Starting all services..."
docker compose -f docker-compose.production.yml up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

echo ""
echo "🧪 STEP 9: Running health checks..."

# Frontend Health Check
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "  Frontend (Port 80): ✅ Healthy (HTTP $FRONTEND_STATUS)"
else
    echo "  Frontend (Port 80): ⚠️  Status: HTTP $FRONTEND_STATUS (may still be starting)"
fi

# Backend Health Check
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "000")
if [ "$BACKEND_STATUS" = "200" ]; then
    echo "  Backend (Port 3000): ✅ Healthy (HTTP $BACKEND_STATUS)"
else
    echo "  Backend (Port 3000): ⚠️  Status: HTTP $BACKEND_STATUS (may still be starting)"
fi

# Database Health Check
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo "  PostgreSQL Database: ✅ Healthy"
else
    echo "  PostgreSQL Database: ❌ Unhealthy"
fi

# Redis Health Check
if docker exec solarnexus-redis redis-cli ping >/dev/null 2>&1; then
    echo "  Redis Cache: ✅ Healthy"
else
    echo "  Redis Cache: ❌ Unhealthy"
fi

echo ""
echo "📊 Container Status:"
docker compose -f docker-compose.production.yml ps

echo ""
echo "🎉 SolarNexus Installation Complete!"
echo "=================================="
echo ""
echo "🌐 Your application is now running at:"
echo "  • Web Interface: http://localhost:80"
echo "  • API Endpoints: http://localhost:3000"
echo "  • Health Check: http://localhost:3000/health"
echo ""
echo "📁 Installation Directory: $(pwd)"
echo ""
echo "🔧 Useful Commands:"
echo "  • View logs: docker compose -f docker-compose.production.yml logs"
echo "  • Restart: docker compose -f docker-compose.production.yml restart"
echo "  • Stop: docker compose -f docker-compose.production.yml down"
echo "  • Status: docker compose -f docker-compose.production.yml ps"
echo ""
echo "📖 For more information, see the SERVER-DEPLOYMENT-GUIDE.md"