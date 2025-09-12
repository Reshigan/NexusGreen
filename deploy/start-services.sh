#!/bin/bash

# SolarNexus Services Start Script
# Starts all SolarNexus services in the correct order

set -e

echo "🚀 Starting SolarNexus Services"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/opt/solarnexus"
APP_DIR="$DEPLOY_DIR/app"
ENV_FILE="$DEPLOY_DIR/.env.production"

# Change to app directory
cd "$APP_DIR"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${BLUE}📄 Loading environment configuration...${NC}"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo -e "${YELLOW}⚠️  Environment file not found: $ENV_FILE${NC}"
    echo -e "${YELLOW}   Using default configuration${NC}"
fi

# Function to wait for service health
wait_for_service() {
    local service_name="$1"
    local health_check="$2"
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}⏳ Waiting for $service_name to be healthy...${NC}"
    
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$health_check" &>/dev/null; then
            echo -e "${GREEN}✅ $service_name is healthy${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo -e "\n${RED}❌ $service_name failed to become healthy${NC}"
    return 1
}

# Create Docker network
echo -e "${BLUE}🌐 Creating Docker network...${NC}"
docker network create solarnexus-network 2>/dev/null || echo "Network already exists"

# Start PostgreSQL Database
echo -e "${BLUE}🗄️  Starting PostgreSQL database...${NC}"
docker run -d --name solarnexus-postgres \
    --network solarnexus-network \
    -p 5432:5432 \
    -e POSTGRES_USER="${POSTGRES_USER:-solarnexus}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-solarnexus}" \
    -e POSTGRES_DB="${POSTGRES_DB:-solarnexus}" \
    -v solarnexus_postgres_data:/var/lib/postgresql/data \
    --health-cmd="pg_isready -U ${POSTGRES_USER:-solarnexus} -d ${POSTGRES_DB:-solarnexus}" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    postgres:15-alpine 2>/dev/null || echo "PostgreSQL container already running"

wait_for_service "PostgreSQL" "docker exec solarnexus-postgres pg_isready -U ${POSTGRES_USER:-solarnexus}"

# Start Redis Cache
echo -e "${BLUE}🔴 Starting Redis cache...${NC}"
docker run -d --name solarnexus-redis \
    --network solarnexus-network \
    -p 6379:6379 \
    -v solarnexus_redis_data:/data \
    --health-cmd="redis-cli ping" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    redis:7-alpine redis-server --appendonly yes 2>/dev/null || echo "Redis container already running"

wait_for_service "Redis" "docker exec solarnexus-redis redis-cli ping"

# Start Backend API
echo -e "${BLUE}🔧 Starting backend API...${NC}"
docker run -d --name solarnexus-backend \
    --network solarnexus-network \
    -p 3000:3000 \
    --env-file "$ENV_FILE" \
    -v "$DEPLOY_DIR/logs:/app/logs" \
    --health-cmd="curl -f http://localhost:3000/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    solarnexus-backend:latest 2>/dev/null || echo "Backend container already running"

wait_for_service "Backend API" "curl -s http://localhost:3000/health"

# Start Frontend
echo -e "${BLUE}🌐 Starting frontend...${NC}"
docker run -d --name solarnexus-frontend \
    --network solarnexus-network \
    -p 8080:80 \
    -v "$APP_DIR/nginx/conf.d:/etc/nginx/conf.d:ro" \
    --health-cmd="curl -f http://localhost/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    solarnexus-frontend:latest 2>/dev/null || echo "Frontend container already running"

wait_for_service "Frontend" "curl -s http://localhost:8080/health"

# Start Nginx Reverse Proxy
echo -e "${BLUE}🔀 Starting Nginx reverse proxy...${NC}"
docker run -d --name solarnexus-nginx \
    --network solarnexus-network \
    -p 80:80 \
    -p 443:443 \
    -v "$APP_DIR/nginx/conf.d:/etc/nginx/conf.d:ro" \
    -v "$APP_DIR/dist:/var/www/html:ro" \
    -v /etc/nginx/ssl:/etc/nginx/ssl:ro \
    --health-cmd="curl -f http://localhost/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    nginx:alpine 2>/dev/null || echo "Nginx container already running"

wait_for_service "Nginx" "curl -s http://localhost/health"

# Verify all services
echo -e "\n${BLUE}✅ Verifying all services...${NC}"
services=("solarnexus-postgres" "solarnexus-redis" "solarnexus-backend" "solarnexus-frontend" "solarnexus-nginx")

all_healthy=true
for service in "${services[@]}"; do
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$service" | grep -q "healthy\|Up"; then
        echo -e "  ${service}: ${GREEN}✅ Running${NC}"
    else
        echo -e "  ${service}: ${RED}❌ Not running${NC}"
        all_healthy=false
    fi
done

# Final status
if [[ "$all_healthy" == true ]]; then
    echo -e "\n${GREEN}🎉 All SolarNexus services started successfully!${NC}"
    
    echo -e "\n${BLUE}🌐 Service URLs:${NC}"
    echo "   • Frontend: http://localhost:8080"
    echo "   • Backend API: http://localhost:3000"
    echo "   • Health Check: http://localhost:3000/health"
    
    echo -e "\n${BLUE}📊 Service Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep solarnexus
    
    echo -e "\n${BLUE}💾 Data Volumes:${NC}"
    docker volume ls | grep solarnexus
    
else
    echo -e "\n${RED}❌ Some services failed to start properly${NC}"
    echo -e "${YELLOW}Check logs with: docker logs <service-name>${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ SolarNexus is ready for use!${NC}"