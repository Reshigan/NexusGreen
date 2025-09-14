#!/bin/bash

# Database Debug Script for NexusGreen
echo "🔍 NexusGreen Database Debug Script"
echo "==================================="

# Start only the database service
echo "🗄️  Starting database service only..."
docker compose up -d nexus-db

# Wait a moment
sleep 5

# Check database logs
echo ""
echo "📋 Database container logs:"
echo "=========================="
docker compose logs nexus-db

# Check if database is responding
echo ""
echo "🏥 Testing database connection..."
echo "================================"

# Wait for database to be ready
for i in {1..30}; do
    if docker compose exec nexus-db pg_isready -U nexususer -d nexusgreen > /dev/null 2>&1; then
        echo "✅ Database is ready!"
        break
    else
        echo "⏳ Waiting for database... ($i/30)"
        sleep 2
    fi
done

# Test connection
if docker compose exec nexus-db psql -U nexususer -d nexusgreen -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Database connection successful!"
    echo ""
    echo "📊 Database info:"
    docker compose exec nexus-db psql -U nexususer -d nexusgreen -c "
        SELECT 
            current_database() as database,
            current_user as user,
            version() as version;
    "
    
    echo ""
    echo "📋 Tables in database:"
    docker compose exec nexus-db psql -U nexususer -d nexusgreen -c "\dt"
else
    echo "❌ Database connection failed!"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Check if PostgreSQL is starting properly"
    echo "2. Verify environment variables"
    echo "3. Check volume permissions"
    echo ""
    echo "📋 Container status:"
    docker compose ps nexus-db
fi

echo ""
echo "🛠️  Next steps:"
echo "If database is working, start all services:"
echo "  docker compose up -d"
echo ""
echo "If database has issues, check the logs above and:"
echo "  docker compose down"
echo "  docker volume rm nexus-green-db-data"
echo "  docker compose up -d"