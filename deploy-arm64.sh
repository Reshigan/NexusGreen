#!/bin/bash

# SolarNexus ARM64 Deployment Script for AWS t4g.medium
# Optimized for ARM64 instances with enhanced performance

set -e

echo "🚀 Starting SolarNexus ARM64 deployment..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root (use sudo)"
   exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    echo "[WARNING] This script is optimized for ARM64 (aarch64), detected: $ARCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Configuration
PROJECT_DIR="/opt/solarnexus"
DOMAIN="nexus.gonxt.tech"
SERVER_IP="13.247.192.38"

echo "📋 Configuration:"
echo "   - Project Directory: $PROJECT_DIR"
echo "   - Domain: $DOMAIN"
echo "   - Server IP: $SERVER_IP"
echo "   - Architecture: $ARCH"

# Check available memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
echo "   - Available Memory: ${TOTAL_MEM}MB"

if [[ $TOTAL_MEM -lt 3500 ]]; then
    echo "[WARNING] Lower memory detected (${TOTAL_MEM}MB). Expected 4GB for t4g.medium."
    echo "Performance may be impacted."
elif [[ $TOTAL_MEM -ge 3500 ]]; then
    echo "✅ Good memory allocation detected (${TOTAL_MEM}MB)"
fi

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw htop unzip

# Install Docker for ARM64
echo "🐳 Installing Docker for ARM64..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    usermod -aG docker $SUDO_USER 2>/dev/null || true
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    # Use system package for Ubuntu 24.04+ compatibility
    apt install -y docker-compose-v2
    # Create symlink for backward compatibility
    if [ ! -f /usr/local/bin/docker-compose ]; then
        ln -s /usr/bin/docker-compose /usr/local/bin/docker-compose 2>/dev/null || true
    fi
fi

# Start Docker service
echo "🐳 Starting Docker service..."
if ! systemctl is-active --quiet docker; then
    # Try starting Docker daemon directly if systemctl fails
    if ! systemctl start docker 2>/dev/null; then
        echo "Starting Docker daemon manually..."
        sudo dockerd > /tmp/docker.log 2>&1 &
        sleep 10
    fi
fi
systemctl enable docker 2>/dev/null || true

# Verify Docker is working
echo "🔍 Verifying Docker installation..."
if ! docker --version; then
    echo "[ERROR] Docker installation failed"
    exit 1
fi

# Configure firewall
echo "🔥 Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Create swap file for optimal performance
echo "💾 Creating swap file for optimal performance..."
if [[ ! -f /swapfile ]]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo "vm.swappiness=10" | tee -a /etc/sysctl.conf
    echo "✅ 4GB swap file created"
fi

# Navigate to project directory
cd $PROJECT_DIR

# Create environment file
echo "⚙️ Creating environment configuration..."
if [[ ! -f .env ]]; then
    cp .env.production .env
    
    # Generate secure passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 64)
    
    # Update environment file
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" .env
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    
    echo "✅ Environment file created with secure passwords"
fi

# Build and start services with ARM64 optimizations
echo "🏗️ Building and starting services (ARM64 optimized)..."
echo "⚠️  This may take 10-20 minutes on t4g.medium..."

# Use ARM64 optimized compose file
docker-compose -f docker-compose.arm64.yml down 2>/dev/null || true
docker-compose -f docker-compose.arm64.yml build --no-cache
docker-compose -f docker-compose.arm64.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 60

# Check service health
echo "🔍 Checking service health..."
for i in {1..10}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ Backend service is healthy"
        break
    fi
    echo "   Attempt $i/10: Backend not ready, waiting..."
    sleep 30
done

if curl -f http://localhost/ >/dev/null 2>&1; then
    echo "✅ Frontend service is healthy"
else
    echo "⚠️  Frontend service may need more time to start"
fi

# Configure SSL (optional)
echo "🔒 SSL Configuration..."
read -p "Configure SSL certificate for $DOMAIN? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Configure Nginx for SSL
    cat > /etc/nginx/sites-available/solarnexus << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/solarnexus /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    
    # Get SSL certificate
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
fi

# Setup log rotation
echo "📝 Setting up log rotation..."
cat > /etc/logrotate.d/solarnexus << EOF
/opt/solarnexus/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > /usr/local/bin/solarnexus-monitor << 'EOF'
#!/bin/bash
echo "=== SolarNexus System Status ==="
echo "Date: $(date)"
echo "Architecture: $(uname -m)"
echo "Memory Usage: $(free -h | grep Mem)"
echo "Disk Usage: $(df -h / | tail -1)"
echo "Docker Status:"
docker-compose -f /opt/solarnexus/docker-compose.arm64.yml ps
echo "Service Health:"
curl -s http://localhost:3000/health || echo "Backend: UNHEALTHY"
curl -s http://localhost/ >/dev/null && echo "Frontend: HEALTHY" || echo "Frontend: UNHEALTHY"
EOF

chmod +x /usr/local/bin/solarnexus-monitor

# Final status check
echo ""
echo "🎉 SolarNexus ARM64 deployment completed!"
echo ""
echo "📊 System Status:"
echo "   - Architecture: $ARCH"
echo "   - Memory: ${TOTAL_MEM}MB"
echo "   - Swap: $(free -h | grep Swap | awk '{print $2}')"
echo ""
echo "🌐 Access Points:"
echo "   - Application: http://localhost/"
echo "   - API: http://localhost:3000/"
echo "   - Health Check: http://localhost:3000/health"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   - SSL Domain: https://$DOMAIN"
fi
echo ""
echo "🔧 Management Commands:"
echo "   - Monitor: sudo /usr/local/bin/solarnexus-monitor"
echo "   - Logs: docker-compose -f docker-compose.arm64.yml logs -f"
echo "   - Restart: docker-compose -f docker-compose.arm64.yml restart"
echo "   - Stop: docker-compose -f docker-compose.arm64.yml down"
echo ""
echo "✅ Running on t4g.medium - Good performance expected"
echo "   4GB RAM and 100GB storage provide excellent capacity"
echo ""