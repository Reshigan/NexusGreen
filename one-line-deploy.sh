#!/bin/bash

# NexusGreen One-Line Deployment Script
# Usage: curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/main/one-line-deploy.sh | bash

set -e

echo "🚀 NexusGreen One-Line Deployment"
echo "================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Clean up any existing conflicting resources
echo "🧹 Cleaning up existing resources..."
docker compose down 2>/dev/null || true
docker rm -f nexus-green-prod nexus-green-api nexus-green-db 2>/dev/null || true
docker network rm nexus-green-network nexus-network 2>/dev/null || true

# Clone or update repository
if [ -d "NexusGreen" ]; then
    echo "📁 Updating existing repository..."
    cd NexusGreen
    git pull origin main
else
    echo "📥 Cloning repository..."
    git clone https://github.com/Reshigan/NexusGreen.git
    cd NexusGreen
fi

# Deploy with Docker
echo "🐳 Starting Docker deployment..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check service health
echo "🏥 Checking service health..."
if curl -f http://localhost:3001/api/status > /dev/null 2>&1; then
    echo "✅ API is healthy"
else
    echo "⚠️  API may still be starting..."
fi

if curl -f http://localhost > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "⚠️  Frontend may still be starting..."
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Access your application:"
echo "   Frontend: http://localhost"
echo "   API: http://localhost:3001"
echo ""
echo "📊 Check status:"
echo "   docker compose ps"
echo "   curl http://localhost:3001/api/status"
echo ""
echo "🛠️  Troubleshooting:"
echo "   ./docker-cleanup.sh  # Clean up conflicts"
echo "   docker compose logs  # View logs"
echo ""