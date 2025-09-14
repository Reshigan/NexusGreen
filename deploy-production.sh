#!/bin/bash

# SolarNexus Production Deployment Script
# Server: 13.247.192.38
# Domain: nexus.gonxt.tech
# SSL Email: reshigan@gonxt.tech

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="13.247.192.38"
DOMAIN="nexus.gonxt.tech"
SSL_EMAIL="reshigan@gonxt.tech"
APP_DIR="/opt/solarnexus"
REPO_URL="https://github.com/Reshigan/SolarNexus.git"

echo -e "${BLUE}🚀 SolarNexus Production Deployment${NC}"
echo -e "${BLUE}Server: ${SERVER_IP}${NC}"
echo -e "${BLUE}Domain: ${DOMAIN}${NC}"
echo -e "${BLUE}SSL Email: ${SSL_EMAIL}${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential dependencies
print_status "Installing essential dependencies..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    nano \
    vim

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    print_status "Docker installed successfully"
else
    print_status "Docker already installed"
fi

# Install Node.js (for local development/debugging)
print_status "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    print_status "Node.js installed successfully"
else
    print_status "Node.js already installed"
fi

# Install Nginx
print_status "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
    sudo systemctl enable nginx
    print_status "Nginx installed successfully"
else
    print_status "Nginx already installed"
fi

# Install Certbot for SSL
print_status "Installing Certbot for SSL..."
if ! command -v certbot &> /dev/null; then
    sudo apt install -y certbot python3-certbot-nginx
    print_status "Certbot installed successfully"
else
    print_status "Certbot already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Create application directory
print_status "Creating application directory..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    print_status "Updating repository..."
    cd $APP_DIR
    git pull origin main
else
    print_status "Cloning repository..."
    git clone $REPO_URL $APP_DIR
    cd $APP_DIR
fi

# Create environment file
print_status "Creating environment configuration..."
cat > $APP_DIR/.env.production << EOF
# Production Environment Configuration
NODE_ENV=production
PORT=3000

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32)

# JWT Secrets
JWT_SECRET=$(openssl rand -base64 64)
JWT_REFRESH_SECRET=$(openssl rand -base64 64)

# Server Configuration
SERVER_IP=${SERVER_IP}
FRONTEND_URL=https://${DOMAIN}
BACKEND_URL=https://${DOMAIN}/api

# Email Configuration (Update with your SMTP settings)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@${DOMAIN}
EMAIL_FROM_NAME=SolarNexus

# SSL Configuration
SSL_EMAIL=${SSL_EMAIL}
DOMAIN=${DOMAIN}

# Optional: External API configurations
# SOLAX_API_TOKEN=your_solax_token
# SOLAX_API_URL=https://www.solaxcloud.com:9443/proxy/api/getRealtimeInfo.do
EOF

print_status "Environment file created at $APP_DIR/.env.production"

# Create production docker-compose file
print_status "Creating production Docker Compose configuration..."
cat > $APP_DIR/docker-compose.production.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: solarnexus-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./solarnexus-backend/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "127.0.0.1:5432:5432"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - solarnexus-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ./solarnexus-backend
      dockerfile: Dockerfile.debian
      target: production
    container_name: solarnexus-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      JWT_SECRET: ${JWT_SECRET}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
      EMAIL_HOST: ${EMAIL_HOST}
      EMAIL_PORT: ${EMAIL_PORT}
      EMAIL_USER: ${EMAIL_USER}
      EMAIL_PASS: ${EMAIL_PASS}
      EMAIL_FROM: ${EMAIL_FROM}
      EMAIL_FROM_NAME: ${EMAIL_FROM_NAME}
      FRONTEND_URL: ${FRONTEND_URL}
      SERVER_IP: ${SERVER_IP}
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - solarnexus-network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
      args:
        VITE_API_URL: ${BACKEND_URL}
        VITE_WS_URL: wss://${DOMAIN}/ws
    container_name: solarnexus-frontend
    restart: unless-stopped
    volumes:
      - frontend_build:/usr/share/nginx/html
    networks:
      - solarnexus-network
    depends_on:
      - backend

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  frontend_build:
    driver: local

networks:
  solarnexus-network:
    driver: bridge
EOF

# Create Nginx configuration
print_status "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/solarnexus << EOF > /dev/null
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    # SSL Configuration (will be updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
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

    # Frontend (React app)
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Handle client-side routing
        try_files \$uri \$uri/ @fallback;
    }

    # Fallback for client-side routing
    location @fallback {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # WebSocket endpoint
    location /ws {
        proxy_pass http://127.0.0.1:3000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static files with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/solarnexus /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "Testing Nginx configuration..."
sudo nginx -t

# Create directories for uploads and logs
mkdir -p $APP_DIR/uploads $APP_DIR/logs
chmod 755 $APP_DIR/uploads $APP_DIR/logs

# Build and start services
print_status "Building and starting services..."
cd $APP_DIR
sudo docker compose -f docker-compose.production.yml --env-file .env.production build
sudo docker compose -f docker-compose.production.yml --env-file .env.production up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check if services are running
if sudo docker compose -f docker-compose.production.yml ps | grep -q "Up"; then
    print_status "Services are running successfully"
else
    print_error "Some services failed to start. Check logs with: sudo docker compose -f docker-compose.production.yml logs"
fi

# Restart Nginx
print_status "Restarting Nginx..."
sudo systemctl restart nginx

# Obtain SSL certificate
print_status "Obtaining SSL certificate..."
if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --email ${SSL_EMAIL} --agree-tos --non-interactive --redirect
    print_status "SSL certificate obtained successfully"
else
    print_status "SSL certificate already exists"
fi

# Setup automatic SSL renewal
print_status "Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Create management scripts
print_status "Creating management scripts..."

# Start script
cat > $APP_DIR/start.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml --env-file .env.production up -d
sudo systemctl restart nginx
echo "SolarNexus started successfully"
EOF

# Stop script
cat > $APP_DIR/stop.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml down
echo "SolarNexus stopped successfully"
EOF

# Restart script
cat > $APP_DIR/restart.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml --env-file .env.production down
sudo docker compose -f docker-compose.production.yml --env-file .env.production up -d
sudo systemctl restart nginx
echo "SolarNexus restarted successfully"
EOF

# Update script
cat > $APP_DIR/update.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
echo "Pulling latest changes..."
git pull origin main
echo "Rebuilding and restarting services..."
sudo docker compose -f docker-compose.production.yml --env-file .env.production down
sudo docker compose -f docker-compose.production.yml --env-file .env.production build --no-cache
sudo docker compose -f docker-compose.production.yml --env-file .env.production up -d
sudo systemctl restart nginx
echo "SolarNexus updated successfully"
EOF

# Logs script
cat > $APP_DIR/logs.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
sudo docker compose -f docker-compose.production.yml logs -f
EOF

# Status script
cat > $APP_DIR/status.sh << 'EOF'
#!/bin/bash
cd /opt/solarnexus
echo "=== Docker Services ==="
sudo docker compose -f docker-compose.production.yml ps
echo ""
echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager -l
echo ""
echo "=== SSL Certificate Status ==="
sudo certbot certificates
EOF

# Make scripts executable
chmod +x $APP_DIR/*.sh

print_status "Management scripts created:"
print_status "  - start.sh: Start all services"
print_status "  - stop.sh: Stop all services"
print_status "  - restart.sh: Restart all services"
print_status "  - update.sh: Update and restart services"
print_status "  - logs.sh: View service logs"
print_status "  - status.sh: Check service status"

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}Your SolarNexus application is now available at:${NC}"
echo -e "${GREEN}  https://${DOMAIN}${NC}"
echo ""
echo -e "${BLUE}Management commands:${NC}"
echo -e "${YELLOW}  cd ${APP_DIR}${NC}"
echo -e "${YELLOW}  ./start.sh    # Start services${NC}"
echo -e "${YELLOW}  ./stop.sh     # Stop services${NC}"
echo -e "${YELLOW}  ./restart.sh  # Restart services${NC}"
echo -e "${YELLOW}  ./update.sh   # Update and restart${NC}"
echo -e "${YELLOW}  ./logs.sh     # View logs${NC}"
echo -e "${YELLOW}  ./status.sh   # Check status${NC}"
echo ""
echo -e "${BLUE}Important:${NC}"
echo -e "${YELLOW}  1. Update email settings in ${APP_DIR}/.env.production${NC}"
echo -e "${YELLOW}  2. Configure any external API tokens as needed${NC}"
echo -e "${YELLOW}  3. The application will be available after DNS propagation${NC}"
echo ""
echo -e "${GREEN}Deployment log saved to: /var/log/solarnexus-deployment.log${NC}"