#!/bin/bash

# SolarNexus Quick SSL Installation
# One-command SSL deployment for production

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}⚡ SolarNexus Quick SSL Install${NC}"
echo -e "${CYAN}===============================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   echo -e "${YELLOW}Run: sudo $0 your-domain.com your-email@domain.com${NC}"
   exit 1
fi

# Get domain and email from arguments
DOMAIN=${1:-}
EMAIL=${2:-}

if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}❌ Domain is required${NC}"
    echo -e "${YELLOW}Usage: sudo $0 your-domain.com your-email@domain.com${NC}"
    exit 1
fi

if [[ -z "$EMAIL" ]]; then
    echo -e "${RED}❌ Email is required for SSL certificates${NC}"
    echo -e "${YELLOW}Usage: sudo $0 your-domain.com your-email@domain.com${NC}"
    exit 1
fi

echo -e "${BLUE}🌐 Domain: $DOMAIN${NC}"
echo -e "${BLUE}📧 Email: $EMAIL${NC}"
echo ""

# Quick dependency installation
echo -e "${BLUE}📦 Installing dependencies...${NC}"
apt-get update -qq

# Remove conflicting packages first
apt-get remove -y containerd.io docker-ce docker-ce-cli 2>/dev/null || true

apt-get install -y docker.io docker-compose git curl wget openssl

# Start Docker
systemctl start docker
systemctl enable docker

# Clone repository
INSTALL_DIR="/home/ubuntu/SolarNexus"
echo -e "${BLUE}📥 Setting up SolarNexus...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [[ -d ".git" ]]; then
    git pull origin main
else
    git clone https://github.com/Reshigan/SolarNexus.git .
fi

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Create environment
echo -e "${BLUE}⚙️  Creating configuration...${NC}"
cat > .env << EOF
NODE_ENV=production
DOMAIN=$DOMAIN
SSL_EMAIL=$EMAIL
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=$DB_PASSWORD
DATABASE_URL=postgresql://solarnexus:$DB_PASSWORD@postgres:5432/solarnexus
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_URL=redis://:$REDIS_PASSWORD@redis:6379
JWT_SECRET=$JWT_SECRET
CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN
SSL_ENABLED=true
VITE_API_URL=https://$DOMAIN
EOF

chmod 600 .env

# Setup SSL directories
mkdir -p ssl/certbot ssl/www nginx/ssl logs/nginx

# Create nginx config for SSL
echo -e "${BLUE}🌐 Configuring SSL...${NC}"
cat > nginx/conf.d/default.conf << EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location /health {
        return 200 "SolarNexus SSL Setup";
        add_header Content-Type text/plain;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location /health {
        return 200 "SolarNexus is healthy";
        add_header Content-Type text/plain;
    }
    
    location /api/ {
        proxy_pass http://solarnexus-backend:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Start temporary nginx for certificate
echo -e "${BLUE}🔒 Obtaining SSL certificate...${NC}"
docker run -d --name temp-nginx \
    -p 80:80 \
    -v "$PWD/ssl/www:/var/www/certbot:ro" \
    -v "$PWD/nginx/conf.d:/etc/nginx/conf.d:ro" \
    nginx:alpine

sleep 5

# Get SSL certificate
docker run --rm \
    -v "$PWD/ssl/certbot:/etc/letsencrypt" \
    -v "$PWD/ssl/www:/var/www/certbot" \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN" \
    -d "www.$DOMAIN"

# Stop temporary nginx
docker stop temp-nginx
docker rm temp-nginx

# Copy certificates
cp "ssl/certbot/live/$DOMAIN/fullchain.pem" "nginx/ssl/"
cp "ssl/certbot/live/$DOMAIN/privkey.pem" "nginx/ssl/"
chmod 644 "nginx/ssl/fullchain.pem"
chmod 600 "nginx/ssl/privkey.pem"

# Start services
echo -e "${BLUE}🚀 Starting SolarNexus with SSL...${NC}"
docker-compose -f docker-compose.ssl.yml up -d --build

# Setup auto-renewal
echo -e "${BLUE}🔄 Setting up certificate renewal...${NC}"
cat > /usr/local/bin/renew-solarnexus-ssl.sh << EOF
#!/bin/bash
cd $INSTALL_DIR
docker run --rm \\
    -v "$PWD/ssl/certbot:/etc/letsencrypt" \\
    -v "$PWD/ssl/www:/var/www/certbot" \\
    certbot/certbot renew --quiet
cp "ssl/certbot/live/$DOMAIN/fullchain.pem" "nginx/ssl/" 2>/dev/null || true
cp "ssl/certbot/live/$DOMAIN/privkey.pem" "nginx/ssl/" 2>/dev/null || true
docker-compose -f docker-compose.ssl.yml restart nginx
EOF

chmod +x /usr/local/bin/renew-solarnexus-ssl.sh

# Add cron job
echo "0 12 * * * root /usr/local/bin/renew-solarnexus-ssl.sh" > /etc/cron.d/solarnexus-ssl-renewal

# Wait for services
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 30

# Test installation
echo -e "${BLUE}🧪 Testing installation...${NC}"
if curl -s -k "https://$DOMAIN/health" | grep -q "healthy"; then
    echo -e "${GREEN}✅ HTTPS is working!${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS may need a moment to initialize${NC}"
fi

# Final output
echo ""
echo -e "${GREEN}🎉 SolarNexus SSL Installation Complete!${NC}"
echo ""
echo -e "${CYAN}🌐 Your site: https://$DOMAIN${NC}"
echo -e "${CYAN}📁 Install directory: $INSTALL_DIR${NC}"
echo ""
echo -e "${BLUE}Management commands:${NC}"
echo -e "  Status: ${YELLOW}docker-compose -f $INSTALL_DIR/docker-compose.ssl.yml ps${NC}"
echo -e "  Logs: ${YELLOW}docker-compose -f $INSTALL_DIR/docker-compose.ssl.yml logs${NC}"
echo -e "  Restart: ${YELLOW}docker-compose -f $INSTALL_DIR/docker-compose.ssl.yml restart${NC}"
echo ""
echo -e "${GREEN}✅ SSL certificates will auto-renew twice daily${NC}"
echo -e "${GREEN}✅ Your SolarNexus platform is ready!${NC}"