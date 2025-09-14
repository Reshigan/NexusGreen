#!/bin/bash

# NexusGreen SSL Deployment Script
# Deploys with SSL for nexus.gonxt.tech while keeping Docker running

set -e

DOMAIN="nexus.gonxt.tech"
PROJECT_NAME="nexusgreen"

echo "🚀 Deploying NexusGreen with SSL for $DOMAIN"

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to backup current deployment
backup_current() {
    echo "💾 Creating backup of current deployment..."
    
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    if [ -d docker/ssl ]; then
        cp -r docker/ssl docker/ssl.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi
    
    echo "✅ Backup created"
}

# Function to build the application
build_application() {
    echo "🔨 Building NexusGreen application..."
    
    # Build the frontend
    npm run build
    
    echo "✅ Application built successfully"
}

# Function to generate self-signed certificates for immediate deployment
generate_temp_ssl() {
    echo "🔐 Generating temporary SSL certificates..."
    
    mkdir -p docker/ssl
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "docker/ssl/$DOMAIN.key" \
        -out "docker/ssl/$DOMAIN.crt" \
        -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=GoNXT/OU=IT Department/CN=$DOMAIN" \
        2>/dev/null
    
    # Set proper permissions
    chmod 600 "docker/ssl/$DOMAIN.key"
    chmod 644 "docker/ssl/$DOMAIN.crt"
    
    echo "✅ Temporary SSL certificates generated"
}

# Function to create production SSL nginx config
create_ssl_nginx_config() {
    echo "⚙️ Creating SSL nginx configuration..."
    
    cat > docker/ssl.conf << 'EOF'
# SSL Configuration for nexus.gonxt.tech
server {
    listen 80;
    server_name nexus.gonxt.tech localhost;
    
    # Redirect HTTP to HTTPS (except for health checks and Let's Encrypt)
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech localhost;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/nexus.gonxt.tech.crt;
    ssl_certificate_key /etc/nginx/ssl/nexus.gonxt.tech.key;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: blob: 'unsafe-inline' 'unsafe-eval'; font-src 'self' https: data:; img-src 'self' https: data: blob:; connect-src 'self' https: wss:;" always;
    
    # Root and index
    root /usr/share/nginx/html;
    index index.html;
    
    # Cache control for HTML files (no cache)
    location ~* \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        try_files $uri $uri/ /index.html;
    }
    
    # Cache control for static assets (long-term cache)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable" always;
        access_log off;
        try_files $uri =404;
    }
    
    # Main location block for SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Additional security for SPA
        location ~* \.(js|css)$ {
            add_header Cache-Control "public, max-age=31536000, immutable" always;
        }
    }
    
    # API proxy to backend
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
        
        # CORS headers for API
        add_header Access-Control-Allow-Origin "https://nexus.gonxt.tech" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://nexus.gonxt.tech";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept";
            add_header Access-Control-Allow-Credentials "true";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # WebSocket support for real-time features
    location /ws/ {
        proxy_pass http://nexus-api:3001/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Security: Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|conf|sql|md)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Custom error pages
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
        internal;
    }
}
EOF
    
    echo "✅ SSL nginx configuration created"
}

# Function to update docker-compose for SSL
update_docker_compose_ssl() {
    echo "🐳 Updating docker-compose for SSL deployment..."
    
    cat > docker-compose.yml << 'EOF'
# Nexus Green Production Docker Compose with SSL

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
      - VITE_API_URL=https://nexus.gonxt.tech/api
      - VITE_ENVIRONMENT=production
      - VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
      - VITE_COMPANY_REG=2019/123456/07
      - VITE_PPA_RATE=1.20
    volumes:
      - ./docker/ssl:/etc/nginx/ssl:ro
      - ./docker/ssl.conf:/etc/nginx/conf.d/default.conf:ro
      - ./docker/logs:/var/log/nginx
    networks:
      - nexus-network
    depends_on:
      - nexus-api
    healthcheck:
      test: ["CMD", "curl", "-f", "-k", "https://localhost/health"]
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
      - JWT_SECRET=nexus-green-jwt-secret-2024
      - SOLAX_SYNC_INTERVAL_MINUTES=60
      - CORS_ORIGIN=https://nexus.gonxt.tech
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
    
    echo "✅ Docker-compose updated for SSL"
}

# Function to deploy with rolling update
deploy_with_rolling_update() {
    echo "🔄 Performing rolling update deployment..."
    
    # Check if containers are running
    if docker compose ps | grep -q "Up"; then
        echo "📦 Existing containers found, performing rolling update..."
        
        # Build new images
        docker compose build --no-cache
        
        # Update services one by one to minimize downtime
        echo "🔄 Updating database service..."
        docker compose up -d nexus-db
        
        echo "⏳ Waiting for database to be ready..."
        sleep 10
        
        echo "🔄 Updating API service..."
        docker compose up -d nexus-api
        
        echo "⏳ Waiting for API to be ready..."
        sleep 15
        
        echo "🔄 Updating frontend service..."
        docker compose up -d nexus-green
        
    else
        echo "🚀 No existing containers, performing fresh deployment..."
        docker compose up -d
    fi
    
    echo "✅ Rolling update completed"
}

# Function to verify deployment
verify_deployment() {
    echo "🔍 Verifying deployment..."
    
    # Wait for services to be ready
    echo "⏳ Waiting for services to start..."
    sleep 30
    
    # Check container status
    echo "📊 Container status:"
    docker compose ps
    
    # Check health endpoints
    echo ""
    echo "🏥 Health checks:"
    
    # Check HTTP health (should redirect to HTTPS)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/health | grep -q "301\|200"; then
        echo "✅ HTTP health check passed"
    else
        echo "⚠️ HTTP health check failed"
    fi
    
    # Check HTTPS health
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost/health | grep -q "200"; then
        echo "✅ HTTPS health check passed"
    else
        echo "⚠️ HTTPS health check failed"
    fi
    
    # Check API health
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health | grep -q "200"; then
        echo "✅ API health check passed"
    else
        echo "⚠️ API health check failed"
    fi
    
    echo ""
    echo "📋 Service URLs:"
    echo "🌐 Frontend (HTTP): http://nexus.gonxt.tech (redirects to HTTPS)"
    echo "🔒 Frontend (HTTPS): https://nexus.gonxt.tech"
    echo "🔌 API: http://nexus.gonxt.tech/api"
    echo "💾 Database: localhost:5432"
}

# Function to show logs
show_logs() {
    echo ""
    echo "📋 Recent logs:"
    echo "==============="
    docker compose logs --tail=20
}

# Function to clean up old references
cleanup_old_references() {
    echo "🧹 Cleaning up old references..."
    
    # Remove old nginx configurations
    rm -f docker/default.conf.old
    rm -f nginx.conf.old
    rm -f nginx-*.conf
    
    # Clean up old SSL files
    find docker/ssl -name "*.old" -delete 2>/dev/null || true
    find docker/ssl -name "*.bak" -delete 2>/dev/null || true
    
    # Remove old deployment scripts that might conflict
    rm -f deploy-old.sh
    rm -f deploy-*.sh.old
    
    echo "✅ Old references cleaned up"
}

# Main deployment function
main() {
    echo "🚀 Starting SSL deployment for NexusGreen"
    echo "Domain: $DOMAIN"
    echo "Project: $PROJECT_NAME"
    echo ""
    
    # Pre-deployment checks
    check_docker
    
    # Clean up old references
    cleanup_old_references
    
    # Backup current deployment
    backup_current
    
    # Build application
    build_application
    
    # Generate temporary SSL certificates
    generate_temp_ssl
    
    # Create SSL nginx configuration
    create_ssl_nginx_config
    
    # Update docker-compose for SSL
    update_docker_compose_ssl
    
    # Deploy with rolling update
    deploy_with_rolling_update
    
    # Verify deployment
    verify_deployment
    
    # Show logs
    show_logs
    
    echo ""
    echo "🎉 SSL deployment completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Test the application: https://nexus.gonxt.tech"
    echo "2. Replace self-signed certificates with Let's Encrypt:"
    echo "   ./setup-ssl-nexus.sh"
    echo "3. Monitor logs: docker compose logs -f"
    echo "4. Check container status: docker compose ps"
    echo ""
    echo "🔧 Management commands:"
    echo "- Restart services: docker compose restart"
    echo "- View logs: docker compose logs -f [service_name]"
    echo "- Scale services: docker compose up -d --scale nexus-api=2"
    echo "- Update SSL: ./setup-ssl-nexus.sh"
    echo ""
    echo "🔒 SSL Status: Self-signed certificates (for testing)"
    echo "📁 SSL Location: ./docker/ssl/"
    echo "⚙️ Nginx Config: ./docker/ssl.conf"
}

# Run main function
main "$@"