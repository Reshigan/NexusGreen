#!/bin/bash

# NexusGreen Single Server Deployment Script
# This script deploys the complete NexusGreen stack using Docker Compose

set -e

echo "🚀 Starting NexusGreen deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
else
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
fi

# Stop any existing containers
print_status "Stopping existing containers..."
$COMPOSE_CMD down --remove-orphans 2>/dev/null || true

# Remove old images (optional)
read -p "Do you want to remove old images and rebuild? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing old images..."
    $DOCKER_CMD image prune -f
    $DOCKER_CMD rmi nexusgreen-frontend:latest nexusgreen-backend:latest 2>/dev/null || true
fi

# Build and start services
print_status "Building and starting services..."
$COMPOSE_CMD up --build -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check service health
print_status "Checking service health..."

# Check database
if $DOCKER_CMD exec nexusgreen-postgres pg_isready -U nexusgreen > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not ready"
fi

# Check backend
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    print_success "Backend API is ready"
else
    print_warning "Backend API might still be starting..."
fi

# Check frontend
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_success "Frontend is ready"
else
    print_warning "Frontend might still be starting..."
fi

# Display service status
print_status "Service status:"
$COMPOSE_CMD ps

echo
print_success "🎉 NexusGreen deployment completed!"
echo
echo "📋 Access Information:"
echo "   Frontend: http://localhost"
echo "   Backend API: http://localhost:3001"
echo "   Database: localhost:5432"
echo
echo "👤 Test Credentials:"
echo "   Admin: admin / admin123"
echo "   User:  user / user123"
echo
echo "🔧 Management Commands:"
echo "   View logs:    $COMPOSE_CMD logs -f"
echo "   Stop:         $COMPOSE_CMD down"
echo "   Restart:      $COMPOSE_CMD restart"
echo "   Update:       $COMPOSE_CMD pull && $COMPOSE_CMD up -d"
echo
print_status "Deployment script completed successfully!"