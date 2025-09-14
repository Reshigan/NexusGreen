# Nexus Green Production Dockerfile
# Multi-stage build for optimized production deployment

# Stage 1: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Clean npm cache and install dependencies
RUN npm cache clean --force && \
    npm install --silent --no-audit --no-fund

# Copy source code
COPY . .

# Set production environment
ENV NODE_ENV=production
ENV VITE_ENVIRONMENT=production

# Build the application
RUN npm run build

# Stage 2: Production stage
FROM nginx:alpine AS production

# Install curl and openssl for health checks and SSL
RUN apk add --no-cache curl openssl

# Copy custom nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Create temp directories and set permissions
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html /tmp /var/log/nginx /etc/nginx/ssl

# Create a default health check page
RUN echo "healthy" > /usr/share/nginx/html/health.txt

# Switch back to root for nginx to bind to privileged ports
USER root

# Expose ports for HTTP and HTTPS
EXPOSE 80 443

# Health check (try HTTPS first, fallback to HTTP)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f -k https://localhost/health || curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]