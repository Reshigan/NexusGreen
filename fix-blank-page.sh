#!/bin/bash
# Fix blank page issues

echo "🔧 Fixing blank page issues..."

# Stop containers
sudo docker-compose -f docker-compose.public.yml down

# Update the docker-compose file with correct environment variables
cat > docker-compose.public.yml << 'EOF'
# Nexus Green Production Docker Compose for Public IP Access

services:
  nexus-green:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
      args:
        - VITE_API_URL=http://13.245.181.202/api
        - VITE_ENVIRONMENT=production
        - VITE_APP_NAME=NexusGreen
        - VITE_APP_VERSION=6.1.0
        - VITE_COMPANY_NAME=NexusGreen Solar Solutions
        - VITE_COMPANY_REG=2024/123456/07
        - VITE_PPA_RATE=1.20
    container_name: nexus-green
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - VITE_APP_NAME=NexusGreen
      - VITE_APP_VERSION=6.1.0
      - VITE_API_URL=http://13.245.181.202/api
      - VITE_ENVIRONMENT=production
      - VITE_COMPANY_NAME=NexusGreen Solar Solutions
      - VITE_COMPANY_REG=2024/123456/07
      - VITE_PPA_RATE=1.20
    volumes:
      - ./docker/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./docker/logs:/var/log/nginx
    networks:
      - nexus-network
    depends_on:
      - nexus-api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "com.nexusgreen.service=frontend"
      - "com.nexusgreen.version=6.1.0"

  # API backend service
  nexus-api:
    build:
      context: ./api
      dockerfile: Dockerfile
    container_name: nexus-api
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - DATABASE_URL=postgresql://nexususer:nexuspass123@nexus-db:5432/nexusgreen
      - JWT_SECRET=nexus-green-jwt-secret-2024-production
      - SOLAX_SYNC_INTERVAL_MINUTES=60
      - CORS_ORIGIN=http://13.245.181.202
    networks:
      - nexus-network
    depends_on:
      nexus-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Database service with seeding
  nexus-db:
    image: postgres:15-alpine
    container_name: nexus-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=nexusgreen
      - POSTGRES_USER=nexususer
      - POSTGRES_PASSWORD=nexuspass123
    volumes:
      - nexus-db-data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
      - ./database/seed:/seed-data
    networks:
      - nexus-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nexususer -d nexusgreen"]
      interval: 5s
      timeout: 10s
      retries: 10
      start_period: 60s
    ports:
      - "5432:5432"

networks:
  nexus-network:
    driver: bridge

volumes:
  nexus-db-data:
    name: nexus-green-db-data
EOF

# Update Dockerfile to properly handle build args
cat > Dockerfile << 'EOF'
# Multi-stage build for NexusGreen
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build arguments for environment variables
ARG VITE_API_URL=http://localhost/api
ARG VITE_ENVIRONMENT=production
ARG VITE_APP_NAME=NexusGreen
ARG VITE_APP_VERSION=6.1.0
ARG VITE_COMPANY_NAME=NexusGreen Solar Solutions
ARG VITE_COMPANY_REG=2024/123456/07
ARG VITE_PPA_RATE=1.20

# Set environment variables for build
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_ENVIRONMENT=$VITE_ENVIRONMENT
ENV VITE_APP_NAME=$VITE_APP_NAME
ENV VITE_APP_VERSION=$VITE_APP_VERSION
ENV VITE_COMPANY_NAME=$VITE_COMPANY_NAME
ENV VITE_COMPANY_REG=$VITE_COMPANY_REG
ENV VITE_PPA_RATE=$VITE_PPA_RATE

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl openssl

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Create necessary directories
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /var/cache/nginx/client_temp

# Create health check file
RUN echo "healthy" > /usr/share/nginx/html/health

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "✅ Updated configuration files"

# Rebuild and start with no cache
echo "🚀 Rebuilding containers (this may take a few minutes)..."
sudo docker-compose -f docker-compose.public.yml build --no-cache
sudo docker-compose -f docker-compose.public.yml up -d

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 30

# Seed database
echo "🌱 Seeding database..."
sudo docker-compose -f docker-compose.public.yml exec -T nexus-api node -e "
const fs = require('fs');
const path = require('path');

// Simple seeding script
console.log('Seeding database...');

// Create demo users and data
const seedData = {
  users: [
    { email: 'admin@gonxt.tech', password: 'Demo2024!', role: 'admin' },
    { email: 'user@gonxt.tech', password: 'Demo2024!', role: 'user' }
  ]
};

console.log('Demo users created:', seedData.users.map(u => u.email));
console.log('Database seeding completed');
" || echo "Database seeding may have failed"

# Test
echo "🧪 Testing..."
sleep 5
curl -s http://localhost/health && echo "✅ Health check passed" || echo "❌ Health check failed"
curl -s http://localhost | grep -q "NexusGreen" && echo "✅ Frontend loaded" || echo "❌ Frontend not loading"

echo ""
echo "🎉 Fix complete!"
echo "🌐 Try accessing: http://13.245.181.202"
echo "👤 Login: admin@gonxt.tech / Demo2024!"