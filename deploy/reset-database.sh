#!/bin/bash

# SolarNexus Database Reset and Migration Script
# Resets the database and runs migrations to fix schema issues

set -e

echo "🔄 SolarNexus Database Reset and Migration"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER="solarnexus-postgres"
BACKEND_CONTAINER="solarnexus-backend"
DB_NAME="${POSTGRES_DB:-solarnexus}"
DB_USER="${POSTGRES_USER:-solarnexus}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script should be run as root or with sudo${NC}"
   echo "Usage: sudo ./reset-database.sh"
   exit 1
fi

# Function to wait for database
wait_for_database() {
    echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker exec $POSTGRES_CONTAINER pg_isready -U $DB_USER &>/dev/null; then
            echo -e "${GREEN}✅ Database is ready${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo -e "\n${RED}❌ Database failed to become ready${NC}"
    return 1
}

# Backup existing data (if any)
echo -e "${BLUE}💾 Creating backup of existing data...${NC}"
BACKUP_FILE="/tmp/solarnexus_backup_$(date +%Y%m%d_%H%M%S).sql"

if docker exec $POSTGRES_CONTAINER pg_dump -U $DB_USER -d $DB_NAME > "$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  No existing data to backup or backup failed${NC}"
fi

# Stop backend to prevent connections during reset
echo -e "${BLUE}🛑 Stopping backend service...${NC}"
docker stop $BACKEND_CONTAINER 2>/dev/null || echo "Backend not running"

# Wait for database to be ready
wait_for_database

# Drop and recreate database
echo -e "${BLUE}🗄️  Resetting database...${NC}"
docker exec $POSTGRES_CONTAINER psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
docker exec $POSTGRES_CONTAINER psql -U $DB_USER -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || true

echo -e "${GREEN}✅ Database reset completed${NC}"

# Run migrations
echo -e "${BLUE}📄 Running database migrations...${NC}"

# Copy migration file to container
docker cp /opt/solarnexus/app/solarnexus-backend/migration.sql $POSTGRES_CONTAINER:/tmp/migration.sql

# Execute migration
if docker exec $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME -f /tmp/migration.sql; then
    echo -e "${GREEN}✅ Database migration completed successfully${NC}"
else
    echo -e "${RED}❌ Database migration failed${NC}"
    
    # Try to restore backup if migration failed
    if [[ -f "$BACKUP_FILE" ]]; then
        echo -e "${YELLOW}🔄 Attempting to restore from backup...${NC}"
        docker exec -i $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME < "$BACKUP_FILE"
    fi
    
    exit 1
fi

# Clean up migration file from container
docker exec $POSTGRES_CONTAINER rm -f /tmp/migration.sql

# Start backend service
echo -e "${BLUE}🚀 Starting backend service...${NC}"
docker start $BACKEND_CONTAINER

# Wait for backend to be ready
echo -e "${BLUE}⏳ Waiting for backend to be ready...${NC}"
sleep 10

# Test database connection
echo -e "${BLUE}🧪 Testing database connection...${NC}"
if docker exec $BACKEND_CONTAINER node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.organization.count().then(count => {
    console.log('Organizations count:', count);
    process.exit(0);
}).catch(err => {
    console.error('Database test failed:', err.message);
    process.exit(1);
});
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection test passed${NC}"
else
    echo -e "${RED}❌ Database connection test failed${NC}"
    echo -e "${YELLOW}Trying alternative migration method...${NC}"
    
    # Alternative: Run migration through backend container
    if docker exec $BACKEND_CONTAINER node src/migrations/index.js; then
        echo -e "${GREEN}✅ Alternative migration completed${NC}"
    else
        echo -e "${RED}❌ Alternative migration also failed${NC}"
        exit 1
    fi
fi

# Verify schema
echo -e "${BLUE}🔍 Verifying database schema...${NC}"
TABLES=$(docker exec $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

if [[ $TABLES -gt 10 ]]; then
    echo -e "${GREEN}✅ Database schema verified ($TABLES tables created)${NC}"
else
    echo -e "${RED}❌ Database schema incomplete (only $TABLES tables found)${NC}"
    exit 1
fi

# Test sample data
echo -e "${BLUE}📊 Verifying sample data...${NC}"
ORGS=$(docker exec $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM organizations;" | tr -d ' ')
SITES=$(docker exec $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM sites;" | tr -d ' ')

echo -e "  Organizations: $ORGS"
echo -e "  Sites: $SITES"

if [[ $ORGS -gt 0 ]] && [[ $SITES -gt 0 ]]; then
    echo -e "${GREEN}✅ Sample data verified${NC}"
else
    echo -e "${YELLOW}⚠️  Sample data may be incomplete${NC}"
fi

# Clean up backup file (optional)
read -p "Remove backup file $BACKUP_FILE? (y/N): " remove_backup
if [[ "$remove_backup" =~ ^[Yy]$ ]]; then
    rm -f "$BACKUP_FILE"
    echo -e "${GREEN}✅ Backup file removed${NC}"
else
    echo -e "${BLUE}💾 Backup file preserved: $BACKUP_FILE${NC}"
fi

# Final status
echo -e "\n${GREEN}🎉 Database reset and migration completed successfully!${NC}"

echo -e "\n${BLUE}📋 Summary:${NC}"
echo "  • Database: $DB_NAME"
echo "  • Tables created: $TABLES"
echo "  • Organizations: $ORGS"
echo "  • Sites: $SITES"
echo "  • Default admin: admin@nexus.gonxt.tech (password: admin123)"

echo -e "\n${BLUE}🔧 Next steps:${NC}"
echo "  • Test API: curl http://localhost:3000/health"
echo "  • Check logs: docker logs solarnexus-backend"
echo "  • Access frontend: http://localhost:8080"

echo -e "\n${GREEN}✅ SolarNexus database is ready!${NC}"