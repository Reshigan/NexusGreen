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

# Build the React app with SolarNexus branding
ENV REACT_APP_NAME="SolarNexus"
ENV REACT_APP_VERSION="1.0.0"
ENV GENERATE_SOURCEMAP=false

RUN npm run build

# Production stage - serve with nginx
FROM nginx:alpine AS production

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built React app
COPY --from=build /app/dist /usr/share/nginx/html

# Create non-root user
RUN addgroup -g 1001 -S nginx-user
RUN adduser -S nginx-user -u 1001 -G nginx-user

# Set permissions
RUN chown -R nginx-user:nginx-user /usr/share/nginx/html
RUN chown -R nginx-user:nginx-user /var/cache/nginx
RUN chown -R nginx-user:nginx-user /var/log/nginx
RUN chown -R nginx-user:nginx-user /etc/nginx/conf.d
RUN touch /var/run/nginx.pid
RUN chown -R nginx-user:nginx-user /var/run/nginx.pid

# Switch to non-root user
USER nginx-user

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]