#!/bin/bash
# Complete frontend rebuild to fix blank page

echo "🔧 Complete frontend rebuild starting..."

# Stop containers
echo "🛑 Stopping containers..."
sudo docker-compose -f docker-compose.public.yml down

# Remove old images to force rebuild
echo "🗑️ Removing old images..."
sudo docker rmi nexusgreen-nexus-green 2>/dev/null || true

# Check if we have the source files
echo "📁 Checking source files..."
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found! Downloading from GitHub..."
    git pull origin main
fi

# Create a simple test HTML to verify nginx is working
echo "🧪 Creating test page..."
mkdir -p test-html
cat > test-html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>NexusGreen Test</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        .success { color: #10B981; }
        .error { color: #EF4444; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✅ NexusGreen Server Working!</h1>
        <p>If you can see this page, the server is running correctly.</p>
        <p>The React app will be rebuilt and deployed shortly.</p>
        <div id="status">
            <h3>System Status:</h3>
            <p>✅ Nginx: Running</p>
            <p>✅ Docker: Running</p>
            <p>🔄 React App: Rebuilding...</p>
        </div>
        <script>
            console.log('Test page loaded successfully');
            // Test API connection
            fetch('/api/health')
                .then(response => response.json())
                .then(data => {
                    console.log('API Health:', data);
                    document.getElementById('status').innerHTML += '<p class="success">✅ API: Connected</p>';
                })
                .catch(error => {
                    console.error('API Error:', error);
                    document.getElementById('status').innerHTML += '<p class="error">❌ API: Error</p>';
                });
        </script>
    </div>
</body>
</html>
EOF

# Create temporary docker-compose for test
cat > docker-compose.test.yml << 'EOF'
services:
  nexus-test:
    image: nginx:alpine
    container_name: nexus-test
    ports:
      - "80:80"
    volumes:
      - ./test-html:/usr/share/nginx/html:ro
      - ./docker/default.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - nexus-network
    depends_on:
      - nexus-api

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
      - CORS_ORIGIN=http://13.245.181.202
    networks:
      - nexus-network
    depends_on:
      nexus-db:
        condition: service_healthy

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

echo "🚀 Starting test environment..."
sudo docker-compose -f docker-compose.test.yml up -d

echo "⏳ Waiting for test environment..."
sleep 15

echo "🧪 Testing basic connectivity..."
curl -s http://localhost | grep -q "NexusGreen Test" && echo "✅ Test page working" || echo "❌ Test page failed"
curl -s http://localhost/api/health | grep -q "healthy" && echo "✅ API working" || echo "❌ API failed"

echo ""
echo "🎯 Test environment is running!"
echo "🌐 Visit: http://13.245.181.202 to see the test page"
echo ""
echo "Now rebuilding the React app..."

# Now rebuild the React app with verbose logging
echo "📦 Installing dependencies..."
npm install --verbose

echo "🏗️ Building React app with verbose output..."
VITE_API_URL=http://13.245.181.202/api \
VITE_ENVIRONMENT=production \
VITE_APP_NAME=NexusGreen \
VITE_APP_VERSION=6.1.0 \
VITE_COMPANY_NAME="NexusGreen Solar Solutions" \
VITE_COMPANY_REG=2024/123456/07 \
VITE_PPA_RATE=1.20 \
npm run build -- --mode production

# Check if build was successful
if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    echo "✅ Build successful!"
    echo "📁 Build contents:"
    ls -la dist/
    echo ""
    echo "📄 Index.html preview:"
    head -20 dist/index.html
else
    echo "❌ Build failed!"
    echo "📋 Build logs:"
    npm run build 2>&1 | tail -50
    exit 1
fi

# Stop test environment
echo "🛑 Stopping test environment..."
sudo docker-compose -f docker-compose.test.yml down

# Update the production Dockerfile with better error handling
cat > Dockerfile << 'EOF'
# Multi-stage build for NexusGreen
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with verbose logging
RUN npm ci --only=production --verbose

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

# Debug: Show environment variables
RUN echo "Build environment:" && env | grep VITE

# Build the application with verbose output
RUN npm run build -- --mode production

# Debug: Show build output
RUN echo "Build completed. Contents:" && ls -la dist/ && echo "Index.html:" && head -10 dist/index.html

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

echo "🚀 Building production containers..."
sudo docker-compose -f docker-compose.public.yml build --no-cache --progress=plain

echo "🎯 Starting production environment..."
sudo docker-compose -f docker-compose.public.yml up -d

echo "⏳ Waiting for services to start..."
sleep 20

# Final tests
echo "🧪 Final testing..."
echo "Health check:"
curl -s http://localhost/health

echo -e "\nFrontend test:"
curl -s http://localhost | head -10

echo -e "\nAPI test:"
curl -s http://localhost/api/health

echo -e "\nContainer status:"
sudo docker-compose -f docker-compose.public.yml ps

echo ""
echo "🎉 Rebuild complete!"
echo "🌐 Visit: http://13.245.181.202"
echo "👤 Login: admin@gonxt.tech / Demo2024!"

# Cleanup
rm -rf test-html docker-compose.test.yml