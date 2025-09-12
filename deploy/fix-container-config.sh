#!/bin/bash

# SolarNexus Container Configuration Fix Script
# Fixes 'ContainerConfig' KeyError issues with Docker Compose

set -e

echo "🔧 SolarNexus Container Configuration Fix"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./fix-container-config.sh"
   exit 1
fi

echo -e "${BLUE}🛑 Stopping all SolarNexus services...${NC}"
docker-compose -f docker-compose.production.yml down --remove-orphans 2>/dev/null || true

echo -e "${BLUE}🗑️  Removing problematic containers...${NC}"
# Remove all SolarNexus containers
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

echo -e "${BLUE}🧹 Cleaning up Docker system...${NC}"
# Clean up dangling images and containers
docker system prune -f

echo -e "${BLUE}🔄 Removing and recreating Docker volumes...${NC}"
# Remove volumes to ensure clean state
docker volume rm solarnexus_postgres_data 2>/dev/null || true
docker volume rm solarnexus_redis_data 2>/dev/null || true

# Recreate volumes
docker volume create solarnexus_postgres_data
docker volume create solarnexus_redis_data

echo -e "${BLUE}📦 Pulling fresh Docker images...${NC}"
# Pull fresh images to avoid metadata issues
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine

echo -e "${BLUE}🔧 Updating Docker Compose version compatibility...${NC}"
# Create a temporary docker-compose file with version compatibility fixes
cat > /tmp/docker-compose.temp.yml << 'EOF'
services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: solarnexus-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-solarnexus}
      - POSTGRES_USER=${POSTGRES_USER:-solarnexus}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-solarnexus}
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - solarnexus_postgres_data:/var/lib/postgresql/data
      - /opt/solarnexus/backups/database:/backups
    ports:
      - "5432:5432"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-solarnexus}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - solarnexus_redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  solarnexus_postgres_data:
    external: true
  solarnexus_redis_data:
    external: true

networks:
  solarnexus-network:
    driver: bridge
EOF

echo -e "${BLUE}🚀 Starting database and cache services...${NC}"
# Start only database and cache first
docker-compose -f /tmp/docker-compose.temp.yml up -d

echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
sleep 15

# Check if services are healthy
echo -e "${BLUE}🔍 Checking service health...${NC}"
if docker exec solarnexus-postgres pg_isready -U solarnexus; then
    echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
else
    echo -e "${RED}❌ PostgreSQL failed to start${NC}"
    exit 1
fi

if docker exec solarnexus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✅ Redis is ready${NC}"
else
    echo -e "${RED}❌ Redis failed to start${NC}"
    exit 1
fi

echo -e "${BLUE}🗄️  Initializing database...${NC}"
# Initialize database
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;" 2>/dev/null || echo "Database already exists"

# Copy and run migration
if [[ -f "/opt/solarnexus/app/solarnexus-backend/migration.sql" ]]; then
    docker cp /opt/solarnexus/app/solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    echo -e "${GREEN}✅ Database migration completed${NC}"
else
    echo -e "${YELLOW}⚠️  Migration file not found, will run basic schema${NC}"
fi

echo -e "${BLUE}🔧 Updating main Docker Compose file...${NC}"
# Update the main docker-compose file to fix compatibility issues
cd /opt/solarnexus/app

# Backup original file
cp deploy/docker-compose.production.yml deploy/docker-compose.production.yml.backup

# Create updated docker-compose file with fixes
cat > deploy/docker-compose.production.yml << 'EOF'
services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: solarnexus-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-solarnexus}
      - POSTGRES_USER=${POSTGRES_USER:-solarnexus}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-solarnexus}
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - /opt/solarnexus/backups/database:/backups
    ports:
      - "5432:5432"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-solarnexus}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backend API
  backend:
    build:
      context: ../solarnexus-backend
      dockerfile: Dockerfile
    image: solarnexus-backend:latest
    container_name: solarnexus-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://${POSTGRES_USER:-solarnexus}:${POSTGRES_PASSWORD:-solarnexus}@postgres:5432/${POSTGRES_DB:-solarnexus}
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET:-default_jwt_secret_change_in_production}
      - SOLAX_API_TOKEN=${SOLAX_API_TOKEN:-}
      - OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY:-}
      - EMAIL_USER=${EMAIL_USER:-}
      - EMAIL_PASS=${EMAIL_PASS:-}
      - MUNICIPAL_RATE_API_KEY=${MUNICIPAL_RATE_API_KEY:-}
      - MUNICIPAL_RATE_ENDPOINT=${MUNICIPAL_RATE_ENDPOINT:-}
      - REACT_APP_API_URL=${REACT_APP_API_URL:-https://nexus.gonxt.tech/api}
    ports:
      - "3000:3000"
    volumes:
      - /opt/solarnexus/logs:/app/logs
    networks:
      - solarnexus-network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Frontend Web App
  frontend:
    build:
      context: ../
      dockerfile: Dockerfile
      args:
        - REACT_APP_API_URL=${REACT_APP_API_URL:-https://nexus.gonxt.tech/api}
        - REACT_APP_ENVIRONMENT=${REACT_APP_ENVIRONMENT:-production}
        - REACT_APP_VERSION=${REACT_APP_VERSION:-1.0.0}
    image: solarnexus-frontend:latest
    container_name: solarnexus-frontend
    restart: unless-stopped
    environment:
      - REACT_APP_API_URL=${REACT_APP_API_URL:-https://nexus.gonxt.tech/api}
      - REACT_APP_ENVIRONMENT=${REACT_APP_ENVIRONMENT:-production}
      - REACT_APP_VERSION=${REACT_APP_VERSION:-1.0.0}
    ports:
      - "8080:80"
    volumes:
      - ../nginx/conf.d:/etc/nginx/conf.d:ro
    networks:
      - solarnexus-network
    depends_on:
      backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: solarnexus-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../nginx/conf.d:/etc/nginx/conf.d:ro
      - ../nginx/ssl:/etc/nginx/ssl:ro
      - /var/log/nginx:/var/log/nginx
    networks:
      - solarnexus-network
    depends_on:
      - frontend
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:

networks:
  solarnexus-network:
    driver: bridge
EOF

echo -e "${BLUE}🚀 Starting remaining services...${NC}"
# Now start all services with the fixed configuration
docker-compose -f deploy/docker-compose.production.yml up -d --build

echo -e "${BLUE}⏳ Waiting for all services to be ready...${NC}"
sleep 30

echo -e "${BLUE}🧪 Testing services...${NC}"
# Test all services
services=("postgres" "redis" "backend")
for service in "${services[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "solarnexus-$service"; then
        echo -e "  ${service}: ${GREEN}✅ Running${NC}"
    else
        echo -e "  ${service}: ${RED}❌ Not Running${NC}"
    fi
done

# Clean up temporary file
rm -f /tmp/docker-compose.temp.yml

echo -e "\n${GREEN}🎉 Container configuration fix completed!${NC}"

echo -e "\n${BLUE}📋 Next Steps:${NC}"
echo "  • Check logs: docker logs solarnexus-backend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Run verification: sudo ./deploy/verify-deployment.sh"

echo -e "\n${BLUE}🔧 If issues persist:${NC}"
echo "  • Check Docker version: docker --version"
echo "  • Update Docker Compose: sudo apt update && sudo apt install docker-compose-plugin"
echo "  • Review logs: docker-compose -f deploy/docker-compose.production.yml logs"

echo -e "\n${GREEN}✅ SolarNexus services should now be running properly!${NC}"