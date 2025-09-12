#!/bin/bash

# SolarNexus Production Deployment Script
# Deploys the complete SolarNexus platform to production server

set -e

echo "🚀 SolarNexus Production Deployment"
echo "===================================="

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
LOG_FILE="/var/log/solarnexus/deployment.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

log "Starting SolarNexus production deployment..."

# Create directories
echo -e "${BLUE}📁 Creating deployment directories...${NC}"
mkdir -p "$DEPLOY_DIR"/{app,backups,logs,secrets}
mkdir -p /var/log/solarnexus
chmod 755 "$DEPLOY_DIR" /var/log/solarnexus

# Install dependencies
echo -e "${BLUE}📦 Installing system dependencies...${NC}"
apt update
apt install -y curl wget git docker.io docker-compose nginx certbot python3-certbot-nginx jq

# Start Docker service
systemctl start docker
systemctl enable docker

# Add current user to docker group
usermod -aG docker $USER

# Clone or update repository
echo -e "${BLUE}📥 Cloning SolarNexus repository...${NC}"
if [[ -d "$APP_DIR/.git" ]]; then
    log "Updating existing repository..."
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/main
else
    log "Cloning fresh repository..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# Set permissions
chown -R root:root "$APP_DIR"
chmod +x "$APP_DIR"/scripts/*.sh

# Create production environment file
echo -e "${BLUE}⚙️  Creating production environment...${NC}"
if [[ ! -f "$DEPLOY_DIR/.env.production" ]]; then
    cp "$APP_DIR/.env.production.template" "$DEPLOY_DIR/.env.production"
    log "Created production environment template"
    echo -e "${YELLOW}⚠️  Please configure API keys in $DEPLOY_DIR/.env.production${NC}"
fi

# Build Docker images
echo -e "${BLUE}🐳 Building Docker images...${NC}"
cd "$APP_DIR"

# Build backend image
log "Building backend Docker image..."
docker build -t solarnexus-backend:latest -f backend/Dockerfile backend/

# Build frontend image
log "Building frontend Docker image..."
docker build -t solarnexus-frontend:latest -f frontend/Dockerfile frontend/

# Create Docker network
echo -e "${BLUE}🌐 Creating Docker network...${NC}"
docker network create solarnexus-network 2>/dev/null || true

# Deploy database
echo -e "${BLUE}🗄️  Deploying PostgreSQL database...${NC}"
docker stop solarnexus-postgres 2>/dev/null || true
docker rm solarnexus-postgres 2>/dev/null || true

docker run -d --name solarnexus-postgres \
    --network solarnexus-network \
    -p 5432:5432 \
    -e POSTGRES_USER=solarnexus \
    -e POSTGRES_PASSWORD=solarnexus \
    -e POSTGRES_DB=solarnexus \
    -v solarnexus_postgres_data:/var/lib/postgresql/data \
    --health-cmd="pg_isready -U solarnexus -d solarnexus" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    postgres:15-alpine

# Deploy Redis
echo -e "${BLUE}🔴 Deploying Redis cache...${NC}"
docker stop solarnexus-redis 2>/dev/null || true
docker rm solarnexus-redis 2>/dev/null || true

docker run -d --name solarnexus-redis \
    --network solarnexus-network \
    -p 6379:6379 \
    -v solarnexus_redis_data:/data \
    --health-cmd="redis-cli ping" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    redis:7-alpine

# Wait for database to be ready
echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
sleep 30

# Deploy backend
echo -e "${BLUE}🔧 Deploying backend service...${NC}"
docker stop solarnexus-backend 2>/dev/null || true
docker rm solarnexus-backend 2>/dev/null || true

docker run -d --name solarnexus-backend \
    --network solarnexus-network \
    -p 3000:3000 \
    --env-file "$DEPLOY_DIR/.env.production" \
    -v "$DEPLOY_DIR/logs:/app/logs" \
    --health-cmd="curl -f http://localhost:3000/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    solarnexus-backend:latest

# Deploy frontend
echo -e "${BLUE}🌐 Deploying frontend service...${NC}"
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
    solarnexus-frontend:latest

# Deploy Nginx reverse proxy
echo -e "${BLUE}🔀 Deploying Nginx reverse proxy...${NC}"
docker stop solarnexus-nginx 2>/dev/null || true
docker rm solarnexus-nginx 2>/dev/null || true

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
    nginx:alpine

# Wait for services to start
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 60

# Verify deployment
echo -e "${BLUE}✅ Verifying deployment...${NC}"
services=("solarnexus-postgres" "solarnexus-redis" "solarnexus-backend" "solarnexus-frontend" "solarnexus-nginx")

for service in "${services[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "$service"; then
        status="✅ Running"
    else
        status="❌ Failed"
    fi
    printf "  %-20s %s\n" "$service" "$status"
done

# Test endpoints
echo -e "\n${BLUE}🧪 Testing endpoints...${NC}"
sleep 10

if curl -s http://localhost:3000/health | grep -q "healthy"; then
    echo -e "  Backend API: ${GREEN}✅ Healthy${NC}"
else
    echo -e "  Backend API: ${RED}❌ Unhealthy${NC}"
fi

if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo -e "  Frontend: ${GREEN}✅ Healthy${NC}"
else
    echo -e "  Frontend: ${RED}❌ Unhealthy${NC}"
fi

# Create systemd service
echo -e "${BLUE}⚙️  Creating systemd service...${NC}"
cat > /etc/systemd/system/solarnexus.service << EOF
[Unit]
Description=SolarNexus Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash $APP_DIR/deploy/start-services.sh
ExecStop=/bin/bash $APP_DIR/deploy/stop-services.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable solarnexus.service

# Set up log rotation
echo -e "${BLUE}📝 Setting up log rotation...${NC}"
cat > /etc/logrotate.d/solarnexus << 'EOF'
/var/log/solarnexus/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}

/opt/solarnexus/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Create deployment summary
log "SolarNexus deployment completed successfully"

echo -e "\n${GREEN}🎉 SolarNexus Deployment Complete!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo "   • Application directory: $APP_DIR"
echo "   • Configuration: $DEPLOY_DIR/.env.production"
echo "   • Logs: /var/log/solarnexus/"
echo "   • Service: systemctl status solarnexus"

echo -e "\n${BLUE}🌐 Access URLs:${NC}"
echo "   • Frontend: http://$(curl -s ifconfig.me):8080"
echo "   • Backend API: http://$(curl -s ifconfig.me):3000"
echo "   • Health Check: http://$(curl -s ifconfig.me):3000/health"

echo -e "\n${BLUE}🔧 Management Commands:${NC}"
echo "   • Start services: systemctl start solarnexus"
echo "   • Stop services: systemctl stop solarnexus"
echo "   • View logs: docker logs solarnexus-backend"
echo "   • Update deployment: $APP_DIR/deploy/update-deployment.sh"

echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
echo "   1. Configure API keys: $DEPLOY_DIR/.env.production"
echo "   2. Set up SSL certificate: $APP_DIR/scripts/setup-ssl.sh"
echo "   3. Configure monitoring: $APP_DIR/scripts/setup-monitoring.sh"
echo "   4. Set up backups: $APP_DIR/scripts/setup-backup.sh"
echo "   5. Configure domain DNS to point to this server"

echo -e "\n${GREEN}✅ SolarNexus is ready for production!${NC}"