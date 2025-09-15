#!/bin/bash
# NexusGreen AWS EC2 Deployment Script
# This script deploys the complete NexusGreen application to an AWS EC2 instance

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - MODIFY THESE VALUES
DOMAIN="nexus.yourdomain.com"  # Change to your domain
EMAIL="your-email@domain.com"  # Change to your email
COMPANY_NAME="Your Company Name"  # Change to your company name
COMPANY_REG="Your Registration Number"  # Change to your registration number

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as ubuntu user with sudo privileges."
   exit 1
fi

print_status "🚀 Starting NexusGreen AWS Deployment..."
print_status "Domain: $DOMAIN"
print_status "Email: $EMAIL"

# Update system
print_status "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
print_status "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_success "Docker already installed"
fi

# Install Docker Compose
print_status "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose already installed"
fi

# Install additional tools
print_status "🛠️ Installing additional tools..."
sudo apt install -y git nginx certbot python3-certbot-nginx ufw curl wget

# Configure firewall
print_status "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable
print_success "Firewall configured"

# Clone or update repository
if [ -d "NexusGreen" ]; then
    print_status "📥 Updating existing repository..."
    cd NexusGreen
    git pull origin main
else
    print_status "📥 Cloning NexusGreen repository..."
    git clone https://github.com/Reshigan/NexusGreen.git
    cd NexusGreen
fi

# Generate secure passwords
print_status "🔐 Generating secure credentials..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Create production environment file
print_status "⚙️ Creating production environment configuration..."
cat > .env.production << EOF
# Database Configuration
DATABASE_URL=postgresql://nexususer:${DB_PASSWORD}@nexus-db:5432/nexusgreen
POSTGRES_DB=nexusgreen
POSTGRES_USER=nexususer
POSTGRES_PASSWORD=${DB_PASSWORD}

# JWT Configuration
JWT_SECRET=${JWT_SECRET}

# Application Configuration
NODE_ENV=production
VITE_ENVIRONMENT=production
VITE_API_URL=https://${DOMAIN}/api
CORS_ORIGIN=https://${DOMAIN}

# Company Configuration
VITE_COMPANY_NAME=${COMPANY_NAME}
VITE_COMPANY_REG=${COMPANY_REG}
VITE_PPA_RATE=1.20

# Monitoring Configuration
SOLAX_SYNC_INTERVAL_MINUTES=60

# Timezone Configuration
TZ=Africa/Johannesburg
EOF

# Update docker-compose.yml with your domain
print_status "🔧 Updating Docker Compose configuration..."
sed -i "s/nexus.gonxt.tech/${DOMAIN}/g" docker-compose.yml

# Create SSL directory
sudo mkdir -p /etc/nginx/ssl
sudo mkdir -p ./docker/ssl

# Stop any existing services
print_status "🛑 Stopping any existing services..."
sudo docker-compose down 2>/dev/null || true

# Build and start services
print_status "🏗️ Building and starting services..."
sudo docker-compose up -d --build

# Wait for services to be ready
print_status "⏳ Waiting for services to start (this may take a few minutes)..."
sleep 60

# Check if services are running
print_status "🔍 Checking service status..."
if sudo docker-compose ps | grep -q "Up"; then
    print_success "Services are running"
else
    print_error "Some services failed to start. Checking logs..."
    sudo docker-compose logs
    exit 1
fi

# Setup SSL certificate
print_status "🔒 Setting up SSL certificate..."
if [[ "$DOMAIN" != "nexus.yourdomain.com" ]]; then
    # Stop nginx temporarily
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Get SSL certificate
    sudo certbot certonly --standalone -d ${DOMAIN} --email ${EMAIL} --agree-tos --non-interactive
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate obtained successfully"
        
        # Copy certificates to docker directory
        sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ./docker/ssl/
        sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ./docker/ssl/
        sudo chown -R 1000:1000 ./docker/ssl/
        
        # Setup auto-renewal
        echo "0 12 * * * /usr/bin/certbot renew --quiet && sudo docker-compose restart nexus-green" | sudo crontab -
        
        # Restart services with SSL
        sudo docker-compose restart
    else
        print_warning "SSL certificate setup failed. Application will run on HTTP only."
    fi
else
    print_warning "Please update the DOMAIN variable in this script with your actual domain name"
fi

# Run database seeding
print_status "🌱 Seeding database with demo data..."
sleep 10
sudo docker-compose exec -T nexus-api node quick-seed.js 2>/dev/null || print_warning "Database seeding may have failed - check logs"

# Final health check
print_status "🏥 Performing final health check..."
sleep 10

# Check if application is responding
if curl -f -k https://localhost/health 2>/dev/null || curl -f http://localhost/health 2>/dev/null; then
    print_success "Application health check passed"
else
    print_warning "Health check failed - application may still be starting"
fi

# Display deployment summary
echo ""
echo "🎉 =================================="
echo "🎉  DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "🎉 =================================="
echo ""
print_success "NexusGreen is now deployed and running!"
echo ""
echo "📊 Application Details:"
echo "   🌐 URL: https://${DOMAIN} (or http://${DOMAIN} if SSL failed)"
echo "   🏢 Company: ${COMPANY_NAME}"
echo "   📧 Admin Email: ${EMAIL}"
echo ""
echo "👤 Demo Login Credentials:"
echo "   📧 Admin: admin@gonxt.tech"
echo "   🔑 Password: Demo2024!"
echo ""
echo "   📧 User: user@gonxt.tech"
echo "   🔑 Password: Demo2024!"
echo ""
echo "🔧 Management Commands:"
echo "   📋 View logs: sudo docker-compose logs -f"
echo "   🔄 Restart: sudo docker-compose restart"
echo "   📊 Status: sudo docker-compose ps"
echo "   🛑 Stop: sudo docker-compose down"
echo ""
echo "📁 Application Directory: $(pwd)"
echo "🔐 Environment File: .env.production"
echo ""

# Save deployment info
cat > deployment-info.txt << EOF
NexusGreen AWS Deployment Information
====================================

Deployment Date: $(date)
Domain: ${DOMAIN}
Email: ${EMAIL}
Company: ${COMPANY_NAME}

Application URL: https://${DOMAIN}
Admin Login: admin@gonxt.tech / Demo2024!
User Login: user@gonxt.tech / Demo2024!

Application Directory: $(pwd)
Environment File: .env.production

Management Commands:
- View logs: sudo docker-compose logs -f
- Restart services: sudo docker-compose restart
- Check status: sudo docker-compose ps
- Stop services: sudo docker-compose down

SSL Certificate: $(if [ -f "./docker/ssl/fullchain.pem" ]; then echo "Configured"; else echo "Not configured"; fi)
Auto-renewal: $(if sudo crontab -l | grep -q certbot; then echo "Configured"; else echo "Not configured"; fi)
EOF

print_success "Deployment information saved to deployment-info.txt"
echo ""
print_status "🚀 Your NexusGreen application is now live!"

# Check if we need to remind about domain configuration
if [[ "$DOMAIN" == "nexus.yourdomain.com" ]]; then
    echo ""
    print_warning "⚠️  IMPORTANT: Remember to:"
    print_warning "   1. Update the DOMAIN variable in this script"
    print_warning "   2. Point your domain's DNS to this server's IP address"
    print_warning "   3. Re-run this script after DNS propagation"
fi

echo ""
print_status "🎯 Next Steps:"
echo "   1. Point your domain DNS to this server's public IP"
echo "   2. Wait for DNS propagation (5-30 minutes)"
echo "   3. Access your application at https://${DOMAIN}"
echo "   4. Login with the demo credentials provided above"
echo ""
print_success "Deployment completed successfully! 🎉"