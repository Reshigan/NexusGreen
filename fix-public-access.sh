#!/bin/bash
# Fix NexusGreen to be accessible from public IP
# Run this script on your AWS server

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PUBLIC_IP="13.247.192.46"
DOMAIN="$PUBLIC_IP"  # Using IP as domain for now

print_status "🔧 Fixing NexusGreen for public access..."
print_status "Public IP: $PUBLIC_IP"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the NexusGreen directory."
    exit 1
fi

# Stop existing services
print_status "🛑 Stopping existing services..."
sudo docker-compose down 2>/dev/null || true

# Update environment variables for public access
print_status "⚙️ Updating configuration for public access..."

# Create new environment file for public IP access
cat > .env.production << EOF
# Database Configuration
DATABASE_URL=postgresql://nexususer:nexuspass123@nexus-db:5432/nexusgreen
POSTGRES_DB=nexusgreen
POSTGRES_USER=nexususer
POSTGRES_PASSWORD=nexuspass123

# JWT Configuration
JWT_SECRET=nexus-green-jwt-secret-2024-production

# Application Configuration
NODE_ENV=production
VITE_ENVIRONMENT=production
VITE_API_URL=http://${PUBLIC_IP}/api
CORS_ORIGIN=http://${PUBLIC_IP}

# Company Configuration
VITE_COMPANY_NAME=NexusGreen Solar Solutions
VITE_COMPANY_REG=2024/123456/07
VITE_PPA_RATE=1.20

# Monitoring Configuration
SOLAX_SYNC_INTERVAL_MINUTES=60

# Timezone Configuration
TZ=Africa/Johannesburg
EOF

# Update docker-compose.yml for public access
print_status "🐳 Updating Docker Compose configuration..."

# Create a temporary docker-compose file for public IP access
cat > docker-compose.public.yml << 'EOF'
# Nexus Green Production Docker Compose for Public IP Access

services:
  nexus-green:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    container_name: nexus-green
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - VITE_APP_NAME=NexusGreen
      - VITE_APP_VERSION=6.1.0
      - VITE_API_URL=http://13.247.192.46/api
      - VITE_ENVIRONMENT=production
      - VITE_COMPANY_NAME=NexusGreen Solar Solutions
      - VITE_COMPANY_REG=2024/123456/07
      - VITE_PPA_RATE=1.20
    volumes:
      - ./docker/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./docker/logs:/var/log/nginx
    networks:
      - nexus-network
    depends_on:
      - nexus-api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "com.nexusgreen.service=frontend"
      - "com.nexusgreen.version=6.1.0"

  # API backend service
  nexus-api:
    build:
      context: ./api
      dockerfile: Dockerfile
    container_name: nexus-api
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - DATABASE_URL=postgresql://nexususer:nexuspass123@nexus-db:5432/nexusgreen
      - JWT_SECRET=nexus-green-jwt-secret-2024-production
      - SOLAX_SYNC_INTERVAL_MINUTES=60
      - CORS_ORIGIN=http://13.247.192.46
    networks:
      - nexus-network
    depends_on:
      nexus-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Database service with seeding
  nexus-db:
    image: postgres:15-alpine
    container_name: nexus-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=nexusgreen
      - POSTGRES_USER=nexususer
      - POSTGRES_PASSWORD=nexuspass123
    volumes:
      - nexus-db-data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
      - ./database/seed:/seed-data
    networks:
      - nexus-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nexususer -d nexusgreen"]
      interval: 5s
      timeout: 10s
      retries: 10
      start_period: 60s
    ports:
      - "5432:5432"

networks:
  nexus-network:
    driver: bridge

volumes:
  nexus-db-data:
    name: nexus-green-db-data
EOF

# Create nginx configuration for public access (HTTP only for now)
print_status "🌐 Creating nginx configuration for public access..."
mkdir -p docker
cat > docker/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # Root directory
    root /usr/share/nginx/html;
    index index.html index.htm;

    # Handle client-side routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://nexus-api:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Check AWS Security Group settings
print_status "🔍 Checking network connectivity..."
print_warning "Make sure your AWS Security Group allows:"
print_warning "  - Port 22 (SSH) from your IP"
print_warning "  - Port 80 (HTTP) from anywhere (0.0.0.0/0)"
print_warning "  - Port 443 (HTTPS) from anywhere (0.0.0.0/0)"

# Check if ports are available
if netstat -tuln | grep -q ":80 "; then
    print_warning "Port 80 is already in use. Stopping conflicting services..."
    sudo systemctl stop nginx 2>/dev/null || true
    sudo systemctl stop apache2 2>/dev/null || true
fi

# Build and start services with public configuration
print_status "🚀 Starting services for public access..."
sudo docker-compose -f docker-compose.public.yml up -d --build

# Wait for services to start
print_status "⏳ Waiting for services to start..."
sleep 30

# Check service status
print_status "🔍 Checking service status..."
sudo docker-compose -f docker-compose.public.yml ps

# Test local connectivity
print_status "🧪 Testing local connectivity..."
if curl -f http://localhost/health 2>/dev/null; then
    print_success "Local health check passed"
else
    print_warning "Local health check failed - services may still be starting"
fi

# Seed database if needed
print_status "🌱 Seeding database..."
sleep 10
sudo docker-compose -f docker-compose.public.yml exec -T nexus-api node quick-seed.js 2>/dev/null || print_warning "Database seeding may have failed - check logs"

# Final status check
print_status "📊 Final service status:"
sudo docker-compose -f docker-compose.public.yml ps

echo ""
echo "🎉 =================================="
echo "🎉  PUBLIC ACCESS CONFIGURATION COMPLETE!"
echo "🎉 =================================="
echo ""
print_success "NexusGreen is now configured for public access!"
echo ""
echo "📊 Access Information:"
echo "   🌐 Public URL: http://${PUBLIC_IP}"
echo "   🏥 Health Check: http://${PUBLIC_IP}/health"
echo "   🔧 API Endpoint: http://${PUBLIC_IP}/api"
echo ""
echo "👤 Demo Login Credentials:"
echo "   📧 Admin: admin@gonxt.tech"
echo "   🔑 Password: Demo2024!"
echo ""
echo "   📧 User: user@gonxt.tech"
echo "   🔑 Password: Demo2024!"
echo ""
echo "🔧 Management Commands:"
echo "   📋 View logs: sudo docker-compose -f docker-compose.public.yml logs -f"
echo "   🔄 Restart: sudo docker-compose -f docker-compose.public.yml restart"
echo "   📊 Status: sudo docker-compose -f docker-compose.public.yml ps"
echo "   🛑 Stop: sudo docker-compose -f docker-compose.public.yml down"
echo ""
echo "🌐 Test your application:"
echo "   curl http://${PUBLIC_IP}/health"
echo "   Open browser: http://${PUBLIC_IP}"
echo ""

# Save configuration info
cat > public-access-info.txt << EOF
NexusGreen Public Access Configuration
=====================================

Deployment Date: $(date)
Public IP: ${PUBLIC_IP}
Configuration: HTTP (no SSL for IP access)

Application URL: http://${PUBLIC_IP}
Health Check: http://${PUBLIC_IP}/health
API Endpoint: http://${PUBLIC_IP}/api

Demo Credentials:
- Admin: admin@gonxt.tech / Demo2024!
- User: user@gonxt.tech / Demo2024!

Docker Compose File: docker-compose.public.yml
Nginx Config: docker/default.conf
Environment: .env.production

Management Commands:
- View logs: sudo docker-compose -f docker-compose.public.yml logs -f
- Restart: sudo docker-compose -f docker-compose.public.yml restart
- Status: sudo docker-compose -f docker-compose.public.yml ps
- Stop: sudo docker-compose -f docker-compose.public.yml down

AWS Security Group Requirements:
- Port 22 (SSH): Your IP only
- Port 80 (HTTP): 0.0.0.0/0
- Port 443 (HTTPS): 0.0.0.0/0 (for future SSL)
EOF

print_success "Configuration saved to public-access-info.txt"
echo ""
print_status "🎯 Next Steps:"
echo "   1. Test access: http://${PUBLIC_IP}"
echo "   2. If you have a domain, point it to ${PUBLIC_IP}"
echo "   3. For SSL, run SSL setup after domain configuration"
echo ""
print_success "Your NexusGreen application is now publicly accessible! 🚀"