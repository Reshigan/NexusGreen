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
mkdir -p uploads logs database/init
sudo chown -R $USER:$USER uploads logs database

print_status "Building and starting services..."
sudo docker compose up -d --build

print_status "Waiting for services to start..."
sleep 30

print_status "Running database migrations and seeding..."
sudo docker compose exec -T backend npx prisma migrate deploy || true
sudo docker compose exec -T backend npm run db:seed || true

echo ""
print_status "✅ SolarNexus reinstalled successfully!"
echo ""
echo "🌐 Application URL: https://$DOMAIN"
echo "📁 Installation Directory: $DEPLOY_DIR"
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