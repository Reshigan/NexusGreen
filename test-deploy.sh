#!/bin/bash

# Test deployment script - minimal version for testing
set -e

# Configuration
APP_DIR="/tmp/solarnexus-test"
SERVER_IP="13.245.249.110"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; exit 1; }

log "🧪 Testing SolarNexus deployment components..."

# Test 1: Check Docker
log "1. Testing Docker..."
if ! docker ps >/dev/null 2>&1; then
    error "Docker is not running"
fi
log "✅ Docker is working"

# Test 2: Test PostgreSQL container
log "2. Testing PostgreSQL container..."
docker stop test-postgres 2>/dev/null || true
docker rm test-postgres 2>/dev/null || true

docker run -d \
  --name test-postgres \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=testpass \
  -p 5433:5432 \
  postgres:15-alpine

sleep 10

if docker exec test-postgres psql -U testuser -d testdb -c "SELECT 1;" >/dev/null 2>&1; then
    log "✅ PostgreSQL container works"
else
    error "PostgreSQL container failed"
fi

# Test 3: Test Redis container
log "3. Testing Redis container..."
docker stop test-redis 2>/dev/null || true
docker rm test-redis 2>/dev/null || true

docker run -d \
  --name test-redis \
  -p 6380:6379 \
  redis:7-alpine

sleep 5

if docker exec test-redis redis-cli ping | grep -q PONG; then
    log "✅ Redis container works"
else
    error "Redis container failed"
fi

# Test 4: Test backend build
log "4. Testing backend build..."
cd /workspace/project/SolarNexus/solarnexus-backend

# Create test environment
cat > .env.test << EOF
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://testuser:testpass@localhost:5433/testdb
REDIS_URL=redis://localhost:6380
JWT_SECRET=test-secret
EOF

# Try to build the backend
if docker build -t test-backend . >/dev/null 2>&1; then
    log "✅ Backend builds successfully"
else
    error "Backend build failed"
fi

# Test 5: Test frontend build
log "5. Testing frontend build..."
cd /workspace/project/SolarNexus

if [[ -f "package.json" ]]; then
    if npm ci >/dev/null 2>&1; then
        log "✅ Frontend dependencies install"
        if VITE_API_BASE_URL="http://localhost:5000" npm run build >/dev/null 2>&1; then
            log "✅ Frontend builds successfully"
        else
            error "Frontend build failed"
        fi
    else
        error "Frontend dependency installation failed"
    fi
else
    error "Frontend package.json not found"
fi

# Cleanup
log "6. Cleaning up test containers..."
docker stop test-postgres test-redis >/dev/null 2>&1 || true
docker rm test-postgres test-redis >/dev/null 2>&1 || true
docker rmi test-backend >/dev/null 2>&1 || true

log ""
log "🎉 ALL TESTS PASSED!"
log "✅ Docker works"
log "✅ PostgreSQL container works"
log "✅ Redis container works"
log "✅ Backend builds successfully"
log "✅ Frontend builds successfully"
log ""
log "The deployment script should work correctly!"