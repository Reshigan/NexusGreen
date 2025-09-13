#!/bin/bash

# SolarNexus Production Installation Script
# Ubuntu 22.04 AWS - Industry Best Practices
# Version: 1.0.0
# Author: OpenHands AI
# Date: 2025-09-13

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly APP_NAME="solarnexus"
readonly APP_USER="solarnexus"
readonly APP_DIR="/opt/solarnexus"
readonly LOG_DIR="/var/log/solarnexus"
readonly DATA_DIR="/var/lib/solarnexus"
readonly BACKUP_DIR="/var/backups/solarnexus"
readonly GITHUB_REPO="https://github.com/Reshigan/SolarNexus.git"
readonly SERVER_IP="13.245.249.110"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1" | tee -a "${LOG_DIR}/install.log" 2>/dev/null || echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" | tee -a "${LOG_DIR}/install.log" 2>/dev/null || echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1" | tee -a "${LOG_DIR}/install.log" 2>/dev/null || echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1" | tee -a "${LOG_DIR}/install.log" 2>/dev/null || echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

success() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1" | tee -a "${LOG_DIR}/install.log" 2>/dev/null || echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use: sudo $0"
    fi
}

# System requirements check
check_system() {
    log "Checking system requirements..."
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        warn "This script is optimized for Ubuntu 22.04. Current system: $(lsb_release -d | cut -f2)"
    fi
    
    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        error "Unsupported architecture: $arch"
    fi
    
    # Check available memory (minimum 2GB)
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $mem_gb -lt 2 ]]; then
        warn "Low memory detected: ${mem_gb}GB. Minimum recommended: 2GB"
    fi
    
    # Check available disk space (minimum 10GB)
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [[ $disk_gb -lt 10 ]]; then
        error "Insufficient disk space: ${disk_gb}GB available. Minimum required: 10GB"
    fi
    
    success "System requirements check passed"
}

# Create system user and directories
setup_system_user() {
    log "Setting up system user and directories..."
    
    # Create application user
    if ! id "$APP_USER" &>/dev/null; then
        useradd --system --shell /bin/bash --home-dir "$APP_DIR" --create-home "$APP_USER"
        success "Created system user: $APP_USER"
    else
        info "System user $APP_USER already exists"
    fi
    
    # Create directories with proper permissions
    local dirs=("$APP_DIR" "$LOG_DIR" "$DATA_DIR" "$BACKUP_DIR")
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        chown "$APP_USER:$APP_USER" "$dir"
        chmod 755 "$dir"
    done
    
    # Create log file
    touch "${LOG_DIR}/install.log"
    chown "$APP_USER:$APP_USER" "${LOG_DIR}/install.log"
    chmod 644 "${LOG_DIR}/install.log"
    
    success "System user and directories created"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Update package lists
    apt-get update -qq
    
    # Upgrade system packages
    apt-get upgrade -y -qq
    
    # Install essential packages
    apt-get install -y -qq \
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
        tree \
        jq \
        build-essential \
        python3 \
        python3-pip
    
    success "System packages updated"
}

# Install Docker with best practices
install_docker() {
    log "Installing Docker..."
    
    # Remove old Docker versions
    apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt-get update -qq
    
    # Install Docker
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    usermod -aG docker "$APP_USER"
    
    # Configure Docker daemon
    cat > /etc/docker/daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "metrics-addr": "127.0.0.1:9323",
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Verify Docker installation
    docker --version
    docker compose version
    
    success "Docker installed and configured"
}

# Install Node.js LTS
install_nodejs() {
    log "Installing Node.js LTS..."
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    
    # Install Node.js
    apt-get install -y -qq nodejs
    
    # Verify installation
    node --version
    npm --version
    
    # Configure npm for production
    npm config set fund false
    npm config set audit-level moderate
    
    success "Node.js LTS installed"
}

# Install and configure PostgreSQL
install_postgresql() {
    log "Installing PostgreSQL..."
    
    # Install PostgreSQL
    apt-get install -y -qq postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Configure PostgreSQL
    sudo -u postgres psql << EOF
CREATE USER $APP_USER WITH PASSWORD 'SolarNexus2024!';
CREATE DATABASE $APP_NAME OWNER $APP_USER;
GRANT ALL PRIVILEGES ON DATABASE $APP_NAME TO $APP_USER;
ALTER USER $APP_USER CREATEDB;
\q
EOF
    
    # Configure PostgreSQL for production
    local pg_version=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    local pg_config="/etc/postgresql/${pg_version}/main/postgresql.conf"
    local pg_hba="/etc/postgresql/${pg_version}/main/pg_hba.conf"
    
    # Backup original configs
    cp "$pg_config" "${pg_config}.backup"
    cp "$pg_hba" "${pg_hba}.backup"
    
    # Configure PostgreSQL settings
    cat >> "$pg_config" << EOF

# SolarNexus Production Settings
shared_preload_libraries = 'pg_stat_statements'
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
EOF
    
    # Restart PostgreSQL
    systemctl restart postgresql
    
    success "PostgreSQL installed and configured"
}

# Install and configure Redis
install_redis() {
    log "Installing Redis..."
    
    # Install Redis
    apt-get install -y -qq redis-server
    
    # Configure Redis for production
    cat > /etc/redis/redis.conf << EOF
# SolarNexus Redis Configuration
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
maxmemory 256mb
maxmemory-policy allkeys-lru
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
EOF
    
    # Start and enable Redis
    systemctl start redis-server
    systemctl enable redis-server
    
    success "Redis installed and configured"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
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
    
    # Allow application ports
    ufw allow 3000/tcp comment "SolarNexus Frontend"
    ufw allow 5000/tcp comment "SolarNexus Backend"
    
    # Enable firewall
    ufw --force enable
    
    success "Firewall configured"
}

# Clone and setup application
setup_application() {
    log "Setting up SolarNexus application..."
    
    # Change to app user
    cd "$APP_DIR"
    
    # Clone repository
    if [[ -d ".git" ]]; then
        info "Repository already exists, pulling latest changes..."
        sudo -u "$APP_USER" git pull origin main
    else
        info "Cloning repository..."
        sudo -u "$APP_USER" git clone "$GITHUB_REPO" .
    fi
    
    # Create environment file
    sudo -u "$APP_USER" cat > .env.production << EOF
# SolarNexus Production Environment
NODE_ENV=production
PORT=5000

# Database Configuration
DATABASE_URL=postgresql://$APP_USER:SolarNexus2024!@localhost:5432/$APP_NAME
POSTGRES_DB=$APP_NAME
POSTGRES_USER=$APP_USER
POSTGRES_PASSWORD=SolarNexus2024!

# Redis Configuration
REDIS_URL=redis://localhost:6379

# Application Configuration
JWT_SECRET=$(openssl rand -hex 32)
BCRYPT_ROUNDS=12
SESSION_SECRET=$(openssl rand -hex 32)

# File Upload Configuration
UPLOAD_PATH=$DATA_DIR/uploads
MAX_FILE_SIZE=10485760

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=$LOG_DIR/app.log

# Server Configuration
SERVER_IP=$SERVER_IP
FRONTEND_URL=http://$SERVER_IP:3000
API_BASE_URL=http://$SERVER_IP:5000
EOF
    
    # Set proper permissions
    chown "$APP_USER:$APP_USER" .env.production
    chmod 600 .env.production
    
    # Create uploads directory
    mkdir -p "$DATA_DIR/uploads"
    chown "$APP_USER:$APP_USER" "$DATA_DIR/uploads"
    chmod 755 "$DATA_DIR/uploads"
    
    success "Application setup completed"
}

# Build application
build_application() {
    log "Building SolarNexus application..."
    
    cd "$APP_DIR"
    
    # Install backend dependencies
    if [[ -d "solarnexus-backend" ]]; then
        cd solarnexus-backend
        sudo -u "$APP_USER" npm ci --only=production
        cd ..
    fi
    
    # Install and build frontend
    if [[ -f "package.json" ]]; then
        sudo -u "$APP_USER" npm ci
        sudo -u "$APP_USER" VITE_API_BASE_URL="http://$SERVER_IP:5000" npm run build
    fi
    
    success "Application built successfully"
}

# Setup database schema
setup_database() {
    log "Setting up database schema..."
    
    cd "$APP_DIR"
    
    # Apply database migration if exists
    if [[ -f "database/migration.sql" ]]; then
        sudo -u postgres psql -d "$APP_NAME" -f database/migration.sql
        success "Database schema applied"
    else
        warn "No database migration file found"
    fi
}

# Create systemd services
create_systemd_services() {
    log "Creating systemd services..."
    
    # Backend service
    cat > /etc/systemd/system/solarnexus-backend.service << EOF
[Unit]
Description=SolarNexus Backend API
After=network.target postgresql.service redis-server.service
Wants=postgresql.service redis-server.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR/solarnexus-backend
Environment=NODE_ENV=production
EnvironmentFile=$APP_DIR/.env.production
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=solarnexus-backend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DATA_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # Frontend service (nginx)
    cat > /etc/systemd/system/solarnexus-frontend.service << EOF
[Unit]
Description=SolarNexus Frontend (Nginx)
After=network.target solarnexus-backend.service
Wants=solarnexus-backend.service

[Service]
Type=forking
User=root
Group=root
ExecStart=/usr/sbin/nginx -c $APP_DIR/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    success "Systemd services created"
}

# Install and configure Nginx
install_nginx() {
    log "Installing and configuring Nginx..."
    
    # Install Nginx
    apt-get install -y -qq nginx
    
    # Create Nginx configuration
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
    
    server {
        listen 3000;
        server_name $SERVER_IP localhost;
        root $APP_DIR/dist;
        index index.html;
        
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
    
    # Set proper permissions
    chown "$APP_USER:$APP_USER" "$APP_DIR/nginx.conf"
    
    success "Nginx installed and configured"
}

# Create backup script
create_backup_script() {
    log "Creating backup script..."
    
    cat > /usr/local/bin/solarnexus-backup.sh << 'EOF'
#!/bin/bash

# SolarNexus Backup Script
BACKUP_DIR="/var/backups/solarnexus"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/opt/solarnexus"
LOG_FILE="/var/log/solarnexus/backup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Database backup
pg_dump -U solarnexus -h localhost solarnexus | gzip > "$BACKUP_DIR/database_$DATE.sql.gz"

# Application files backup
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" -C "$APP_DIR" .

# Uploads backup
tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" -C "/var/lib/solarnexus" uploads

# Remove backups older than 7 days
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete

echo "$(date): Backup completed successfully" >> "$LOG_FILE"
EOF
    
    chmod +x /usr/local/bin/solarnexus-backup.sh
    
    # Create cron job for daily backups
    echo "0 2 * * * root /usr/local/bin/solarnexus-backup.sh" > /etc/cron.d/solarnexus-backup
    
    success "Backup script created"
}

# Start services
start_services() {
    log "Starting SolarNexus services..."
    
    # Enable and start backend
    systemctl enable solarnexus-backend
    systemctl start solarnexus-backend
    
    # Enable and start frontend
    systemctl enable solarnexus-frontend
    systemctl start solarnexus-frontend
    
    # Wait for services to start
    sleep 10
    
    success "Services started"
}

# Health check
health_check() {
    log "Performing health checks..."
    
    local checks_passed=0
    local total_checks=4
    
    # Check backend
    if curl -f -s http://localhost:5000/health >/dev/null 2>&1; then
        success "✅ Backend API is healthy"
        ((checks_passed++))
    else
        error "❌ Backend API health check failed"
    fi
    
    # Check frontend
    if curl -f -s http://localhost:3000/health >/dev/null 2>&1; then
        success "✅ Frontend is healthy"
        ((checks_passed++))
    else
        error "❌ Frontend health check failed"
    fi
    
    # Check database
    if sudo -u postgres psql -d "$APP_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        success "✅ Database is healthy"
        ((checks_passed++))
    else
        error "❌ Database health check failed"
    fi
    
    # Check Redis
    if redis-cli ping >/dev/null 2>&1; then
        success "✅ Redis is healthy"
        ((checks_passed++))
    else
        error "❌ Redis health check failed"
    fi
    
    if [[ $checks_passed -eq $total_checks ]]; then
        success "All health checks passed ($checks_passed/$total_checks)"
    else
        error "Health checks failed ($checks_passed/$total_checks)"
    fi
}

# Display final information
display_final_info() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🎉 INSTALLATION COMPLETE! 🎉              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🌐 Access URLs:${NC}"
    echo -e "   Frontend:    http://$SERVER_IP:3000"
    echo -e "   Backend API: http://$SERVER_IP:5000"
    echo -e "   Health:      http://$SERVER_IP:5000/health"
    echo ""
    echo -e "${CYAN}📊 Service Management:${NC}"
    echo -e "   Status:      systemctl status solarnexus-backend solarnexus-frontend"
    echo -e "   Logs:        journalctl -u solarnexus-backend -f"
    echo -e "   Restart:     systemctl restart solarnexus-backend solarnexus-frontend"
    echo ""
    echo -e "${CYAN}🔧 File Locations:${NC}"
    echo -e "   Application: $APP_DIR"
    echo -e "   Logs:        $LOG_DIR"
    echo -e "   Data:        $DATA_DIR"
    echo -e "   Backups:     $BACKUP_DIR"
    echo ""
    echo -e "${CYAN}🛡️ Security:${NC}"
    echo -e "   Firewall:    ufw status"
    echo -e "   SSL Setup:   Use certbot for Let's Encrypt SSL"
    echo ""
    echo -e "${GREEN}✅ SolarNexus is now running in production mode!${NC}"
    echo ""
}

# Main installation function
main() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              SolarNexus Production Installation               ║${NC}"
    echo -e "${PURPLE}║                    Ubuntu 22.04 AWS                         ║${NC}"
    echo -e "${PURPLE}║                    Version $SCRIPT_VERSION                           ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Pre-flight checks
    check_root
    check_system
    
    # System setup
    setup_system_user
    update_system
    
    # Install dependencies
    install_docker
    install_nodejs
    install_postgresql
    install_redis
    install_nginx
    
    # Security
    configure_firewall
    
    # Application setup
    setup_application
    build_application
    setup_database
    
    # Service management
    create_systemd_services
    create_backup_script
    start_services
    
    # Final checks
    health_check
    display_final_info
}

# Run main function
main "$@"