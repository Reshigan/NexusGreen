#!/bin/bash

echo "=== Fixing PostgreSQL Port Conflict ==="
echo

# Stop the deployment first
echo "1. Stopping NexusGreen deployment..."
docker-compose down -v

# Stop system PostgreSQL service
echo "2. Stopping system PostgreSQL service..."
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Clean up any remaining Docker containers
echo "3. Cleaning up Docker containers and volumes..."
docker stop $(docker ps -aq) 2>/dev/null || echo "No containers to stop"
docker rm $(docker ps -aq) 2>/dev/null || echo "No containers to remove"
docker volume prune -f
docker system prune -f

# Check if port 5432 is now free
echo "4. Checking if port 5432 is free..."
if command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep 5432 || echo "Port 5432 is now free"
elif command -v lsof >/dev/null 2>&1; then
    lsof -i :5432 || echo "Port 5432 is now free"
else
    echo "Cannot check port status (netstat/ss/lsof not available)"
fi

# Start fresh deployment
echo "5. Starting fresh NexusGreen deployment..."
docker-compose up -d

echo "6. Monitoring deployment progress..."
echo "Database logs:"
sleep 5
docker-compose logs nexus-db | tail -10

echo
echo "Deployment status:"
docker-compose ps

echo
echo "=== Fix Complete ==="
echo "Monitor with: docker-compose logs -f"
echo "Check status: docker-compose ps"