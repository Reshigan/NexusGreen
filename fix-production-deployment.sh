#!/bin/bash

# NexusGreen Production Deployment Fix Script
# This script diagnoses and fixes API connectivity and nginx configuration issues

set -e

echo "🔧 NexusGreen Production Deployment Fix Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."
if ! command_exists docker; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command_exists docker-compose; then
    print_error "Docker Compose is not installed or not in PATH"
    exit 1
fi

if ! command_exists nginx; then
    print_error "Nginx is not installed or not in PATH"
    exit 1
fi

print_success "All prerequisites found"

# Step 1: Diagnose current state
print_status "Step 1: Diagnosing current deployment state..."

echo "Current container status:"
sudo docker-compose ps || print_warning "No containers running"

echo ""
echo "Current docker-compose.yml API configuration:"
grep -A 15 "nexus-api:" ~/NexusGreen/docker-compose.yml || print_error "Could not find nexus-api in docker-compose.yml"

echo ""
echo "Checking if API port is exposed to host:"
API_CONTAINER=$(sudo docker ps -q --filter name=nexus-api)
if [ -n "$API_CONTAINER" ]; then
    sudo docker port $API_CONTAINER || print_warning "No ports exposed for API container"
else
    print_warning "API container not running"
fi

echo ""
echo "Checking nginx configuration:"
sudo find /etc/nginx -name "*.conf" -exec grep -l "nexus.gonxt.tech" {} \; || print_warning "No nginx config found for nexus.gonxt.tech"

# Step 2: Stop containers
print_status "Step 2: Stopping containers..."
sudo docker-compose down

# Step 3: Fix docker-compose.yml
print_status "Step 3: Fixing docker-compose.yml API port mapping..."

# Backup original file
cp ~/NexusGreen/docker-compose.yml ~/NexusGreen/docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
print_success "Backup created: docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"

# Fix API port mapping - replace expose with ports
python3 << 'EOF'
import re

# Read the docker-compose.yml file
with open('/root/NexusGreen/docker-compose.yml', 'r') as f:
    content = f.read()

# Find the nexus-api section and replace expose with ports
pattern = r'(nexus-api:.*?)(expose:\s*\n\s*-\s*"3001")'
replacement = r'\1ports:\n      - "3001:3001"'

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back to file
with open('/root/NexusGreen/docker-compose.yml', 'w') as f:
    f.write(new_content)

print("✅ Updated docker-compose.yml API port mapping")
EOF

# Verify the change
echo ""
echo "Updated API configuration:"
grep -A 15 "nexus-api:" ~/NexusGreen/docker-compose.yml

# Step 4: Create proper nginx configuration
print_status "Step 4: Creating proper nginx configuration..."

# Remove any existing nexus config
sudo rm -f /etc/nginx/sites-enabled/nexus.gonxt.tech
sudo rm -f /etc/nginx/sites-available/nexus.gonxt.tech

# Create new nginx configuration
sudo tee /etc/nginx/sites-available/nexus.gonxt.tech > /dev/null << 'EOF'
server {
    listen 80;
    server_name nexus.gonxt.tech;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name nexus.gonxt.tech;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'";

    # API Proxy
    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        
        # Handle CORS if needed
        proxy_hide_header Access-Control-Allow-Origin;
        add_header Access-Control-Allow-Origin $http_origin;
    }

    # Frontend Proxy
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/nexus.gonxt.tech /etc/nginx/sites-enabled/

# Disable default site
sudo rm -f /etc/nginx/sites-enabled/default

print_success "Created nginx configuration for nexus.gonxt.tech"

# Test nginx configuration
print_status "Testing nginx configuration..."
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Step 5: Start containers
print_status "Step 5: Starting containers with fixed configuration..."
sudo docker-compose up -d

# Wait for containers to be healthy
print_status "Waiting for containers to start..."
sleep 15

# Check container status
echo ""
echo "Container status:"
sudo docker-compose ps

# Step 6: Reload nginx
print_status "Step 6: Reloading nginx with new configuration..."
sudo systemctl reload nginx
print_success "Nginx reloaded"

# Step 7: Test everything
print_status "Step 7: Testing complete setup..."

echo ""
echo "Testing API direct access:"
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    print_success "✅ API accessible on localhost:3001"
    curl http://localhost:3001/api/health
else
    print_error "❌ API not accessible on localhost:3001"
fi

echo ""
echo "Testing website access:"
if curl -f -I https://nexus.gonxt.tech > /dev/null 2>&1; then
    print_success "✅ Website accessible at https://nexus.gonxt.tech"
else
    print_error "❌ Website not accessible at https://nexus.gonxt.tech"
fi

echo ""
echo "Testing API through nginx:"
if curl -f https://nexus.gonxt.tech/api/health > /dev/null 2>&1; then
    print_success "✅ API accessible through nginx at https://nexus.gonxt.tech/api/health"
    curl https://nexus.gonxt.tech/api/health
else
    print_error "❌ API not accessible through nginx"
fi

# Step 8: Final verification
print_status "Step 8: Final verification..."

echo ""
echo "Container port mappings:"
for container in nexus-api nexus-green nexus-db; do
    CONTAINER_ID=$(sudo docker ps -q --filter name=$container)
    if [ -n "$CONTAINER_ID" ]; then
        echo "$container:"
        sudo docker port $CONTAINER_ID || echo "  No ports exposed"
    fi
done

echo ""
echo "Active nginx sites:"
ls -la /etc/nginx/sites-enabled/

echo ""
print_status "Deployment fix complete!"
echo ""
echo "🌐 Website: https://nexus.gonxt.tech"
echo "🔌 API: https://nexus.gonxt.tech/api/health"
echo "📊 Direct API: http://localhost:3001/api/health"
echo ""

# Check if everything is working
ALL_WORKING=true

if ! curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    ALL_WORKING=false
fi

if ! curl -f https://nexus.gonxt.tech > /dev/null 2>&1; then
    ALL_WORKING=false
fi

if ! curl -f https://nexus.gonxt.tech/api/health > /dev/null 2>&1; then
    ALL_WORKING=false
fi

if [ "$ALL_WORKING" = true ]; then
    print_success "🎉 All systems operational! NexusGreen is fully deployed and functional."
else
    print_warning "⚠️  Some issues remain. Check the test results above."
fi

echo ""
echo "📝 Next steps:"
echo "1. Test the website in your browser: https://nexus.gonxt.tech"
echo "2. Check browser console for any JavaScript errors"
echo "3. Commit the fixes to your repository"
echo ""
EOF