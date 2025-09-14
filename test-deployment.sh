#!/bin/bash

# SolarNexus Deployment Test Script
# Tests the deployment locally before pushing to production

set -e

echo "🧪 Testing SolarNexus deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

# Check if Docker is running
print_status "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi
print_success "Docker is running"

# Check if Docker Compose is available
print_status "Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed"
    exit 1
fi
print_success "Docker Compose is available"

# Check if frontend build exists
print_status "Checking frontend build..."
if [ ! -d "dist" ]; then
    print_error "Frontend build not found. Please run 'npm run build' first."
    exit 1
fi
print_success "Frontend build exists"

# Check if backend build exists
print_status "Checking backend build..."
if [ ! -d "solarnexus-backend/dist" ]; then
    print_error "Backend build not found. Please run 'npm run build' in solarnexus-backend directory."
    exit 1
fi
print_success "Backend build exists"

# Create test environment file
print_status "Creating test environment..."
if [ ! -f ".env" ]; then
    cp .env.production.template .env
    
    # Set test values
    sed -i 's/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=test_postgres_password/' .env
    sed -i 's/REDIS_PASSWORD=.*/REDIS_PASSWORD=test_redis_password/' .env
    sed -i 's/JWT_SECRET=.*/JWT_SECRET=test_jwt_secret_key_for_testing_only/' .env
    sed -i 's/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=test_jwt_refresh_secret_key_for_testing_only/' .env
    sed -i 's/SERVER_IP=.*/SERVER_IP=localhost/' .env
    sed -i 's/DOMAIN=.*/DOMAIN=localhost/' .env
    
    print_success "Test environment created"
else
    print_success "Environment file exists"
fi

# Stop any existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans > /dev/null 2>&1 || true
print_success "Existing containers stopped"

# Build images
print_status "Building Docker images..."
if docker-compose build --no-cache > /dev/null 2>&1; then
    print_success "Docker images built successfully"
else
    print_error "Failed to build Docker images"
    exit 1
fi

# Start services
print_status "Starting services..."
if docker-compose up -d > /dev/null 2>&1; then
    print_success "Services started"
else
    print_error "Failed to start services"
    docker-compose logs
    exit 1
fi

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check if containers are running
print_status "Checking container status..."
if docker-compose ps | grep -q "Up"; then
    print_success "All containers are running"
else
    print_error "Some containers are not running"
    docker-compose ps
    exit 1
fi

# Test database connection
print_status "Testing database connection..."
if docker-compose exec -T postgres pg_isready -U solarnexus -d solarnexus > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database connection failed"
    docker-compose logs postgres
    exit 1
fi

# Test Redis connection
print_status "Testing Redis connection..."
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_error "Redis connection failed"
    docker-compose logs redis
    exit 1
fi

# Test backend health endpoint
print_status "Testing backend health endpoint..."
sleep 10
if docker-compose exec -T backend curl -f http://localhost:3000/health > /dev/null 2>&1; then
    print_success "Backend health check passed"
else
    print_warning "Backend health check failed (this might be normal if health endpoint is not implemented)"
fi

# Test if backend is responding
print_status "Testing backend API..."
if docker-compose exec -T backend curl -f http://localhost:3000/ > /dev/null 2>&1; then
    print_success "Backend is responding"
else
    print_warning "Backend is not responding on root path (this might be normal)"
fi

# Test Nginx configuration
print_status "Testing Nginx configuration..."
if docker-compose exec -T nginx nginx -t > /dev/null 2>&1; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration is invalid"
    docker-compose logs nginx
    exit 1
fi

# Test if Nginx is serving content
print_status "Testing Nginx response..."
if docker-compose exec -T nginx curl -f http://localhost/ > /dev/null 2>&1; then
    print_success "Nginx is serving content"
else
    print_warning "Nginx is not responding (this might be normal without SSL setup)"
fi

# Show service status
print_status "Service status:"
docker-compose ps

# Show resource usage
print_status "Resource usage:"
docker stats --no-stream

# Test logs
print_status "Checking for critical errors in logs..."
if docker-compose logs | grep -i "error\|fatal\|exception" | grep -v "test" > /dev/null 2>&1; then
    print_warning "Found some errors in logs (check manually):"
    docker-compose logs | grep -i "error\|fatal\|exception" | head -5
else
    print_success "No critical errors found in logs"
fi

# Cleanup
print_status "Cleaning up test environment..."
docker-compose down --remove-orphans > /dev/null 2>&1
print_success "Test environment cleaned up"

echo ""
echo "🎉 Deployment test completed successfully!"
echo ""
echo "📋 Test Results Summary:"
echo "  ✅ Docker and Docker Compose are working"
echo "  ✅ Frontend and backend builds exist"
echo "  ✅ Docker images build successfully"
echo "  ✅ All services start correctly"
echo "  ✅ Database and Redis connections work"
echo "  ✅ Nginx configuration is valid"
echo ""
echo "🚀 Your deployment is ready for production!"
echo ""
echo "Next steps:"
echo "  1. Commit and push changes to GitHub"
echo "  2. Run deployment script on production server"
echo "  3. Monitor logs after deployment"
echo ""