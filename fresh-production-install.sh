#!/bin/bash

# NexusGreen Fresh Production Installation Script
# For Ubuntu 20.04/22.04 on AWS t4g.medium (ARM64)

set -e

echo "========================================"
echo "NexusGreen Fresh Production Installation"
echo "========================================"
echo
echo "This script will install NexusGreen on a fresh Ubuntu server."
echo "Requirements:"
echo "- Fresh Ubuntu 20.04/22.04 server"
echo "- At least 4GB RAM (t4g.medium recommended)"
echo "- Port 80 and 443 available"
echo "- Domain name pointing to this server (for SSL)"
echo

# Check if domain provided as argument
if [[ -n "$1" ]]; then
    DOMAIN_NAME="$1"
    echo "Using domain from command line: $DOMAIN_NAME"
else
    # Interactive mode
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi

    # Get domain name for SSL
    echo
    echo "Please enter your domain name for SSL setup."
    echo "Example: nexus.gonxt.tech"
    echo -n "Domain name: "
    read DOMAIN_NAME
fi

# Trim whitespace and validate
DOMAIN_NAME=$(echo "$DOMAIN_NAME" | xargs)
if [[ -z "$DOMAIN_NAME" ]]; then
    echo "ERROR: Domain name is required for SSL setup."
    echo "Usage: $0 [domain-name]"
    echo "Example: $0 nexus.gonxt.tech"
    exit 1
fi

# Validate domain format (basic validation)
if [[ ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]] || [[ ! "$DOMAIN_NAME" == *.* ]]; then
    echo "ERROR: Invalid domain name format: $DOMAIN_NAME"
    echo "Please provide a valid domain name (e.g., nexus.gonxt.tech)"
    exit 1
fi

# Additional validation - check for valid TLD
if [[ ${#DOMAIN_NAME} -lt 4 ]] || [[ ${#DOMAIN_NAME} -gt 253 ]]; then
    echo "ERROR: Domain name length invalid: $DOMAIN_NAME"
    echo "Domain must be between 4 and 253 characters"
    exit 1
fi

echo
echo "Starting installation for domain: $DOMAIN_NAME"
echo

# Update system
echo "1. Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential packages
echo "2. Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw

# Configure firewall
echo "3. Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# Install Docker
echo "4. Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo "5. Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
echo "6. Installing Nginx..."
sudo apt-get install -y nginx

# Install Certbot for SSL
echo "7. Installing Certbot for SSL..."
sudo apt-get install -y certbot python3-certbot-nginx

# Clone NexusGreen repository
echo "8. Cloning NexusGreen repository..."
cd ~
rm -rf NexusGreen 2>/dev/null || true
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen
git checkout fix-production-deployment

# Configure Nginx for the domain
echo "9. Configuring Nginx..."
sudo tee /etc/nginx/sites-available/nexusgreen > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    # Redirect HTTP to HTTPS (will be configured by Certbot)
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL certificates (will be configured by Certbot)
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
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
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    
    # Main application
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # API endpoints
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8080/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/nexusgreen /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Update docker-compose for production ports
echo "10. Configuring Docker Compose for production..."
sed -i 's/- "80:80"/- "8080:80"/' docker-compose.yml

# Start Docker daemon (in case it's not running)
echo "11. Starting Docker daemon..."
sudo systemctl start docker
sudo systemctl enable docker

# Build and start the application
echo "12. Building and starting NexusGreen..."
docker-compose down -v 2>/dev/null || true
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
echo "13. Waiting for services to start..."
sleep 30

# Check service status
echo "14. Checking service status..."
docker-compose ps

# Restart Nginx
echo "15. Starting Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Setup SSL certificate
echo "16. Setting up SSL certificate..."
echo "Obtaining SSL certificate for $DOMAIN_NAME..."
sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME --redirect

# Final status check
echo "17. Final status check..."
echo
echo "Docker services:"
docker-compose ps
echo
echo "Nginx status:"
sudo systemctl status nginx --no-pager -l
echo
echo "Application logs (last 10 lines):"
docker-compose logs --tail=10

echo
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo
echo "NexusGreen has been successfully installed!"
echo
echo "Access your application:"
echo "- URL: https://$DOMAIN_NAME"
echo "- Login: admin@nexusgreen.energy"
echo "- Password: NexusGreen2024!"
echo
echo "System Information:"
echo "- Docker Compose: $(docker-compose --version)"
echo "- Docker: $(docker --version)"
echo "- Nginx: $(nginx -v 2>&1)"
echo
echo "Useful commands:"
echo "- View logs: cd ~/NexusGreen && docker-compose logs -f"
echo "- Restart services: cd ~/NexusGreen && docker-compose restart"
echo "- Stop services: cd ~/NexusGreen && docker-compose down"
echo "- Start services: cd ~/NexusGreen && docker-compose up -d"
echo
echo "If you encounter any issues:"
echo "1. Check logs: docker-compose logs"
echo "2. Check service status: docker-compose ps"
echo "3. Restart services: docker-compose restart"
echo
echo "SSL certificate will auto-renew. Test renewal with:"
echo "sudo certbot renew --dry-run"
echo
echo "Installation completed successfully!"