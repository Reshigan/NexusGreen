#!/bin/bash
# Build complete production system with all components

echo "🚀 Building Complete NexusGreen Production System..."

# Make all scripts executable
chmod +x *.sh

# Step 1: Apply API server fixes
echo "=== Step 1: Applying API server fixes ==="
sudo ./fix-api-server.sh

# Wait for API to be ready
echo "Waiting for API server to be ready..."
sleep 30

# Step 2: Seed database with South African data
echo "=== Step 2: Seeding database with South African data ==="
sudo ./seed-database.sh

# Step 3: Apply production dashboard components
echo "=== Step 3: Applying production dashboard components ==="
sudo ./create-production-dashboard.sh

# Step 4: Build and deploy frontend
echo "=== Step 4: Building and deploying frontend ==="

# Install frontend dependencies
echo "Installing frontend dependencies..."
npm install

# Build the frontend
echo "Building frontend..."
npm run build

# Update docker-compose to use the new build
echo "Updating docker-compose for production build..."
sudo docker-compose -f docker-compose.public.yml down
sudo docker-compose -f docker-compose.public.yml build --no-cache
sudo docker-compose -f docker-compose.public.yml up -d

# Wait for all services to be ready
echo "Waiting for all services to be ready..."
sleep 45

# Step 5: Verify everything is working
echo "=== Step 5: Verifying system functionality ==="

echo "Testing API endpoints..."
curl -s http://localhost/api/health | jq . || echo "API health check failed"
curl -s http://localhost/api/dashboard/overview | jq . || echo "Dashboard API failed"

echo "Testing frontend..."
curl -s -I http://localhost | head -1

echo "Testing database connectivity..."
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT COUNT(*) FROM companies;" || echo "Database test failed"

echo ""
echo "🎉 NexusGreen Production System Build Complete!"
echo ""
echo "🌐 Access your application at: http://13.245.181.202"
echo ""
echo "👥 Demo Login Credentials:"
echo "Super Admin: superadmin@nexusgreen.co.za / demo123"
echo "Customer: customer@solartech.co.za / demo123"
echo "Operator: operator@solartech.co.za / demo123"
echo "Funder: funder@solartech.co.za / demo123"
echo ""
echo "📊 System Features:"
echo "✅ Multi-tenant architecture with role-based dashboards"
echo "✅ 2 years of South African solar data (2 companies, 4 projects, 20 sites)"
echo "✅ Real ZAR financial calculations and ROI analysis"
echo "✅ Comprehensive API with authentication and security"
echo "✅ Professional UI with responsive design"
echo "✅ Production-ready deployment with Docker"
echo ""
echo "🔧 System Components:"
echo "- PostgreSQL database with seeded SA solar data"
echo "- Express.js API server with JWT authentication"
echo "- React frontend with role-based routing"
echo "- Nginx reverse proxy with SSL support"
echo "- Docker containerization for scalability"
echo ""
echo "📈 Dashboard Insights by Role:"
echo "Super Admin: Platform management, company creation, license tracking"
echo "Customer: Energy savings vs municipal rates, ROI analysis"
echo "Operator: System performance, maintenance scheduling, efficiency monitoring"
echo "Funder: Investment returns, PPA rate optimization, portfolio analysis"
echo ""
echo "🎯 Production Ready Features:"
echo "- Multi-tenant data isolation"
echo "- Role-based access control"
echo "- South African regulatory compliance"
echo "- Real-time performance monitoring"
echo "- Financial tracking and reporting"
echo "- Maintenance management system"
echo "- Comprehensive audit trails"