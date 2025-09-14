#!/bin/bash

# NexusGreen SSL Setup Script for nexus.gonxt.tech
# This script sets up SSL certificates and configures nginx for production

set -e

DOMAIN="nexus.gonxt.tech"
SSL_DIR="./docker/ssl"
NGINX_CONF_DIR="./docker"
EMAIL="admin@gonxt.tech"  # Change this to your email

echo "🔐 Setting up SSL for $DOMAIN..."

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Function to generate self-signed certificates (for testing)
generate_self_signed() {
    echo "📝 Generating self-signed certificates for testing..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/$DOMAIN.key" \
        -out "$SSL_DIR/$DOMAIN.crt" \
        -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=GoNXT/OU=IT Department/CN=$DOMAIN"
    
    echo "✅ Self-signed certificates generated"
}

# Function to setup Let's Encrypt certificates
setup_letsencrypt() {
    echo "🔒 Setting up Let's Encrypt certificates..."
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo "📦 Installing certbot..."
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Stop nginx if running
    echo "⏹️ Stopping nginx temporarily..."
    sudo systemctl stop nginx 2>/dev/null || true
    docker compose down 2>/dev/null || true
    
    # Generate certificates
    echo "🔐 Generating Let's Encrypt certificates..."
    sudo certbot certonly --standalone \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN"
    
    # Copy certificates to docker SSL directory
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
    
    # Set proper permissions
    sudo chown $(whoami):$(whoami) "$SSL_DIR/$DOMAIN.crt" "$SSL_DIR/$DOMAIN.key"
    chmod 644 "$SSL_DIR/$DOMAIN.crt"
    chmod 600 "$SSL_DIR/$DOMAIN.key"
    
    echo "✅ Let's Encrypt certificates installed"
}

# Function to create nginx SSL configuration
create_ssl_config() {
    echo "⚙️ Creating SSL nginx configuration..."
    
    cat > "$NGINX_CONF_DIR/ssl.conf" << 'EOF'
# SSL Configuration for nexus.gonxt.tech
server {
    listen 80;
    server_name nexus.gonxt.tech;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;
    
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
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    
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
update_docker_compose() {
    echo "🐳 Updating docker-compose for SSL..."
    
    # Backup original docker-compose.yml
    cp docker-compose.yml docker-compose.yml.backup
    
    # Update docker-compose.yml to use SSL configuration
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

# Function to create certificate renewal script
create_renewal_script() {
    echo "🔄 Creating certificate renewal script..."
    
    cat > renew-ssl.sh << 'EOF'
#!/bin/bash

# SSL Certificate Renewal Script for nexus.gonxt.tech

DOMAIN="nexus.gonxt.tech"
SSL_DIR="./docker/ssl"

echo "🔄 Renewing SSL certificates for $DOMAIN..."

# Renew certificates
sudo certbot renew --quiet

# Copy renewed certificates
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
    
    # Set proper permissions
    sudo chown $(whoami):$(whoami) "$SSL_DIR/$DOMAIN.crt" "$SSL_DIR/$DOMAIN.key"
    chmod 644 "$SSL_DIR/$DOMAIN.crt"
    chmod 600 "$SSL_DIR/$DOMAIN.key"
    
    # Reload nginx
    docker compose exec nexus-green nginx -s reload
    
    echo "✅ SSL certificates renewed and nginx reloaded"
else
    echo "❌ Certificate renewal failed"
    exit 1
fi
EOF
    
    chmod +x renew-ssl.sh
    echo "✅ Certificate renewal script created"
}

# Function to clean up old references
cleanup_old_references() {
    echo "🧹 Cleaning up old references..."
    
    # Remove old nginx configurations that might conflict
    rm -f ./docker/default.conf.old
    rm -f ./nginx.conf.old
    rm -f ./nginx-*.conf
    
    # Clean up old SSL files
    find ./docker/ssl -name "*.old" -delete 2>/dev/null || true
    find ./docker/ssl -name "*.bak" -delete 2>/dev/null || true
    
    echo "✅ Old references cleaned up"
}

# Main execution
main() {
    echo "🚀 Starting SSL setup for NexusGreen at $DOMAIN"
    
    # Clean up old references first
    cleanup_old_references
    
    # Ask user for certificate type
    echo ""
    echo "Choose SSL certificate type:"
    echo "1) Let's Encrypt (Production - requires domain pointing to this server)"
    echo "2) Self-signed (Testing/Development)"
    echo ""
    read -p "Enter your choice (1 or 2): " cert_choice
    
    case $cert_choice in
        1)
            setup_letsencrypt
            ;;
        2)
            generate_self_signed
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    # Create SSL configuration
    create_ssl_config
    
    # Update docker-compose
    update_docker_compose
    
    # Create renewal script
    create_renewal_script
    
    echo ""
    echo "🎉 SSL setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Build and start the containers: docker compose up --build -d"
    echo "2. Check logs: docker compose logs -f"
    echo "3. Test HTTPS: https://nexus.gonxt.tech"
    echo ""
    echo "For Let's Encrypt certificates:"
    echo "- Set up automatic renewal: sudo crontab -e"
    echo "- Add: 0 12 * * * /path/to/renew-ssl.sh"
    echo ""
    echo "SSL certificates location: $SSL_DIR"
    echo "Nginx SSL config: $NGINX_CONF_DIR/ssl.conf"
}

# Run main function
main "$@"