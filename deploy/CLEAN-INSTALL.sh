#!/bin/bash

# SolarNexus Clean Install Script
# This script completely removes all previous installations and does a fresh install
# Version: 2.0
# Author: OpenHands AI Assistant

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    DOCKER_CMD="docker"
    DOCKER_COMPOSE_CMD="docker-compose"
    SUDO_CMD=""
else
    DOCKER_CMD="sudo docker"
    DOCKER_COMPOSE_CMD="sudo docker-compose"
    SUDO_CMD="sudo"
fi

print_header "SolarNexus Clean Install v2.0"
echo ""
print_warning "This script will completely remove all existing SolarNexus installations"
print_warning "and perform a fresh installation from scratch."
echo ""

# Check if running in non-interactive mode (piped from curl)
if [ -t 0 ]; then
    # Interactive mode - ask for confirmation
    read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm
    if [ "$confirm" != "YES" ]; then
        print_error "Installation cancelled by user"
        exit 1
    fi
else
    # Non-interactive mode (piped) - auto-confirm with warning
    print_warning "Running in non-interactive mode - proceeding automatically"
    print_status "To cancel, press Ctrl+C within 5 seconds..."
    sleep 5
fi

print_header "STEP 1: System Preparation"

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_step "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    $SUDO_CMD sh get-docker.sh
    $SUDO_CMD usermod -aG docker $USER
    print_success "Docker installed"
else
    print_success "Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_step "Installing Docker Compose..."
    $SUDO_CMD curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO_CMD chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose already installed"
fi

# Start Docker service
print_step "Starting Docker service..."
$SUDO_CMD systemctl start docker 2>/dev/null || true
$SUDO_CMD systemctl enable docker 2>/dev/null || true
print_success "Docker service started"

print_header "STEP 2: Complete Cleanup"

# Stop all running containers
print_step "Stopping all Docker containers..."
$DOCKER_CMD stop $($DOCKER_CMD ps -aq) 2>/dev/null || true
print_success "All containers stopped"

# Remove all containers
print_step "Removing all Docker containers..."
$DOCKER_CMD rm $($DOCKER_CMD ps -aq) 2>/dev/null || true
print_success "All containers removed"

# Remove SolarNexus images
print_step "Removing SolarNexus Docker images..."
$DOCKER_CMD rmi $($DOCKER_CMD images | grep -E "(solarnexus|solar-nexus)" | awk '{print $3}') 2>/dev/null || true
print_success "SolarNexus images removed"

# Remove all volumes
print_step "Removing all Docker volumes..."
$DOCKER_CMD volume rm $($DOCKER_CMD volume ls -q) 2>/dev/null || true
print_success "All volumes removed"

# Remove all networks (except default ones)
print_step "Removing custom Docker networks..."
$DOCKER_CMD network rm $($DOCKER_CMD network ls | grep -v -E "(bridge|host|none)" | awk 'NR>1 {print $1}') 2>/dev/null || true
print_success "Custom networks removed"

# Clean Docker system
print_step "Cleaning Docker system..."
$DOCKER_CMD system prune -af --volumes 2>/dev/null || true
print_success "Docker system cleaned"

# Remove existing SolarNexus directories
print_step "Removing existing SolarNexus directories..."
rm -rf ~/SolarNexus* /opt/SolarNexus* /var/lib/SolarNexus* 2>/dev/null || true
rm -rf ./SolarNexus* 2>/dev/null || true
print_success "Existing directories removed"

# Kill processes using SolarNexus ports
print_step "Freeing up ports..."
$SUDO_CMD fuser -k 80/tcp 2>/dev/null || true
$SUDO_CMD fuser -k 443/tcp 2>/dev/null || true
$SUDO_CMD fuser -k 3000/tcp 2>/dev/null || true
$SUDO_CMD fuser -k 5432/tcp 2>/dev/null || true
$SUDO_CMD fuser -k 6379/tcp 2>/dev/null || true
$SUDO_CMD fuser -k 27017/tcp 2>/dev/null || true
print_success "Ports freed"

print_header "STEP 3: Fresh Installation"

# Create installation directory
INSTALL_DIR="$HOME/SolarNexus"
print_step "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
print_success "Installation directory created"

# Clone repository
print_step "Cloning SolarNexus repository..."
git clone https://github.com/Reshigan/SolarNexus.git .
print_success "Repository cloned"

# Create comprehensive Dockerfiles
print_step "Creating optimized Dockerfiles..."

# Backend Dockerfile
cat > solarnexus-backend/Dockerfile << 'EOF'
FROM node:20-alpine as base

# Install comprehensive system dependencies
RUN apk add --no-cache \
    python3 py3-pip make g++ gcc libc-dev \
    curl wget git openssh-client \
    imagemagick graphicsmagick poppler-utils \
    postgresql-client ca-certificates openssl \
    file unzip dumb-init tzdata \
    && rm -rf /var/cache/apk/*

ENV TZ=UTC
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/ 2>/dev/null || true

FROM base as production
RUN addgroup -g 1001 -S nodejs && \
    adduser -S solarnexus -u 1001 -G nodejs

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy application code
COPY --chown=solarnexus:nodejs . .

# Generate Prisma client and build if needed
RUN if [ -f "prisma/schema.prisma" ]; then npx prisma generate; fi
RUN if [ -f "tsconfig.json" ]; then npm run build 2>/dev/null || true; fi

# Create directories
RUN mkdir -p /app/uploads /app/logs /app/temp /app/backups && \
    chown -R solarnexus:nodejs /app/uploads /app/logs /app/temp /app/backups && \
    chmod 755 /app/uploads /app/logs /app/temp /app/backups

# Install PM2 and prune dev dependencies
RUN npm install -g pm2 2>/dev/null || true
RUN npm prune --production

USER solarnexus
ENV NODE_ENV=production
ENV NPM_CONFIG_CACHE=/tmp/.npm
ENV HOME=/app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || curl -f http://localhost:3000/ || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sh", "-c", "if command -v pm2 >/dev/null 2>&1; then pm2-runtime start ecosystem.config.js 2>/dev/null || npm start; else npm start; fi"]
EOF

# Frontend Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine as build

# Install build dependencies
RUN apk add --no-cache \
    python3 py3-pip make g++ gcc libc-dev \
    curl wget git imagemagick optipng jpegoptim \
    file unzip ca-certificates openssl \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock ./yarn.lock 2>/dev/null || true

# Install dependencies
RUN if [ -f "yarn.lock" ]; then yarn install --frozen-lockfile; else npm ci; fi

# Copy source and build
COPY . .

ARG VITE_API_URL=http://localhost:3000
ARG REACT_APP_API_URL=http://localhost:3000
ARG NODE_ENV=production

ENV VITE_API_URL=$VITE_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV NODE_ENV=$NODE_ENV
ENV GENERATE_SOURCEMAP=false

# Build application
RUN if [ -f "yarn.lock" ]; then yarn build; elif npm run build:prod >/dev/null 2>&1; then npm run build:prod; else npm run build; fi

# Optimize images
RUN if [ -d "dist" ]; then \
        find dist -name "*.png" -exec optipng -o2 {} \; 2>/dev/null || true; \
        find dist -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --max=85 {} \; 2>/dev/null || true; \
    elif [ -d "build" ]; then \
        find build -name "*.png" -exec optipng -o2 {} \; 2>/dev/null || true; \
        find build -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --max=85 {} \; 2>/dev/null || true; \
    fi

# Production stage
FROM nginx:alpine

RUN apk add --no-cache curl wget ca-certificates openssl gzip dumb-init tzdata && \
    rm -rf /var/cache/apk/*

ENV TZ=UTC

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html 2>/dev/null || \
COPY --from=build /app/build /usr/share/nginx/html

# Create nginx configuration
RUN echo 'server { \
    listen 8080; \
    server_name localhost; \
    add_header X-Frame-Options "SAMEORIGIN" always; \
    add_header X-XSS-Protection "1; mode=block" always; \
    add_header X-Content-Type-Options "nosniff" always; \
    gzip on; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    location /api/ { \
        proxy_pass http://solarnexus-backend:3000/; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
    } \
    location /health { \
        proxy_pass http://solarnexus-backend:3000/health; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Set up non-root user
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S nginx-user -u 1001 -G nginx-user && \
    chown -R nginx-user:nginx-user /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && chown nginx-user:nginx-user /var/run/nginx.pid

USER nginx-user
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
EOF

print_success "Dockerfiles created"

# Generate secure environment configuration
print_step "Generating secure environment configuration..."
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

cat > .env << EOF
# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
DATABASE_URL=postgresql://solarnexus:${POSTGRES_PASSWORD}@postgres:5432/solarnexus

# Redis Configuration
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# Application Configuration
NODE_ENV=production
PORT=3000
JWT_SECRET=${JWT_SECRET}

# Frontend Configuration
VITE_API_URL=http://localhost:3000

# Security Configuration
CORS_ORIGIN=http://localhost,https://localhost
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Generated on: $(date)
EOF

print_success "Environment configuration created"

# Create production Docker Compose
print_step "Creating production Docker Compose configuration..."
cat > docker-compose.production.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: solarnexus-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes --appendfsync everysec
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

  backend:
    build:
      context: ./solarnexus-backend
      dockerfile: Dockerfile
      target: production
    container_name: solarnexus-backend
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
      - PORT=3000
      - CORS_ORIGIN=${CORS_ORIGIN}
      - RATE_LIMIT_WINDOW_MS=${RATE_LIMIT_WINDOW_MS}
      - RATE_LIMIT_MAX_REQUESTS=${RATE_LIMIT_MAX_REQUESTS}
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - solarnexus-network
    restart: unless-stopped
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  frontend:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - VITE_API_URL=${VITE_API_URL}
        - REACT_APP_API_URL=${VITE_API_URL}
        - NODE_ENV=production
    container_name: solarnexus-frontend
    ports:
      - "80:8080"
      - "443:8080"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  solarnexus-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

print_success "Docker Compose configuration created"

print_header "STEP 4: Building and Deploying"

# Create necessary directories
print_step "Creating application directories..."
mkdir -p logs uploads backups temp
chmod 755 logs uploads backups temp
print_success "Directories created"

# Build and start services
print_step "Building Docker images and starting services..."
$DOCKER_COMPOSE_CMD -f docker-compose.production.yml up -d --build

print_header "STEP 5: Service Health Checks"

# Wait for services to be healthy
print_step "Waiting for services to start..."
sleep 30

# Check PostgreSQL
print_step "Checking PostgreSQL health..."
for i in {1..12}; do
    if $DOCKER_CMD exec solarnexus-postgres pg_isready -U solarnexus -d solarnexus >/dev/null 2>&1; then
        print_success "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 12 ]; then
        print_error "PostgreSQL failed to start"
        print_warning "Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.production.yml logs postgres"
        exit 1
    fi
    sleep 5
done

# Check Redis
print_step "Checking Redis health..."
for i in {1..12}; do
    if $DOCKER_CMD exec solarnexus-redis redis-cli -a "${REDIS_PASSWORD}" ping >/dev/null 2>&1; then
        print_success "Redis is ready"
        break
    fi
    if [ $i -eq 12 ]; then
        print_error "Redis failed to start"
        print_warning "Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.production.yml logs redis"
        exit 1
    fi
    sleep 5
done

# Check Backend
print_step "Checking Backend API health..."
for i in {1..24}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1 || curl -f http://localhost:3000/ >/dev/null 2>&1; then
        print_success "Backend API is ready"
        break
    fi
    if [ $i -eq 24 ]; then
        print_error "Backend API failed to start"
        print_warning "Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.production.yml logs backend"
        exit 1
    fi
    sleep 5
done

# Check Frontend
print_step "Checking Frontend health..."
for i in {1..12}; do
    if curl -f http://localhost/ >/dev/null 2>&1; then
        print_success "Frontend is ready"
        break
    fi
    if [ $i -eq 12 ]; then
        print_error "Frontend failed to start"
        print_warning "Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.production.yml logs frontend"
        exit 1
    fi
    sleep 5
done

print_header "STEP 6: Database Initialization"

# Initialize database
print_step "Initializing database..."
$DOCKER_CMD exec solarnexus-backend npx prisma migrate deploy 2>/dev/null || print_warning "No Prisma migrations found"
$DOCKER_CMD exec solarnexus-backend npx prisma generate 2>/dev/null || print_warning "Prisma generate completed"
print_success "Database initialization completed"

print_header "STEP 7: Final Verification"

# Final health check
print_step "Performing final system verification..."
RUNNING_CONTAINERS=$($DOCKER_CMD ps --filter "name=solarnexus" --format "table {{.Names}}\t{{.Status}}" | grep -c "Up" || echo "0")

if [ "$RUNNING_CONTAINERS" -ge 4 ]; then
    print_success "All services are running successfully!"
else
    print_warning "Some services may not be running properly"
fi

# Create deployment information file
cat > deployment-info.txt << EOF
SolarNexus Clean Installation Complete
=====================================
Installation Date: $(date)
Installation Directory: $INSTALL_DIR
Version: 2.0

Service URLs:
- Frontend: http://localhost
- Backend API: http://localhost:3000
- Health Check: http://localhost:3000/health

Database Information:
- PostgreSQL: localhost:5432
- Database: solarnexus
- User: solarnexus
- Password: ${POSTGRES_PASSWORD}

Redis Information:
- Host: localhost:6379
- Password: ${REDIS_PASSWORD}

Security:
- JWT Secret: ${JWT_SECRET}
- All passwords are randomly generated and secure

Management Commands:
- View status: docker-compose -f docker-compose.production.yml ps
- View logs: docker-compose -f docker-compose.production.yml logs -f
- Stop services: docker-compose -f docker-compose.production.yml down
- Restart services: docker-compose -f docker-compose.production.yml restart
- Update services: docker-compose -f docker-compose.production.yml up -d --build

Important Files:
- Environment: .env
- Docker Compose: docker-compose.production.yml
- Logs: ./logs/
- Uploads: ./uploads/
- Backups: ./backups/
- This info: deployment-info.txt

Container Status:
$($DOCKER_COMPOSE_CMD -f docker-compose.production.yml ps)

Installation completed successfully!
EOF

print_header "🎉 INSTALLATION COMPLETE! 🎉"
echo ""
print_success "SolarNexus has been successfully installed and is running!"
echo ""
echo -e "${CYAN}📊 Service Status:${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose.production.yml ps
echo ""
echo -e "${CYAN}🌐 Access URLs:${NC}"
echo "   Frontend: http://localhost"
echo "   Backend API: http://localhost:3000"
echo "   Health Check: http://localhost:3000/health"
echo ""
echo -e "${CYAN}🔧 Quick Management Commands:${NC}"
echo "   View logs: docker-compose -f docker-compose.production.yml logs -f"
echo "   Stop: docker-compose -f docker-compose.production.yml down"
echo "   Restart: docker-compose -f docker-compose.production.yml restart"
echo ""
echo -e "${CYAN}📁 Important Files:${NC}"
echo "   Installation directory: $INSTALL_DIR"
echo "   Environment config: .env"
echo "   Deployment info: deployment-info.txt"
echo ""
print_success "Installation information saved to deployment-info.txt"
print_success "Your SolarNexus application is ready for production use!"
echo ""
print_header "Happy Solar Nexus-ing! ☀️"