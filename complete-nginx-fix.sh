#!/bin/bash

# Complete Nginx Fix for Nexus Green
# Fixes www-data user issue and Nginx configuration

echo "🔧 Complete Nginx Fix for Nexus Green..."

# Create www-data user if it doesn't exist
echo "Checking for www-data user..."
if ! id "www-data" &>/dev/null; then
    echo "Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
    echo "✅ www-data user created"
else
    echo "✅ www-data user already exists"
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# Create necessary directories
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
sudo mkdir -p /var/log/nginx
sudo mkdir -p /var/lib/nginx

# Set proper ownership
sudo chown -R www-data:www-data /var/log/nginx
sudo chown -R www-data:www-data /var/lib/nginx

# Remove all broken configurations
echo "Removing broken configurations..."
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-available/solarnexus
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-available/nexus-green
sudo rm -f /etc/nginx/sites-enabled/default

# Create basic nginx.conf if it's corrupted
echo "Creating basic nginx.conf..."
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/sites-enabled/*;
}
EOF

# Create the Nexus Green site configuration
echo "Creating Nexus Green site configuration..."
sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << 'EOF'
server {
    listen 80;
    server_name nexus.gonxt.tech localhost;
    
    root /opt/nexus-green/dist;
    index index.html;
    
    # Basic security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Cache control
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Basic gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json;
    
    # Main location
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # API proxy (if backend is running)
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site
echo "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Create the dist directory if it doesn't exist
sudo mkdir -p /opt/nexus-green/dist
echo "<h1>Nexus Green - Building...</h1>" | sudo tee /opt/nexus-green/dist/index.html > /dev/null

# Set proper permissions
sudo chown -R www-data:www-data /opt/nexus-green/dist

# Test configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid!"
    
    # Start/restart Nginx
    echo "Starting Nginx..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Check status
    if sudo systemctl is-active --quiet nginx; then
        echo "🎉 Nginx is running successfully!"
        echo ""
        echo "✅ Site should be accessible at:"
        echo "   - http://nexus.gonxt.tech"
        echo "   - http://$(curl -s ifconfig.me)"
        echo ""
        echo "Next steps:"
        echo "1. Build your app: cd /opt/nexus-green && npm run build"
        echo "2. Test the site: curl -I http://nexus.gonxt.tech"
        echo "3. Set up SSL: sudo certbot --nginx -d nexus.gonxt.tech"
    else
        echo "❌ Nginx failed to start"
        sudo systemctl status nginx
    fi
else
    echo "❌ Configuration still has errors!"
    sudo nginx -t
fi