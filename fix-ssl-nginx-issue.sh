#!/bin/bash

# Fix SSL certificate and nginx configuration issue
# This script handles the chicken-and-egg problem with Let's Encrypt and nginx

echo "🔒 Fixing SSL certificate and nginx configuration issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Configuration
DOMAIN=${1:-nexus.gonxt.tech}
SSL_EMAIL=${2:-reshigan@gonxt.tech}

print_step "Step 1: Creating temporary nginx configuration without SSL..."

# Create temporary nginx config without SSL
$SUDO tee /etc/nginx/sites-available/solarnexus-temp << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Temporary redirect to show we're setting up
    location / {
        return 200 'SolarNexus is being configured. Please wait...';
        add_header Content-Type text/plain;
    }
}
EOF

print_step "Step 2: Enabling temporary configuration..."
$SUDO rm -f /etc/nginx/sites-enabled/default
$SUDO rm -f /etc/nginx/sites-enabled/solarnexus
$SUDO ln -sf /etc/nginx/sites-available/solarnexus-temp /etc/nginx/sites-enabled/

print_step "Step 3: Testing nginx configuration..."
if $SUDO nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

print_step "Step 4: Restarting nginx with temporary configuration..."
$SUDO systemctl restart nginx

print_step "Step 5: Creating webroot directory for Let's Encrypt..."
$SUDO mkdir -p /var/www/html/.well-known/acme-challenge
$SUDO chown -R www-data:www-data /var/www/html

print_step "Step 6: Obtaining SSL certificate..."
if $SUDO certbot certonly \
    --webroot \
    --webroot-path=/var/www/html \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN; then
    print_success "SSL certificate obtained successfully"
else
    print_error "Failed to obtain SSL certificate"
    print_warning "You may need to:"
    print_warning "1. Ensure DNS is pointing to this server"
    print_warning "2. Check firewall allows port 80"
    print_warning "3. Verify domain is accessible from internet"
    exit 1
fi

print_step "Step 7: Creating production nginx configuration with SSL..."

# Create production nginx config with SSL
$SUDO tee /etc/nginx/sites-available/solarnexus << 'EOF'
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Upstream backend
upstream backend {
    server localhost:5000;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name nexus.gonxt.tech;
    
    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none';" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Frontend (React app)
    location / {
        root /opt/solarnexus/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend;
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
    
    # Login rate limiting
    location /api/auth/login {
        limit_req zone=login burst=3 nodelay;
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }
}
EOF

print_step "Step 8: Enabling production configuration..."
$SUDO rm -f /etc/nginx/sites-enabled/solarnexus-temp
$SUDO ln -sf /etc/nginx/sites-available/solarnexus /etc/nginx/sites-enabled/

print_step "Step 9: Testing production nginx configuration..."
if $SUDO nginx -t; then
    print_success "Production nginx configuration is valid"
else
    print_error "Production nginx configuration test failed"
    exit 1
fi

print_step "Step 10: Restarting nginx with SSL configuration..."
$SUDO systemctl restart nginx

print_step "Step 11: Setting up SSL certificate auto-renewal..."
# Create renewal hook
$SUDO tee /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh << 'EOF'
#!/bin/bash
systemctl reload nginx
EOF

$SUDO chmod +x /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh

# Test renewal
print_status "Testing SSL certificate renewal..."
$SUDO certbot renew --dry-run

print_step "Step 12: Verifying SSL setup..."
if curl -f -s https://$DOMAIN/health > /dev/null 2>&1; then
    print_success "SSL setup completed successfully!"
    print_success "Site is accessible at: https://$DOMAIN"
else
    print_warning "SSL is configured but backend may not be ready yet"
    print_status "You can verify SSL at: https://$DOMAIN"
fi

print_success "SSL certificate and nginx configuration fixed!"
print_status "Certificate location: /etc/letsencrypt/live/$DOMAIN/"
print_status "Nginx config: /etc/nginx/sites-available/solarnexus"
print_status "Auto-renewal: Configured with certbot"

echo ""
echo "🔒 SSL Certificate Information:"
$SUDO certbot certificates

echo ""
echo "✅ Next steps:"
echo "1. Ensure your application containers are running"
echo "2. Test the site: https://$DOMAIN"
echo "3. Check nginx logs if needed: sudo tail -f /var/log/nginx/error.log"