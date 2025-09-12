#!/bin/bash

# Simple SolarNexus Container Fix Script
# Works from any directory and fixes the ContainerConfig error

set -e

echo "🔧 Simple SolarNexus Container Fix"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping all services...${NC}"
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true

echo -e "${BLUE}🗑️  Removing containers...${NC}"
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

echo -e "${BLUE}🧹 Cleaning Docker system...${NC}"
docker system prune -f

echo -e "${BLUE}📦 Pulling fresh images...${NC}"
docker pull postgres:15-alpine
docker pull redis:7-alpine

echo -e "${BLUE}🔄 Creating volumes...${NC}"
docker volume create postgres_data 2>/dev/null || true
docker volume create redis_data 2>/dev/null || true

echo -e "${BLUE}🚀 Starting database and cache...${NC}"
# Start PostgreSQL
docker run -d \
  --name solarnexus-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=solarnexus \
  -e POSTGRES_USER=solarnexus \
  -e POSTGRES_PASSWORD=solarnexus \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network-alias postgres \
  postgres:15-alpine

# Start Redis
docker run -d \
  --name solarnexus-redis \
  --restart unless-stopped \
  -v redis_data:/data \
  -p 6379:6379 \
  --network-alias redis \
  redis:7-alpine redis-server --appendonly yes

echo -e "${BLUE}⏳ Waiting for services...${NC}"
sleep 10

echo -e "${BLUE}🔍 Testing services...${NC}"
# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus; then
    echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
else
    echo -e "${RED}❌ PostgreSQL failed${NC}"
    exit 1
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✅ Redis is ready${NC}"
else
    echo -e "${RED}❌ Redis failed${NC}"
    exit 1
fi

echo -e "${BLUE}🗄️  Setting up database...${NC}"
# Create database
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;" 2>/dev/null || echo "Database exists"

# Create basic schema if migration file not available
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "
-- Basic schema for SolarNexus
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

-- Create enums
DO \$\$ BEGIN
    CREATE TYPE \"UserRole\" AS ENUM ('SUPER_ADMIN', 'CUSTOMER', 'FUNDER', 'OM_PROVIDER');
EXCEPTION
    WHEN duplicate_object THEN null;
END \$\$;

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    domain TEXT UNIQUE,
    settings JSONB DEFAULT '{}',
    \"isActive\" BOOLEAN DEFAULT true,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    \"firstName\" TEXT NOT NULL,
    \"lastName\" TEXT NOT NULL,
    phone TEXT,
    avatar TEXT,
    role \"UserRole\" NOT NULL,
    \"isActive\" BOOLEAN DEFAULT true,
    \"emailVerified\" BOOLEAN DEFAULT false,
    \"lastLoginAt\" TIMESTAMP,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"organizationId\" TEXT NOT NULL
);

-- Sites table
CREATE TABLE IF NOT EXISTS sites (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    municipality TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    timezone TEXT DEFAULT 'UTC',
    capacity DOUBLE PRECISION NOT NULL,
    \"installDate\" TIMESTAMP NOT NULL,
    \"isActive\" BOOLEAN DEFAULT true,
    \"organizationId\" TEXT NOT NULL,
    \"projectId\" TEXT,
    \"municipalRate\" DOUBLE PRECISION,
    \"touTariff\" JSONB,
    \"targetPerformance\" DOUBLE PRECISION,
    \"solaxClientId\" TEXT,
    \"solaxClientSecret\" TEXT,
    \"solaxPlantId\" TEXT,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default data
INSERT INTO organizations (id, name, slug, domain, \"isActive\")
VALUES ('org_default', 'SolarNexus Default', 'solarnexus-default', 'nexus.gonxt.tech', true)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
VALUES (
    'user_admin',
    'admin@nexus.gonxt.tech',
    '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
    'System',
    'Administrator',
    'SUPER_ADMIN',
    true,
    true,
    'org_default'
) ON CONFLICT (email) DO NOTHING;

INSERT INTO sites (id, name, address, municipality, latitude, longitude, capacity, \"installDate\", \"organizationId\")
VALUES (
    'site_demo',
    'Demo Solar Site',
    '123 Solar Street, Green City',
    'Green City',
    -26.2041,
    28.0473,
    50.0,
    '2024-01-15',
    'org_default'
) ON CONFLICT (id) DO NOTHING;
"

echo -e "${GREEN}✅ Basic database schema created${NC}"

echo -e "\n${GREEN}🎉 Simple fix completed!${NC}"
echo -e "\n${BLUE}📋 Services Status:${NC}"
echo "  • PostgreSQL: Running on port 5432"
echo "  • Redis: Running on port 6379"
echo "  • Database: solarnexus (with basic schema)"
echo "  • Admin user: admin@nexus.gonxt.tech (password: admin123)"

echo -e "\n${BLUE}🔧 Next Steps:${NC}"
echo "  1. Start your backend service manually or with Docker Compose"
echo "  2. Test database connection: docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c 'SELECT COUNT(*) FROM users;'"
echo "  3. Check backend logs for any remaining issues"

echo -e "\n${YELLOW}💡 To start backend manually:${NC}"
echo "  docker run -d --name solarnexus-backend \\"
echo "    --link solarnexus-postgres:postgres \\"
echo "    --link solarnexus-redis:redis \\"
echo "    -e DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus \\"
echo "    -e REDIS_URL=redis://redis:6379 \\"
echo "    -p 3000:3000 \\"
echo "    your-backend-image"

echo -e "\n${GREEN}✅ Database and cache are ready for your application!${NC}"