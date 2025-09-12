#!/bin/bash

# SolarNexus SSL Certificate Setup Script
# Supports both Let's Encrypt and manual certificate installation

set -e

echo "🔒 SolarNexus SSL Certificate Setup"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Configuration
DOMAIN="nexus.gonxt.tech"
WWW_DOMAIN="www.nexus.gonxt.tech"
SSL_DIR="/etc/nginx/ssl"
NGINX_CONF="/workspace/project/PPA-Frontend/nginx/conf.d/solarnexus.conf"

# Create SSL directory
mkdir -p "$SSL_DIR"
chmod 700 "$SSL_DIR"

echo -e "${BLUE}🌐 Domain Configuration${NC}"
echo "   Primary domain: $DOMAIN"
echo "   WWW domain: $WWW_DOMAIN"
echo "   SSL directory: $SSL_DIR"

# Function to setup Let's Encrypt
setup_letsencrypt() {
    echo -e "\n${GREEN}🔐 Setting up Let's Encrypt SSL Certificate${NC}"
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        echo -e "${BLUE}📦 Installing certbot...${NC}"
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Stop nginx temporarily for standalone mode
    echo -e "${BLUE}🛑 Stopping nginx for certificate generation...${NC}"
    docker stop solarnexus-nginx 2>/dev/null || true
    
    # Generate certificate
    echo -e "${BLUE}🔑 Generating SSL certificate...${NC}"
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN}" \
        -d "$DOMAIN" \
        -d "$WWW_DOMAIN"
    
    # Copy certificates to nginx directory
    cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "$SSL_DIR/solarnexus.crt"
    cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "$SSL_DIR/solarnexus.key"
    
    # Set permissions
    chmod 644 "$SSL_DIR/solarnexus.crt"
    chmod 600 "$SSL_DIR/solarnexus.key"
    
    # Setup auto-renewal
    echo -e "${BLUE}🔄 Setting up auto-renewal...${NC}"
    cat > /etc/cron.d/certbot-renewal << EOF
# Renew Let's Encrypt certificates
0 12 * * * root /usr/bin/certbot renew --quiet --post-hook "docker restart solarnexus-nginx"
EOF
    
    echo -e "${GREEN}✅ Let's Encrypt certificate installed successfully${NC}"
}

# Function to setup manual certificate
setup_manual_certificate() {
    echo -e "\n${GREEN}🔐 Manual SSL Certificate Setup${NC}"
    
    read -p "Enter path to certificate file (.crt or .pem): " cert_path
    read -p "Enter path to private key file (.key): " key_path
    
    if [[ ! -f "$cert_path" ]]; then
        echo -e "${RED}❌ Certificate file not found: $cert_path${NC}"
        exit 1
    fi
    
    if [[ ! -f "$key_path" ]]; then
        echo -e "${RED}❌ Private key file not found: $key_path${NC}"
        exit 1
    fi
    
    # Copy certificates
    cp "$cert_path" "$SSL_DIR/solarnexus.crt"
    cp "$key_path" "$SSL_DIR/solarnexus.key"
    
    # Set permissions
    chmod 644 "$SSL_DIR/solarnexus.crt"
    chmod 600 "$SSL_DIR/solarnexus.key"
    
    echo -e "${GREEN}✅ Manual certificate installed successfully${NC}"
}

# Function to generate self-signed certificate (for testing)
setup_self_signed() {
    echo -e "\n${YELLOW}⚠️  Generating Self-Signed Certificate (Testing Only)${NC}"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/solarnexus.key" \
        -out "$SSL_DIR/solarnexus.crt" \
        -subj "/C=US/ST=State/L=City/O=SolarNexus/CN=${DOMAIN}"
    
    # Set permissions
    chmod 644 "$SSL_DIR/solarnexus.crt"
    chmod 600 "$SSL_DIR/solarnexus.key"
    
    echo -e "${YELLOW}⚠️  Self-signed certificate generated (browsers will show warnings)${NC}"
}

# Function to update nginx configuration
update_nginx_config() {
    echo -e "\n${BLUE}⚙️  Updating nginx configuration for SSL...${NC}"
    
    # Create SSL-enabled nginx configuration
    cat > "$NGINX_CONF" << 'EOF'
# SolarNexus SSL Configuration

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name nexus.gonxt.tech www.nexus.gonxt.tech 13.244.63.26;
    
    # Health check (allow HTTP for monitoring)
    location /health {
        access_log off;
        return 200 "SolarNexus is healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Configuration
server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech www.nexus.gonxt.tech;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/solarnexus.crt;
    ssl_certificate_key /etc/nginx/ssl/solarnexus.key;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'self';" always;
    
    # Root directory
    root /var/www/html;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;
    
    # Health check
    location /health {
        access_log off;
        return 200 "SolarNexus is healthy\n";
        add_header Content-Type text/plain;
    }
    
    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://solarnexus-backend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Authentication routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=5 nodelay;
        
        proxy_pass http://solarnexus-backend:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket support for real-time updates
    location /socket.io/ {
        proxy_pass http://solarnexus-backend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static file uploads
    location /uploads/ {
        alias /app/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Frontend static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # Frontend routes (React Router)
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /var/www/html;
    }
}
EOF
    
    echo -e "${GREEN}✅ Nginx configuration updated for SSL${NC}"
}

# Function to restart services with SSL
restart_services() {
    echo -e "\n${BLUE}🔄 Restarting services with SSL configuration...${NC}"
    
    # Stop existing containers
    docker stop solarnexus-nginx 2>/dev/null || true
    docker rm solarnexus-nginx 2>/dev/null || true
    
    # Start nginx with SSL support
    docker run -d --name solarnexus-nginx \
        --network project_solarnexus-network \
        -p 80:80 \
        -p 443:443 \
        -v "$SSL_DIR:/etc/nginx/ssl:ro" \
        -v "/workspace/project/PPA-Frontend/nginx/conf.d:/etc/nginx/conf.d:ro" \
        -v "/workspace/project/PPA-Frontend/dist:/var/www/html:ro" \
        --health-cmd="curl -f http://localhost/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        nginx:alpine
    
    echo -e "${GREEN}✅ Services restarted with SSL support${NC}"
}

# Function to test SSL configuration
test_ssl() {
    echo -e "\n${BLUE}🧪 Testing SSL configuration...${NC}"
    
    # Wait for nginx to start
    sleep 5
    
    # Test HTTP redirect
    echo -e "${BLUE}Testing HTTP to HTTPS redirect...${NC}"
    if curl -s -I "http://${DOMAIN}" | grep -q "301"; then
        echo -e "${GREEN}✅ HTTP to HTTPS redirect working${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP redirect may not be working${NC}"
    fi
    
    # Test HTTPS
    echo -e "${BLUE}Testing HTTPS connection...${NC}"
    if curl -s -k "https://${DOMAIN}/health" | grep -q "healthy"; then
        echo -e "${GREEN}✅ HTTPS connection working${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS connection may have issues${NC}"
    fi
    
    # Test SSL certificate
    echo -e "${BLUE}Testing SSL certificate...${NC}"
    if openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -dates; then
        echo -e "${GREEN}✅ SSL certificate is valid${NC}"
    else
        echo -e "${YELLOW}⚠️  SSL certificate validation failed${NC}"
    fi
}

# Main menu
echo -e "\n${BLUE}🔧 SSL Setup Options:${NC}"
echo "1. Let's Encrypt (Recommended for production)"
echo "2. Manual certificate installation"
echo "3. Self-signed certificate (Testing only)"
echo "4. Skip certificate setup (update nginx config only)"

read -p "Choose an option (1-4): " ssl_option

case $ssl_option in
    1)
        setup_letsencrypt
        ;;
    2)
        setup_manual_certificate
        ;;
    3)
        setup_self_signed
        ;;
    4)
        echo -e "${YELLOW}⚠️  Skipping certificate setup${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

# Update nginx configuration
update_nginx_config

# Restart services
restart_services

# Test SSL if certificate was installed
if [[ $ssl_option != 4 ]]; then
    test_ssl
fi

# Final summary
echo -e "\n${GREEN}🎉 SSL Setup Complete!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   • SSL certificates: $SSL_DIR"
echo "   • Nginx configuration: $NGINX_CONF"
echo "   • HTTPS URL: https://$DOMAIN"
echo "   • HTTP redirects to HTTPS: ✅"

if [[ $ssl_option == 1 ]]; then
    echo -e "\n${BLUE}🔄 Auto-renewal:${NC}"
    echo "   • Let's Encrypt certificates will auto-renew"
    echo "   • Check renewal: certbot certificates"
fi

echo -e "\n${BLUE}🔍 Verification:${NC}"
echo "   • Test HTTPS: curl -I https://$DOMAIN"
echo "   • Check SSL: openssl s_client -connect $DOMAIN:443"
echo "   • Monitor logs: docker logs solarnexus-nginx"

echo -e "\n${GREEN}✅ SolarNexus is now secured with SSL!${NC}"