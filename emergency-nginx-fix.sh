#!/bin/bash

# Emergency Nginx Fix for Nexus Green
# Fixes the must-revalidate directive error

echo "🔧 Emergency Nginx Fix for Nexus Green..."

# Remove all broken configurations
echo "Removing broken configurations..."
sudo rm -f /etc/nginx/sites-enabled/solarnexus
sudo rm -f /etc/nginx/sites-available/solarnexus
sudo rm -f /etc/nginx/sites-enabled/nexus-green
sudo rm -f /etc/nginx/sites-available/nexus-green

# Create a simple working configuration
echo "Creating simple working Nginx configuration..."
sudo tee /etc/nginx/sites-available/nexus-green > /dev/null << 'EOF'
server {
    listen 80;
    server_name nexus.gonxt.tech;
    
    # For now, just serve HTTP until SSL is configured
    root /opt/nexus-green/dist;
    index index.html;
    
    # Basic security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Simple cache control (FIXED - no standalone must-revalidate)
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Basic gzip (FIXED - removed must-revalidate from gzip_proxied)
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
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
}
EOF

# Enable the site
echo "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/nexus-green /etc/nginx/sites-enabled/

# Test configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid!"
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
    echo "🎉 Nginx fixed! Site should be accessible at: http://nexus.gonxt.tech"
    echo ""
    echo "Next steps:"
    echo "1. Test the site: curl -I http://nexus.gonxt.tech"
    echo "2. Set up SSL with: sudo certbot --nginx -d nexus.gonxt.tech"
else
    echo "❌ Configuration still has errors!"
    sudo nginx -t
fi