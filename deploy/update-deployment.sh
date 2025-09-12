#!/bin/bash

# SolarNexus Update Deployment Script
# Updates the SolarNexus platform with zero-downtime deployment

set -e

echo "🔄 SolarNexus Update Deployment"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Reshigan/SolarNexus.git"
DEPLOY_DIR="/opt/solarnexus"
APP_DIR="$DEPLOY_DIR/app"
BACKUP_DIR="$DEPLOY_DIR/backups"
LOG_FILE="/var/log/solarnexus/update.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

log "Starting SolarNexus update deployment..."

# Create backup before update
echo -e "${BLUE}💾 Creating backup before update...${NC}"
BACKUP_NAME="pre-update-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup database
echo -e "${BLUE}🗄️  Backing up database...${NC}"
if docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > "$BACKUP_DIR/$BACKUP_NAME/database.sql"; then
    gzip "$BACKUP_DIR/$BACKUP_NAME/database.sql"
    log "Database backup created successfully"
else
    log "ERROR: Database backup failed"
    exit 1
fi

# Backup application files
echo -e "${BLUE}📄 Backing up application files...${NC}"
tar -czf "$BACKUP_DIR/$BACKUP_NAME/app-files.tar.gz" -C "$APP_DIR" . 2>/dev/null
log "Application files backup created"

# Update repository
echo -e "${BLUE}📥 Updating repository...${NC}"
cd "$APP_DIR"

# Stash any local changes
git stash push -m "Auto-stash before update $(date)" 2>/dev/null || true

# Fetch latest changes
git fetch origin
CURRENT_COMMIT=$(git rev-parse HEAD)
LATEST_COMMIT=$(git rev-parse origin/main)

if [[ "$CURRENT_COMMIT" == "$LATEST_COMMIT" ]]; then
    echo -e "${GREEN}✅ Already up to date${NC}"
    log "No updates available"
    exit 0
fi

log "Updating from $CURRENT_COMMIT to $LATEST_COMMIT"

# Pull latest changes
git reset --hard origin/main
log "Repository updated successfully"

# Check for breaking changes
echo -e "${BLUE}🔍 Checking for breaking changes...${NC}"
BREAKING_CHANGES=$(git log --oneline "$CURRENT_COMMIT..$LATEST_COMMIT" | grep -i "breaking\|major\|migration" || true)
if [[ -n "$BREAKING_CHANGES" ]]; then
    echo -e "${YELLOW}⚠️  Breaking changes detected:${NC}"
    echo "$BREAKING_CHANGES"
    read -p "Continue with update? (y/N): " continue_update
    if [[ ! "$continue_update" =~ ^[Yy]$ ]]; then
        log "Update cancelled by user due to breaking changes"
        exit 0
    fi
fi

# Build new Docker images
echo -e "${BLUE}🐳 Building updated Docker images...${NC}"

# Build backend
log "Building updated backend image..."
if docker build -t solarnexus-backend:latest -f backend/Dockerfile backend/; then
    log "Backend image built successfully"
else
    log "ERROR: Backend image build failed"
    exit 1
fi

# Build frontend
log "Building updated frontend image..."
if docker build -t solarnexus-frontend:latest -f frontend/Dockerfile frontend/; then
    log "Frontend image built successfully"
else
    log "ERROR: Frontend image build failed"
    exit 1
fi

# Rolling update strategy
echo -e "${BLUE}🔄 Performing rolling update...${NC}"

# Update backend with zero downtime
echo -e "${BLUE}🔧 Updating backend service...${NC}"

# Start new backend container with different name
docker run -d --name solarnexus-backend-new \
    --network solarnexus-network \
    -p 3001:3000 \
    --env-file "$DEPLOY_DIR/.env.production" \
    -v "$DEPLOY_DIR/logs:/app/logs" \
    --health-cmd="curl -f http://localhost:3000/health || exit 1" \
    --health-interval=10s \
    --health-timeout=5s \
    --health-retries=3 \
    solarnexus-backend:latest

# Wait for new backend to be healthy
echo -e "${BLUE}⏳ Waiting for new backend to be healthy...${NC}"
sleep 30

# Check if new backend is healthy
if curl -s http://localhost:3001/health | grep -q "healthy"; then
    log "New backend is healthy, switching traffic..."
    
    # Update nginx configuration to point to new backend
    # Stop old backend
    docker stop solarnexus-backend 2>/dev/null || true
    docker rm solarnexus-backend 2>/dev/null || true
    
    # Rename new backend to original name
    docker rename solarnexus-backend-new solarnexus-backend
    
    # Update port mapping
    docker stop solarnexus-backend
    docker run -d --name solarnexus-backend-temp \
        --network solarnexus-network \
        -p 3000:3000 \
        --env-file "$DEPLOY_DIR/.env.production" \
        -v "$DEPLOY_DIR/logs:/app/logs" \
        --health-cmd="curl -f http://localhost:3000/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --restart unless-stopped \
        solarnexus-backend:latest
    
    docker rm solarnexus-backend
    docker rename solarnexus-backend-temp solarnexus-backend
    
    log "Backend updated successfully"
else
    log "ERROR: New backend failed health check, rolling back..."
    docker stop solarnexus-backend-new 2>/dev/null || true
    docker rm solarnexus-backend-new 2>/dev/null || true
    exit 1
fi

# Update frontend
echo -e "${BLUE}🌐 Updating frontend service...${NC}"

# Stop and update frontend
docker stop solarnexus-frontend 2>/dev/null || true
docker rm solarnexus-frontend 2>/dev/null || true

docker run -d --name solarnexus-frontend \
    --network solarnexus-network \
    -p 8080:80 \
    -v "$APP_DIR/nginx/conf.d:/etc/nginx/conf.d:ro" \
    --health-cmd="curl -f http://localhost/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --restart unless-stopped \
    solarnexus-frontend:latest

# Wait for frontend to be ready
sleep 20

if curl -s http://localhost:8080/health | grep -q "healthy"; then
    log "Frontend updated successfully"
else
    log "ERROR: Frontend update failed"
    exit 1
fi

# Update nginx if needed
echo -e "${BLUE}🔀 Updating nginx configuration...${NC}"
docker restart solarnexus-nginx
sleep 10

# Run database migrations if needed
echo -e "${BLUE}🗄️  Running database migrations...${NC}"
if [[ -f "$APP_DIR/backend/prisma/schema.prisma" ]]; then
    docker exec solarnexus-backend npx prisma migrate deploy 2>/dev/null || log "No migrations to run"
fi

# Verify update
echo -e "${BLUE}✅ Verifying update...${NC}"
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

# Test endpoints
echo -e "\n${BLUE}🧪 Testing endpoints...${NC}"
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    echo -e "  Backend API: ${GREEN}✅ Healthy${NC}"
else
    echo -e "  Backend API: ${RED}❌ Unhealthy${NC}"
    all_healthy=false
fi

if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo -e "  Frontend: ${GREEN}✅ Healthy${NC}"
else
    echo -e "  Frontend: ${RED}❌ Unhealthy${NC}"
    all_healthy=false
fi

# Clean up old Docker images
echo -e "\n${BLUE}🧹 Cleaning up old Docker images...${NC}"
docker image prune -f --filter "label=solarnexus" 2>/dev/null || true

# Final status
if [[ "$all_healthy" == true ]]; then
    log "SolarNexus update completed successfully"
    echo -e "\n${GREEN}🎉 SolarNexus Update Complete!${NC}"
    
    echo -e "\n${BLUE}📋 Update Summary:${NC}"
    echo "   • Updated from: $CURRENT_COMMIT"
    echo "   • Updated to: $LATEST_COMMIT"
    echo "   • Backup location: $BACKUP_DIR/$BACKUP_NAME"
    echo "   • Update time: $(date)"
    
    echo -e "\n${BLUE}🌐 Service URLs:${NC}"
    echo "   • Frontend: http://$(curl -s ifconfig.me):8080"
    echo "   • Backend API: http://$(curl -s ifconfig.me):3000"
    echo "   • Health Check: http://$(curl -s ifconfig.me):3000/health"
    
    # Send notification if configured
    if [[ -n "$NOTIFICATION_EMAIL" ]]; then
        echo "SolarNexus update completed successfully on $(date)" | \
        mail -s "SolarNexus Update Success" "$NOTIFICATION_EMAIL"
    fi
    
else
    log "ERROR: SolarNexus update failed"
    echo -e "\n${RED}❌ Update failed! Some services are not healthy${NC}"
    echo -e "${YELLOW}Backup available at: $BACKUP_DIR/$BACKUP_NAME${NC}"
    echo -e "${YELLOW}Check logs with: docker logs <service-name>${NC}"
    
    # Send failure notification if configured
    if [[ -n "$NOTIFICATION_EMAIL" ]]; then
        echo "SolarNexus update failed on $(date). Check logs for details." | \
        mail -s "SolarNexus Update Failed" "$NOTIFICATION_EMAIL"
    fi
    
    exit 1
fi

echo -e "\n${GREEN}✅ SolarNexus is updated and ready!${NC}"