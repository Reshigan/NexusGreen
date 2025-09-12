#!/bin/bash

# SolarNexus Services Stop Script
# Gracefully stops all SolarNexus services

set -e

echo "🛑 Stopping SolarNexus Services"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to stop service gracefully
stop_service() {
    local service_name="$1"
    local timeout="${2:-30}"
    
    if docker ps --format "{{.Names}}" | grep -q "^${service_name}$"; then
        echo -e "${BLUE}🛑 Stopping $service_name...${NC}"
        
        # Try graceful stop first
        if docker stop --time="$timeout" "$service_name" 2>/dev/null; then
            echo -e "${GREEN}✅ $service_name stopped gracefully${NC}"
        else
            echo -e "${YELLOW}⚠️  Force stopping $service_name...${NC}"
            docker kill "$service_name" 2>/dev/null || true
        fi
        
        # Remove container
        docker rm "$service_name" 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠️  $service_name is not running${NC}"
    fi
}

# Stop services in reverse order (frontend first, database last)
echo -e "${BLUE}📋 Stopping services in order...${NC}"

# Stop Nginx reverse proxy
stop_service "solarnexus-nginx" 10

# Stop Frontend
stop_service "solarnexus-frontend" 10

# Stop Backend API (give more time for graceful shutdown)
stop_service "solarnexus-backend" 30

# Stop Redis cache
stop_service "solarnexus-redis" 10

# Stop PostgreSQL database (give time for connections to close)
stop_service "solarnexus-postgres" 30

# Stop monitoring services if running
echo -e "\n${BLUE}📊 Stopping monitoring services...${NC}"
monitoring_services=("solarnexus-prometheus" "solarnexus-grafana" "solarnexus-alertmanager" "solarnexus-node-exporter" "solarnexus-postgres-exporter" "solarnexus-redis-exporter")

for service in "${monitoring_services[@]}"; do
    stop_service "$service" 10
done

# Clean up orphaned containers
echo -e "\n${BLUE}🧹 Cleaning up orphaned containers...${NC}"
orphaned=$(docker ps -a --filter "name=solarnexus-" --format "{{.Names}}" | grep -v "solarnexus-postgres\|solarnexus-redis" || true)
if [[ -n "$orphaned" ]]; then
    echo "$orphaned" | xargs docker rm -f 2>/dev/null || true
    echo -e "${GREEN}✅ Cleaned up orphaned containers${NC}"
fi

# Show remaining containers
echo -e "\n${BLUE}📊 Remaining SolarNexus containers:${NC}"
remaining=$(docker ps -a --filter "name=solarnexus-" --format "table {{.Names}}\t{{.Status}}" || true)
if [[ -n "$remaining" ]]; then
    echo "$remaining"
else
    echo "   No SolarNexus containers running"
fi

# Option to remove volumes (data)
echo -e "\n${YELLOW}💾 Data volumes are preserved${NC}"
echo -e "${BLUE}📋 SolarNexus volumes:${NC}"
docker volume ls | grep solarnexus || echo "   No SolarNexus volumes found"

read -p "Do you want to remove data volumes? (y/N): " remove_volumes
if [[ "$remove_volumes" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Removing data volumes...${NC}"
    docker volume rm solarnexus_postgres_data solarnexus_redis_data 2>/dev/null || true
    echo -e "${GREEN}✅ Data volumes removed${NC}"
else
    echo -e "${GREEN}✅ Data volumes preserved for next startup${NC}"
fi

# Option to remove network
echo -e "\n${BLUE}🌐 Cleaning up network...${NC}"
if docker network ls | grep -q "solarnexus-network"; then
    docker network rm solarnexus-network 2>/dev/null || echo "Network still in use"
fi

# Final status
echo -e "\n${GREEN}✅ SolarNexus services stopped successfully!${NC}"

echo -e "\n${BLUE}🔧 Management Commands:${NC}"
echo "   • Start services: sudo systemctl start solarnexus"
echo "   • Start manually: sudo /opt/solarnexus/app/deploy/start-services.sh"
echo "   • View logs: docker logs <service-name>"
echo "   • Remove all data: docker volume prune"

echo -e "\n${BLUE}📊 System Status:${NC}"
echo "   • Running containers: $(docker ps --format "{{.Names}}" | grep solarnexus | wc -l)"
echo "   • Stopped containers: $(docker ps -a --format "{{.Names}}" | grep solarnexus | wc -l)"
echo "   • Data volumes: $(docker volume ls | grep solarnexus | wc -l)"

echo -e "\n${GREEN}🎉 SolarNexus shutdown complete!${NC}"