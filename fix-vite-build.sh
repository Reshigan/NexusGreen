#!/bin/bash
# Fix Vite build issue

echo "🔧 Fixing Vite build issue..."

# Stop containers
sudo docker-compose -f docker-compose.public.yml down

# Fix the Dockerfile to install all dependencies (including dev dependencies)
cat > Dockerfile << 'EOF'
# Multi-stage build for NexusGreen
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev dependencies like vite)
RUN npm ci --verbose

# Copy source code
COPY . .

# Build arguments for environment variables
ARG VITE_API_URL=http://13.245.181.202/api
ARG VITE_ENVIRONMENT=production
ARG VITE_APP_NAME=NexusGreen
ARG VITE_APP_VERSION=6.1.0
ARG VITE_COMPANY_NAME="NexusGreen Solar Solutions"
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

# Debug: Show environment variables and verify vite is available
RUN echo "Build environment:" && env | grep VITE
RUN echo "Checking vite installation:" && npx vite --version

# Build the application
RUN npm run build

# Debug: Show build output
RUN echo "Build completed. Contents:" && ls -la dist/ && echo "Index.html preview:" && head -10 dist/index.html

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

# Debug: Verify files were copied
RUN echo "Files in nginx html:" && ls -la /usr/share/nginx/html/

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

echo "✅ Fixed Dockerfile to install dev dependencies"

# Also check if package.json has the right dependencies
echo "📦 Checking package.json..."
if [ -f "package.json" ]; then
    echo "Current dependencies:"
    grep -A 10 '"devDependencies"' package.json || echo "No devDependencies found"
    grep -A 10 '"dependencies"' package.json || echo "No dependencies found"
else
    echo "❌ package.json not found!"
fi

# Build with no cache to ensure fresh install
echo "🚀 Building with fixed Dockerfile..."
sudo docker-compose -f docker-compose.public.yml build --no-cache nexus-green

echo "🎯 Starting containers..."
sudo docker-compose -f docker-compose.public.yml up -d

echo "⏳ Waiting for services..."
sleep 20

# Test
echo "🧪 Testing..."
echo "Health check:"
curl -s http://localhost/health && echo " ✅" || echo " ❌"

echo "Frontend check:"
curl -s http://localhost | head -5

echo "API check:"
curl -s http://localhost/api/health && echo " ✅" || echo " ❌"

echo ""
echo "🎉 Vite build fix complete!"
echo "🌐 Try: http://13.245.181.202"