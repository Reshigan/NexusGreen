#!/bin/bash

# NexusGreen Production Deployment Script for AWS t4g.medium
# Optimized for ARM64 architecture with memory constraints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Reshigan/NexusGreen.git"
REPO_DIR="NexusGreen"
COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="nexusgreen"
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"

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

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running on ARM64
    if [ "$(uname -m)" != "aarch64" ]; then
        log_warning "Not running on ARM64 architecture. This script is optimized for AWS t4g.medium instances."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check available memory
    AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$AVAILABLE_MEM" -lt 1024 ]; then
        log_warning "Available memory is less than 1GB. Build may fail on t4g.medium instances."
    fi
    
    log_success "System requirements check passed"
}

clone_or_update_repo() {
    log_info "Setting up NexusGreen repository..."
    
    # If running as root, switch to ubuntu user for git operations
    if [ "$EUID" -eq 0 ]; then
        log_info "Running as root, switching to ubuntu user for git operations..."
        if id "ubuntu" &>/dev/null; then
            # Create directory as ubuntu user
            sudo -u ubuntu mkdir -p "$(dirname "$REPO_DIR")"
            
            if [ -d "$REPO_DIR" ]; then
                log_info "Repository exists, updating..."
                cd "$REPO_DIR"
                sudo -u ubuntu git fetch origin
                sudo -u ubuntu git reset --hard origin/main
                sudo -u ubuntu git clean -fd
                log_success "Repository updated to latest version"
            else
                log_info "Cloning repository from $REPO_URL..."
                sudo -u ubuntu git clone "$REPO_URL" "$REPO_DIR"
                cd "$REPO_DIR"
                log_success "Repository cloned successfully"
            fi
        else
            log_error "Running as root but ubuntu user not found. Please run without sudo."
            exit 1
        fi
    else
        if [ -d "$REPO_DIR" ]; then
            log_info "Repository exists, updating..."
            cd "$REPO_DIR"
            git fetch origin
            git reset --hard origin/main
            git clean -fd
            log_success "Repository updated to latest version"
        else
            log_info "Cloning repository from $REPO_URL..."
            git clone "$REPO_URL" "$REPO_DIR"
            cd "$REPO_DIR"
            log_success "Repository cloned successfully"
        fi
    fi
    
    # Update compose file path to be relative to repo directory
    COMPOSE_FILE="$PWD/docker-compose.yml"
    BACKUP_DIR="$PWD/backups/$(date +%Y%m%d_%H%M%S)"
    
    log_info "Working directory: $PWD"
    log_info "Compose file: $COMPOSE_FILE"
}

cleanup_old_containers() {
    log_info "Cleaning up old containers and images..."
    
    # Stop and remove existing containers (if compose file exists)
    if [ -f "$COMPOSE_FILE" ]; then
        docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down --remove-orphans 2>/dev/null || true
    else
        # Fallback: stop containers by name pattern
        docker stop nexus-green nexus-api nexus-db 2>/dev/null || true
        docker rm nexus-green nexus-api nexus-db 2>/dev/null || true
    fi
    
    # Remove unused images to free up space
    docker image prune -f
    
    # Remove unused volumes (be careful with this in production)
    docker volume prune -f
    
    log_success "Cleanup completed"
}

backup_database() {
    log_info "Creating database backup..."
    
    # Check if database container exists and is running
    if docker ps -q -f name=nexus-db | grep -q .; then
        log_info "Database container found, creating backup..."
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        docker exec nexus-db pg_dump -U nexususer nexusgreen > "$BACKUP_DIR/database_backup.sql" 2>/dev/null || {
            log_warning "Database backup failed or database is empty"
        }
    else
        log_info "No existing database container found, skipping backup"
    fi
}

build_and_deploy() {
    log_info "Building and deploying NexusGreen..."
    
    # Set memory limits for build process
    export NODE_OPTIONS="--max-old-space-size=3072"
    export DOCKER_BUILDKIT=1
    export BUILDKIT_PROGRESS=plain
    
    log_info "Memory optimization: NODE_OPTIONS=$NODE_OPTIONS"
    
    # Build with memory optimization
    log_info "Building containers (this may take several minutes on ARM64)..."
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" build --no-cache --parallel
    
    # Start services
    log_info "Starting services..."
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    log_success "Deployment completed"
}

wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    # Wait for database
    log_info "Waiting for database..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec -T nexus-db pg_isready -U nexususer -d nexusgreen &>/dev/null; then
            log_success "Database is ready"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        log_error "Database failed to start within 60 seconds"
        return 1
    fi
    
    # Wait for API
    log_info "Waiting for API..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost:3001/health &>/dev/null; then
            log_success "API is ready"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        log_error "API failed to start within 60 seconds"
        return 1
    fi
    
    # Wait for frontend
    log_info "Waiting for frontend..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost/health &>/dev/null; then
            log_success "Frontend is ready"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        log_error "Frontend failed to start within 60 seconds"
        return 1
    fi
    
    log_success "All services are ready"
}

show_status() {
    log_info "Deployment Status:"
    echo "===================="
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    echo ""
    
    log_info "Service URLs:"
    echo "Frontend: http://localhost"
    echo "API: http://localhost:3001"
    echo "Database: localhost:5432 (internal only)"
    echo ""
    
    log_info "Memory Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
}

# Main execution
main() {
    log_info "Starting NexusGreen deployment for AWS t4g.medium..."
    log_info "Script version: $(date '+%Y-%m-%d %H:%M:%S')"
    
    check_requirements
    clone_or_update_repo
    backup_database
    cleanup_old_containers
    build_and_deploy
    
    if wait_for_services; then
        show_status
        log_success "NexusGreen deployment completed successfully!"
        log_info "You can now access the application at http://localhost"
    else
        log_error "Deployment failed - services did not start properly"
        log_info "Check logs with: docker compose -f $COMPOSE_FILE -p $PROJECT_NAME logs"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "clean")
        log_info "Performing clean deployment..."
        cleanup_old_containers
        docker system prune -af
        main
        ;;
    "logs")
        docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f
        ;;
    "status")
        show_status
        ;;
    "stop")
        log_info "Stopping NexusGreen..."
        docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
        log_success "NexusGreen stopped"
        ;;
    "restart")
        log_info "Restarting NexusGreen..."
        docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" restart
        wait_for_services
        show_status
        ;;
    *)
        main
        ;;
esac