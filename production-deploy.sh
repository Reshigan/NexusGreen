#!/bin/bash

# NexusGreen Production Deployment Script
# This script deploys NexusGreen to production with SSL support
# Server: Amazon Linux 2023 ARM64
# Domain: nexus.gonxt.tech

set -e

echo "🚀 Starting NexusGreen Production Deployment..."

# Update system
echo "📦 Updating system packages..."
sudo yum update -y

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install nginx
echo "🌐 Installing nginx..."
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Install certbot for SSL
echo "🔒 Installing certbot for SSL..."
sudo yum install -y python3-pip
sudo pip3 install certbot certbot-nginx

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/nexusgreen
sudo chown ec2-user:ec2-user /opt/nexusgreen
cd /opt/nexusgreen

# Clone repository (if not already present)
if [ ! -d ".git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/Reshigan/NexusGreen.git .
fi

# Create production environment file
echo "⚙️ Creating production environment..."
cat > .env.production << 'EOF'
# Production Environment Configuration
NODE_ENV=production
PORT=3001

# Database Configuration
DATABASE_URL=postgresql://nexus_user:nexus_secure_password_2024@nexus-db:5432/nexusgreen_db
POSTGRES_DB=nexusgreen_db
POSTGRES_USER=nexus_user
POSTGRES_PASSWORD=nexus_secure_password_2024

# JWT Configuration
JWT_SECRET=nexus_super_secure_jwt_secret_key_2024_production
JWT_EXPIRES_IN=24h

# API Configuration
API_BASE_URL=https://nexus.gonxt.tech/api

# Frontend Configuration
VITE_API_BASE_URL=https://nexus.gonxt.tech/api
VITE_APP_NAME=NexusGreen
VITE_APP_VERSION=1.0.0

# Security
CORS_ORIGIN=https://nexus.gonxt.tech
ALLOWED_ORIGINS=https://nexus.gonxt.tech,https://www.nexus.gonxt.tech

# Logging
LOG_LEVEL=info
EOF

# Create production docker-compose file
echo "🐳 Creating production Docker Compose configuration..."
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  nexus-db:
    image: postgres:15-alpine
    container_name: nexus-db
    environment:
      POSTGRES_DB: nexusgreen_db
      POSTGRES_USER: nexus_user
      POSTGRES_PASSWORD: nexus_secure_password_2024
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"
    networks:
      - nexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nexus_user -d nexusgreen_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  nexus-api:
    build:
      context: .
      dockerfile: docker/Dockerfile.api
    container_name: nexus-api
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://nexus_user:nexus_secure_password_2024@nexus-db:5432/nexusgreen_db
      JWT_SECRET: nexus_super_secure_jwt_secret_key_2024_production
      JWT_EXPIRES_IN: 24h
      PORT: 3001
    ports:
      - "3001:3001"
    depends_on:
      nexus-db:
        condition: service_healthy
    networks:
      - nexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nexus-green:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: nexus-green
    ports:
      - "8080:80"
    networks:
      - nexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:

networks:
  nexus-network:
    driver: bridge
EOF

# Create nginx configuration
echo "🌐 Setting up nginx reverse proxy..."
sudo tee /etc/nginx/conf.d/nexus.gonxt.tech.conf > /dev/null << 'EOF'
upstream nexus_frontend {
    server 127.0.0.1:8080;
}

upstream nexus_api {
    server 127.0.0.1:3001;
}

server {
    server_name nexus.gonxt.tech localhost _;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }

    location /api/ {
        proxy_pass http://nexus_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location / {
        proxy_pass http://nexus_frontend/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    listen 80 default_server;
}
EOF

# Comment out default nginx server block to avoid conflicts
sudo sed -i '/server {/,/^}/s/^/#/' /etc/nginx/nginx.conf

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
sudo nginx -t

# Reload nginx
echo "🔄 Reloading nginx..."
sudo systemctl reload nginx

# Build and start containers
echo "🏗️ Building and starting Docker containers..."
sudo docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check container status
echo "📊 Checking container status..."
sudo docker-compose -f docker-compose.prod.yml ps

# Setup SSL certificate
echo "🔒 Setting up SSL certificate..."
sudo certbot --nginx -d nexus.gonxt.tech --non-interactive --agree-tos --email admin@nexus.gonxt.tech

# Test SSL renewal
echo "🔄 Testing SSL certificate renewal..."
sudo certbot renew --dry-run

# Final verification
echo "✅ Running final verification..."
curl -f http://localhost:3001/api/health || echo "API health check failed"
curl -f http://localhost:8080/ || echo "Frontend health check failed"

echo "🎉 Production deployment completed successfully!"
echo "🌐 Website: https://nexus.gonxt.tech"
echo "🔧 API: https://nexus.gonxt.tech/api"
echo ""
echo "📋 Next steps:"
echo "1. Verify DNS is pointing to this server"
echo "2. Test the website functionality"
echo "3. Monitor logs: sudo docker-compose -f docker-compose.prod.yml logs -f"
echo "4. SSL certificate will auto-renew via cron"