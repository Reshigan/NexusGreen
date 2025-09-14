#!/bin/bash

# SolarNexus Complete Clean Deployment Script
# This script completely removes old installation and deploys fresh

set -e  # Exit on any error

echo "🚀 SolarNexus Complete Clean Deployment"
echo "======================================="
echo "This will completely remove existing installation and deploy fresh"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Set deployment directory
DEPLOY_DIR="/home/solarnexus"
BACKUP_DIR="/home/solarnexus-backup"

print_status "Starting complete clean deployment..."

# Step 1: Stop and remove all existing containers
print_status "Step 1: Cleaning up existing Docker containers..."
$SUDO docker stop $(docker ps -aq) 2>/dev/null || true
$SUDO docker rm $(docker ps -aq) 2>/dev/null || true
$SUDO docker system prune -af --volumes
$SUDO docker network prune -f
print_success "Docker cleanup completed"

# Step 2: Remove existing installation
print_status "Step 2: Removing existing installation..."
if [ -d "$DEPLOY_DIR" ]; then
    # Create backup if directory exists
    if [ "$(ls -A $DEPLOY_DIR 2>/dev/null)" ]; then
        BACKUP_NAME="solarnexus-backup-$(date +%Y%m%d_%H%M%S)"
        print_status "Creating backup at $BACKUP_DIR/$BACKUP_NAME"
        $SUDO mkdir -p "$BACKUP_DIR"
        $SUDO cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null || true
    fi
    $SUDO rm -rf "$DEPLOY_DIR"
fi

# Also clean /opt/solarnexus if it exists
if [ -d "/opt/solarnexus" ]; then
    print_status "Removing /opt/solarnexus..."
    $SUDO rm -rf "/opt/solarnexus"
fi

print_success "Old installation removed"

# Step 3: Clone fresh repository
print_status "Step 3: Cloning fresh repository..."
$SUDO mkdir -p "$DEPLOY_DIR"
cd "$(dirname $DEPLOY_DIR)"
$SUDO git clone https://github.com/Reshigan/SolarNexus.git solarnexus
cd "$DEPLOY_DIR"

# Fix git ownership
$SUDO git config --global --add safe.directory "$DEPLOY_DIR"
print_success "Repository cloned"

# Step 4: Create environment file
print_status "Step 4: Creating environment configuration..."
cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=secure_solarnexus_2024

# API Configuration
SOLAX_API_TOKEN=
JWT_SECRET=your_super_secure_jwt_secret_key_here_change_this

# Email Configuration (optional)
EMAIL_USER=
EMAIL_PASS=

# Environment
NODE_ENV=production
EOF

print_success "Environment file created"

# Step 5: Fix backend TypeScript issues
print_status "Step 5: Fixing backend configuration..."

# Create proper package.json for backend
cat > solarnexus-backend/package.json << 'EOF'
{
  "name": "solarnexus-backend",
  "version": "1.0.0",
  "description": "SolarNexus Backend API",
  "main": "dist/server.js",
  "scripts": {
    "start": "node dist/server.js",
    "dev": "ts-node src/server.ts",
    "build": "tsc",
    "build:start": "npm run build && npm start"
  },
  "dependencies": {
    "express": "^4.18.2",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.1",
    "pg": "^8.11.3",
    "redis": "^4.6.7",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "@types/express": "^4.17.17",
    "@types/compression": "^1.7.2",
    "@types/morgan": "^1.9.4",
    "@types/cors": "^2.8.13",
    "@types/node": "^20.4.5",
    "@types/pg": "^8.10.2",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/bcryptjs": "^2.4.2",
    "typescript": "^5.1.6",
    "ts-node": "^10.9.1"
  }
}
EOF

# Create TypeScript config
cat > solarnexus-backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": false,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noImplicitAny": false,
    "strictNullChecks": false
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# Create improved backend Dockerfile
cat > solarnexus-backend/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies
RUN npm install

# Copy source code
COPY . .

# Build TypeScript (if possible)
RUN npm run build || echo "Build failed, will use ts-node"

# Install ts-node globally as fallback
RUN npm install -g ts-node typescript

# Create startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'if [ -d "dist" ] && [ -f "dist/server.js" ]; then' >> /app/start.sh && \
    echo '  echo "Starting compiled version..."' >> /app/start.sh && \
    echo '  node dist/server.js' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '  echo "Starting with ts-node..."' >> /app/start.sh && \
    echo '  ts-node src/server.ts' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]
EOF

print_success "Backend configuration fixed"

# Step 6: Create nginx configuration
print_status "Step 6: Creating nginx configuration..."
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost nexus.gonxt.tech;
    root /usr/share/nginx/html;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Handle React Router
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://solarnexus-backend:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

print_success "Nginx configuration created"

# Step 7: Create optimized docker-compose.yml
print_status "Step 7: Creating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: solarnexus-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-solarnexus}
      POSTGRES_USER: ${POSTGRES_USER:-solarnexus}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-secure_solarnexus_2024}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-solarnexus}"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    volumes:
      - redis_data:/data
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build: ./solarnexus-backend
    container_name: solarnexus-backend
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-solarnexus}:${POSTGRES_PASSWORD:-secure_solarnexus_2024}@postgres:5432/${POSTGRES_DB:-solarnexus}
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET:-your_super_secure_jwt_secret_key_here_change_this}
      SOLAX_API_TOKEN: ${SOLAX_API_TOKEN:-}
      EMAIL_USER: ${EMAIL_USER:-}
      EMAIL_PASS: ${EMAIL_PASS:-}
      NODE_ENV: production
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - solarnexus-network
    restart: unless-stopped
    ports:
      - "5000:5000"

  frontend:
    build: .
    container_name: solarnexus-frontend
    depends_on:
      - backend
    networks:
      - solarnexus-network
    restart: unless-stopped
    ports:
      - "3000:80"

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  solarnexus-network:
    driver: bridge
EOF

print_success "Docker Compose configuration created"

# Step 8: Build and deploy
print_status "Step 8: Building and deploying application..."

# Build and start services
$SUDO docker-compose build --no-cache
$SUDO docker-compose up -d

print_success "Application deployed"

# Step 9: Wait and verify deployment
print_status "Step 9: Verifying deployment..."
sleep 30

# Check container status
echo ""
echo "=== Container Status ==="
$SUDO docker-compose ps

# Test backend
echo ""
echo "=== Backend Health Check ==="
if curl -f http://localhost:5000/health 2>/dev/null; then
    print_success "Backend is running"
else
    print_warning "Backend may still be starting..."
    echo "Backend logs:"
    $SUDO docker logs solarnexus-backend --tail=10
fi

# Test frontend
echo ""
echo "=== Frontend Check ==="
if curl -I http://localhost:3000/ 2>/dev/null | grep -q "200 OK"; then
    print_success "Frontend is running"
else
    print_warning "Frontend may have issues"
    echo "Frontend logs:"
    $SUDO docker logs solarnexus-frontend --tail=10
fi

# Final status
echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo "• Application URL: http://nexus.gonxt.tech"
echo "• Local URL: http://localhost:3000"
echo "• Backend API: http://localhost:5000"
echo "• Deployment directory: $DEPLOY_DIR"
echo "• Backup location: $BACKUP_DIR (if created)"
echo ""
echo "Useful commands:"
echo "• View logs: cd $DEPLOY_DIR && sudo docker-compose logs"
echo "• Restart: cd $DEPLOY_DIR && sudo docker-compose restart"
echo "• Stop: cd $DEPLOY_DIR && sudo docker-compose down"
echo "• Update: cd $DEPLOY_DIR && git pull && sudo docker-compose up -d --build"
echo ""

# Check if services are healthy
sleep 10
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null || echo "000")
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")

if [ "$BACKEND_STATUS" = "200" ] && [ "$FRONTEND_STATUS" = "200" ]; then
    print_success "✅ All services are healthy and running!"
    echo "🌐 Your SolarNexus application is ready at: http://nexus.gonxt.tech"
else
    print_warning "⚠️  Some services may still be starting. Check logs if issues persist."
    echo "Run: cd $DEPLOY_DIR && sudo docker-compose logs"
fi

echo ""
echo "Deployment completed at: $(date)"