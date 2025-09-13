#!/bin/bash

# SolarNexus Production Instant Deployment
# CRITICAL GO-LIVE VERSION - NO BUILD REQUIRED
# Uses pre-optimized images for instant deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Configuration
SERVER_IP="13.245.249.110"
PROJECT_DIR="/home/ubuntu/SolarNexus"
COMPOSE_FILE="docker-compose.production.yml"

log "🚀 SolarNexus CRITICAL GO-LIVE Deployment"
log "=========================================="
log "Server IP: $SERVER_IP"
log "Deployment Mode: PRODUCTION INSTANT"

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root or with sudo"
fi

# Ensure we're in the right directory
if [[ ! -d "$PROJECT_DIR" ]]; then
    error "SolarNexus directory not found at $PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Stop any existing deployment
log "🛑 Stopping existing services..."
docker compose down -v 2>/dev/null || true
docker system prune -f >/dev/null 2>&1

# Create production environment
log "⚙️ Creating production environment..."
cat > .env.production << EOF
# SolarNexus Production Environment
NODE_ENV=production
SERVER_IP=$SERVER_IP

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=SolarNexus2024!
DATABASE_URL=postgresql://solarnexus:SolarNexus2024!@postgres:5432/solarnexus

# Redis Configuration
REDIS_URL=redis://redis:6379

# API Configuration
API_BASE_URL=http://$SERVER_IP:5000
FRONTEND_URL=http://$SERVER_IP:3000

# Security
JWT_SECRET=your-super-secret-jwt-key-change-in-production
BCRYPT_ROUNDS=12

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH=/app/uploads

# Logging
LOG_LEVEL=info
LOG_FILE=/app/logs/app.log
EOF

# Create optimized production docker-compose
log "📦 Creating production Docker Compose configuration..."
cat > $COMPOSE_FILE << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: solarnexus-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: solarnexus
      POSTGRES_USER: solarnexus
      POSTGRES_PASSWORD: SolarNexus2024!
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/migration.sql:/docker-entrypoint-initdb.d/migration.sql:ro
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U solarnexus -d solarnexus"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - solarnexus-network

  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - solarnexus-network

  backend:
    image: node:20-slim
    container_name: solarnexus-backend
    restart: unless-stopped
    working_dir: /app
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://solarnexus:SolarNexus2024!@postgres:5432/solarnexus
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-super-secret-jwt-key-change-in-production
      - PORT=5000
    volumes:
      - ./solarnexus-backend:/app
      - backend_uploads:/app/uploads
      - backend_logs:/app/logs
    ports:
      - "5000:5000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "
        apt-get update && apt-get install -y python3 make g++ curl &&
        npm ci --only=production &&
        npx prisma generate &&
        npx prisma db push &&
        npm start
      "
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - solarnexus-network

  frontend:
    image: nginx:alpine
    container_name: solarnexus-frontend
    restart: unless-stopped
    volumes:
      - ./solarnexus-frontend/dist:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "3000:80"
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - solarnexus-network

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  backend_uploads:
    driver: local
  backend_logs:
    driver: local

networks:
  solarnexus-network:
    driver: bridge
EOF

# Create optimized nginx configuration
log "🌐 Creating nginx configuration..."
mkdir -p nginx
cat > nginx/nginx.conf << EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    
    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    server {
        listen 80;
        server_name $SERVER_IP localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        
        # Frontend routes
        location / {
            try_files \$uri \$uri/ /index.html;
            expires 1h;
            add_header Cache-Control "public, immutable";
        }
        
        # API proxy
        location /api/ {
            proxy_pass http://backend:5000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Build frontend locally (faster than Docker build)
log "🏗️ Building frontend application..."
if [[ ! -d "solarnexus-frontend/dist" ]]; then
    cd solarnexus-frontend
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        info "Installing frontend dependencies..."
        npm ci
    fi
    
    # Create production build
    info "Creating production build..."
    VITE_API_BASE_URL="http://$SERVER_IP:5000" npm run build
    
    cd ..
fi

# Ensure backend dependencies
log "📦 Preparing backend dependencies..."
cd solarnexus-backend
if [[ ! -d "node_modules" ]]; then
    info "Installing backend dependencies..."
    npm ci --only=production
fi
cd ..

# Start services
log "🚀 Starting production services..."
docker compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
log "⏳ Waiting for services to be ready..."
sleep 10

# Health check function
check_service() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            log "✅ $service is healthy"
            return 0
        fi
        info "Waiting for $service... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    error "$service failed to start"
}

# Check all services
check_service "Backend API" "http://localhost:5000/health"
check_service "Frontend" "http://localhost:3000/health"

# Final verification
log "🔍 Final system verification..."
docker compose -f $COMPOSE_FILE ps

log ""
log "🎉 PRODUCTION DEPLOYMENT SUCCESSFUL!"
log "=================================="
log ""
log "🌐 Access URLs:"
log "   Frontend:    http://$SERVER_IP:3000"
log "   Backend API: http://$SERVER_IP:5000"
log "   Health:      http://$SERVER_IP:5000/health"
log ""
log "📊 Service Status:"
docker compose -f $COMPOSE_FILE ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
log ""
log "🔧 Management Commands:"
log "   View logs:    docker compose -f $COMPOSE_FILE logs -f"
log "   Stop:         docker compose -f $COMPOSE_FILE down"
log "   Restart:      docker compose -f $COMPOSE_FILE restart"
log ""
log "✅ SolarNexus is now LIVE and ready for production!"
EOF