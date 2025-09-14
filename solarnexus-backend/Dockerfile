# Multi-stage build for production optimization
FROM node:20-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    curl \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Development stage
FROM base AS development
RUN npm install --include=dev
COPY . .
RUN npx prisma generate
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS build
RUN npm install --only=production && npm cache clean --force
COPY . .
RUN npx prisma generate
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S solarnexus -u 1001

# Install production dependencies and TypeScript runtime
RUN apk add --no-cache \
    curl \
    python3 \
    make \
    g++ \
    openssl \
    openssl-dev \
    libc6-compat \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files and install dependencies with limited cache
COPY --from=base /app/package*.json ./
RUN npm install --no-audit --no-fund && \
    npm cache clean --force && \
    rm -rf /tmp/* /var/tmp/* /root/.npm

# Copy source code and configuration
COPY --chown=solarnexus:nodejs . .
COPY --from=base /app/prisma ./prisma

# Generate Prisma client and clean up
RUN npx prisma generate && \
    rm -rf /tmp/* /var/tmp/*

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs && \
    chown -R solarnexus:nodejs /app/uploads /app/logs

# Switch to non-root user
USER solarnexus

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-5000}/health || exit 1

EXPOSE 5000

# Start the application with ts-node and path resolution
CMD ["npx", "ts-node", "-r", "tsconfig-paths/register", "src/server.ts"]