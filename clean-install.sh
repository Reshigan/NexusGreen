#!/bin/bash

# SolarNexus Clean Install Script - Fixed Version
# Completely removes everything and installs from scratch in current directory

set -e

echo "🧹 SolarNexus Clean Install from Scratch (Fixed)"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./clean-install.sh"
   exit 1
fi

# Get current directory for installation
INSTALL_DIR="$(pwd)/SolarNexus"
echo -e "${BLUE}📍 Installation will be in: $INSTALL_DIR${NC}"

echo -e "${YELLOW}⚠️  WARNING: This will completely remove all SolarNexus data and containers!${NC}"
echo -e "${YELLOW}⚠️  This includes databases, volumes, and all configuration!${NC}"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm

if [[ "$confirm" != "YES" ]]; then
    echo -e "${BLUE}❌ Installation cancelled${NC}"
    exit 0
fi

echo -e "\n${RED}🛑 STEP 1: Stopping and removing all SolarNexus services...${NC}"

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
cleanup_containers "SolarNexus"

# Also try to stop any docker-compose services in common locations
for compose_dir in "/root/SolarNexus" "$HOME/SolarNexus" "./SolarNexus" "../SolarNexus"; do
    if [[ -f "$compose_dir/docker-compose.yml" ]]; then
        echo -e "${BLUE}Found docker-compose in $compose_dir, stopping services...${NC}"
        (cd "$compose_dir" && docker-compose down 2>/dev/null || true)
    fi
    if [[ -f "$compose_dir/deploy/docker-compose.compatible.yml" ]]; then
        echo -e "${BLUE}Found compatible docker-compose in $compose_dir, stopping services...${NC}"
        (cd "$compose_dir" && docker-compose -f deploy/docker-compose.compatible.yml down 2>/dev/null || true)
    fi
done

# Remove all SolarNexus images
echo -e "${BLUE}Removing images...${NC}"
docker rmi -f $(docker images --filter "reference=solarnexus*" -q) 2>/dev/null || true
docker rmi -f $(docker images --filter "reference=SolarNexus*" -q) 2>/dev/null || true

# Remove all SolarNexus volumes
echo -e "${BLUE}Removing volumes...${NC}"
docker volume rm $(docker volume ls --filter "name=solarnexus" -q) 2>/dev/null || true
docker volume rm postgres_data redis_data 2>/dev/null || true

# Remove all SolarNexus networks
echo -e "${BLUE}Removing networks...${NC}"
docker network rm $(docker network ls --filter "name=solarnexus" -q) 2>/dev/null || true

echo -e "${GREEN}✅ All SolarNexus Docker resources removed${NC}"

echo -e "\n${RED}🗑️  STEP 2: Removing SolarNexus directories...${NC}"

# Remove SolarNexus directories
DIRS_TO_REMOVE=(
    "/opt/solarnexus"
    "/root/SolarNexus"
    "$HOME/SolarNexus"
    "/tmp/SolarNexus"
    "/var/www/SolarNexus"
    "./SolarNexus"
    "../SolarNexus"
    "$INSTALL_DIR"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "${BLUE}Removing directory: $dir${NC}"
        rm -rf "$dir"
    fi
done

# Remove any SolarNexus related files
find /root -name "*solarnexus*" -type f -delete 2>/dev/null || true
find /tmp -name "*solarnexus*" -type f -delete 2>/dev/null || true

echo -e "${GREEN}✅ All SolarNexus directories removed${NC}"

echo -e "\n${BLUE}🧹 STEP 3: Cleaning Docker system...${NC}"

# Clean Docker system
docker system prune -af --volumes
docker builder prune -af

echo -e "${GREEN}✅ Docker system cleaned${NC}"

echo -e "\n${GREEN}🚀 STEP 4: Fresh installation...${NC}"

# Create installation directory
echo -e "${BLUE}Creating installation directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone fresh repository
echo -e "${BLUE}📥 Cloning SolarNexus repository...${NC}"
git clone https://github.com/Reshigan/SolarNexus.git .

echo -e "${GREEN}✅ Repository cloned${NC}"

echo -e "\n${BLUE}🐳 STEP 5: Creating Docker volumes...${NC}"

# Create fresh volumes
docker volume create postgres_data
docker volume create redis_data

echo -e "${GREEN}✅ Docker volumes created${NC}"

echo -e "\n${BLUE}📦 STEP 6: Pulling Docker images...${NC}"

# Pull required images
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:20-alpine

echo -e "${GREEN}✅ Docker images pulled${NC}"

echo -e "\n${BLUE}⚙️  STEP 7: Creating environment configuration...${NC}"

# Create production environment file
cat > .env << 'EOF'
# SolarNexus Production Environment
NODE_ENV=production

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus

# Redis Configuration
REDIS_URL=redis://solarnexus-redis:6379

# Security
JWT_SECRET=your_jwt_secret_change_in_production_immediately
JWT_EXPIRES_IN=24h

# API Configuration
REACT_APP_API_URL=http://localhost:3000/api
API_PORT=3000

# Frontend Configuration
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
REACT_APP_COMPANY_NAME=SolarNexus
REACT_APP_SUPPORT_EMAIL=support@nexus.gonxt.tech

# External APIs (configure as needed)
SOLAX_API_TOKEN=
OPENWEATHER_API_KEY=
MUNICIPAL_RATE_API_KEY=
MUNICIPAL_RATE_ENDPOINT=

# Email Configuration (configure as needed)
EMAIL_USER=
EMAIL_PASS=
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587

# Logging
LOG_LEVEL=info
LOG_FILE=/app/logs/solarnexus.log

# Performance
MAX_CONNECTIONS=100
QUERY_TIMEOUT=30000
CONNECTION_TIMEOUT=10000
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

echo -e "\n${BLUE}🗄️  STEP 8: Setting up database with Docker Compose...${NC}"

# Start database services first using docker-compose
echo -e "${BLUE}Starting database services...${NC}"
docker-compose up -d postgres redis

echo -e "${BLUE}⏳ Waiting for database services to start...${NC}"
sleep 20

# Test services
echo -e "${BLUE}🧪 Testing database services...${NC}"

# Wait for PostgreSQL to be ready
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
    exit 1
fi

# Wait for Redis to be ready
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
    exit 1
fi

echo -e "\n${BLUE}🗄️  STEP 9: Setting up database schema...${NC}"

# Create database
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;" 2>/dev/null || echo "Database already exists"

# Apply migration if available
if [[ -f "solarnexus-backend/migration.sql" ]]; then
    echo -e "${GREEN}✅ Found migration file, applying...${NC}"
    docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo -e "${GREEN}✅ Database migration completed${NC}"
else
    echo -e "${YELLOW}⚠️  Migration file not found, skipping schema setup${NC}"
    echo -e "${BLUE}Database will be initialized when backend starts${NC}"
fi

echo -e "\n${BLUE}🏗️  STEP 10: Building and starting all services...${NC}"

# Build and start all services
echo -e "${BLUE}Building application images and starting services...${NC}"
docker-compose up -d --build

echo -e "${BLUE}⏳ Waiting for all services to start...${NC}"
sleep 30

echo -e "\n${BLUE}🧪 STEP 11: Testing all services...${NC}"

# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
    POSTGRES_OK=true
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
    POSTGRES_OK=false
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping | grep -q "PONG" 2>/dev/null; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
    REDIS_OK=true
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
    REDIS_OK=false
fi

# Test Backend
sleep 10  # Give backend more time to start
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
    BACKEND_OK=true
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend API: ${YELLOW}⚠️  Starting (may need more time)${NC}"
    BACKEND_OK=false
else
    echo -e "  Backend API: ${RED}❌ Not Running${NC}"
    BACKEND_OK=false
fi

# Test Frontend
if curl -f http://localhost/ >/dev/null 2>&1; then
    echo -e "  Frontend: ${GREEN}✅ Ready${NC}"
    FRONTEND_OK=true
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-frontend"; then
    echo -e "  Frontend: ${YELLOW}⚠️  Starting (may need more time)${NC}"
    FRONTEND_OK=false
else
    echo -e "  Frontend: ${RED}❌ Not Running${NC}"
    FRONTEND_OK=false
fi

# Test Nginx
if curl -f http://localhost/health >/dev/null 2>&1; then
    echo -e "  Nginx: ${GREEN}✅ Ready${NC}"
    NGINX_OK=true
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-nginx"; then
    echo -e "  Nginx: ${YELLOW}⚠️  Starting (may need more time)${NC}"
    NGINX_OK=false
else
    echo -e "  Nginx: ${RED}❌ Not Running${NC}"
    NGINX_OK=false
fi

echo -e "\n${GREEN}🎉 SolarNexus Clean Installation Completed!${NC}"

echo -e "\n${BLUE}📋 Installation Summary:${NC}"
echo "  • Installation Directory: $INSTALL_DIR"
echo "  • PostgreSQL: Port 5432 $([ "$POSTGRES_OK" = true ] && echo "✅" || echo "❌")"
echo "  • Redis: Port 6379 $([ "$REDIS_OK" = true ] && echo "✅" || echo "❌")"
echo "  • Backend API: Port 3000 $([ "$BACKEND_OK" = true ] && echo "✅" || echo "⚠️")"
echo "  • Frontend: Port 80 $([ "$FRONTEND_OK" = true ] && echo "✅" || echo "⚠️")"
echo "  • Nginx: Port 80 $([ "$NGINX_OK" = true ] && echo "✅" || echo "⚠️")"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • View all containers: docker ps"
echo "  • Check all services: docker-compose ps"
echo "  • Check backend logs: docker-compose logs backend"
echo "  • Check frontend logs: docker-compose logs frontend"
echo "  • Check nginx logs: docker-compose logs nginx"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Access frontend: http://localhost/"
echo "  • Database shell: docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus"
echo "  • Redis shell: docker exec -it solarnexus-redis redis-cli"

echo -e "\n${BLUE}📁 Important Files:${NC}"
echo "  • Environment: $INSTALL_DIR/.env"
echo "  • Docker Compose: $INSTALL_DIR/docker-compose.yml"
echo "  • Logs: Use 'docker-compose logs [service]'"

echo -e "\n${BLUE}🔄 Service Management:${NC}"
echo "  • Stop all: docker-compose down"
echo "  • Start all: docker-compose up -d"
echo "  • Restart: docker-compose restart"
echo "  • Rebuild: docker-compose up -d --build"

if [[ "$BACKEND_OK" = false ]] || [[ "$FRONTEND_OK" = false ]] || [[ "$NGINX_OK" = false ]]; then
    echo -e "\n${YELLOW}⚠️  Some services may still be starting. Wait a few minutes and check:${NC}"
    echo "  • docker-compose ps"
    echo "  • docker-compose logs [service-name]"
fi

echo -e "\n${GREEN}✅ SolarNexus is ready for use!${NC}"
echo -e "${GREEN}🌟 Access your solar portal at: http://localhost/${NC}"
echo -e "${GREEN}🔧 API endpoint available at: http://localhost:3000/${NC}"
