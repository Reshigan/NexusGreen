#!/bin/bash

# Docker Cleanup Script for NexusGreen
# Resolves network conflicts and prepares for clean deployment

echo "🧹 NexusGreen Docker Cleanup Script"
echo "=================================="

# Stop all running containers
echo "📦 Stopping all containers..."
docker compose down 2>/dev/null || true

# Remove any existing containers with our names
echo "🗑️  Removing existing containers..."
docker rm -f nexus-green-prod nexus-green-api nexus-green-db 2>/dev/null || true

# Remove conflicting networks
echo "🌐 Cleaning up networks..."
docker network rm nexus-green-network 2>/dev/null || true
docker network rm nexus-network 2>/dev/null || true

# Remove any dangling images
echo "🖼️  Cleaning up images..."
docker image prune -f

# Remove any volumes if they exist
echo "💾 Cleaning up volumes..."
docker volume rm nexus-db-data 2>/dev/null || true

# Clean up any build cache
echo "🔧 Cleaning build cache..."
docker builder prune -f

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "🚀 Ready for fresh deployment. Run:"
echo "   docker compose up -d"
echo ""