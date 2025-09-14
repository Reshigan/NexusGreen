#!/bin/bash

# SolarNexus Deployment Troubleshooting Script
# This script helps diagnose and fix common deployment issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker_containers() {
    print_header "CHECKING DOCKER CONTAINERS"
    
    if command -v docker compose &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        print_error "Docker Compose not found!"
        exit 1
    fi
    
    echo "Container Status:"
    sudo $COMPOSE_CMD ps
    echo ""
    
    echo "Container Logs (last 20 lines):"
    echo "--- Backend Logs ---"
    sudo $COMPOSE_CMD logs --tail=20 backend || echo "No backend logs"
    echo ""
    echo "--- Frontend Logs ---"
    sudo $COMPOSE_CMD logs --tail=20 frontend || echo "No frontend logs"
    echo ""
}

check_port_connectivity() {
    print_header "CHECKING PORT CONNECTIVITY"
    
    # Check if ports are listening
    echo "Checking port availability:"
    
    # Backend port 5000
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null | grep -q "200\|404"; then
        print_status "✅ Backend port 5000 is accessible"
    else
        print_warning "❌ Backend port 5000 is not accessible"
        echo "Trying to connect to backend container directly..."
        BACKEND_IP=$(sudo docker inspect solarnexus-backend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "")
        if [ ! -z "$BACKEND_IP" ]; then
            echo "Backend container IP: $BACKEND_IP"
            curl -s -o /dev/null -w "Backend direct connection: %{http_code}\n" http://$BACKEND_IP:5000/health || echo "Direct connection failed"
        fi
    fi
    
    # Frontend port 3000
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200\|404"; then
        print_status "✅ Frontend port 3000 is accessible"
    else
        print_warning "❌ Frontend port 3000 is not accessible"
        echo "Trying to connect to frontend container directly..."
        FRONTEND_IP=$(sudo docker inspect solarnexus-frontend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "")
        if [ ! -z "$FRONTEND_IP" ]; then
            echo "Frontend container IP: $FRONTEND_IP"
            curl -s -o /dev/null -w "Frontend direct connection: %{http_code}\n" http://$FRONTEND_IP:8080 || echo "Direct connection failed"
        fi
    fi
}

check_nginx_config() {
    print_header "CHECKING NGINX CONFIGURATION"
    
    # Check if nginx is running
    if systemctl is-active --quiet nginx; then
        print_status "✅ System nginx is running"
        
        # Check nginx configuration
        if sudo nginx -t 2>/dev/null; then
            print_status "✅ Nginx configuration is valid"
        else
            print_error "❌ Nginx configuration has errors"
            sudo nginx -t
        fi
        
        # Check if site is configured
        if [ -f "/etc/nginx/sites-available/nexus.gonxt.tech" ]; then
            print_status "✅ Site configuration exists"
        else
            print_warning "❌ Site configuration not found"
        fi
        
        # Check if site is enabled
        if [ -L "/etc/nginx/sites-enabled/nexus.gonxt.tech" ]; then
            print_status "✅ Site is enabled"
        else
            print_warning "❌ Site is not enabled"
        fi
        
    else
        print_warning "❌ System nginx is not running"
        echo "Starting nginx..."
        sudo systemctl start nginx
    fi
}

check_ssl_certificates() {
    print_header "CHECKING SSL CERTIFICATES"
    
    if [ -f "/etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem" ]; then
        print_status "✅ SSL certificate exists"
        
        # Check certificate expiry
        EXPIRY=$(sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem | cut -d= -f2)
        echo "Certificate expires: $EXPIRY"
        
        # Check if certificate is valid for domain
        if sudo openssl x509 -text -noout -in /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem | grep -q "nexus.gonxt.tech"; then
            print_status "✅ Certificate is valid for nexus.gonxt.tech"
        else
            print_warning "❌ Certificate domain mismatch"
        fi
    else
        print_warning "❌ SSL certificate not found"
    fi
}

fix_common_issues() {
    print_header "APPLYING COMMON FIXES"
    
    print_status "Restarting Docker containers with proper port binding..."
    sudo $COMPOSE_CMD down
    sudo $COMPOSE_CMD up -d --remove-orphans
    
    print_status "Waiting for containers to start..."
    sleep 15
    
    print_status "Reloading nginx configuration..."
    sudo systemctl reload nginx
    
    print_status "Testing connectivity after fixes..."
    sleep 5
    
    # Test backend
    if curl -s -f http://localhost:5000/health > /dev/null; then
        print_status "✅ Backend is now accessible"
    else
        print_warning "❌ Backend still not accessible"
    fi
    
    # Test frontend
    if curl -s -f http://localhost:3000 > /dev/null; then
        print_status "✅ Frontend is now accessible"
    else
        print_warning "❌ Frontend still not accessible"
    fi
}

show_access_info() {
    print_header "ACCESS INFORMATION"
    
    echo "🌐 Application URLs:"
    echo "   HTTPS: https://nexus.gonxt.tech"
    echo "   HTTP:  http://nexus.gonxt.tech (redirects to HTTPS)"
    echo ""
    echo "🔧 Direct Container Access (for testing):"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:5000"
    echo "   Backend Health: http://localhost:5000/health"
    echo ""
    echo "👤 Demo Credentials:"
    echo "   Admin: admin@gonxt.tech / Demo2024!"
    echo "   User:  user@gonxt.tech / Demo2024!"
    echo ""
    echo "📋 Management Commands:"
    echo "   View logs: sudo docker compose logs -f"
    echo "   Restart:   sudo docker compose restart"
    echo "   Status:    sudo docker compose ps"
}

# Main execution
print_header "SOLARNEXUS DEPLOYMENT TROUBLESHOOTER"
echo "This script will diagnose and fix common deployment issues."
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in current directory!"
    echo "Please run this script from the SolarNexus installation directory."
    echo "Common locations:"
    echo "  - /opt/solarnexus"
    echo "  - ~/solarnexus"
    echo "  - Current directory: $(pwd)"
    exit 1
fi

# Run diagnostics
check_docker_containers
check_port_connectivity
check_nginx_config
check_ssl_certificates

# Ask if user wants to apply fixes
echo ""
read -p "Would you like to apply common fixes? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    fix_common_issues
fi

show_access_info

print_status "Troubleshooting complete!"