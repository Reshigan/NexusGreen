#!/bin/bash

# SolarNexus Production Deployment Script
# This script deploys the SolarNexus platform to production

set -e

echo "🚀 Starting SolarNexus Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="nexus.gonxt.tech"
SERVER_IP="13.244.63.26"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env.production"

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file $ENV_FILE not found!"
    exit 1
fi

print_status "Environment file found: $ENV_FILE"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs uploads ssl database/data

# Set proper permissions
print_status "Setting directory permissions..."
chmod 755 logs uploads ssl
chmod 700 database/data

# Copy environment file
print_status "Setting up environment configuration..."
cp "$ENV_FILE" .env

# Generate SSL certificates if they don't exist
if [ ! -f "ssl/${DOMAIN}.crt" ] || [ ! -f "ssl/${DOMAIN}.key" ]; then
    print_warning "SSL certificates not found. Generating self-signed certificates..."
    print_warning "For production, replace these with proper SSL certificates from a CA."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "ssl/${DOMAIN}.key" \
        -out "ssl/${DOMAIN}.crt" \
        -subj "/C=US/ST=State/L=City/O=SolarNexus/CN=${DOMAIN}"
    
    print_success "Self-signed SSL certificates generated"
else
    print_success "SSL certificates found"
fi

# Pull latest images
print_status "Pulling latest Docker images..."
docker compose pull

# Build custom images
print_status "Building application images..."
docker compose build --no-cache

# Stop existing containers
print_status "Stopping existing containers..."
docker compose down --remove-orphans

# Start the database first
print_status "Starting database..."
docker compose up -d postgres redis

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 10

# Run database migrations
print_status "Running database migrations..."
docker compose exec -T backend npx prisma migrate deploy || {
    print_error "Database migration failed"
    exit 1
}

# Generate Prisma client
print_status "Generating Prisma client..."
docker compose exec -T backend npx prisma generate || {
    print_error "Prisma client generation failed"
    exit 1
}

# Start all services
print_status "Starting all services..."
docker compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 15

# Health check
print_status "Performing health checks..."
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health || echo "000")

if [ "$BACKEND_HEALTH" = "200" ]; then
    print_success "Backend health check passed"
else
    print_error "Backend health check failed (HTTP $BACKEND_HEALTH)"
    print_status "Checking container logs..."
    docker compose logs backend --tail=20
fi

# Check if all containers are running
print_status "Checking container status..."
RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL_CONTAINERS=$(docker compose ps --services | wc -l)

if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
    print_success "All containers are running ($RUNNING_CONTAINERS/$TOTAL_CONTAINERS)"
else
    print_warning "Some containers may not be running ($RUNNING_CONTAINERS/$TOTAL_CONTAINERS)"
    docker compose ps
fi

# Display service URLs
echo ""
echo "🎉 SolarNexus deployment completed!"
echo ""
echo "📊 Service URLs:"
echo "   Frontend:  http://${DOMAIN}"
echo "   Backend:   http://${DOMAIN}/api"
echo "   Health:    http://${DOMAIN}/health"
echo ""
echo "🔧 Management Commands:"
echo "   View logs:     docker compose logs -f"
echo "   Stop services: docker compose down"
echo "   Restart:       docker compose restart"
echo "   Update:        ./deploy-production.sh"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure proper SSL certificates for production"
echo "   2. Set up domain DNS to point to $SERVER_IP"
echo "   3. Configure email settings in environment file"
echo "   4. Set up monitoring and backups"
echo "   5. Review security settings"
echo ""

# Show container status
print_status "Current container status:"
docker compose ps

# Show resource usage
print_status "Resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

print_success "Deployment completed successfully! 🚀"

# Optional: Open browser (if running locally)
if command -v xdg-open &> /dev/null; then
    read -p "Open application in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "http://${DOMAIN}"
    fi
fi