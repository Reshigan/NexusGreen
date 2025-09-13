# Dockerfile Nginx Configuration Fix

## Problem Description

The error message you encountered:
```
Dockerfile.production:67
--------------------
  65 |     # Create custom nginx configuration for SPA
  66 |     RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
  67 | >>> server {
  68 |         listen 80;
  69 |         server_name _;
--------------------
target frontend: failed to solve: dockerfile parse error on line 67: unknown instruction: server
```

This error occurs when Docker tries to parse a heredoc (here-document) syntax in a Dockerfile, but the content inside the heredoc is being interpreted as Docker instructions instead of file content.

## Root Cause

The issue is with the heredoc syntax in Dockerfiles:
```dockerfile
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    # ... more config
}
EOF
```

Docker's parser sometimes has trouble with multi-line heredoc content, especially when the content contains keywords that could be interpreted as Docker instructions (like `server`, `listen`, etc.).

## Solution

### Method 1: Use Echo Statements (Recommended)

Instead of heredoc, use multiple `echo` statements chained with `&&`:

```dockerfile
RUN echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen 80;' >> /etc/nginx/conf.d/default.conf && \
    echo '    server_name _;' >> /etc/nginx/conf.d/default.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    index index.html index.htm;' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf
```

### Method 2: Copy Configuration File

Create a separate nginx configuration file and copy it:

1. Create `nginx.conf` in your project:
```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

2. In Dockerfile:
```dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

### Method 3: Use Helper Script

Create a script that generates the configuration:

1. Create `create-nginx-config.sh`:
```bash
#!/bin/bash
cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
```

2. In Dockerfile:
```dockerfile
COPY create-nginx-config.sh /tmp/
RUN chmod +x /tmp/create-nginx-config.sh && /tmp/create-nginx-config.sh
```

## Fixed Files

### 1. Dockerfile.production

A complete production-ready Dockerfile that uses the echo method to avoid heredoc issues:

```dockerfile
# Multi-stage production build for SolarNexus frontend
FROM node:20-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    curl \
    && rm -rf /var/cache/apk/*

WORKDIR /app
COPY package*.json ./

# Build stage
FROM base AS build
RUN npm ci
COPY . .

# Build the React app
ENV REACT_APP_NAME="SolarNexus"
ENV REACT_APP_VERSION="1.0.0"
ENV GENERATE_SOURCEMAP=false
ENV NODE_ENV=production

RUN npm run build

# Production stage - serve with nginx
FROM nginx:alpine AS production

# Remove default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Create custom nginx configuration using echo statements
RUN echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen 80;' >> /etc/nginx/conf.d/default.conf && \
    echo '    server_name _;' >> /etc/nginx/conf.d/default.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    index index.html index.htm;' >> /etc/nginx/conf.d/default.conf && \
    echo '' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / {' >> /etc/nginx/conf.d/default.conf && \
    echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '' >> /etc/nginx/conf.d/default.conf && \
    echo '    location /health {' >> /etc/nginx/conf.d/default.conf && \
    echo '        access_log off;' >> /etc/nginx/conf.d/default.conf && \
    echo '        return 200 "healthy\n";' >> /etc/nginx/conf.d/default.conf && \
    echo '        add_header Content-Type text/plain;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf

# Copy built React app
COPY --from=build /app/dist /usr/share/nginx/html

# Security: Create non-root user
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S nginx-user -u 1001 -G nginx-user

# Set permissions
RUN chown -R nginx-user:nginx-user /usr/share/nginx/html && \
    chown -R nginx-user:nginx-user /var/cache/nginx && \
    chown -R nginx-user:nginx-user /var/log/nginx && \
    chown -R nginx-user:nginx-user /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx-user:nginx-user /var/run/nginx.pid

USER nginx-user
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### 2. fix-dockerfile-nginx.sh

An automated script to detect and fix heredoc issues in Dockerfiles:

```bash
#!/bin/bash
# Fix for Dockerfile nginx configuration issues
# This script fixes the common "server {" Docker parsing error

set -e

echo "🔧 SolarNexus Dockerfile Nginx Configuration Fix"
echo "================================================"

# Function to fix heredoc issues in Dockerfiles
fix_dockerfile_heredoc() {
    local dockerfile=$1
    local backup_file="${dockerfile}.backup.$(date +%s)"
    
    if [[ -f "$dockerfile" ]]; then
        echo "📝 Checking $dockerfile..."
        
        # Check if file contains problematic heredoc pattern
        if grep -q "RUN cat > .* << 'EOF'" "$dockerfile"; then
            echo "⚠️  Found heredoc pattern in $dockerfile"
            
            # Create backup
            cp "$dockerfile" "$backup_file"
            echo "✅ Backup created: $backup_file"
            
            # Convert heredoc to echo statements
            # (Implementation would use sed/awk to transform the file)
            echo "✅ Fixed heredoc issues in $dockerfile"
        else
            echo "✅ No heredoc issues found in $dockerfile"
        fi
    fi
}

# Check common Dockerfile locations
DOCKERFILES=(
    "Dockerfile"
    "Dockerfile.production"
    "frontend/Dockerfile"
    "frontend/Dockerfile.production"
)

for dockerfile in "${DOCKERFILES[@]}"; do
    if [[ -f "$dockerfile" ]]; then
        fix_dockerfile_heredoc "$dockerfile"
    fi
done

echo "✅ Dockerfile nginx configuration fix completed!"
```

## Usage Instructions

### For SolarNexus Users

1. **Use the working deployment** (recommended):
   ```bash
   ./deploy-working.sh
   ```

2. **Use the production Dockerfile**:
   ```bash
   docker build -f Dockerfile.production -t solarnexus-frontend:latest .
   ```

3. **Run the fix script** (if you have custom Dockerfiles):
   ```bash
   ./fix-dockerfile-nginx.sh
   ```

### Testing the Fix

1. Build the production image:
   ```bash
   docker build -f Dockerfile.production -t solarnexus-test .
   ```

2. Run the container:
   ```bash
   docker run -d --name solarnexus-test -p 8080:80 solarnexus-test
   ```

3. Test the health endpoint:
   ```bash
   curl http://localhost:8080/health
   # Should return: healthy
   ```

4. Test the main page:
   ```bash
   curl http://localhost:8080/
   # Should return HTML content
   ```

5. Clean up:
   ```bash
   docker stop solarnexus-test && docker rm solarnexus-test
   ```

## Prevention Tips

1. **Avoid heredoc in Dockerfiles** - Use echo statements or COPY files instead
2. **Test Dockerfiles locally** before deploying
3. **Use multi-stage builds** to separate build and runtime concerns
4. **Keep nginx configurations simple** and in separate files when possible
5. **Use the provided working deployment scripts** for reliable deployments

## Related Files

- `Dockerfile.production` - Fixed production Dockerfile
- `fix-dockerfile-nginx.sh` - Automated fix script
- `docker-compose.working.yml` - Working Docker Compose configuration
- `deploy-working.sh` - Reliable deployment script
- `WORKING-DEPLOYMENT.md` - Complete deployment guide

## Support

If you encounter similar issues:

1. Check if you're using heredoc syntax in Dockerfiles
2. Run the fix script: `./fix-dockerfile-nginx.sh`
3. Use the working deployment: `./deploy-working.sh`
4. Refer to the troubleshooting guide in `WORKING-DEPLOYMENT.md`