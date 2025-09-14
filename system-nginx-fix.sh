#!/bin/bash

# System-level Nginx Fix for Nexus Green
# Fixes the www-data user issue and Nginx configuration

echo "🔧 System-level Nginx Fix for Nexus Green..."

# Check if www-data user exists
if ! id "www-data" &>/dev/null; then
    echo "Creating www-data user..."
    sudo useradd --system --no-create-home --shell /bin/false www-data
    sudo usermod -L www-data  # Lock the account for security
fi

# Check if www-data group exists
if ! getent group www-data &>/dev/null; then
    echo "Creating www-data group..."
    sudo groupadd --system www-data
fi

# Ensure www-data user is in www-data group
sudo usermod -g www-data www-data

# Check current Nginx user configuration
echo "Checking Nginx configuration..."
NGINX_USER=$(grep -E "^user" /etc/nginx/nginx.conf | awk '{print $2}' | sed 's/;//')

if [ "$NGINX_USER" = "www-data" ]; then
    echo "Nginx is configured to use www-data user - this is correct"
else
    echo "Nginx user is: $NGINX_USER"
    echo "Updating Nginx to use www-data..."
    sudo sed -i 's/^user .*/user www-data;/' /etc/nginx/nginx.conf
fi

# Alternative: Use the current system user instead of www-data
CURRENT_USER=$(whoami)
echo "Alternative: Configure Nginx to use current user: $CURRENT_USER"

# Create backup of nginx.conf
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Update nginx.conf to use current user
sudo sed -i "s/^user .*/user $CURRENT_USER;/" /etc/nginx/nginx.conf

echo "Updated Nginx to use user: $CURRENT_USER"

# Remove all broken configurations
echo "Removing broken configurations..."
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-available/solarnexus
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-available/nexus-green

# Create working configuration
echo "Creating working Nginx configuration..."
sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << EOF
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
        try_files \$uri \$uri/ /index.html;
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
}
EOF

# Enable the site
echo "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Set proper permissions
echo "Setting proper permissions..."
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/nexus-green/
sudo chmod -R 755 /opt/nexus-green/

# Test configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid!"
    echo "Starting/reloading Nginx..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    echo "🎉 Nginx fixed! Site should be accessible at: http://nexus.gonxt.tech"
    echo ""
    echo "Testing local access:"
    curl -I http://localhost 2>/dev/null || echo "Local test failed - check if site is built"
    echo ""
    echo "Next steps:"
    echo "1. Build the site: cd /opt/nexus-green && npm run build"
    echo "2. Test: curl -I http://nexus.gonxt.tech"
    echo "3. Set up SSL: sudo certbot --nginx -d nexus.gonxt.tech"
else
    echo "❌ Configuration still has errors!"
    sudo nginx -t
    echo ""
    echo "Nginx configuration details:"
    echo "User: $(grep -E '^user' /etc/nginx/nginx.conf)"
    echo "Current system user: $CURRENT_USER"
    echo "www-data user exists: $(id www-data &>/dev/null && echo 'Yes' || echo 'No')"
fi