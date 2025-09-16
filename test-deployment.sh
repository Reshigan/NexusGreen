#!/bin/bash

# Test deployment script for NexusGreen
# Tests the fixes for API and frontend issues

echo "🧪 Testing NexusGreen deployment fixes..."

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Please install Docker Compose."
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose up --build -d

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 30

# Test API health check
echo "🔍 Testing API health check..."
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api-health)
if [ "$API_HEALTH" = "200" ]; then
    echo "✅ API health check passed"
else
    echo "❌ API health check failed (HTTP $API_HEALTH)"
fi

# Test frontend
echo "🔍 Testing frontend..."
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$FRONTEND_HEALTH" = "200" ]; then
    echo "✅ Frontend health check passed"
else
    echo "❌ Frontend health check failed (HTTP $FRONTEND_HEALTH)"
fi

# Test nginx health
echo "🔍 Testing nginx health..."
NGINX_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
if [ "$NGINX_HEALTH" = "200" ]; then
    echo "✅ Nginx health check passed"
else
    echo "❌ Nginx health check failed (HTTP $NGINX_HEALTH)"
fi

# Show container status
echo "📊 Container status:"
docker-compose ps

# Show recent logs
echo "📋 Recent API logs:"
docker-compose logs --tail=10 nexus-api

echo "📋 Recent frontend logs:"
docker-compose logs --tail=10 nexus-frontend

echo "🎉 Deployment test completed!"