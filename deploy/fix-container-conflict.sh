#!/bin/bash

# Fix Container Name Conflict Script
# Resolves the container name conflict issue

set -e

echo "🔧 Fixing Container Name Conflicts"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping conflicting containers...${NC}"

# Stop containers by name
docker stop solarnexus-postgres solarnexus-redis 2>/dev/null || true

# Stop containers by ID (from the error message)
docker stop e12c483b0a99 37034414f920 2>/dev/null || true

echo -e "${BLUE}🗑️  Removing conflicting containers...${NC}"

# Remove containers by name
docker rm -f solarnexus-postgres solarnexus-redis 2>/dev/null || true

# Remove containers by ID
docker rm -f e12c483b0a99 37034414f920 2>/dev/null || true

# Remove any other SolarNexus containers
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

echo -e "${BLUE}🧹 Cleaning up Docker Compose...${NC}"

# Stop any Docker Compose services
cd /root/SolarNexus 2>/dev/null || cd $(find / -name "docker-compose.compatible.yml" -exec dirname {} \; 2>/dev/null | head -1) || cd /root

if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    docker-compose -f deploy/docker-compose.compatible.yml down --remove-orphans 2>/dev/null || true
fi

if [[ -f "deploy/docker-compose.production.yml" ]]; then
    docker-compose -f deploy/docker-compose.production.yml down --remove-orphans 2>/dev/null || true
fi

echo -e "${BLUE}🔄 Recreating volumes...${NC}"

# Remove and recreate volumes
docker volume rm postgres_data redis_data 2>/dev/null || true
docker volume create postgres_data
docker volume create redis_data

echo -e "${BLUE}🚀 Starting services with Docker Compose...${NC}"

# Find the SolarNexus directory
SOLARNEXUS_DIR=""
POSSIBLE_DIRS=("/root/SolarNexus" "$(pwd)" "./SolarNexus" "../SolarNexus")

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/deploy/docker-compose.compatible.yml" ]]; then
        SOLARNEXUS_DIR="$dir"
        break
    fi
done

if [[ -z "$SOLARNEXUS_DIR" ]]; then
    echo -e "${RED}❌ Could not find SolarNexus directory${NC}"
    exit 1
fi

cd "$SOLARNEXUS_DIR"
echo -e "${GREEN}✅ Working in: $SOLARNEXUS_DIR${NC}"

# Start services
if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    echo -e "${BLUE}Using compatible Docker Compose...${NC}"
    docker-compose -f deploy/docker-compose.compatible.yml up -d
elif [[ -f "deploy/docker-compose.production.yml" ]]; then
    echo -e "${BLUE}Using production Docker Compose...${NC}"
    docker-compose -f deploy/docker-compose.production.yml up -d
else
    echo -e "${YELLOW}⚠️  Docker Compose files not found, starting manually...${NC}"
    
    # Start PostgreSQL
    docker run -d \
        --name solarnexus-postgres \
        --restart unless-stopped \
        -e POSTGRES_DB=solarnexus \
        -e POSTGRES_USER=solarnexus \
        -e POSTGRES_PASSWORD=solarnexus \
        -v postgres_data:/var/lib/postgresql/data \
        -p 5432:5432 \
        --network deploy_solarnexus-network \
        postgres:15-alpine
    
    # Start Redis
    docker run -d \
        --name solarnexus-redis \
        --restart unless-stopped \
        -v redis_data:/data \
        -p 6379:6379 \
        --network deploy_solarnexus-network \
        redis:7-alpine redis-server --appendonly yes
    
    # Wait for services
    sleep 10
    
    # Start backend if image exists
    if docker images --format "{{.Repository}}" | grep -q "solarnexus-backend"; then
        docker run -d \
            --name solarnexus-backend \
            --restart unless-stopped \
            --network deploy_solarnexus-network \
            -e DATABASE_URL=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus \
            -e REDIS_URL=redis://solarnexus-redis:6379 \
            -e NODE_ENV=production \
            -p 3000:3000 \
            solarnexus-backend:latest
    fi
    
    # Start frontend if image exists
    if docker images --format "{{.Repository}}" | grep -q "solarnexus-frontend"; then
        docker run -d \
            --name solarnexus-frontend \
            --restart unless-stopped \
            --network deploy_solarnexus-network \
            -p 8080:80 \
            solarnexus-frontend:latest
    fi
fi

echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 15

echo -e "${BLUE}🧪 Testing services...${NC}"

# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
fi

# Test Backend
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend API: ${YELLOW}⚠️  Starting${NC}"
else
    echo -e "  Backend API: ${RED}❌ Not Running${NC}"
fi

# Test Frontend
if curl -f http://localhost:8080 >/dev/null 2>&1; then
    echo -e "  Frontend: ${GREEN}✅ Ready${NC}"
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-frontend"; then
    echo -e "  Frontend: ${YELLOW}⚠️  Starting${NC}"
else
    echo -e "  Frontend: ${RED}❌ Not Running${NC}"
fi

echo -e "\n${GREEN}🎉 Container conflicts resolved!${NC}"

echo -e "\n${BLUE}📋 Current Status:${NC}"
echo "  • Working Directory: $SOLARNEXUS_DIR"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=solarnexus"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • View containers: docker ps"
echo "  • Check logs: docker logs solarnexus-backend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Access frontend: http://localhost:8080"

echo -e "\n${GREEN}✅ Services should now be running without conflicts!${NC}"