#!/bin/bash

# SolarNexus Server Status Monitor
# Version: 2.1.0
# Updated: 2025-09-13

INSTALL_DIR="/opt/solarnexus"

echo "🔍 SolarNexus Server Status Monitor"
echo "==================================="

# Check if SolarNexus is installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ SolarNexus not found at $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR/deploy"

echo ""
echo "📊 Docker Services Status:"
docker compose -f docker-compose.production.yml ps

echo ""
echo "🧪 Health Checks:"

# Frontend Health Check
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "  Frontend (Port 80): ✅ Healthy (HTTP $FRONTEND_STATUS)"
else
    echo "  Frontend (Port 80): ❌ Unhealthy (HTTP $FRONTEND_STATUS)"
fi

# Backend Health Check
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo "  Backend (Port 3000): ✅ Healthy (HTTP $BACKEND_STATUS)"
else
    echo "  Backend (Port 3000): ❌ Unhealthy (HTTP $BACKEND_STATUS)"
fi

# Database Health Check
if docker exec solarnexus-postgres pg_isready -U solarnexus >/dev/null 2>&1; then
    echo "  PostgreSQL Database: ✅ Healthy"
else
    echo "  PostgreSQL Database: ❌ Unhealthy"
fi

# Redis Health Check
REDIS_STATUS=$(docker exec solarnexus-redis redis-cli ping 2>/dev/null)
if [ "$REDIS_STATUS" = "PONG" ]; then
    echo "  Redis Cache: ✅ Healthy"
else
    echo "  Redis Cache: ❌ Unhealthy"
fi

echo ""
echo "💾 Resource Usage:"

# Docker stats (brief)
echo "  Container Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --format "{{.Names}}" | grep solarnexus)

echo ""
echo "💿 Disk Usage:"
df -h "$INSTALL_DIR" | tail -1 | awk '{print "  SolarNexus Directory: " $3 " used of " $2 " (" $5 " full)"}'

echo ""
echo "🌐 Network Connectivity:"

# Check if ports are listening
if netstat -tuln | grep -q ":80 "; then
    echo "  Port 80 (HTTP): ✅ Listening"
else
    echo "  Port 80 (HTTP): ❌ Not listening"
fi

if netstat -tuln | grep -q ":3000 "; then
    echo "  Port 3000 (API): ✅ Listening"
else
    echo "  Port 3000 (API): ❌ Not listening"
fi

echo ""
echo "📝 Recent Logs (Last 10 lines):"
echo "  Frontend Logs:"
docker compose -f docker-compose.production.yml logs --tail=5 frontend 2>/dev/null | sed 's/^/    /'

echo "  Backend Logs:"
docker compose -f docker-compose.production.yml logs --tail=5 backend 2>/dev/null | sed 's/^/    /'

echo ""
echo "⏰ Last Updated: $(date)"
echo ""
echo "🔧 Quick Commands:"
echo "  • View all logs: docker compose -f $INSTALL_DIR/deploy/docker-compose.production.yml logs"
echo "  • Restart services: docker compose -f $INSTALL_DIR/deploy/docker-compose.production.yml restart"
echo "  • Update SolarNexus: curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/server-update.sh | sudo bash"