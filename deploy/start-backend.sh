#!/bin/bash

# Start SolarNexus Backend Service
# Since PostgreSQL and Redis are working, just start the backend

set -e

echo "🚀 Starting SolarNexus Backend Service"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking current status...${NC}"

# Check if PostgreSQL and Redis are running (they should be)
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
    exit 1
fi

if docker exec solarnexus-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
    exit 1
fi

# Check if backend is already running
if docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend: ${YELLOW}⚠️  Already running, restarting...${NC}"
    docker stop solarnexus-backend
    docker rm solarnexus-backend
else
    echo -e "  Backend: ${BLUE}ℹ️  Not running${NC}"
fi

echo -e "\n${BLUE}📁 Finding SolarNexus directory...${NC}"

# Find the SolarNexus directory
SOLARNEXUS_DIR=""
POSSIBLE_DIRS=("/root/SolarNexus" "$(pwd)" "./SolarNexus" "../SolarNexus" "/home/ubuntu/SolarNexus")

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/deploy/docker-compose.compatible.yml" || -f "$dir/solarnexus-backend/package.json" ]]; then
        SOLARNEXUS_DIR="$dir"
        break
    fi
done

if [[ -z "$SOLARNEXUS_DIR" ]]; then
    echo -e "${YELLOW}⚠️  SolarNexus directory not found, cloning...${NC}"
    git clone https://github.com/Reshigan/SolarNexus.git /root/SolarNexus
    SOLARNEXUS_DIR="/root/SolarNexus"
fi

cd "$SOLARNEXUS_DIR"
echo -e "${GREEN}✅ Working in: $SOLARNEXUS_DIR${NC}"

echo -e "\n${BLUE}⚙️  Creating environment file...${NC}"

# Create environment file if it doesn't exist
if [[ ! -f ".env.production" ]]; then
    cat > .env.production << 'EOF'
NODE_ENV=production
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus
REDIS_URL=redis://solarnexus-redis:6379
JWT_SECRET=your_jwt_secret_change_in_production
REACT_APP_API_URL=https://nexus.gonxt.tech/api
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
EOF
    echo -e "${GREEN}✅ Environment file created${NC}"
else
    echo -e "${GREEN}✅ Environment file exists${NC}"
fi

echo -e "\n${BLUE}🏗️  Building backend image...${NC}"

# Build backend image if Dockerfile exists
if [[ -f "solarnexus-backend/Dockerfile" ]]; then
    echo -e "${BLUE}Building from Dockerfile...${NC}"
    docker build -t solarnexus-backend:latest solarnexus-backend/
    echo -e "${GREEN}✅ Backend image built${NC}"
else
    echo -e "${YELLOW}⚠️  No Dockerfile found, will try Docker Compose build${NC}"
fi

echo -e "\n${BLUE}🚀 Starting backend service...${NC}"

# Try Docker Compose first
if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    echo -e "${BLUE}Using Docker Compose...${NC}"
    docker-compose -f deploy/docker-compose.compatible.yml up -d backend
elif [[ -f "deploy/docker-compose.production.yml" ]]; then
    echo -e "${BLUE}Using production Docker Compose...${NC}"
    docker-compose -f deploy/docker-compose.production.yml up -d backend
else
    echo -e "${BLUE}Using direct Docker command...${NC}"
    
    # Get the network name
    NETWORK_NAME=$(docker network ls --format "{{.Name}}" | grep solarnexus | head -1)
    if [[ -z "$NETWORK_NAME" ]]; then
        NETWORK_NAME="deploy_solarnexus-network"
        docker network create "$NETWORK_NAME" 2>/dev/null || true
    fi
    
    # Start backend container directly
    docker run -d \
        --name solarnexus-backend \
        --restart unless-stopped \
        --network "$NETWORK_NAME" \
        -e NODE_ENV=production \
        -e DATABASE_URL=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus \
        -e REDIS_URL=redis://solarnexus-redis:6379 \
        -e JWT_SECRET=your_jwt_secret_change_in_production \
        -p 3000:3000 \
        -v "$PWD/logs:/app/logs" \
        solarnexus-backend:latest
fi

echo -e "\n${BLUE}⏳ Waiting for backend to start...${NC}"
sleep 20

echo -e "\n${BLUE}🧪 Testing backend service...${NC}"

# Test backend multiple times
for i in {1..5}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
        BACKEND_OK=true
        break
    else
        echo -e "  Attempt $i: ${YELLOW}⚠️  Still starting...${NC}"
        sleep 5
    fi
done

if [[ "$BACKEND_OK" != true ]]; then
    echo -e "  Backend API: ${RED}❌ Not responding${NC}"
    echo -e "\n${BLUE}📋 Checking backend logs...${NC}"
    docker logs solarnexus-backend --tail 20
    
    echo -e "\n${BLUE}🔧 Troubleshooting steps:${NC}"
    echo "  1. Check if backend container is running: docker ps"
    echo "  2. Check backend logs: docker logs solarnexus-backend"
    echo "  3. Check if port 3000 is available: netstat -tlnp | grep 3000"
    echo "  4. Try restarting: docker restart solarnexus-backend"
else
    echo -e "\n${GREEN}🎉 Backend is running successfully!${NC}"
fi

echo -e "\n${BLUE}📋 Current Status:${NC}"
echo "  • Working Directory: $SOLARNEXUS_DIR"
echo "  • PostgreSQL: ✅ Ready on port 5432"
echo "  • Redis: ✅ Ready on port 6379"
echo "  • Backend: $([ "$BACKEND_OK" = true ] && echo "✅ Ready" || echo "⚠️  Check logs") on port 3000"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Check logs: docker logs solarnexus-backend"
echo "  • Restart backend: docker restart solarnexus-backend"
echo "  • View containers: docker ps"

if [[ "$BACKEND_OK" = true ]]; then
    echo -e "\n${GREEN}✅ SolarNexus backend is ready!${NC}"
    echo -e "${GREEN}🌟 API available at: http://localhost:3000${NC}"
else
    echo -e "\n${YELLOW}⚠️  Backend needs troubleshooting. Check the logs above.${NC}"
fi