#!/bin/bash
# Fix browser loading issues

echo "🔧 Fixing browser loading issues..."

# Update nginx config to fix potential CSP and MIME type issues
cat > docker/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers (relaxed for debugging)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: http: https:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types 
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/x-javascript
        application/xml+rss
        application/json;

    # Root directory
    root /usr/share/nginx/html;
    index index.html index.htm;

    # Proper MIME types
    location ~* \.js$ {
        add_header Content-Type application/javascript;
        add_header Cache-Control "public, max-age=31536000";
        try_files $uri =404;
    }

    location ~* \.css$ {
        add_header Content-Type text/css;
        add_header Cache-Control "public, max-age=31536000";
        try_files $uri =404;
    }

    # Handle client-side routing
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # API proxy
    location /api/ {
        proxy_pass http://nexus-api:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Static assets with proper headers
    location ~* \.(png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "✅ Updated nginx configuration"

# Restart nginx container
echo "🔄 Restarting nginx..."
sudo docker-compose -f docker-compose.public.yml restart nexus-green

# Wait for restart
sleep 10

# Clear any browser cache by adding cache busting
echo "🧹 Adding cache busting..."
TIMESTAMP=$(date +%s)
sudo docker-compose -f docker-compose.public.yml exec nexus-green sh -c "
echo '<!-- Cache bust: $TIMESTAMP -->' >> /usr/share/nginx/html/index.html
"

# Test loading
echo "🧪 Testing asset loading..."
curl -s -I http://localhost/assets/index-CwU5SbkU.js | grep -E 'HTTP|Content-Type'
curl -s -I http://localhost/assets/index-DxQpe1lr.css | grep -E 'HTTP|Content-Type'

echo ""
echo "🎉 Browser loading fix applied!"
echo "🌐 Try accessing: http://13.245.181.202"
echo "💡 If still blank, try:"
echo "   - Hard refresh (Ctrl+F5 or Cmd+Shift+R)"
echo "   - Open in incognito/private mode"
echo "   - Clear browser cache"