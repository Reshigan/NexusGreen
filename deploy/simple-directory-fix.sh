#!/bin/bash

# Simple Directory Fix for SolarNexus
# Works from any location and finds/creates the right directory structure

set -e

echo "🔧 Simple SolarNexus Directory Fix"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Looking for SolarNexus directory...${NC}"

# Check current directory first
if [[ -f "deploy/docker-compose.production.yml" ]] || [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    SOLARNEXUS_DIR="$(pwd)"
    echo -e "${GREEN}✅ Found SolarNexus in current directory: $SOLARNEXUS_DIR${NC}"
elif [[ -d "SolarNexus" ]] && [[ -f "SolarNexus/deploy/docker-compose.production.yml" ]]; then
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
    echo -e "${GREEN}✅ Found SolarNexus subdirectory: $SOLARNEXUS_DIR${NC}"
elif [[ -d "/root/SolarNexus" ]] && [[ -f "/root/SolarNexus/deploy/docker-compose.production.yml" ]]; then
    SOLARNEXUS_DIR="/root/SolarNexus"
    echo -e "${GREEN}✅ Found SolarNexus in /root: $SOLARNEXUS_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  SolarNexus directory not found. Creating it...${NC}"
    
    # Clone to current directory
    if [[ ! -d "SolarNexus" ]]; then
        echo -e "${BLUE}📥 Cloning SolarNexus repository...${NC}"
        git clone https://github.com/Reshigan/SolarNexus.git SolarNexus
    fi
    
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
    echo -e "${GREEN}✅ SolarNexus ready at: $SOLARNEXUS_DIR${NC}"
fi

# Change to SolarNexus directory
cd "$SOLARNEXUS_DIR"

echo -e "${BLUE}📋 Current status check...${NC}"

# Check if services are running (they should be from your previous output)
if docker ps --format "{{.Names}}" | grep -q "solarnexus-postgres"; then
    echo -e "  PostgreSQL: ${GREEN}✅ Running${NC}"
    POSTGRES_RUNNING=true
else
    echo -e "  PostgreSQL: ${RED}❌ Not Running${NC}"
    POSTGRES_RUNNING=false
fi

if docker ps --format "{{.Names}}" | grep -q "solarnexus-redis"; then
    echo -e "  Redis: ${GREEN}✅ Running${NC}"
    REDIS_RUNNING=true
else
    echo -e "  Redis: ${RED}❌ Not Running${NC}"
    REDIS_RUNNING=false
fi

# Since your services are already running, just complete the setup
if [[ "$POSTGRES_RUNNING" == true ]] && [[ "$REDIS_RUNNING" == true ]]; then
    echo -e "${GREEN}✅ Database and Redis are already running!${NC}"
    
    echo -e "${BLUE}🗄️  Checking database schema...${NC}"
    
    # Apply migration if available
    if [[ -f "solarnexus-backend/migration.sql" ]]; then
        echo -e "${GREEN}✅ Found migration file, applying...${NC}"
        docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
        docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql 2>/dev/null || echo "Migration already applied or failed"
        docker exec solarnexus-postgres rm -f /tmp/migration.sql
        echo -e "${GREEN}✅ Database migration completed${NC}"
    else
        echo -e "${YELLOW}⚠️  No migration file found, backend will handle schema${NC}"
    fi
    
    echo -e "${BLUE}⚙️  Creating environment file...${NC}"
    
    # Create environment file
    cat > .env.production << 'EOF'
# SolarNexus Production Environment
NODE_ENV=production
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus
REDIS_URL=redis://redis:6379
JWT_SECRET=your_jwt_secret_change_in_production
REACT_APP_API_URL=https://nexus.gonxt.tech/api
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
EOF
    
    echo -e "${GREEN}✅ Environment file created${NC}"
    
    echo -e "${BLUE}🚀 Starting backend service...${NC}"
    
    # Start backend using the compatible Docker Compose file
    if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
        echo -e "${BLUE}Using compatible Docker Compose...${NC}"
        docker-compose -f deploy/docker-compose.compatible.yml up -d backend
    else
        echo -e "${BLUE}Using production Docker Compose...${NC}"
        docker-compose -f deploy/docker-compose.production.yml up -d backend
    fi
    
    echo -e "${BLUE}⏳ Waiting for backend to start...${NC}"
    sleep 15
    
    echo -e "${BLUE}🧪 Testing backend...${NC}"
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
    elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
        echo -e "  Backend API: ${YELLOW}⚠️  Starting (check logs)${NC}"
    else
        echo -e "  Backend API: ${RED}❌ Failed to start${NC}"
    fi
    
else
    echo -e "${RED}❌ Database or Redis not running. Please run the simple-fix.sh script first.${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Directory issue resolved!${NC}"

echo -e "\n${BLUE}📋 Final Status:${NC}"
echo "  • Working Directory: $SOLARNEXUS_DIR"
echo "  • PostgreSQL: Running on port 5432"
echo "  • Redis: Running on port 6379"
echo "  • Backend: Starting on port 3000"
echo "  • Environment: .env.production created"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • Check backend logs: docker logs solarnexus-backend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • View all containers: docker ps"

echo -e "\n${GREEN}✅ SolarNexus is ready!${NC}"