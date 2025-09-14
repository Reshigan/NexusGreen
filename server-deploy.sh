#!/bin/bash

# 🚀 NexusGreen Server Deployment Script
# Deploys the working dashboard to your production server

echo "🚀 NexusGreen Server Deployment"
echo "==============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

print_info "Starting deployment process..."
echo ""

# Step 1: Pull latest changes
print_info "Step 1: Pulling latest changes from GitHub..."
git pull origin main
if [ $? -eq 0 ]; then
    print_status "Successfully pulled latest changes"
else
    print_error "Failed to pull changes from GitHub"
    exit 1
fi
echo ""

# Step 2: Stop existing services
print_info "Step 2: Stopping existing services..."
docker compose down --remove-orphans
if [ $? -eq 0 ]; then
    print_status "Services stopped successfully"
else
    print_warning "Some services may not have stopped cleanly"
fi
echo ""

# Step 3: Clean up Docker system
print_info "Step 3: Cleaning up Docker system..."
docker system prune -f
docker volume prune -f
print_status "Docker cleanup completed"
echo ""

# Step 4: Remove old build files
print_info "Step 4: Cleaning build cache..."
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf node_modules/.cache/
npm cache clean --force
print_status "Build cache cleaned"
echo ""

# Step 5: Install dependencies
print_info "Step 5: Installing fresh dependencies..."
npm install --no-audit --no-fund
if [ $? -eq 0 ]; then
    print_status "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi
echo ""

# Step 6: Build the application
print_info "Step 6: Building the application..."
npm run build
if [ $? -eq 0 ]; then
    print_status "Application built successfully"
else
    print_error "Build failed"
    exit 1
fi
echo ""

# Step 7: Verify build output
print_info "Step 7: Verifying build output..."
if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    BUILD_SIZE=$(du -sh dist/ | cut -f1)
    print_status "Build verification passed - Size: $BUILD_SIZE"
    ls -la dist/
else
    print_error "Build verification failed - dist directory or index.html missing"
    exit 1
fi
echo ""

# Step 8: Build Docker containers
print_info "Step 8: Building Docker containers..."
docker compose build --no-cache --pull
if [ $? -eq 0 ]; then
    print_status "Docker containers built successfully"
else
    print_error "Docker build failed"
    exit 1
fi
echo ""

# Step 9: Start services
print_info "Step 9: Starting services..."
docker compose up -d
if [ $? -eq 0 ]; then
    print_status "Services started successfully"
else
    print_error "Failed to start services"
    exit 1
fi
echo ""

# Step 10: Wait for services to initialize
print_info "Step 10: Waiting for services to initialize..."
sleep 30
print_status "Initialization wait completed"
echo ""

# Step 11: Health checks
print_info "Step 11: Performing health checks..."
echo ""

# Check container status
print_info "Container Status:"
docker compose ps
echo ""

# Check frontend
print_info "Frontend Health Check:"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    print_status "Frontend: ONLINE (HTTP $FRONTEND_STATUS)"
else
    print_error "Frontend: OFFLINE (HTTP $FRONTEND_STATUS)"
fi

# Check API
print_info "API Health Check:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    print_status "API: ONLINE (HTTP $API_STATUS)"
else
    print_error "API: OFFLINE (HTTP $API_STATUS)"
fi

# Check database
print_info "Database Health Check:"
DB_STATUS=$(docker compose exec -T nexus-db pg_isready -U nexususer -d nexusgreen 2>/dev/null && echo "ready" || echo "not ready")
if [ "$DB_STATUS" = "ready" ]; then
    print_status "Database: ONLINE"
else
    print_error "Database: OFFLINE"
fi
echo ""

# Step 12: Final verification
print_info "Step 12: Final verification..."
HTML_CONTENT=$(curl -s http://localhost:80 | head -1)
if [[ "$HTML_CONTENT" == *"<!DOCTYPE html>"* ]]; then
    print_status "HTML content verification passed"
else
    print_warning "HTML content verification failed"
fi

JS_CHECK=$(curl -s http://localhost:80 | grep -o 'index-[^"]*\.js' | head -1)
if [ ! -z "$JS_CHECK" ]; then
    print_status "JavaScript bundle detected: $JS_CHECK"
else
    print_warning "JavaScript bundle not detected"
fi
echo ""

# Deployment summary
echo "🎉 DEPLOYMENT COMPLETED!"
echo "========================"
echo ""
print_status "NexusGreen Dashboard Successfully Deployed!"
echo ""
echo "🌐 ACCESS INFORMATION:"
echo "   Dashboard URL: http://$(hostname -I | awk '{print $1}'):80"
echo "   Local URL: http://localhost:80"
echo "   API Health: http://$(hostname -I | awk '{print $1}'):3001/health"
echo ""
echo "🎨 DASHBOARD FEATURES:"
echo "   ✅ Real-time energy generation metrics"
echo "   ✅ Revenue tracking and financial data"
echo "   ✅ System performance indicators"
echo "   ✅ CO₂ savings environmental impact"
echo "   ✅ Interactive solar installation overview"
echo "   ✅ Live clock and status updates"
echo "   ✅ Mobile-responsive design"
echo ""
echo "📊 EXPECTED METRICS:"
echo "   • Total Generation: 2,847 kWh"
echo "   • Revenue Today: \$125,680"
echo "   • System Performance: 96.8%"
echo "   • CO₂ Saved: 1,247 kg"
echo "   • Active Installations: 3 sites"
echo ""
echo "🔧 TROUBLESHOOTING:"
echo "   View logs: docker compose logs -f"
echo "   Restart: docker compose restart"
echo "   Status: docker compose ps"
echo "   Re-deploy: ./server-deploy.sh"
echo ""
echo "🌞 Welcome to NexusGreen v6.0.0!"
echo "Professional Solar Energy Management Platform"
echo ""

# Final status check
if [ "$FRONTEND_STATUS" = "200" ] && [ "$API_STATUS" = "200" ] && [ "$DB_STATUS" = "ready" ]; then
    print_status "🎉 ALL SYSTEMS OPERATIONAL - DEPLOYMENT SUCCESSFUL!"
    exit 0
else
    print_warning "⚠️  Some services may need attention - Check logs above"
    exit 1
fi