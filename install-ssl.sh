#!/bin/bash

# SolarNexus SSL Installation Script
# Complete deployment with SSL/TLS support using Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/solarnexus"
LOG_FILE="/var/log/solarnexus-install.log"

# Default values
DEFAULT_DOMAIN="yourdomain.com"
DEFAULT_EMAIL="admin@yourdomain.com"
DEFAULT_DB_PASSWORD="$(openssl rand -base64 32)"
DEFAULT_REDIS_PASSWORD="$(openssl rand -base64 32)"
DEFAULT_JWT_SECRET="$(openssl rand -base64 64)"

echo -e "${CYAN}🌟 SolarNexus SSL Installation${NC}"
echo -e "${CYAN}================================${NC}"
echo ""
echo -e "${BLUE}This script will install SolarNexus with SSL/TLS support${NC}"
echo -e "${BLUE}Features:${NC}"
echo -e "  • Let's Encrypt SSL certificates"
echo -e "  • Automatic HTTPS redirect"
echo -e "  • Security headers and hardening"
echo -e "  • Rate limiting and DDoS protection"
echo -e "  • Automated certificate renewal"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   echo -e "${YELLOW}Please run: sudo $0${NC}"
   exit 1
fi

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Function to check system requirements
check_requirements() {
    log "${BLUE}🔍 Checking system requirements...${NC}"
    
    # Check OS
    if ! command -v apt-get &> /dev/null; then
        log "${RED}❌ This script requires Ubuntu/Debian with apt-get${NC}"
        exit 1
    fi
    
    # Check memory
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $MEMORY_GB -lt 2 ]]; then
        log "${YELLOW}⚠️  Warning: Less than 2GB RAM detected. Performance may be affected.${NC}"
    fi
    
    # Check disk space
    DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [[ $DISK_SPACE -lt 5000000 ]]; then
        log "${YELLOW}⚠️  Warning: Less than 5GB free disk space. Installation may fail.${NC}"
    fi
    
    log "${GREEN}✅ System requirements check completed${NC}"
}

# Function to collect configuration
collect_config() {
    log "${BLUE}⚙️  Configuration Setup${NC}"
    
    echo ""
    echo -e "${PURPLE}Domain Configuration:${NC}"
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}
    
    read -p "Enter your email for SSL certificates: " SSL_EMAIL
    SSL_EMAIL=${SSL_EMAIL:-$DEFAULT_EMAIL}
    
    echo ""
    echo -e "${PURPLE}Security Configuration:${NC}"
    read -p "Enter database password (or press Enter for auto-generated): " DB_PASSWORD
    DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASSWORD}
    
    read -p "Enter Redis password (or press Enter for auto-generated): " REDIS_PASSWORD
    REDIS_PASSWORD=${REDIS_PASSWORD:-$DEFAULT_REDIS_PASSWORD}
    
    read -p "Enter JWT secret (or press Enter for auto-generated): " JWT_SECRET
    JWT_SECRET=${JWT_SECRET:-$DEFAULT_JWT_SECRET}
    
    echo ""
    echo -e "${BLUE}📋 Configuration Summary:${NC}"
    echo -e "  Domain: ${CYAN}$DOMAIN${NC}"
    echo -e "  SSL Email: ${CYAN}$SSL_EMAIL${NC}"
    echo -e "  Install Directory: ${CYAN}$INSTALL_DIR${NC}"
    echo -e "  Database Password: ${CYAN}[HIDDEN]${NC}"
    echo -e "  Redis Password: ${CYAN}[HIDDEN]${NC}"
    echo -e "  JWT Secret: ${CYAN}[HIDDEN]${NC}"
    echo ""
    
    read -p "Continue with installation? (y/N): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log "${YELLOW}Installation cancelled by user${NC}"
        exit 0
    fi
}

# Function to install dependencies
install_dependencies() {
    log "${BLUE}📦 Installing system dependencies...${NC}"
    
    # Update package list
    apt-get update -qq
    
    # Install required packages
    apt-get install -y \
        curl \
        wget \
        git \
        docker.io \
        docker-compose \
        nginx \
        certbot \
        python3-certbot-nginx \
        ufw \
        fail2ban \
        htop \
        unzip \
        jq \
        openssl
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group if not root
    if [[ $SUDO_USER ]]; then
        usermod -aG docker $SUDO_USER
    fi
    
    log "${GREEN}✅ Dependencies installed successfully${NC}"
}

# Function to setup firewall
setup_firewall() {
    log "${BLUE}🔥 Configuring firewall...${NC}"
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (be careful not to lock yourself out)
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable firewall
    ufw --force enable
    
    log "${GREEN}✅ Firewall configured${NC}"
}

# Function to setup fail2ban
setup_fail2ban() {
    log "${BLUE}🛡️  Configuring fail2ban...${NC}"
    
    # Create nginx jail configuration
    cat > /etc/fail2ban/jail.d/nginx.conf << EOF
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF
    
    # Restart fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log "${GREEN}✅ Fail2ban configured${NC}"
}

# Function to clone repository
clone_repository() {
    log "${BLUE}📥 Cloning SolarNexus repository...${NC}"
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Clone repository
    if [[ -d ".git" ]]; then
        log "${BLUE}Repository exists, pulling latest changes...${NC}"
        git pull origin main
    else
        git clone https://github.com/Reshigan/SolarNexus.git .
    fi
    
    # Set permissions
    chown -R $SUDO_USER:$SUDO_USER "$INSTALL_DIR" 2>/dev/null || true
    
    log "${GREEN}✅ Repository cloned successfully${NC}"
}

# Function to create environment configuration
create_environment() {
    log "${BLUE}⚙️  Creating environment configuration...${NC}"
    
    # Create .env file
    cat > "$INSTALL_DIR/.env" << EOF
# SolarNexus Production Configuration
NODE_ENV=production

# Domain Configuration
DOMAIN=$DOMAIN
SSL_EMAIL=$SSL_EMAIL

# Database Configuration
POSTGRES_DB=solarnexus
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=$DB_PASSWORD
DATABASE_URL=postgresql://solarnexus:$DB_PASSWORD@postgres:5432/solarnexus

# Redis Configuration
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_URL=redis://:$REDIS_PASSWORD@redis:6379

# Security Configuration
JWT_SECRET=$JWT_SECRET
CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN

# SSL Configuration
SSL_ENABLED=true

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# API Configuration
VITE_API_URL=https://$DOMAIN
EOF
    
    # Set secure permissions
    chmod 600 "$INSTALL_DIR/.env"
    
    log "${GREEN}✅ Environment configuration created${NC}"
}

# Function to setup SSL directories
setup_ssl_directories() {
    log "${BLUE}📁 Setting up SSL directories...${NC}"
    
    # Create SSL directories
    mkdir -p "$INSTALL_DIR/ssl/certbot"
    mkdir -p "$INSTALL_DIR/ssl/www"
    mkdir -p "$INSTALL_DIR/nginx/ssl"
    mkdir -p "$INSTALL_DIR/logs/nginx"
    
    # Set permissions
    chmod 755 "$INSTALL_DIR/ssl"
    chmod 755 "$INSTALL_DIR/nginx"
    
    log "${GREEN}✅ SSL directories created${NC}"
}

# Function to create nginx configuration
create_nginx_config() {
    log "${BLUE}🌐 Creating nginx configuration...${NC}"
    
    # Create nginx configuration with domain substitution
    envsubst '${DOMAIN}' < "$INSTALL_DIR/nginx/conf.d/ssl.conf" > "$INSTALL_DIR/nginx/conf.d/default.conf"
    
    # Create temporary nginx config for initial certificate generation
    cat > "$INSTALL_DIR/nginx/conf.d/temp.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 "SolarNexus SSL Setup in Progress";
        add_header Content-Type text/plain;
    }
}
EOF
    
    log "${GREEN}✅ Nginx configuration created${NC}"
}

# Function to obtain SSL certificates
obtain_ssl_certificates() {
    log "${BLUE}🔒 Obtaining SSL certificates...${NC}"
    
    # Start temporary nginx for certificate validation
    docker run -d --name temp-nginx \
        -p 80:80 \
        -v "$INSTALL_DIR/ssl/www:/var/www/certbot:ro" \
        -v "$INSTALL_DIR/nginx/conf.d/temp.conf:/etc/nginx/conf.d/default.conf:ro" \
        nginx:alpine
    
    # Wait for nginx to start
    sleep 5
    
    # Obtain certificate using certbot
    docker run --rm \
        -v "$INSTALL_DIR/ssl/certbot:/etc/letsencrypt" \
        -v "$INSTALL_DIR/ssl/www:/var/www/certbot" \
        certbot/certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$SSL_EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$DOMAIN" \
        -d "www.$DOMAIN"
    
    # Stop temporary nginx
    docker stop temp-nginx
    docker rm temp-nginx
    
    # Copy certificates to nginx directory
    cp "$INSTALL_DIR/ssl/certbot/live/$DOMAIN/fullchain.pem" "$INSTALL_DIR/nginx/ssl/"
    cp "$INSTALL_DIR/ssl/certbot/live/$DOMAIN/privkey.pem" "$INSTALL_DIR/nginx/ssl/"
    
    # Set permissions
    chmod 644 "$INSTALL_DIR/nginx/ssl/fullchain.pem"
    chmod 600 "$INSTALL_DIR/nginx/ssl/privkey.pem"
    
    log "${GREEN}✅ SSL certificates obtained successfully${NC}"
}

# Function to setup certificate renewal
setup_certificate_renewal() {
    log "${BLUE}🔄 Setting up automatic certificate renewal...${NC}"
    
    # Create renewal script
    cat > /usr/local/bin/renew-solarnexus-ssl.sh << EOF
#!/bin/bash
cd $INSTALL_DIR
docker run --rm \\
    -v "$INSTALL_DIR/ssl/certbot:/etc/letsencrypt" \\
    -v "$INSTALL_DIR/ssl/www:/var/www/certbot" \\
    certbot/certbot renew --quiet

# Copy renewed certificates
if [[ -f "$INSTALL_DIR/ssl/certbot/live/$DOMAIN/fullchain.pem" ]]; then
    cp "$INSTALL_DIR/ssl/certbot/live/$DOMAIN/fullchain.pem" "$INSTALL_DIR/nginx/ssl/"
    cp "$INSTALL_DIR/ssl/certbot/live/$DOMAIN/privkey.pem" "$INSTALL_DIR/nginx/ssl/"
    
    # Restart nginx to load new certificates
    docker-compose restart nginx
fi
EOF
    
    chmod +x /usr/local/bin/renew-solarnexus-ssl.sh
    
    # Create cron job for renewal
    cat > /etc/cron.d/solarnexus-ssl-renewal << EOF
# Renew SolarNexus SSL certificates twice daily
0 12 * * * root /usr/local/bin/renew-solarnexus-ssl.sh
0 0 * * * root /usr/local/bin/renew-solarnexus-ssl.sh
EOF
    
    log "${GREEN}✅ Certificate renewal configured${NC}"
}

# Function to build and start services
start_services() {
    log "${BLUE}🚀 Building and starting services...${NC}"
    
    cd "$INSTALL_DIR"
    
    # Build and start services with SSL configuration
    docker-compose -f docker-compose.ssl.yml up -d --build
    
    # Wait for services to start
    log "${BLUE}⏳ Waiting for services to initialize...${NC}"
    sleep 30
    
    # Check service health
    log "${BLUE}🏥 Checking service health...${NC}"
    
    # Check database
    if docker-compose -f docker-compose.ssl.yml exec -T postgres pg_isready -U solarnexus; then
        log "${GREEN}✅ Database: Healthy${NC}"
    else
        log "${RED}❌ Database: Unhealthy${NC}"
    fi
    
    # Check Redis
    if docker-compose -f docker-compose.ssl.yml exec -T redis redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG; then
        log "${GREEN}✅ Redis: Healthy${NC}"
    else
        log "${RED}❌ Redis: Unhealthy${NC}"
    fi
    
    # Check backend
    if curl -f http://localhost:3000/health &>/dev/null; then
        log "${GREEN}✅ Backend: Healthy${NC}"
    else
        log "${RED}❌ Backend: Unhealthy${NC}"
    fi
    
    # Check nginx
    if curl -f http://localhost/health &>/dev/null; then
        log "${GREEN}✅ Nginx: Healthy${NC}"
    else
        log "${RED}❌ Nginx: Unhealthy${NC}"
    fi
    
    log "${GREEN}✅ Services started successfully${NC}"
}

# Function to test SSL configuration
test_ssl() {
    log "${BLUE}🧪 Testing SSL configuration...${NC}"
    
    # Wait for services to be fully ready
    sleep 10
    
    # Test HTTP to HTTPS redirect
    if curl -s -I "http://$DOMAIN" | grep -q "301\|302"; then
        log "${GREEN}✅ HTTP to HTTPS redirect: Working${NC}"
    else
        log "${YELLOW}⚠️  HTTP to HTTPS redirect: May have issues${NC}"
    fi
    
    # Test HTTPS connection
    if curl -s -k "https://$DOMAIN/health" | grep -q "healthy"; then
        log "${GREEN}✅ HTTPS connection: Working${NC}"
    else
        log "${YELLOW}⚠️  HTTPS connection: May have issues${NC}"
    fi
    
    # Test SSL certificate
    if echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -dates &>/dev/null; then
        log "${GREEN}✅ SSL certificate: Valid${NC}"
    else
        log "${YELLOW}⚠️  SSL certificate: May have issues${NC}"
    fi
    
    log "${GREEN}✅ SSL testing completed${NC}"
}

# Function to create management scripts
create_management_scripts() {
    log "${BLUE}📝 Creating management scripts...${NC}"
    
    # Create status script
    cat > "$INSTALL_DIR/status-ssl.sh" << 'EOF'
#!/bin/bash
echo "🌟 SolarNexus SSL Status"
echo "======================="
echo ""

cd "$(dirname "$0")"

echo "📊 Service Status:"
docker-compose -f docker-compose.ssl.yml ps

echo ""
echo "🔒 SSL Certificate Status:"
if [[ -f "nginx/ssl/fullchain.pem" ]]; then
    echo "Certificate file: ✅ Present"
    echo "Certificate expires: $(openssl x509 -enddate -noout -in nginx/ssl/fullchain.pem | cut -d= -f2)"
else
    echo "Certificate file: ❌ Missing"
fi

echo ""
echo "🌐 Connectivity Tests:"
DOMAIN=$(grep "DOMAIN=" .env | cut -d= -f2)
if curl -s -I "https://$DOMAIN/health" | grep -q "200"; then
    echo "HTTPS Health Check: ✅ Passing"
else
    echo "HTTPS Health Check: ❌ Failing"
fi

echo ""
echo "📈 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
EOF
    
    chmod +x "$INSTALL_DIR/status-ssl.sh"
    
    # Create backup script
    cat > "$INSTALL_DIR/backup-ssl.sh" << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/solarnexus-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/solarnexus_ssl_backup_$DATE.tar.gz"

echo "🔄 Creating SolarNexus SSL backup..."

mkdir -p "$BACKUP_DIR"
cd "$(dirname "$0")"

# Create backup
tar -czf "$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='logs' \
    --exclude='.git' \
    .

echo "✅ Backup created: $BACKUP_FILE"
echo "📊 Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
EOF
    
    chmod +x "$INSTALL_DIR/backup-ssl.sh"
    
    log "${GREEN}✅ Management scripts created${NC}"
}

# Function to display final information
display_final_info() {
    log "${GREEN}🎉 SolarNexus SSL Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}📋 Installation Summary:${NC}"
    echo -e "  🌐 Domain: ${GREEN}https://$DOMAIN${NC}"
    echo -e "  📁 Install Directory: ${GREEN}$INSTALL_DIR${NC}"
    echo -e "  📜 Log File: ${GREEN}$LOG_FILE${NC}"
    echo ""
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo -e "  Status Check: ${YELLOW}$INSTALL_DIR/status-ssl.sh${NC}"
    echo -e "  Create Backup: ${YELLOW}$INSTALL_DIR/backup-ssl.sh${NC}"
    echo -e "  View Logs: ${YELLOW}docker-compose -f $INSTALL_DIR/docker-compose.ssl.yml logs${NC}"
    echo -e "  Restart Services: ${YELLOW}docker-compose -f $INSTALL_DIR/docker-compose.ssl.yml restart${NC}"
    echo ""
    echo -e "${CYAN}🔒 SSL Information:${NC}"
    echo -e "  Certificate Location: ${GREEN}$INSTALL_DIR/nginx/ssl/${NC}"
    echo -e "  Auto-renewal: ${GREEN}Configured (twice daily)${NC}"
    echo -e "  Manual Renewal: ${YELLOW}/usr/local/bin/renew-solarnexus-ssl.sh${NC}"
    echo ""
    echo -e "${CYAN}🛡️  Security Features:${NC}"
    echo -e "  • HTTPS redirect enabled"
    echo -e "  • Security headers configured"
    echo -e "  • Rate limiting active"
    echo -e "  • Firewall configured"
    echo -e "  • Fail2ban protection"
    echo ""
    echo -e "${GREEN}✅ Your SolarNexus installation is ready at: https://$DOMAIN${NC}"
    echo ""
}

# Main installation flow
main() {
    log "${BLUE}Starting SolarNexus SSL installation...${NC}"
    
    check_requirements
    collect_config
    install_dependencies
    setup_firewall
    setup_fail2ban
    clone_repository
    create_environment
    setup_ssl_directories
    create_nginx_config
    obtain_ssl_certificates
    setup_certificate_renewal
    start_services
    test_ssl
    create_management_scripts
    display_final_info
    
    log "${GREEN}SolarNexus SSL installation completed successfully!${NC}"
}

# Run main function
main "$@"