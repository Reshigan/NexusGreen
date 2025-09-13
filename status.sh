#!/bin/bash

# SolarNexus Status Checker
# Check the health of all SolarNexus services

echo "🔍 SolarNexus Status Check"
echo "=========================="
echo ""

# Use docker compose or docker-compose
DOCKER_COMPOSE="docker compose"
if ! docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
fi

# Check if containers are running
echo "📊 Container Status:"
if [ -f "docker-compose.simple.yml" ]; then
    $DOCKER_COMPOSE -f docker-compose.simple.yml ps
else
    echo "❌ docker-compose.simple.yml not found. Are you in the SolarNexus directory?"
    exit 1
fi

echo ""
echo "🧪 Service Health Checks:"

# Check Frontend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    echo "   ✅ Frontend: http://localhost:80 (Ready)"
else
    echo "   ❌ Frontend: http://localhost:80 (Not responding)"
fi

# Check Backend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health | grep -q "200"; then
    echo "   ✅ Backend: http://localhost:3000 (Ready)"
    echo "      API Response: $(curl -s http://localhost:3000/health | jq -r '.status // "No JSON response"' 2>/dev/null || echo "No JSON response")"
else
    echo "   ❌ Backend: http://localhost:3000 (Not responding)"
fi

# Check Database
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo "   ✅ Database: PostgreSQL (Ready)"
else
    echo "   ❌ Database: PostgreSQL (Not ready)"
fi

# Check Redis
if docker exec solarnexus-redis redis-cli -a redis_secure_password_2024 ping >/dev/null 2>&1; then
    echo "   ✅ Cache: Redis (Ready)"
else
    echo "   ❌ Cache: Redis (Not ready)"
fi

echo ""
echo "📈 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" $(docker ps --filter "name=solarnexus" --format "{{.Names}}")

echo ""
echo "📝 Recent Logs (last 10 lines):"
echo "================================"
$DOCKER_COMPOSE -f docker-compose.simple.yml logs --tail=10

echo ""
echo "🔧 Management Commands:"
echo "   • View full logs: docker-compose -f docker-compose.simple.yml logs"
echo "   • Restart services: docker-compose -f docker-compose.simple.yml restart"
echo "   • Stop services: docker-compose -f docker-compose.simple.yml down"
echo "   • Update: git pull && docker-compose -f docker-compose.simple.yml up -d --build"