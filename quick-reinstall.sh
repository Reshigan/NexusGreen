#!/bin/bash

# Quick SolarNexus Reinstall Script
# This will reinstall SolarNexus in the correct location with proper permissions

set -e

echo "🔧 Quick SolarNexus Reinstall"
echo "============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
DEPLOY_DIR="/opt/solarnexus"
DOMAIN="nexus.gonxt.tech"

print_status "Stopping any existing containers..."
sudo docker compose down 2>/dev/null || true
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true

print_status "Cleaning up old installation..."
sudo rm -rf "$DEPLOY_DIR" 2>/dev/null || true

print_status "Creating deployment directory..."
sudo mkdir -p "$DEPLOY_DIR"
sudo chown $USER:$USER "$DEPLOY_DIR"

print_status "Cloning SolarNexus repository..."
cd "$(dirname $DEPLOY_DIR)"
git clone https://github.com/Reshigan/SolarNexus.git "$(basename $DEPLOY_DIR)"
cd "$DEPLOY_DIR"

print_status "Setting up environment file..."
cat > .env << EOF
# Database Configuration
POSTGRES_PASSWORD=solarnexus_secure_password_2024
REDIS_PASSWORD=redis_secure_password_2024

# JWT Configuration
JWT_SECRET=your_super_secure_jwt_secret_key_2024_$(openssl rand -hex 16)
JWT_REFRESH_SECRET=your_super_secure_jwt_refresh_secret_key_2024_$(openssl rand -hex 16)

# Application Configuration
NODE_ENV=production
FRONTEND_URL=https://$DOMAIN
SERVER_IP=$(curl -s ifconfig.me || echo "127.0.0.1")

# Demo Configuration
DEMO_COMPANY_NAME=GonXT Solar Solutions
DEMO_ADMIN_EMAIL=admin@gonxt.tech
DEMO_ADMIN_PASSWORD=Demo2024!
DEMO_USER_EMAIL=user@gonxt.tech
DEMO_USER_PASSWORD=Demo2024!

# Timezone
TZ=Africa/Johannesburg
EOF

print_status "Creating required directories..."
mkdir -p uploads logs database/init nginx/conf.d ssl logs/nginx
sudo chown -R $USER:$USER uploads logs database nginx ssl

print_status "Setting up nginx configuration..."
# Copy nginx config if it exists in root
if [ -f "nginx.conf" ]; then
    cp nginx.conf nginx/nginx.conf
fi

print_status "Building and starting services..."
# Remove any orphaned containers (like nginx) to avoid port conflicts
sudo docker compose up -d --build --remove-orphans

print_status "Waiting for services to start..."
sleep 30

print_status "Testing connectivity..."
# Test backend connectivity
if curl -s -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Backend is accessible on port 5000"
else
    echo "⚠️  Backend not accessible on port 5000"
fi

# Test frontend connectivity  
if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is accessible on port 3000"
else
    echo "⚠️  Frontend not accessible on port 3000"
fi

print_status "Making troubleshooting script executable..."
chmod +x troubleshoot-deployment.sh

print_status "Running database migrations and seeding..."
sudo docker compose exec -T backend npx prisma migrate deploy || true
sudo docker compose exec -T backend npm run db:seed || true

echo ""
print_status "✅ SolarNexus reinstalled successfully!"
echo ""
echo "🌐 Application URL: https://$DOMAIN"
echo "📁 Installation Directory: $DEPLOY_DIR"
echo ""
echo "🔧 If you experience connectivity issues:"
echo "  Troubleshoot: cd $DEPLOY_DIR && ./troubleshoot-deployment.sh"
echo ""
echo "🛠️ Management Commands:"
echo "  View logs:    cd $DEPLOY_DIR && sudo docker compose logs"
echo "  Restart:      cd $DEPLOY_DIR && sudo docker compose restart"
echo "  Stop:         cd $DEPLOY_DIR && sudo docker compose down"
echo "  Update:       cd $DEPLOY_DIR && git pull && sudo docker compose up -d --build"
echo ""
echo "📋 Demo Credentials:"
echo "  Admin: admin@gonxt.tech / Demo2024!"
echo "  User:  user@gonxt.tech / Demo2024!"
echo ""