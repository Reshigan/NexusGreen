#!/bin/bash

# NexusGreen Production Update Script
# This script updates the production deployment with the latest changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
REPO_DIR="NexusGreen"
COMPOSE_FILE="docker-compose.prod.yml"
PROJECT_NAME="nexusgreen"
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"

main() {
    log_info "Starting NexusGreen production update..."
    log_info "Update started at: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Check if we're in the right directory
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "docker-compose.prod.yml not found. Please run this script from the NexusGreen directory."
        exit 1
    fi
    
    # Create backup directory
    log_info "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    log_info "Creating database backup..."
    if docker ps -q -f name=nexus-db | grep -q .; then
        docker exec nexus-db pg_dump -U nexus_user nexusgreen_db > "$BACKUP_DIR/database_backup.sql" 2>/dev/null || {
            log_warning "Database backup failed or database is empty"
        }
        log_success "Database backup created"
    else
        log_warning "No database container found, skipping backup"
    fi
    
    # Pull latest changes
    log_info "Pulling latest changes from repository..."
    git fetch origin
    git pull origin production-deployment-ssl-setup
    log_success "Repository updated"
    
    # Stop services
    log_info "Stopping current services..."
    docker-compose -f "$COMPOSE_FILE" down
    log_success "Services stopped"
    
    # Remove old images to free space
    log_info "Cleaning up old Docker images..."
    docker image prune -f
    
    # Build new images
    log_info "Building updated application..."
    export NODE_OPTIONS="--max-old-space-size=3072"
    export DOCKER_BUILDKIT=1
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    log_success "Application built successfully"
    
    # Start services
    log_info "Starting updated services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    log_success "Services started"
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    # Check service status
    log_info "Checking service status..."
    docker-compose -f "$COMPOSE_FILE" ps
    
    # Test application
    log_info "Testing application..."
    if curl -f http://localhost:8080 &>/dev/null; then
        log_success "Frontend is responding"
    else
        log_error "Frontend is not responding"
    fi
    
    if curl -f http://localhost:3001/api/health &>/dev/null; then
        log_success "API is responding"
    else
        log_error "API is not responding"
    fi
    
    # Show final status
    log_info "Final deployment status:"
    echo "===================="
    docker-compose -f "$COMPOSE_FILE" ps
    echo ""
    
    log_success "Production update completed successfully!"
    log_info "Application should be available at: https://nexus.gonxt.tech"
    log_info "Backup created at: $BACKUP_DIR"
    
    # Show recent logs
    log_info "Recent application logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=10
}

# Handle script arguments
case "${1:-}" in
    "logs")
        docker-compose -f "$COMPOSE_FILE" logs -f
        ;;
    "status")
        docker-compose -f "$COMPOSE_FILE" ps
        ;;
    "rollback")
        log_info "Rolling back to previous version..."
        docker-compose -f "$COMPOSE_FILE" down
        git reset --hard HEAD~1
        docker-compose -f "$COMPOSE_FILE" up -d --build
        log_success "Rollback completed"
        ;;
    *)
        main
        ;;
esac