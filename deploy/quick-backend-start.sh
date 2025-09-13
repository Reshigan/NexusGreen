#!/bin/bash

# SolarNexus Quick Backend Start Script
# Starts only the backend services (postgres, redis, backend) for development

set -e

echo "🚀 SolarNexus Quick Backend Start"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Find SolarNexus directory
SOLARNEXUS_DIR=""
if [[ -f "docker-compose.simple.yml" ]]; then
    SOLARNEXUS_DIR="$(pwd)"
elif [[ -d "SolarNexus" ]]; then
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
elif [[ -d "/home/ubuntu/SolarNexus" ]]; then
    SOLARNEXUS_DIR="/home/ubuntu/SolarNexus"
elif [[ -d "/root/SolarNexus" ]]; then
    SOLARNEXUS_DIR="/root/SolarNexus"
else
    echo -e "${YELLOW}⚠️  SolarNexus directory not found. Cloning...${NC}"
    git clone https://github.com/Reshigan/SolarNexus.git SolarNexus
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
fi

cd "$SOLARNEXUS_DIR"
echo -e "${GREEN}✅ Working in: $SOLARNEXUS_DIR${NC}"

# Check if we have docker-compose.simple.yml
if [[ ! -f "docker-compose.simple.yml" ]]; then
    echo -e "${RED}❌ docker-compose.simple.yml not found in $SOLARNEXUS_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}🐳 Starting backend services...${NC}"

# Start only backend services using docker-compose
docker-compose -f docker-compose.simple.yml up -d postgres redis backend

echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 15

echo -e "\n${BLUE}🧪 Testing services...${NC}"

# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping | grep -q "PONG" 2>/dev/null; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
fi

# Test Backend (give it more time)
sleep 10
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend API: ${YELLOW}⚠️  Starting (may need more time)${NC}"
else
    echo -e "  Backend API: ${RED}❌ Not Running${NC}"
fi

echo -e "\n${GREEN}✅ Backend services started!${NC}"
echo -e "\n${BLUE}🔧 Available endpoints:${NC}"
echo "  • Backend API: http://localhost:3000/"
echo "  • Health Check: http://localhost:3000/health"
echo "  • Database: localhost:5432 (user: solarnexus, db: solarnexus)"
echo "  • Redis: localhost:6379"

echo -e "\n${BLUE}🔧 Useful commands:${NC}"
echo "  • Check status: docker-compose -f docker-compose.simple.yml ps"
echo "  • View logs: docker-compose -f docker-compose.simple.yml logs backend"
echo "  • Stop services: docker-compose -f docker-compose.simple.yml down"
echo "  • Database shell: docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus"
echo "  • Redis shell: docker exec -it solarnexus-redis redis-cli"

echo -e "\n${GREEN}🎉 Ready for development!${NC}"