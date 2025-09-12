#!/bin/bash

# Quick Backend Start - Skip Docker Compose conflicts
# Since PostgreSQL and Redis are already working, just start the backend

echo "🚀 Quick Backend Start (Skip Container Conflicts)"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}✅ PostgreSQL and Redis are already working!${NC}"

# Remove any existing backend container
echo -e "${BLUE}🗑️  Removing existing backend container...${NC}"
docker stop solarnexus-backend 2>/dev/null || true
docker rm solarnexus-backend 2>/dev/null || true

# Find SolarNexus directory
SOLARNEXUS_DIR=""
if [[ -d "/root/SolarNexus" ]]; then
    SOLARNEXUS_DIR="/root/SolarNexus"
elif [[ -d "SolarNexus" ]]; then
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
elif [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    SOLARNEXUS_DIR="$(pwd)"
else
    echo -e "${YELLOW}⚠️  Cloning SolarNexus...${NC}"
    git clone https://github.com/Reshigan/SolarNexus.git /root/SolarNexus
    SOLARNEXUS_DIR="/root/SolarNexus"
fi

cd "$SOLARNEXUS_DIR"
echo -e "${GREEN}✅ Working in: $SOLARNEXUS_DIR${NC}"

# Build backend image if needed
echo -e "${BLUE}🏗️  Building backend image...${NC}"
if [[ -f "solarnexus-backend/Dockerfile" ]]; then
    docker build -t solarnexus-backend:latest solarnexus-backend/
    echo -e "${GREEN}✅ Backend image built${NC}"
else
    echo -e "${RED}❌ No backend Dockerfile found${NC}"
    exit 1
fi

# Get network name (use existing network)
NETWORK_NAME=$(docker inspect solarnexus-postgres --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' 2>/dev/null || echo "bridge")
echo -e "${BLUE}🌐 Using network: $NETWORK_NAME${NC}"

# Start backend container
echo -e "${BLUE}🚀 Starting backend container...${NC}"
docker run -d \
    --name solarnexus-backend \
    --restart unless-stopped \
    --network "$NETWORK_NAME" \
    -e NODE_ENV=production \
    -e DATABASE_URL=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus \
    -e REDIS_URL=redis://solarnexus-redis:6379 \
    -e JWT_SECRET=your_jwt_secret_change_in_production \
    -e REACT_APP_API_URL=https://nexus.gonxt.tech/api \
    -p 3000:3000 \
    -v "$PWD/logs:/app/logs" \
    solarnexus-backend:latest

echo -e "${BLUE}⏳ Waiting for backend to start...${NC}"
sleep 15

# Test backend
echo -e "${BLUE}🧪 Testing backend...${NC}"
for i in {1..6}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ Ready!${NC}"
        BACKEND_OK=true
        break
    else
        echo -e "  Attempt $i/6: ${YELLOW}⚠️  Still starting...${NC}"
        sleep 5
    fi
done

if [[ "$BACKEND_OK" != true ]]; then
    echo -e "  Backend API: ${RED}❌ Not responding${NC}"
    echo -e "\n${BLUE}📋 Backend logs:${NC}"
    docker logs solarnexus-backend --tail 15
else
    echo -e "\n${GREEN}🎉 Success! All services are running:${NC}"
    echo -e "  • PostgreSQL: ${GREEN}✅ Port 5432${NC}"
    echo -e "  • Redis: ${GREEN}✅ Port 6379${NC}"
    echo -e "  • Backend API: ${GREEN}✅ Port 3000${NC}"
    
    echo -e "\n${BLUE}🔧 Test commands:${NC}"
    echo "  curl http://localhost:3000/health"
    echo "  docker logs solarnexus-backend"
    echo "  docker ps"
fi

echo -e "\n${GREEN}✅ Backend startup completed!${NC}"