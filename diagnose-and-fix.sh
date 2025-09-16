#!/bin/bash

echo "=== NexusGreen Database Diagnostic and Fix ==="
echo

# Stop all containers
echo "1. Stopping all containers..."
docker-compose down

# Check for port conflicts
echo "2. Checking for port conflicts..."
echo "Port 5432 (PostgreSQL):"
sudo netstat -tlnp | grep 5432 || echo "Port 5432 is free"
echo "Port 80 (HTTP):"
sudo netstat -tlnp | grep :80 || echo "Port 80 is free"
echo "Port 3001 (API):"
sudo netstat -tlnp | grep 3001 || echo "Port 3001 is free"

# Check for existing PostgreSQL processes
echo "3. Checking for existing PostgreSQL processes..."
ps aux | grep postgres | grep -v grep || echo "No PostgreSQL processes found"

# Remove old volumes and containers
echo "4. Cleaning up old data..."
docker-compose down -v
docker system prune -f
docker volume rm nexus-green-db-data 2>/dev/null || echo "Volume already removed"

# Check available memory
echo "5. Checking system resources..."
free -h
df -h

# Restart with fresh data
echo "6. Starting fresh deployment..."
docker-compose up -d nexus-db

echo "7. Waiting for database to start..."
sleep 10

echo "8. Checking database container status..."
docker-compose ps nexus-db
docker-compose logs nexus-db | tail -20

echo "9. If database is healthy, starting other services..."
if docker-compose ps nexus-db | grep -q "healthy"; then
    echo "Database is healthy, starting API and frontend..."
    docker-compose up -d
else
    echo "Database is not healthy. Check logs above."
    echo "Manual check: docker-compose logs nexus-db"
fi