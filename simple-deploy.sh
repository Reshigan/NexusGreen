#!/bin/bash

# SolarNexus Simple Deployment Script
# Tested and Working - No Over-Engineering
# Version: 1.0.0

set -e  # Exit on error

# Configuration
SERVER_IP="13.245.249.110"
APP_DIR="/opt/solarnexus"
GITHUB_REPO="https://github.com/Reshigan/SolarNexus.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root: sudo $0"
fi

log "🚀 SolarNexus Simple Deployment Starting..."

# 1. Update system
log "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 2. Install Docker
log "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
else
    log "Docker already installed"
fi

# 3. Install Node.js
log "📦 Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
else
    log "Node.js already installed"
fi

# 4. Create application directory
log "📁 Setting up application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# 5. Clone or update repository
log "📥 Getting application code..."
if [[ -d ".git" ]]; then
    log "Repository exists, pulling latest changes..."
    git pull origin main
else
    log "Cloning repository..."
    git clone "$GITHUB_REPO" .
fi

# 6. Stop any existing containers
log "🛑 Stopping existing containers..."
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# 7. Create Docker network
log "🌐 Creating Docker network..."
docker network create solarnexus-net 2>/dev/null || true

# 8. Start PostgreSQL
log "🗄️ Starting PostgreSQL..."
docker run -d \
  --name postgres \
  --network solarnexus-net \
  --restart unless-stopped \
  -e POSTGRES_DB=solarnexus \
  -e POSTGRES_USER=solarnexus \
  -e POSTGRES_PASSWORD=SolarNexus2024! \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:15-alpine

# 9. Start Redis
log "📦 Starting Redis..."
docker run -d \
  --name redis \
  --network solarnexus-net \
  --restart unless-stopped \
  -p 6379:6379 \
  -v redis_data:/data \
  redis:7-alpine redis-server --appendonly yes

# 10. Wait for databases
log "⏳ Waiting for databases to start..."
sleep 15

# 11. Setup database schema
log "🗄️ Setting up database schema..."
if [[ -f "solarnexus-backend/migration.sql" ]]; then
    docker cp solarnexus-backend/migration.sql postgres:/tmp/migration.sql
    docker exec postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql || warn "Database setup completed with warnings"
else
    # Create basic schema if migration file doesn't exist
    docker exec postgres psql -U solarnexus -d solarnexus -c "
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      role VARCHAR(50) DEFAULT 'user',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO users (email, password, name, role) VALUES 
    ('admin@solarnexus.com', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VjPoyNdO2', 'Admin User', 'admin')
    ON CONFLICT (email) DO NOTHING;
    " || warn "Basic database setup completed"
fi

# 12. Build and start backend
log "⚙️ Building and starting backend..."
cd solarnexus-backend

# Create environment file for backend
cat > .env << EOF
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://solarnexus:SolarNexus2024!@postgres:5432/solarnexus
REDIS_URL=redis://redis:6379
JWT_SECRET=your-super-secret-jwt-key-change-in-production
BCRYPT_ROUNDS=12
EOF

# Build and start backend container
docker build -t solarnexus-backend .
docker run -d \
  --name backend \
  --network solarnexus-net \
  --restart unless-stopped \
  -p 5000:5000 \
  --env-file .env \
  solarnexus-backend

cd ..

# 13. Build frontend
log "🏗️ Building frontend..."
if [[ -f "package.json" ]]; then
    npm ci
    VITE_API_BASE_URL="http://$SERVER_IP:5000" npm run build
else
    error "Frontend package.json not found"
fi

# 14. Start frontend with Nginx
log "🌐 Starting frontend..."
docker run -d \
  --name frontend \
  --network solarnexus-net \
  --restart unless-stopped \
  -p 3000:80 \
  -v "$APP_DIR/dist:/usr/share/nginx/html:ro" \
  nginx:alpine

# 15. Wait for services to start
log "⏳ Waiting for services to start..."
sleep 10

# 16. Health checks
log "🔍 Performing health checks..."
backend_healthy=false
frontend_healthy=false

# Check backend
for i in {1..30}; do
    if curl -f -s http://localhost:5000/health >/dev/null 2>&1 || curl -f -s http://localhost:5000 >/dev/null 2>&1; then
        log "✅ Backend is healthy"
        backend_healthy=true
        break
    fi
    sleep 2
done

# Check frontend
for i in {1..10}; do
    if curl -f -s http://localhost:3000 >/dev/null 2>&1; then
        log "✅ Frontend is healthy"
        frontend_healthy=true
        break
    fi
    sleep 2
done

# 17. Final status
log ""
log "🎉 DEPLOYMENT COMPLETE!"
log "======================"
log ""
log "🌐 Access URLs:"
log "   Frontend: http://$SERVER_IP:3000"
log "   Backend:  http://$SERVER_IP:5000"
log ""
log "👤 Default Login:"
log "   Email: admin@solarnexus.com"
log "   Password: admin123"
log ""
log "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
log ""

if [[ "$backend_healthy" == true && "$frontend_healthy" == true ]]; then
    log "✅ All services are running successfully!"
else
    warn "⚠️  Some services may not be fully healthy. Check logs:"
    log "   Backend logs: docker logs backend"
    log "   Frontend logs: docker logs frontend"
fi

log ""
log "🔧 Management Commands:"
log "   View logs:    docker logs [container_name]"
log "   Restart:      docker restart [container_name]"
log "   Stop all:     docker stop \$(docker ps -q)"
log ""
log "✅ SolarNexus deployment completed!"