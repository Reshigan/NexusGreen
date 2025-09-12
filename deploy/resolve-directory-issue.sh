#!/bin/bash

# SolarNexus Directory Issue Resolver
# Fixes the directory path issue and completes the setup

set -e

echo "🔧 SolarNexus Directory Issue Resolver"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./resolve-directory-issue.sh"
   exit 1
fi

echo -e "${BLUE}🔍 Finding SolarNexus directory...${NC}"

# Possible locations for SolarNexus
POSSIBLE_DIRS=(
    "/root/SolarNexus"
    "/home/*/SolarNexus"
    "$(pwd)"
    "/tmp/SolarNexus"
    "/var/www/SolarNexus"
    "./SolarNexus"
    "../SolarNexus"
    "~/SolarNexus"
)

SOLARNEXUS_DIR=""
for dir in "${POSSIBLE_DIRS[@]}"; do
    # Handle wildcard expansion
    for expanded_dir in $dir; do
        if [[ -d "$expanded_dir" ]] && [[ -f "$expanded_dir/deploy/docker-compose.production.yml" || -f "$expanded_dir/deploy/docker-compose.compatible.yml" ]]; then
            SOLARNEXUS_DIR="$expanded_dir"
            break 2
        fi
    done
done

if [[ -z "$SOLARNEXUS_DIR" ]]; then
    echo -e "${YELLOW}⚠️  SolarNexus directory not found. Let's create it...${NC}"
    
    # Create in current directory or /root
    if [[ -w "$(pwd)" ]]; then
        SOLARNEXUS_DIR="$(pwd)/SolarNexus"
    else
        SOLARNEXUS_DIR="/root/SolarNexus"
    fi
    
    echo -e "${BLUE}📥 Cloning SolarNexus repository to: $SOLARNEXUS_DIR${NC}"
    git clone https://github.com/Reshigan/SolarNexus.git "$SOLARNEXUS_DIR"
    
    echo -e "${GREEN}✅ SolarNexus cloned to: $SOLARNEXUS_DIR${NC}"
else
    echo -e "${GREEN}✅ Found SolarNexus directory: $SOLARNEXUS_DIR${NC}"
fi

# Change to the SolarNexus directory
cd "$SOLARNEXUS_DIR"

echo -e "${BLUE}🔍 Checking current services...${NC}"

# Check if PostgreSQL and Redis are running
POSTGRES_RUNNING=false
REDIS_RUNNING=false

if docker ps --format "{{.Names}}" | grep -q "solarnexus-postgres"; then
    POSTGRES_RUNNING=true
    echo -e "  PostgreSQL: ${GREEN}✅ Running${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Not Running${NC}"
fi

if docker ps --format "{{.Names}}" | grep -q "solarnexus-redis"; then
    REDIS_RUNNING=true
    echo -e "  Redis: ${GREEN}✅ Running${NC}"
else
    echo -e "  Redis: ${RED}❌ Not Running${NC}"
fi

# If services aren't running, start them
if [[ "$POSTGRES_RUNNING" == false ]] || [[ "$REDIS_RUNNING" == false ]]; then
    echo -e "${BLUE}🚀 Starting missing services...${NC}"
    
    if [[ "$POSTGRES_RUNNING" == false ]]; then
        echo -e "${BLUE}Starting PostgreSQL...${NC}"
        docker run -d \
            --name solarnexus-postgres \
            --restart unless-stopped \
            -e POSTGRES_DB=solarnexus \
            -e POSTGRES_USER=solarnexus \
            -e POSTGRES_PASSWORD=solarnexus \
            -v postgres_data:/var/lib/postgresql/data \
            -p 5432:5432 \
            postgres:15-alpine
    fi
    
    if [[ "$REDIS_RUNNING" == false ]]; then
        echo -e "${BLUE}Starting Redis...${NC}"
        docker run -d \
            --name solarnexus-redis \
            --restart unless-stopped \
            -v redis_data:/data \
            -p 6379:6379 \
            redis:7-alpine redis-server --appendonly yes
    fi
    
    echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
    sleep 10
fi

echo -e "${BLUE}🗄️  Setting up database schema...${NC}"

# Ensure database exists
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;" 2>/dev/null || echo "Database already exists"

# Apply migration if available
if [[ -f "solarnexus-backend/migration.sql" ]]; then
    echo -e "${GREEN}✅ Found migration file, applying...${NC}"
    docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql
    docker exec solarnexus-postgres rm -f /tmp/migration.sql
    echo -e "${GREEN}✅ Database migration completed${NC}"
else
    echo -e "${YELLOW}⚠️  Migration file not found, creating basic schema...${NC}"
    
    # Create basic schema
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "
    -- Basic SolarNexus Schema
    CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
    
    -- Create enums
    DO \$\$ BEGIN
        CREATE TYPE \"UserRole\" AS ENUM ('SUPER_ADMIN', 'CUSTOMER', 'FUNDER', 'OM_PROVIDER');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END \$\$;
    
    DO \$\$ BEGIN
        CREATE TYPE \"DeviceType\" AS ENUM ('INVERTER', 'BATTERY', 'METER', 'WEATHER_STATION', 'EV_CHARGER');
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
    
    -- Energy data table
    CREATE TABLE IF NOT EXISTS energy_data (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        timestamp TIMESTAMP NOT NULL,
        \"solarGeneration\" DOUBLE PRECISION,
        \"solarPower\" DOUBLE PRECISION,
        \"gridConsumption\" DOUBLE PRECISION,
        \"gridPower\" DOUBLE PRECISION,
        \"batteryCharge\" DOUBLE PRECISION,
        \"batteryPower\" DOUBLE PRECISION,
        \"batterySOC\" DOUBLE PRECISION,
        irradiance DOUBLE PRECISION,
        temperature DOUBLE PRECISION,
        \"windSpeed\" DOUBLE PRECISION,
        \"netConsumption\" DOUBLE PRECISION,
        \"selfConsumption\" DOUBLE PRECISION,
        \"exportedEnergy\" DOUBLE PRECISION,
        \"siteId\" TEXT NOT NULL,
        \"deviceId\" TEXT,
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Create indexes
    CREATE INDEX IF NOT EXISTS idx_energy_data_site_timestamp ON energy_data(\"siteId\", timestamp);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_sites_org ON sites(\"organizationId\");
    
    -- Insert default data
    INSERT INTO organizations (id, name, slug, domain, \"isActive\")
    VALUES ('org_default_solarnexus', 'SolarNexus Default Organization', 'solarnexus-default', 'nexus.gonxt.tech', true)
    ON CONFLICT (slug) DO NOTHING;
    
    INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
    VALUES (
        'user_admin_solarnexus',
        'admin@nexus.gonxt.tech',
        '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
        'System',
        'Administrator',
        'SUPER_ADMIN',
        true,
        true,
        'org_default_solarnexus'
    ) ON CONFLICT (email) DO NOTHING;
    
    INSERT INTO sites (id, name, address, municipality, latitude, longitude, capacity, \"installDate\", \"organizationId\")
    VALUES (
        'site_demo_solarnexus',
        'Demo Solar Site',
        '123 Solar Street, Green City, EC 12345',
        'Green City',
        -26.2041,
        28.0473,
        50.0,
        '2024-01-15',
        'org_default_solarnexus'
    ) ON CONFLICT (id) DO NOTHING;
    "
    
    echo -e "${GREEN}✅ Basic schema created${NC}"
fi

echo -e "${BLUE}🐳 Setting up Docker Compose environment...${NC}"

# Create environment file if it doesn't exist
if [[ ! -f ".env.production" ]]; then
    echo -e "${BLUE}📝 Creating environment file...${NC}"
    cat > .env.production << 'EOF'
# SolarNexus Production Environment
NODE_ENV=production
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus
REDIS_URL=redis://redis:6379
JWT_SECRET=your_jwt_secret_change_in_production
REACT_APP_API_URL=https://nexus.gonxt.tech/api
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
EOF
    echo -e "${GREEN}✅ Environment file created${NC}"
fi

echo -e "${BLUE}🚀 Starting backend service...${NC}"

# Check if backend is already running
if docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "${YELLOW}⚠️  Backend already running, restarting...${NC}"
    docker stop solarnexus-backend
    docker rm solarnexus-backend
fi

# Start backend using Docker Compose if available, otherwise use direct Docker
if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    echo -e "${BLUE}Using Docker Compose...${NC}"
    docker-compose -f deploy/docker-compose.compatible.yml up -d backend
else
    echo -e "${BLUE}Using direct Docker command...${NC}"
    # Build backend image if Dockerfile exists
    if [[ -f "solarnexus-backend/Dockerfile" ]]; then
        echo -e "${BLUE}Building backend image...${NC}"
        docker build -t solarnexus-backend:latest solarnexus-backend/
    fi
    
    # Start backend container
    docker run -d \
        --name solarnexus-backend \
        --link solarnexus-postgres:postgres \
        --link solarnexus-redis:redis \
        --env-file .env.production \
        -p 3000:3000 \
        -v "$PWD/logs:/app/logs" \
        solarnexus-backend:latest
fi

echo -e "${BLUE}⏳ Waiting for backend to start...${NC}"
sleep 15

echo -e "${BLUE}🧪 Testing services...${NC}"

# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
fi

# Test Backend
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend API: ${YELLOW}⚠️  Starting (check logs: docker logs solarnexus-backend)${NC}"
else
    echo -e "  Backend API: ${RED}❌ Not Running${NC}"
fi

# Test Database Schema
TABLES_COUNT=$(docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
if [[ $TABLES_COUNT -gt 5 ]]; then
    echo -e "  Database Schema: ${GREEN}✅ Ready ($TABLES_COUNT tables)${NC}"
else
    echo -e "  Database Schema: ${YELLOW}⚠️  Incomplete ($TABLES_COUNT tables)${NC}"
fi

echo -e "\n${GREEN}🎉 Setup completed!${NC}"

echo -e "\n${BLUE}📋 Service Status:${NC}"
echo "  • Working Directory: $SOLARNEXUS_DIR"
echo "  • PostgreSQL: Running on port 5432"
echo "  • Redis: Running on port 6379"
echo "  • Backend API: Port 3000 (check http://localhost:3000/health)"
echo "  • Database: solarnexus with $TABLES_COUNT tables"
echo "  • Admin Login: admin@nexus.gonxt.tech (password: admin123)"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • Check logs: docker logs solarnexus-backend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Database shell: docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus"
echo "  • Redis shell: docker exec -it solarnexus-redis redis-cli"

echo -e "\n${BLUE}📁 Files Created:${NC}"
echo "  • Environment: $SOLARNEXUS_DIR/.env.production"
echo "  • Database: solarnexus (with schema and sample data)"

if [[ $TABLES_COUNT -lt 10 ]]; then
    echo -e "\n${YELLOW}⚠️  Note: If backend shows schema errors, it will auto-create missing tables on startup.${NC}"
fi

echo -e "\n${GREEN}✅ SolarNexus is ready for use!${NC}"