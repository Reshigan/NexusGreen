# Multi-stage build for React frontend
FROM node:20-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Development stage
FROM base AS development
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# Build stage
FROM base AS build
RUN npm ci
COPY . .

# Build the React app with environment variables
ARG VITE_API_URL=https://nexus.gonxt.tech/api
ARG VITE_WS_URL=wss://nexus.gonxt.tech/ws
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_WS_URL=$VITE_WS_URL
ENV GENERATE_SOURCEMAP=false

RUN npm run build

# Production stage - Simple HTTP server
FROM node:20-alpine AS production

# Install serve globally
RUN npm install -g serve

# Create app directory
WORKDIR /app

# Copy built application
COPY --from=build /app/dist ./dist

# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001 -G appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Serve the application
CMD ["serve", "-s", "dist", "-l", "8080"]