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
RUN npm ci --include=dev
COPY . .
RUN npx prisma generate
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS build
RUN npm ci --only=production && npm cache clean --force
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

# Copy package files and install all dependencies (including dev for ts-node)
COPY --from=base /app/package*.json ./
RUN npm ci && npm cache clean --force

# Copy source code and configuration
COPY --chown=solarnexus:nodejs . .
COPY --from=base /app/prisma ./prisma

# Generate Prisma client
RUN npx prisma generate

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs && \
    chown -R solarnexus:nodejs /app/uploads /app/logs

# Switch to non-root user
USER solarnexus

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

# Start the application with ts-node and path resolution
CMD ["npx", "ts-node", "-r", "tsconfig-paths/register", "src/server.ts"]