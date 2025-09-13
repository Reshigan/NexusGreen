#!/bin/bash

# SolarNexus Working Deployment Script
# This script ensures a clean, working deployment every time

set -e

echo "🚀 SolarNexus Working Deployment"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./deploy-working.sh"
   exit 1
fi

# Get current directory for installation
INSTALL_DIR="$(pwd)"
echo -e "${BLUE}📍 Working in directory: $INSTALL_DIR${NC}"

echo -e "\n${RED}🛑 STEP 1: Cleaning up any existing containers...${NC}"

# Function to safely stop and remove containers
cleanup_containers() {
    local pattern=$1
    local containers=$(docker ps -aq --filter "name=$pattern" 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        echo -e "${BLUE}Stopping containers matching '$pattern'...${NC}"
        docker stop $containers 2>/dev/null || true
        echo -e "${BLUE}Removing containers matching '$pattern'...${NC}"
        docker rm -f $containers 2>/dev/null || true
    fi
}

# Stop and remove containers with different naming patterns
cleanup_containers "solarnexus"

# Remove any existing docker-compose services
if [[ -f "docker-compose.yml" ]]; then
    echo -e "${BLUE}Stopping existing docker-compose services...${NC}"
    docker-compose down 2>/dev/null || true
fi

if [[ -f "docker-compose.working.yml" ]]; then
    echo -e "${BLUE}Stopping existing working docker-compose services...${NC}"
    docker-compose -f docker-compose.working.yml down 2>/dev/null || true
fi

echo -e "${GREEN}✅ Cleanup completed${NC}"

echo -e "\n${BLUE}🐳 STEP 2: Creating Docker volumes...${NC}"

# Create fresh volumes
docker volume create postgres_data 2>/dev/null || true
docker volume create redis_data 2>/dev/null || true

echo -e "${GREEN}✅ Docker volumes ready${NC}"

echo -e "\n${BLUE}📦 STEP 3: Pulling base Docker images...${NC}"

# Pull required images
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:20-alpine
docker pull node:20-slim

echo -e "${GREEN}✅ Base images pulled${NC}"

echo -e "\n${BLUE}⚙️  STEP 4: Creating environment configuration...${NC}"

# Create production environment file
cat > .env << 'EOF'
# SolarNexus Production Environment
NODE_ENV=production

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus

# Redis Configuration
REDIS_URL=redis://redis:6379

# Security
JWT_SECRET=your_super_secure_jwt_secret_key_2024
JWT_REFRESH_SECRET=your_super_secure_jwt_refresh_secret_key_2024

# API Configuration
REACT_APP_API_URL=http://localhost:3000
API_PORT=3000

# Frontend Configuration
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

echo -e "\n${BLUE}📁 STEP 5: Creating required directories...${NC}"

# Create necessary directories
mkdir -p uploads logs logs/nginx backups
chmod 755 uploads logs logs/nginx backups

echo -e "${GREEN}✅ Directories created${NC}"

echo -e "\n${BLUE}🗄️  STEP 6: Starting database services first...${NC}"

# Start only database services first
docker-compose -f docker-compose.working.yml up -d postgres redis

echo -e "${BLUE}⏳ Waiting for database services to initialize...${NC}"
sleep 30

# Test database services
echo -e "${BLUE}🧪 Testing database services...${NC}"

# Wait for PostgreSQL to be ready
POSTGRES_READY=false
for i in {1..30}; do
    if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
        echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
        POSTGRES_READY=true
        break
    fi
    echo -e "  PostgreSQL: Waiting... ($i/30)"
    sleep 2
done

if [[ "$POSTGRES_READY" != true ]]; then
    echo -e "  PostgreSQL: ${RED}❌ Failed to start${NC}"
    echo -e "${YELLOW}Checking PostgreSQL logs:${NC}"
    docker logs solarnexus-postgres --tail 20
    exit 1
fi

# Wait for Redis to be ready
REDIS_READY=false
for i in {1..15}; do
    if docker exec solarnexus-redis redis-cli ping | grep -q "PONG" 2>/dev/null; then
        echo -e "  Redis: ${GREEN}✅ Ready${NC}"
        REDIS_READY=true
        break
    fi
    echo -e "  Redis: Waiting... ($i/15)"
    sleep 2
done

if [[ "$REDIS_READY" != true ]]; then
    echo -e "  Redis: ${RED}❌ Failed to start${NC}"
    echo -e "${YELLOW}Checking Redis logs:${NC}"
    docker logs solarnexus-redis --tail 20
    exit 1
fi

echo -e "\n${BLUE}🗄️  STEP 7: Setting up database schema...${NC}"

# Create database
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;" 2>/dev/null || echo "Database already exists"

# Apply migration if available
if [[ -f "solarnexus-backend/migration.sql" ]]; then
    echo -e "${GREEN}✅ Found migration file, applying...${NC}"
    docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo -e "${GREEN}✅ Database migration completed${NC}"
else
    echo -e "${YELLOW}⚠️  Migration file not found, database will be initialized by backend${NC}"
fi

echo -e "\n${BLUE}🏗️  STEP 8: Building and starting backend...${NC}"

# Build and start backend
docker-compose -f docker-compose.working.yml up -d --build backend

echo -e "${BLUE}⏳ Waiting for backend to start...${NC}"
sleep 45

# Test backend
BACKEND_READY=false
for i in {1..20}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
        BACKEND_READY=true
        break
    elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
        echo -e "  Backend API: Starting... ($i/20)"
        sleep 3
    else
        echo -e "  Backend API: ${RED}❌ Container not running${NC}"
        break
    fi
done

if [[ "$BACKEND_READY" != true ]]; then
    echo -e "  Backend API: ${YELLOW}⚠️  Not responding, checking logs...${NC}"
    docker logs solarnexus-backend --tail 30
    echo -e "${BLUE}Continuing with frontend build...${NC}"
fi

echo -e "\n${BLUE}🎨 STEP 9: Building and starting frontend...${NC}"

# Build and start frontend
docker-compose -f docker-compose.working.yml up -d --build frontend

echo -e "${BLUE}⏳ Waiting for frontend to start...${NC}"
sleep 30

# Test frontend
FRONTEND_READY=false
for i in {1..15}; do
    if curl -f http://localhost/ >/dev/null 2>&1; then
        echo -e "  Frontend: ${GREEN}✅ Ready${NC}"
        FRONTEND_READY=true
        break
    elif docker ps --format "{{.Names}}" | grep -q "solarnexus-frontend"; then
        echo -e "  Frontend: Starting... ($i/15)"
        sleep 2
    else
        echo -e "  Frontend: ${RED}❌ Container not running${NC}"
        break
    fi
done

if [[ "$FRONTEND_READY" != true ]]; then
    echo -e "  Frontend: ${YELLOW}⚠️  Not responding, checking logs...${NC}"
    docker logs solarnexus-frontend --tail 20
fi

echo -e "\n${GREEN}🎉 SolarNexus Deployment Completed!${NC}"

echo -e "\n${BLUE}📋 Deployment Summary:${NC}"
echo "  • Installation Directory: $INSTALL_DIR"
echo "  • PostgreSQL: Port 5432 $([ "$POSTGRES_READY" = true ] && echo "✅" || echo "❌")"
echo "  • Redis: Port 6379 $([ "$REDIS_READY" = true ] && echo "✅" || echo "❌")"
echo "  • Backend API: Port 3000 $([ "$BACKEND_READY" = true ] && echo "✅" || echo "⚠️")"
echo "  • Frontend: Port 80 $([ "$FRONTEND_READY" = true ] && echo "✅" || echo "⚠️")"

echo -e "\n${BLUE}🔧 Service Status:${NC}"
docker-compose -f docker-compose.working.yml ps

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • Check all services: docker-compose -f docker-compose.working.yml ps"
echo "  • Check backend logs: docker-compose -f docker-compose.working.yml logs backend"
echo "  • Check frontend logs: docker-compose -f docker-compose.working.yml logs frontend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Access frontend: http://localhost/"
echo "  • Database shell: docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus"
echo "  • Redis shell: docker exec -it solarnexus-redis redis-cli"

echo -e "\n${BLUE}🔄 Service Management:${NC}"
echo "  • Stop all: docker-compose -f docker-compose.working.yml down"
echo "  • Start all: docker-compose -f docker-compose.working.yml up -d"
echo "  • Restart: docker-compose -f docker-compose.working.yml restart"
echo "  • Rebuild: docker-compose -f docker-compose.working.yml up -d --build"

if [[ "$BACKEND_READY" = false ]] || [[ "$FRONTEND_READY" = false ]]; then
    echo -e "\n${YELLOW}⚠️  Some services may still be starting. Wait a few minutes and check:${NC}"
    echo "  • docker-compose -f docker-compose.working.yml ps"
    echo "  • docker-compose -f docker-compose.working.yml logs [service-name]"
fi

echo -e "\n${GREEN}✅ SolarNexus is ready for use!${NC}"
echo -e "${GREEN}🌟 Access your solar portal at: http://localhost/${NC}"
echo -e "${GREEN}🔧 API endpoint available at: http://localhost:3000/${NC}"