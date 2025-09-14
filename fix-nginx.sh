#!/bin/bash

# Nexus Green Nginx Configuration Fix
# This script fixes the Nginx configuration error

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "🔧 Fixing Nginx configuration for Nexus Green..."

# Remove broken configuration
log "Removing broken Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-available/solarnexus
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-available/nexus-green

# Create corrected configuration
log "Creating corrected Nginx configuration..."
sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << 'EOF'
server {
    listen 80;
    server_name nexus.gonxt.tech;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Cache Control Headers (FIXED - must-revalidate is part of Cache-Control header)
    add_header Cache-Control "public, no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Root directory
    root /opt/nexus-green/dist;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Main location block
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }
    
    # API proxy (if needed)
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|conf)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the site
log "Enabling Nginx site..."
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Test configuration
log "Testing Nginx configuration..."
if sudo nginx -t; then
    log "✅ Nginx configuration is valid!"
    
    # Reload Nginx
    log "Reloading Nginx..."
    sudo systemctl reload nginx
    
    log "🎉 Nginx configuration fixed successfully!"
    log "Site should now be accessible at: https://nexus.gonxt.tech"
else
    error "❌ Nginx configuration test failed!"
    exit 1
fi
EOF