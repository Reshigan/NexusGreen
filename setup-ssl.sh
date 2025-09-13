#!/bin/bash

# SolarNexus SSL/HTTPS Setup Script
# Ubuntu 22.04 AWS - Let's Encrypt SSL Certificate
# Version: 1.0.0

set -euo pipefail

# Configuration
readonly DOMAIN="${1:-}"
readonly EMAIL="${2:-admin@${DOMAIN}}"
readonly APP_DIR="/opt/solarnexus"
readonly LOG_DIR="/var/log/solarnexus"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }

# Check parameters
if [[ -z "$DOMAIN" ]]; then
    error "Usage: $0 <domain> [email]
Example: $0 solarnexus.example.com admin@example.com"
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

log "🔒 Setting up SSL for domain: $DOMAIN"

# Install Certbot
log "Installing Certbot..."
apt-get update -qq
apt-get install -y -qq certbot python3-certbot-nginx

# Stop nginx temporarily
systemctl stop solarnexus-frontend

# Obtain SSL certificate
log "Obtaining SSL certificate..."
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    -d "$DOMAIN"

# Update Nginx configuration with SSL
log "Updating Nginx configuration..."
cat > "$APP_DIR/nginx.conf" << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log $LOG_DIR/nginx-error.log;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log $LOG_DIR/nginx-access.log main;
    
    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name $DOMAIN;
        return 301 https://\$server_name\$request_uri;
    }
    
    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name $DOMAIN;
        root $APP_DIR/dist;
        index index.html;
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozTLS:10m;
        ssl_session_tickets off;
        
        # Modern configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        # HSTS
        add_header Strict-Transport-Security "max-age=63072000" always;
        
        # Frontend routes
        location / {
            try_files \$uri \$uri/ /index.html;
            expires 1h;
            add_header Cache-Control "public, immutable";
        }
        
        # API proxy
        location /api/ {
            proxy_pass http://127.0.0.1:5000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Set up automatic certificate renewal
log "Setting up automatic certificate renewal..."
cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root test -x /usr/bin/certbot -a \! -d /run/systemd/system && perl -e 'sleep int(rand(43200))' && certbot -q renew --post-hook "systemctl reload solarnexus-frontend"
EOF

# Update firewall
log "Updating firewall rules..."
ufw allow 443/tcp comment "HTTPS"

# Start nginx
systemctl start solarnexus-frontend

# Test SSL
log "Testing SSL configuration..."
sleep 5
if curl -f -s "https://$DOMAIN/health" >/dev/null 2>&1; then
    log "✅ SSL setup successful!"
    log "🌐 Your site is now available at: https://$DOMAIN"
else
    error "❌ SSL setup failed. Check logs: journalctl -u solarnexus-frontend"
fi