# Multi-stage build for NexusGreen
FROM node:18-alpine AS frontend-builder

# Set working directory for frontend
WORKDIR /app/frontend

# Copy frontend package files
COPY package*.json ./
RUN npm ci

# Copy frontend source
COPY src/ ./src/
COPY public/ ./public/
COPY index.html ./
COPY tsconfig.json ./
COPY tsconfig.app.json ./
COPY tsconfig.node.json ./
COPY vite.config.ts ./
COPY tailwind.config.ts ./
COPY postcss.config.js ./
COPY eslint.config.js ./
COPY components.json ./

# Build frontend
RUN npm run build

# Backend stage
FROM node:18-alpine AS backend-builder

# Set working directory for backend
WORKDIR /app/backend

# Copy backend package files
COPY api/package*.json ./
RUN npm ci --only=production

# Copy backend source
COPY api/ ./

# Final stage
FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nexus && \
    adduser -S nexus -u 1001 -G nexus

# Copy backend from builder
COPY --from=backend-builder --chown=nexus:nexus /app/backend ./backend

# Copy frontend build from builder
COPY --from=frontend-builder --chown=nexus:nexus /app/frontend/dist ./frontend

# Copy proxy server
COPY --chown=nexus:nexus proxy-server.js ./

# Install proxy dependencies
RUN npm install express http-proxy-middleware

# Create startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "Starting NexusGreen backend..."' >> /app/start.sh && \
    echo 'cd /app/backend && PORT=3001 node server.js &' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo 'echo "Starting NexusGreen proxy server..."' >> /app/start.sh && \
    echo 'cd /app && PORT=3000 node proxy-server.js' >> /app/start.sh && \
    chmod +x /app/start.sh && \
    chown nexus:nexus /app/start.sh

# Switch to non-root user
USER nexus

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["/app/start.sh"]