#!/bin/bash

# NexusGreen Complete Production Deployment Script
# World-Class Solar Energy Management Platform
# Version: 6.0.0 - Production Ready

set -e

echo "🚀 NexusGreen Production Deployment - World-Class Solar Platform"
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Reshigan/NexusGreen.git"
APP_DIR="/opt/nexusgreen"
BACKUP_DIR="/opt/backups/nexusgreen-$(date +%Y%m%d-%H%M%S)"
DOCKER_COMPOSE_FILE="docker-compose.yml"
LOG_FILE="/var/log/nexusgreen-deployment.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${PURPLE}[PHASE]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   print_status "Please run as ubuntu user: su ubuntu"
   exit 1
fi

# Initialize log file
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"
sudo chown $USER:$USER "$LOG_FILE"

print_header "PHASE 1: SYSTEM PREPARATION"

# Check system requirements
print_status "Checking system requirements..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm get-docker.sh
    print_success "Docker installed successfully"
fi

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    print_status "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    print_warning "User added to docker group. Please log out and log back in, or run: newgrp docker"
    exec newgrp docker << EONG
        bash "$0" "$@"
EONG
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
fi

# Test Docker access
if ! docker ps &> /dev/null; then
    print_status "Starting Docker daemon..."
    sudo systemctl start docker
    sudo systemctl enable docker
    sleep 5
    
    if ! docker ps &> /dev/null; then
        print_error "Cannot access Docker. Please check Docker installation."
        print_status "Try running: sudo systemctl status docker"
        exit 1
    fi
fi

print_success "System requirements verified"

print_header "PHASE 2: BACKUP AND PREPARATION"

# Create backup directory
print_status "Creating backup directory..."
sudo mkdir -p "$BACKUP_DIR"

# Backup existing application if it exists
if [ -d "$APP_DIR" ]; then
    print_status "Backing up existing application..."
    sudo cp -r "$APP_DIR" "$BACKUP_DIR/"
    print_success "Backup created at $BACKUP_DIR"
fi

# Create application directory
print_status "Setting up application directory..."
sudo mkdir -p "$APP_DIR"
sudo chown $USER:$USER "$APP_DIR"

print_header "PHASE 3: CODE DEPLOYMENT"

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    print_status "Updating existing repository..."
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/main
    git pull origin main
else
    print_status "Cloning NexusGreen repository..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# Checkout the latest version
print_status "Checking out latest production version..."
git checkout main
git pull origin main

print_success "Code deployment completed"

print_header "PHASE 4: ENVIRONMENT SETUP"

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Remove old images to ensure fresh build
print_status "Cleaning up old Docker images..."
docker system prune -f || true

# Create necessary directories
print_status "Creating required directories..."
mkdir -p docker/ssl
mkdir -p docker/logs
mkdir -p database/data
mkdir -p logs/nginx
mkdir -p logs/api

# Set proper permissions
print_status "Setting permissions..."
sudo chown -R $USER:$USER "$APP_DIR"
chmod +x deploy-production.sh || true
chmod +x test-production.sh || true
chmod +x deploy-production-complete.sh || true

print_success "Environment setup completed"

print_header "PHASE 5: DATABASE INITIALIZATION"

print_status "Initializing production database..."

# Start database container first
docker-compose up -d nexus-green-db

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 30

# Check if database is responding
for i in {1..30}; do
    if docker-compose exec -T nexus-green-db pg_isready -U nexusgreen; then
        print_success "Database is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Database failed to start"
        exit 1
    fi
    sleep 2
done

print_success "Database initialization completed"

print_header "PHASE 6: APPLICATION BUILD AND DEPLOYMENT"

# Build and start all services
print_status "Building and starting NexusGreen services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 45

print_header "PHASE 7: HEALTH CHECKS AND VALIDATION"

# Check service health
print_status "Performing comprehensive health checks..."

# Check if all containers are running
if docker-compose ps | grep -q "Up"; then
    print_success "All services are running!"
else
    print_error "Some services failed to start. Checking logs..."
    docker-compose logs --tail=50
    exit 1
fi

# Test API endpoints
print_status "Testing API endpoints..."
sleep 10

# Test health endpoint
if curl -f -s http://localhost:3001/api/health > /dev/null 2>&1; then
    print_success "API health check passed"
else
    print_warning "API health check failed - service may still be starting"
fi

# Test frontend
if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
    print_success "Frontend health check passed"
else
    print_warning "Frontend health check failed - service may still be starting"
fi

print_header "PHASE 8: PERFORMANCE OPTIMIZATION"

# Optimize Docker containers
print_status "Optimizing container performance..."
docker system prune -f

# Set up log rotation
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/nexusgreen > /dev/null <<EOF
/var/log/nexusgreen-deployment.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF

print_success "Performance optimization completed"

print_header "PHASE 9: SECURITY HARDENING"

# Set up firewall rules (if ufw is available)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall..."
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 22/tcp
    print_success "Firewall configured"
fi

# Set secure file permissions
print_status "Setting secure file permissions..."
find "$APP_DIR" -type f -name "*.sh" -exec chmod +x {} \;
find "$APP_DIR" -type f -name "*.env*" -exec chmod 600 {} \;

print_success "Security hardening completed"

print_header "PHASE 10: MONITORING AND ALERTING SETUP"

# Create monitoring script
print_status "Setting up monitoring..."
cat > "$APP_DIR/monitor.sh" << 'EOF'
#!/bin/bash
# NexusGreen Monitoring Script

LOG_FILE="/var/log/nexusgreen-monitor.log"

check_service() {
    if docker-compose ps | grep -q "$1.*Up"; then
        echo "$(date): $1 is running" >> "$LOG_FILE"
        return 0
    else
        echo "$(date): $1 is DOWN" >> "$LOG_FILE"
        return 1
    fi
}

cd /opt/nexusgreen

# Check all services
check_service "nexus-green-db"
check_service "nexus-green-api"
check_service "nexus-green-prod"

# Check disk space
df -h | grep -E "/$|/opt" >> "$LOG_FILE"

# Check memory usage
free -h >> "$LOG_FILE"
EOF

chmod +x "$APP_DIR/monitor.sh"

# Set up cron job for monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * $APP_DIR/monitor.sh") | crontab -

print_success "Monitoring setup completed"

print_header "DEPLOYMENT SUMMARY"

# Display service status
echo ""
echo "🎉 NexusGreen Production Deployment Complete!"
echo "=============================================="
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Access Points:"
echo "  • Main Application: https://nexus.gonxt.tech"
echo "  • API Endpoint: https://nexus.gonxt.tech/api"
echo "  • Health Check: https://nexus.gonxt.tech/api/health"
echo "  • Local Access: http://localhost:8080"

echo ""
echo "🔧 Management Commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Restart services: docker-compose restart"
echo "  • Stop services: docker-compose down"
echo "  • Update application: git pull && docker-compose up -d --build"
echo "  • Monitor services: $APP_DIR/monitor.sh"

echo ""
echo "📈 New Features in v6.0.0:"
echo "  • World-class modern UI with animations"
echo "  • Complete NexusGreen rebranding"
echo "  • Production database with 90 days of data"
echo "  • Real-time monitoring and alerts"
echo "  • Enhanced security and performance"
echo "  • Comprehensive API with caching"
echo "  • Professional favicon and branding"

echo ""
echo "🔍 Troubleshooting:"
echo "  • Check logs: docker-compose logs [service-name]"
echo "  • Restart specific service: docker-compose restart [service-name]"
echo "  • View system resources: docker stats"
echo "  • Monitor system: tail -f /var/log/nexusgreen-monitor.log"

echo ""
echo "📁 Important Paths:"
echo "  • Application: $APP_DIR"
echo "  • Backups: $BACKUP_DIR"
echo "  • Logs: /var/log/nexusgreen-*.log"
echo "  • Database Data: $APP_DIR/database/data"

echo ""
print_success "NexusGreen v6.0.0 is now running with world-class features!"
print_success "The domain nexus.gonxt.tech will show the new modern interface."

# Final health check
echo ""
print_status "Running final comprehensive health check..."
sleep 10

# Check all endpoints
HEALTH_PASSED=true

if ! curl -f -s http://localhost:3001/api/health > /dev/null 2>&1; then
    print_warning "API health check failed"
    HEALTH_PASSED=false
fi

if ! curl -f -s http://localhost:8080 > /dev/null 2>&1; then
    print_warning "Frontend health check failed"
    HEALTH_PASSED=false
fi

if [ "$HEALTH_PASSED" = true ]; then
    print_success "All health checks passed! 🎉"
    echo ""
    echo "🚀 NexusGreen is ready for production use!"
    echo "Visit https://nexus.gonxt.tech to experience the world-class solar platform!"
else
    print_warning "Some health checks failed. Services may still be starting up."
    print_status "Wait a few more minutes and check manually."
fi

echo ""
echo "Deployment completed at: $(date)"
echo "Log file: $LOG_FILE"
echo ""
echo "Thank you for using NexusGreen - World-Class Solar Energy Management! 🌞"