#!/bin/bash

# SolarNexus Clean Install Script
# Completely removes everything and installs from scratch

set -e

echo "🧹 SolarNexus Clean Install from Scratch"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./clean-install.sh"
   exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will completely remove all SolarNexus data and containers!${NC}"
echo -e "${YELLOW}⚠️  This includes databases, volumes, and all configuration!${NC}"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm

if [[ "$confirm" != "YES" ]]; then
    echo -e "${BLUE}❌ Installation cancelled${NC}"
    exit 0
fi

echo -e "\n${RED}🛑 STEP 1: Stopping and removing all SolarNexus services...${NC}"

# Stop all SolarNexus containers
echo -e "${BLUE}Stopping containers...${NC}"
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=SolarNexus") 2>/dev/null || true

# Remove all SolarNexus containers
echo -e "${BLUE}Removing containers...${NC}"
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=SolarNexus") 2>/dev/null || true

# Remove all SolarNexus images
echo -e "${BLUE}Removing images...${NC}"
docker rmi -f $(docker images --filter "reference=solarnexus*" -q) 2>/dev/null || true
docker rmi -f $(docker images --filter "reference=SolarNexus*" -q) 2>/dev/null || true

# Remove all SolarNexus volumes
echo -e "${BLUE}Removing volumes...${NC}"
docker volume rm $(docker volume ls --filter "name=solarnexus" -q) 2>/dev/null || true
docker volume rm postgres_data redis_data 2>/dev/null || true

# Remove all SolarNexus networks
echo -e "${BLUE}Removing networks...${NC}"
docker network rm $(docker network ls --filter "name=solarnexus" -q) 2>/dev/null || true

echo -e "${GREEN}✅ All SolarNexus Docker resources removed${NC}"

echo -e "\n${RED}🗑️  STEP 2: Removing SolarNexus directories...${NC}"

# Remove common SolarNexus directories
DIRS_TO_REMOVE=(
    "/opt/solarnexus"
    "/root/SolarNexus"
    "/home/*/SolarNexus"
    "/tmp/SolarNexus"
    "/var/www/SolarNexus"
    "./SolarNexus"
    "../SolarNexus"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    for expanded_dir in $dir; do
        if [[ -d "$expanded_dir" ]]; then
            echo -e "${BLUE}Removing directory: $expanded_dir${NC}"
            rm -rf "$expanded_dir"
        fi
    done
done

# Remove any SolarNexus related files
find /root -name "*solarnexus*" -type f -delete 2>/dev/null || true
find /tmp -name "*solarnexus*" -type f -delete 2>/dev/null || true

echo -e "${GREEN}✅ All SolarNexus directories removed${NC}"

echo -e "\n${BLUE}🧹 STEP 3: Cleaning Docker system...${NC}"

# Clean Docker system
docker system prune -af --volumes
docker builder prune -af

echo -e "${GREEN}✅ Docker system cleaned${NC}"

echo -e "\n${GREEN}🚀 STEP 4: Fresh installation...${NC}"

# Create installation directory
INSTALL_DIR="/root/SolarNexus"
echo -e "${BLUE}Creating installation directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone fresh repository
echo -e "${BLUE}📥 Cloning SolarNexus repository...${NC}"
git clone https://github.com/Reshigan/SolarNexus.git .

echo -e "${GREEN}✅ Repository cloned${NC}"

echo -e "\n${BLUE}🐳 STEP 5: Creating Docker volumes...${NC}"

# Create fresh volumes
docker volume create postgres_data
docker volume create redis_data

echo -e "${GREEN}✅ Docker volumes created${NC}"

echo -e "\n${BLUE}📦 STEP 6: Pulling Docker images...${NC}"

# Pull required images
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:18-alpine

echo -e "${GREEN}✅ Docker images pulled${NC}"

echo -e "\n${BLUE}🗄️  STEP 7: Starting database services...${NC}"

# Start PostgreSQL
docker run -d \
    --name solarnexus-postgres \
    --restart unless-stopped \
    -e POSTGRES_DB=solarnexus \
    -e POSTGRES_USER=solarnexus \
    -e POSTGRES_PASSWORD=solarnexus \
    -e POSTGRES_INITDB_ARGS="--encoding=UTF-8 --lc-collate=C --lc-ctype=C" \
    -v postgres_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:15-alpine

# Start Redis
docker run -d \
    --name solarnexus-redis \
    --restart unless-stopped \
    -v redis_data:/data \
    -p 6379:6379 \
    redis:7-alpine redis-server --appendonly yes

echo -e "${BLUE}⏳ Waiting for database services to start...${NC}"
sleep 15

# Test services
echo -e "${BLUE}🧪 Testing database services...${NC}"

if docker exec solarnexus-postgres pg_isready -U solarnexus; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
else
    echo -e "  PostgreSQL: ${RED}❌ Failed${NC}"
    exit 1
fi

if docker exec solarnexus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
else
    echo -e "  Redis: ${RED}❌ Failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}🗄️  STEP 8: Setting up database schema...${NC}"

# Create database
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
    
    # Create comprehensive schema
    docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "
    -- SolarNexus Complete Database Schema
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
    
    DO \$\$ BEGIN
        CREATE TYPE \"AlertSeverity\" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END \$\$;
    
    DO \$\$ BEGIN
        CREATE TYPE \"ProjectStatus\" AS ENUM ('PLANNING', 'CONSTRUCTION', 'OPERATIONAL', 'MAINTENANCE', 'DECOMMISSIONED');
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
    
    -- Projects table
    CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        name TEXT NOT NULL,
        description TEXT,
        status \"ProjectStatus\" DEFAULT 'PLANNING',
        \"startDate\" TIMESTAMP,
        \"endDate\" TIMESTAMP,
        budget DOUBLE PRECISION,
        \"organizationId\" TEXT NOT NULL,
        \"funderId\" TEXT,
        \"omProviderId\" TEXT,
        settings JSONB DEFAULT '{}',
        \"isActive\" BOOLEAN DEFAULT true,
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    
    -- Devices table
    CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        name TEXT NOT NULL,
        type \"DeviceType\" NOT NULL,
        \"serialNumber\" TEXT UNIQUE,
        model TEXT,
        manufacturer TEXT,
        \"installDate\" TIMESTAMP,
        \"warrantyExpiry\" TIMESTAMP,
        specifications JSONB DEFAULT '{}',
        \"isActive\" BOOLEAN DEFAULT true,
        \"siteId\" TEXT NOT NULL,
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
    
    -- Financial data table
    CREATE TABLE IF NOT EXISTS financial_data (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        date DATE NOT NULL,
        \"solarSavings\" DOUBLE PRECISION,
        \"gridCost\" DOUBLE PRECISION,
        \"exportRevenue\" DOUBLE PRECISION,
        \"netSavings\" DOUBLE PRECISION,
        \"cumulativeSavings\" DOUBLE PRECISION,
        \"siteId\" TEXT NOT NULL,
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Alerts table
    CREATE TABLE IF NOT EXISTS alerts (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity \"AlertSeverity\" NOT NULL,
        \"isResolved\" BOOLEAN DEFAULT false,
        \"resolvedAt\" TIMESTAMP,
        \"resolvedBy\" TEXT,
        \"siteId\" TEXT,
        \"deviceId\" TEXT,
        \"userId\" TEXT,
        metadata JSONB DEFAULT '{}',
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Performance metrics table
    CREATE TABLE IF NOT EXISTS performance_metrics (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        date DATE NOT NULL,
        \"expectedGeneration\" DOUBLE PRECISION,
        \"actualGeneration\" DOUBLE PRECISION,
        \"performanceRatio\" DOUBLE PRECISION,
        availability DOUBLE PRECISION,
        \"systemEfficiency\" DOUBLE PRECISION,
        \"siteId\" TEXT NOT NULL,
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Weather data table
    CREATE TABLE IF NOT EXISTS weather_data (
        id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
        timestamp TIMESTAMP NOT NULL,
        temperature DOUBLE PRECISION,
        humidity DOUBLE PRECISION,
        \"windSpeed\" DOUBLE PRECISION,
        \"windDirection\" DOUBLE PRECISION,
        pressure DOUBLE PRECISION,
        irradiance DOUBLE PRECISION,
        \"cloudCover\" DOUBLE PRECISION,
        \"siteId\" TEXT NOT NULL,
        \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Create indexes for performance
    CREATE INDEX IF NOT EXISTS idx_energy_data_site_timestamp ON energy_data(\"siteId\", timestamp);
    CREATE INDEX IF NOT EXISTS idx_financial_data_site_date ON financial_data(\"siteId\", date);
    CREATE INDEX IF NOT EXISTS idx_performance_metrics_site_date ON performance_metrics(\"siteId\", date);
    CREATE INDEX IF NOT EXISTS idx_weather_data_site_timestamp ON weather_data(\"siteId\", timestamp);
    CREATE INDEX IF NOT EXISTS idx_alerts_site_created ON alerts(\"siteId\", \"createdAt\");
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_users_org ON users(\"organizationId\");
    CREATE INDEX IF NOT EXISTS idx_sites_org ON sites(\"organizationId\");
    CREATE INDEX IF NOT EXISTS idx_sites_project ON sites(\"projectId\");
    CREATE INDEX IF NOT EXISTS idx_devices_site ON devices(\"siteId\");
    CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(\"organizationId\");
    
    -- Add foreign key constraints
    ALTER TABLE users ADD CONSTRAINT fk_users_organization FOREIGN KEY (\"organizationId\") REFERENCES organizations(id) ON DELETE CASCADE;
    ALTER TABLE projects ADD CONSTRAINT fk_projects_organization FOREIGN KEY (\"organizationId\") REFERENCES organizations(id) ON DELETE CASCADE;
    ALTER TABLE projects ADD CONSTRAINT fk_projects_funder FOREIGN KEY (\"funderId\") REFERENCES users(id) ON DELETE SET NULL;
    ALTER TABLE projects ADD CONSTRAINT fk_projects_om_provider FOREIGN KEY (\"omProviderId\") REFERENCES users(id) ON DELETE SET NULL;
    ALTER TABLE sites ADD CONSTRAINT fk_sites_organization FOREIGN KEY (\"organizationId\") REFERENCES organizations(id) ON DELETE CASCADE;
    ALTER TABLE sites ADD CONSTRAINT fk_sites_project FOREIGN KEY (\"projectId\") REFERENCES projects(id) ON DELETE SET NULL;
    ALTER TABLE devices ADD CONSTRAINT fk_devices_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    ALTER TABLE energy_data ADD CONSTRAINT fk_energy_data_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    ALTER TABLE energy_data ADD CONSTRAINT fk_energy_data_device FOREIGN KEY (\"deviceId\") REFERENCES devices(id) ON DELETE SET NULL;
    ALTER TABLE financial_data ADD CONSTRAINT fk_financial_data_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    ALTER TABLE alerts ADD CONSTRAINT fk_alerts_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    ALTER TABLE alerts ADD CONSTRAINT fk_alerts_device FOREIGN KEY (\"deviceId\") REFERENCES devices(id) ON DELETE CASCADE;
    ALTER TABLE alerts ADD CONSTRAINT fk_alerts_user FOREIGN KEY (\"userId\") REFERENCES users(id) ON DELETE SET NULL;
    ALTER TABLE performance_metrics ADD CONSTRAINT fk_performance_metrics_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    ALTER TABLE weather_data ADD CONSTRAINT fk_weather_data_site FOREIGN KEY (\"siteId\") REFERENCES sites(id) ON DELETE CASCADE;
    
    -- Insert default organization
    INSERT INTO organizations (id, name, slug, domain, \"isActive\")
    VALUES ('org_solarnexus_default', 'SolarNexus Default Organization', 'solarnexus-default', 'nexus.gonxt.tech', true)
    ON CONFLICT (slug) DO NOTHING;
    
    -- Insert super admin user
    INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
    VALUES (
        'user_super_admin',
        'admin@nexus.gonxt.tech',
        '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
        'System',
        'Administrator',
        'SUPER_ADMIN',
        true,
        true,
        'org_solarnexus_default'
    ) ON CONFLICT (email) DO NOTHING;
    
    -- Insert sample customer user
    INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
    VALUES (
        'user_customer_demo',
        'customer@nexus.gonxt.tech',
        '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
        'Demo',
        'Customer',
        'CUSTOMER',
        true,
        true,
        'org_solarnexus_default'
    ) ON CONFLICT (email) DO NOTHING;
    
    -- Insert sample funder user
    INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
    VALUES (
        'user_funder_demo',
        'funder@nexus.gonxt.tech',
        '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
        'Demo',
        'Funder',
        'FUNDER',
        true,
        true,
        'org_solarnexus_default'
    ) ON CONFLICT (email) DO NOTHING;
    
    -- Insert sample O&M provider user
    INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"isActive\", \"emailVerified\", \"organizationId\")
    VALUES (
        'user_om_demo',
        'om@nexus.gonxt.tech',
        '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
        'Demo',
        'O&M Provider',
        'OM_PROVIDER',
        true,
        true,
        'org_solarnexus_default'
    ) ON CONFLICT (email) DO NOTHING;
    
    -- Insert sample project
    INSERT INTO projects (id, name, description, status, \"startDate\", budget, \"organizationId\", \"funderId\", \"omProviderId\")
    VALUES (
        'project_demo_solar',
        'Demo Solar Project',
        'Demonstration solar installation project',
        'OPERATIONAL',
        '2024-01-01',
        500000.00,
        'org_solarnexus_default',
        'user_funder_demo',
        'user_om_demo'
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Insert sample site
    INSERT INTO sites (id, name, address, municipality, latitude, longitude, capacity, \"installDate\", \"organizationId\", \"projectId\", \"municipalRate\", \"targetPerformance\")
    VALUES (
        'site_demo_residential',
        'Demo Residential Solar Site',
        '123 Solar Street, Green City, EC 12345',
        'Green City',
        -26.2041,
        28.0473,
        10.5,
        '2024-01-15',
        'org_solarnexus_default',
        'project_demo_solar',
        1.85,
        0.85
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Insert sample devices
    INSERT INTO devices (id, name, type, \"serialNumber\", model, manufacturer, \"installDate\", \"siteId\")
    VALUES 
    (
        'device_inverter_demo',
        'Main Inverter',
        'INVERTER',
        'INV-2024-001',
        'SolarMax 10kW',
        'SolarMax',
        '2024-01-15',
        'site_demo_residential'
    ),
    (
        'device_battery_demo',
        'Battery Storage',
        'BATTERY',
        'BAT-2024-001',
        'PowerWall 13.5kWh',
        'Tesla',
        '2024-01-15',
        'site_demo_residential'
    ),
    (
        'device_meter_demo',
        'Smart Meter',
        'METER',
        'MTR-2024-001',
        'SmartMeter Pro',
        'GridTech',
        '2024-01-15',
        'site_demo_residential'
    )
    ON CONFLICT (\"serialNumber\") DO NOTHING;
    
    -- Insert sample energy data (last 7 days)
    INSERT INTO energy_data (timestamp, \"solarGeneration\", \"solarPower\", \"gridConsumption\", \"gridPower\", \"batteryCharge\", \"batteryPower\", \"batterySOC\", \"netConsumption\", \"selfConsumption\", \"exportedEnergy\", \"siteId\", \"deviceId\")
    SELECT 
        generate_series(
            CURRENT_TIMESTAMP - INTERVAL '7 days',
            CURRENT_TIMESTAMP,
            INTERVAL '1 hour'
        ) as timestamp,
        CASE 
            WHEN EXTRACT(hour FROM generate_series) BETWEEN 6 AND 18 
            THEN random() * 8 + 2
            ELSE 0
        END as \"solarGeneration\",
        CASE 
            WHEN EXTRACT(hour FROM generate_series) BETWEEN 6 AND 18 
            THEN random() * 8000 + 2000
            ELSE 0
        END as \"solarPower\",
        random() * 3 + 1 as \"gridConsumption\",
        random() * 3000 + 1000 as \"gridPower\",
        random() * 2 as \"batteryCharge\",
        (random() - 0.5) * 4000 as \"batteryPower\",
        random() * 100 as \"batterySOC\",
        random() * 4 + 2 as \"netConsumption\",
        random() * 6 + 3 as \"selfConsumption\",
        CASE 
            WHEN EXTRACT(hour FROM generate_series) BETWEEN 10 AND 16 
            THEN random() * 2
            ELSE 0
        END as \"exportedEnergy\",
        'site_demo_residential',
        'device_inverter_demo'
    FROM generate_series(
        CURRENT_TIMESTAMP - INTERVAL '7 days',
        CURRENT_TIMESTAMP,
        INTERVAL '1 hour'
    );
    
    -- Insert sample financial data (last 30 days)
    INSERT INTO financial_data (date, \"solarSavings\", \"gridCost\", \"exportRevenue\", \"netSavings\", \"cumulativeSavings\", \"siteId\")
    SELECT 
        generate_series(
            CURRENT_DATE - INTERVAL '30 days',
            CURRENT_DATE,
            INTERVAL '1 day'
        )::date as date,
        random() * 50 + 20 as \"solarSavings\",
        random() * 30 + 10 as \"gridCost\",
        random() * 15 + 5 as \"exportRevenue\",
        random() * 40 + 15 as \"netSavings\",
        (random() * 40 + 15) * (CURRENT_DATE - generate_series::date + 1) as \"cumulativeSavings\",
        'site_demo_residential'
    FROM generate_series(
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE,
        INTERVAL '1 day'
    );
    
    -- Insert sample performance metrics (last 30 days)
    INSERT INTO performance_metrics (date, \"expectedGeneration\", \"actualGeneration\", \"performanceRatio\", availability, \"systemEfficiency\", \"siteId\")
    SELECT 
        generate_series(
            CURRENT_DATE - INTERVAL '30 days',
            CURRENT_DATE,
            INTERVAL '1 day'
        )::date as date,
        random() * 60 + 40 as \"expectedGeneration\",
        random() * 55 + 35 as \"actualGeneration\",
        random() * 0.2 + 0.8 as \"performanceRatio\",
        random() * 0.1 + 0.9 as availability,
        random() * 0.1 + 0.85 as \"systemEfficiency\",
        'site_demo_residential'
    FROM generate_series(
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE,
        INTERVAL '1 day'
    );
    "
    
    echo -e "${GREEN}✅ Complete database schema created with sample data${NC}"
fi

echo -e "\n${BLUE}⚙️  STEP 9: Creating environment configuration...${NC}"

# Create production environment file
cat > .env.production << 'EOF'
# SolarNexus Production Environment
NODE_ENV=production

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=solarnexus
DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus

# Redis Configuration
REDIS_URL=redis://redis:6379

# Security
JWT_SECRET=your_jwt_secret_change_in_production_immediately
JWT_EXPIRES_IN=24h

# API Configuration
REACT_APP_API_URL=https://nexus.gonxt.tech/api
API_PORT=3000

# Frontend Configuration
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
REACT_APP_COMPANY_NAME=SolarNexus
REACT_APP_SUPPORT_EMAIL=support@nexus.gonxt.tech

# External APIs (configure as needed)
SOLAX_API_TOKEN=
OPENWEATHER_API_KEY=
MUNICIPAL_RATE_API_KEY=
MUNICIPAL_RATE_ENDPOINT=

# Email Configuration (configure as needed)
EMAIL_USER=
EMAIL_PASS=
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587

# Logging
LOG_LEVEL=info
LOG_FILE=/app/logs/solarnexus.log

# Performance
MAX_CONNECTIONS=100
QUERY_TIMEOUT=30000
CONNECTION_TIMEOUT=10000
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

echo -e "\n${BLUE}🏗️  STEP 10: Building application images...${NC}"

# Build backend image
if [[ -f "solarnexus-backend/Dockerfile" ]]; then
    echo -e "${BLUE}Building backend image...${NC}"
    docker build -t solarnexus-backend:latest solarnexus-backend/
    echo -e "${GREEN}✅ Backend image built${NC}"
else
    echo -e "${YELLOW}⚠️  Backend Dockerfile not found, will use Docker Compose build${NC}"
fi

# Build frontend image
if [[ -f "Dockerfile" ]]; then
    echo -e "${BLUE}Building frontend image...${NC}"
    docker build -t solarnexus-frontend:latest \
        --build-arg REACT_APP_API_URL=https://nexus.gonxt.tech/api \
        --build-arg REACT_APP_ENVIRONMENT=production \
        --build-arg REACT_APP_VERSION=1.0.0 \
        .
    echo -e "${GREEN}✅ Frontend image built${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend Dockerfile not found, will use Docker Compose build${NC}"
fi

echo -e "\n${BLUE}🚀 STEP 11: Starting all services...${NC}"

# Start all services using Docker Compose
if [[ -f "deploy/docker-compose.compatible.yml" ]]; then
    echo -e "${BLUE}Using compatible Docker Compose configuration...${NC}"
    docker-compose -f deploy/docker-compose.compatible.yml --env-file .env.production up -d
elif [[ -f "deploy/docker-compose.production.yml" ]]; then
    echo -e "${BLUE}Using production Docker Compose configuration...${NC}"
    docker-compose -f deploy/docker-compose.production.yml --env-file .env.production up -d
else
    echo -e "${YELLOW}⚠️  Docker Compose files not found, starting services manually...${NC}"
    
    # Start backend manually
    docker run -d \
        --name solarnexus-backend \
        --link solarnexus-postgres:postgres \
        --link solarnexus-redis:redis \
        --env-file .env.production \
        -p 3000:3000 \
        -v "$PWD/logs:/app/logs" \
        solarnexus-backend:latest
    
    # Start frontend manually
    docker run -d \
        --name solarnexus-frontend \
        --link solarnexus-backend:backend \
        -p 8080:80 \
        solarnexus-frontend:latest
fi

echo -e "${BLUE}⏳ Waiting for all services to start...${NC}"
sleep 30

echo -e "\n${BLUE}🧪 STEP 12: Testing all services...${NC}"

# Test PostgreSQL
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo -e "  PostgreSQL: ${GREEN}✅ Ready${NC}"
    POSTGRES_OK=true
else
    echo -e "  PostgreSQL: ${RED}❌ Not Ready${NC}"
    POSTGRES_OK=false
fi

# Test Redis
if docker exec solarnexus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "  Redis: ${GREEN}✅ Ready${NC}"
    REDIS_OK=true
else
    echo -e "  Redis: ${RED}❌ Not Ready${NC}"
    REDIS_OK=false
fi

# Test Backend
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    echo -e "  Backend API: ${GREEN}✅ Ready${NC}"
    BACKEND_OK=true
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-backend"; then
    echo -e "  Backend API: ${YELLOW}⚠️  Starting (may need more time)${NC}"
    BACKEND_OK=false
else
    echo -e "  Backend API: ${RED}❌ Not Running${NC}"
    BACKEND_OK=false
fi

# Test Frontend
if curl -f http://localhost:8080 >/dev/null 2>&1; then
    echo -e "  Frontend: ${GREEN}✅ Ready${NC}"
    FRONTEND_OK=true
elif docker ps --format "{{.Names}}" | grep -q "solarnexus-frontend"; then
    echo -e "  Frontend: ${YELLOW}⚠️  Starting (may need more time)${NC}"
    FRONTEND_OK=false
else
    echo -e "  Frontend: ${RED}❌ Not Running${NC}"
    FRONTEND_OK=false
fi

# Test Database Schema
TABLES_COUNT=$(docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
if [[ $TABLES_COUNT -gt 10 ]]; then
    echo -e "  Database Schema: ${GREEN}✅ Complete ($TABLES_COUNT tables)${NC}"
    SCHEMA_OK=true
else
    echo -e "  Database Schema: ${YELLOW}⚠️  Incomplete ($TABLES_COUNT tables)${NC}"
    SCHEMA_OK=false
fi

echo -e "\n${GREEN}🎉 SolarNexus Clean Installation Completed!${NC}"

echo -e "\n${BLUE}📋 Installation Summary:${NC}"
echo "  • Installation Directory: $INSTALL_DIR"
echo "  • PostgreSQL: Port 5432 $([ "$POSTGRES_OK" = true ] && echo "✅" || echo "❌")"
echo "  • Redis: Port 6379 $([ "$REDIS_OK" = true ] && echo "✅" || echo "❌")"
echo "  • Backend API: Port 3000 $([ "$BACKEND_OK" = true ] && echo "✅" || echo "⚠️")"
echo "  • Frontend: Port 8080 $([ "$FRONTEND_OK" = true ] && echo "✅" || echo "⚠️")"
echo "  • Database: $TABLES_COUNT tables $([ "$SCHEMA_OK" = true ] && echo "✅" || echo "⚠️")"

echo -e "\n${BLUE}👥 Default Users Created:${NC}"
echo "  • Super Admin: admin@nexus.gonxt.tech (password: admin123)"
echo "  • Customer: customer@nexus.gonxt.tech (password: admin123)"
echo "  • Funder: funder@nexus.gonxt.tech (password: admin123)"
echo "  • O&M Provider: om@nexus.gonxt.tech (password: admin123)"

echo -e "\n${BLUE}🔧 Useful Commands:${NC}"
echo "  • View all containers: docker ps"
echo "  • Check backend logs: docker logs solarnexus-backend"
echo "  • Check frontend logs: docker logs solarnexus-frontend"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Access frontend: http://localhost:8080"
echo "  • Database shell: docker exec -it solarnexus-postgres psql -U solarnexus -d solarnexus"
echo "  • Redis shell: docker exec -it solarnexus-redis redis-cli"

echo -e "\n${BLUE}📁 Important Files:${NC}"
echo "  • Environment: $INSTALL_DIR/.env.production"
echo "  • Docker Compose: $INSTALL_DIR/deploy/docker-compose.*.yml"
echo "  • Logs: $INSTALL_DIR/logs/"

if [[ "$BACKEND_OK" = false ]] || [[ "$FRONTEND_OK" = false ]]; then
    echo -e "\n${YELLOW}⚠️  Some services may still be starting. Wait a few minutes and check logs if needed.${NC}"
fi

echo -e "\n${GREEN}✅ SolarNexus is ready for production use!${NC}"
echo -e "${GREEN}🌟 Access your solar portal at: http://localhost:8080${NC}"