#!/bin/bash

# SolarNexus Server Clean Install Script
# Version: 2.1.0
# Updated: 2025-09-13

set -e

echo "🧹 SolarNexus Server Clean Install"
echo "=================================="
echo "⚠️  WARNING: This will completely remove all SolarNexus data and containers!"
echo "⚠️  This includes databases, volumes, and all configuration!"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm

if [ "$confirm" != "YES" ]; then
    echo "❌ Installation cancelled"
    exit 1
fi

echo ""
echo "🛑 STEP 1: Stopping and removing all SolarNexus services..."

# Stop and remove containers
echo "Stopping containers..."
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

# Remove images
echo "Removing images..."
docker rmi solarnexus-frontend:latest 2>/dev/null || true
docker rmi solarnexus-backend:latest 2>/dev/null || true
docker rmi deploy-frontend:latest 2>/dev/null || true
docker rmi deploy-backend:latest 2>/dev/null || true

# Remove volumes
echo "Removing volumes..."
docker volume rm postgres_data redis_data 2>/dev/null || true
docker volume rm deploy_postgres_data deploy_redis_data 2>/dev/null || true

# Remove networks
echo "Removing networks..."
docker network rm deploy_solarnexus-network 2>/dev/null || true
docker network rm solarnexus-network 2>/dev/null || true

echo "✅ All SolarNexus Docker resources removed"

echo ""
echo "🗑️  STEP 2: Removing SolarNexus directories..."
INSTALL_DIR="/opt/solarnexus"
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi
echo "✅ All SolarNexus directories removed"

echo ""
echo "🧹 STEP 3: Cleaning Docker system..."
docker system prune -af --volumes
echo "✅ Docker system cleaned"

echo ""
echo "🚀 STEP 4: Fresh installation..."
echo "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "📥 Cloning SolarNexus repository..."
git clone https://github.com/Reshigan/SolarNexus.git .
echo "✅ Repository cloned"

echo ""
echo "🐳 STEP 5: Creating Docker volumes..."
docker volume create deploy_postgres_data
docker volume create deploy_redis_data
echo "✅ Docker volumes created"

echo ""
echo "📦 STEP 6: Pulling Docker images..."
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:20-alpine
echo "✅ Docker images pulled"

echo ""
echo "🗄️  STEP 7: Starting database services..."
cd deploy
docker compose -f docker-compose.production.yml up -d postgres redis

echo "⏳ Waiting for database services to start..."
sleep 10

echo "🧪 Testing database services..."
# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus > /dev/null 2>&1; then
    echo "  PostgreSQL: ✅ Ready"
else
    echo "  PostgreSQL: ❌ Not ready"
    exit 1
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping > /dev/null 2>&1; then
    echo "  Redis: ✅ Ready"
else
    echo "  Redis: ❌ Not ready"
    exit 1
fi

echo ""
echo "🗄️  STEP 8: Setting up database schema..."
# Check if database exists
DB_EXISTS=$(docker exec solarnexus-postgres psql -U solarnexus -lqt | cut -d \| -f 1 | grep -w solarnexus | wc -l)

if [ "$DB_EXISTS" -eq 0 ]; then
    echo "Creating database..."
    docker exec solarnexus-postgres createdb -U solarnexus solarnexus
else
    echo "Database already exists"
fi

# Apply migration if it exists
if [ -f "../solarnexus-backend/prisma/migration.sql" ]; then
    echo "✅ Found migration file, applying..."
    docker cp ../solarnexus-backend/prisma/migration.sql solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo "✅ Database migration completed"
else
    echo "⚠️  No migration file found, skipping database setup"
fi

echo ""
echo "🏗️  STEP 9: Building and starting all services..."
docker compose -f docker-compose.production.yml up -d --build

echo ""
echo "⏳ Waiting for all services to start..."
sleep 15

echo ""
echo "🧪 STEP 10: Testing all services..."

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
echo "🎉 SolarNexus installation completed successfully!"
echo ""
echo "📊 Service Status:"
docker compose -f docker-compose.production.yml ps
echo ""
echo "🌐 Access your application:"
echo "  • Web Interface: http://localhost:80"
echo "  • API Endpoints: http://localhost:3000"
echo "  • Health Check: http://localhost:3000/health"
echo ""
echo "📁 Installation Directory: $INSTALL_DIR"
echo "🔧 Configuration Files:"
echo "  • Environment: $INSTALL_DIR/.env.production"
echo "  • Docker Compose: $INSTALL_DIR/deploy/docker-compose.production.yml"
echo ""
echo "📝 Useful Commands:"
echo "  • View logs: docker compose -f deploy/docker-compose.production.yml logs [service]"
echo "  • Restart: docker compose -f deploy/docker-compose.production.yml restart"
echo "  • Stop: docker compose -f deploy/docker-compose.production.yml down"
echo ""
echo "✅ SolarNexus is now running!"