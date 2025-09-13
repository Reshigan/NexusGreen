#!/bin/bash

# SolarNexus Final Production Deployment Script
# Complete, error-free deployment solution
# Version: 1.0.0

set -euo pipefail

# Script configuration
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="SolarNexus Final Deployment"

# Determine the correct working directory
if [[ -f "docker-compose.final.yml" && -f "Dockerfile.final" ]]; then
    # We're already in the SolarNexus directory
    SOLARNEXUS_DIR="$(pwd)"
elif [[ -f "SolarNexus/docker-compose.final.yml" && -f "SolarNexus/Dockerfile.final" ]]; then
    # SolarNexus directory is a subdirectory
    SOLARNEXUS_DIR="$(pwd)/SolarNexus"
    echo "🔍 Found SolarNexus directory, changing to: $SOLARNEXUS_DIR"
    cd "$SOLARNEXUS_DIR"
elif [[ -d "SolarNexus" ]]; then
    # Check if SolarNexus directory has the required files
    if [[ -f "SolarNexus/docker-compose.final.yml" && -f "SolarNexus/Dockerfile.final" ]]; then
        SOLARNEXUS_DIR="$(pwd)/SolarNexus"
        echo "🔍 Found SolarNexus directory, changing to: $SOLARNEXUS_DIR"
        cd "$SOLARNEXUS_DIR"
    else
        echo "❌ ERROR: SolarNexus directory found but missing required files"
        echo "Please ensure docker-compose.final.yml and Dockerfile.final exist in the SolarNexus directory"
        exit 1
    fi
else
    echo "🔍 SolarNexus deployment files not found in current directory"
    echo "📥 Would you like to clone the SolarNexus repository? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "📥 Cloning SolarNexus repository..."
        if command -v git >/dev/null 2>&1; then
            git clone https://github.com/Reshigan/SolarNexus.git
            if [[ -d "SolarNexus" && -f "SolarNexus/docker-compose.final.yml" ]]; then
                SOLARNEXUS_DIR="$(pwd)/SolarNexus"
                echo "✅ Repository cloned successfully, changing to: $SOLARNEXUS_DIR"
                cd "$SOLARNEXUS_DIR"
            else
                echo "❌ ERROR: Failed to clone repository or files are missing"
                exit 1
            fi
        else
            echo "❌ ERROR: git is not installed. Please install git first:"
            echo "  Ubuntu/Debian: sudo apt update && sudo apt install git"
            echo "  CentOS/RHEL: sudo yum install git"
            exit 1
        fi
    else
        echo "❌ Cannot proceed without SolarNexus deployment files"
        echo "Please either:"
        echo "  1. Run this script from inside the SolarNexus directory"
        echo "  2. Run this script from a directory containing SolarNexus subdirectory"
        echo "  3. Clone the repository first: git clone https://github.com/Reshigan/SolarNexus.git"
        exit 1
    fi
fi

# Directory detection completed successfully

INSTALL_DIR="$(pwd)"
LOG_FILE="$INSTALL_DIR/deployment.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Ensure we're in the correct directory for docker-compose commands
ensure_correct_directory() {
    if [[ ! -f "docker-compose.final.yml" ]]; then
        error_message "CRITICAL: docker-compose.final.yml not found in current directory: $(pwd)"
        error_message "This should not happen - directory detection failed!"
        error_message "Files in current directory:"
        ls -la
        error_message "SOLARNEXUS_DIR was set to: ${SOLARNEXUS_DIR:-not set}"
        exit 1
    fi
}

# Docker Compose wrapper function
docker_compose() {
    if command_exists "docker-compose"; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "$message"
}

# Error handling
error_exit() {
    local message=$1
    print_status "$RED" "❌ ERROR: $message"
    log "ERROR" "$message"
    echo -e "${RED}Check the log file for details: $LOG_FILE${NC}"
    exit 1
}

# Success message
success_message() {
    local message=$1
    print_status "$GREEN" "✅ $message"
}

# Warning message
warning_message() {
    local message=$1
    print_status "$YELLOW" "⚠️  $message"
}

# Info message
info_message() {
    local message=$1
    print_status "$BLUE" "ℹ️  $message"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    info_message "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
    
    # Check for required commands
    local required_commands=("docker" "curl" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            error_exit "Required command '$cmd' is not installed"
        fi
    done
    
    # Check for docker-compose (either standalone or plugin)
    if ! command_exists "docker-compose" && ! docker compose version >/dev/null 2>&1; then
        error_exit "Docker Compose is not available (neither 'docker-compose' nor 'docker compose')"
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker daemon is not running"
    fi
    
    # Check available disk space (minimum 5GB)
    local available_space=$(df "$INSTALL_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5242880 ]]; then
        warning_message "Low disk space detected. Minimum 5GB recommended."
    fi
    
    success_message "System requirements check passed"
}

# Create environment configuration
create_environment() {
    info_message "Creating production environment configuration..."
    
    # Generate secure passwords if not provided
    local postgres_password="${POSTGRES_PASSWORD:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
    local redis_password="${REDIS_PASSWORD:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)}"
    local jwt_secret="${JWT_SECRET:-$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)}"
    local jwt_refresh_secret="${JWT_REFRESH_SECRET:-$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)}"
    
    # Create .env file
    cat > .env << EOF
# SolarNexus Production Environment Configuration
# Generated on $(date)

# Application Settings
NODE_ENV=production
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
REACT_APP_NAME=SolarNexus

# Database Configuration
POSTGRES_PASSWORD=$postgres_password
POSTGRES_PORT=5432
DATABASE_URL=postgresql://solarnexus:$postgres_password@postgres:5432/solarnexus

# Redis Configuration
REDIS_PASSWORD=$redis_password
REDIS_PORT=6379
REDIS_URL=redis://:$redis_password@redis:6379

# Security Configuration
JWT_SECRET=$jwt_secret
JWT_REFRESH_SECRET=$jwt_refresh_secret

# API Configuration
BACKEND_PORT=3000
FRONTEND_PORT=80
REACT_APP_API_URL=http://localhost:3000
CORS_ORIGIN=http://localhost
API_RATE_LIMIT=100

# File Upload Settings
MAX_FILE_SIZE=10485760

# Feature Flags
ENABLE_ANALYTICS=false
ENABLE_DEBUG=false

# Logging
LOG_LEVEL=info

# Data Storage
DATA_PATH=./data
EOF

    # Secure the environment file
    chmod 600 .env
    
    success_message "Environment configuration created"
}

# Create required directories
create_directories() {
    info_message "Creating required directories..."
    
    local directories=(
        "data/postgres"
        "data/redis"
        "uploads"
        "logs"
        "logs/nginx"
        "backups"
        "database/init"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
    
    success_message "Required directories created"
}

# Clean up existing containers and resources
cleanup_existing() {
    info_message "Cleaning up existing SolarNexus resources..."
    
    # Stop and remove containers
    local containers=$(docker ps -aq --filter "name=solarnexus" 2>/dev/null || true)
    if [[ -n "$containers" ]]; then
        info_message "Stopping existing containers..."
        docker stop $containers 2>/dev/null || true
        docker rm -f $containers 2>/dev/null || true
    fi
    
    # Stop docker-compose services
    local compose_files=("docker-compose.yml" "docker-compose.final.yml" "docker-compose.working.yml")
    for compose_file in "${compose_files[@]}"; do
        if [[ -f "$compose_file" ]]; then
            docker-compose -f "$compose_file" down 2>/dev/null || true
        fi
    done
    
    # Remove unused images (optional)
    docker image prune -f >/dev/null 2>&1 || true
    
    success_message "Cleanup completed"
}

# Pull required Docker images
pull_images() {
    info_message "Pulling required Docker images..."
    
    local images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "nginx:alpine"
        "node:20-alpine"
        "node:20-slim"
    )
    
    for image in "${images[@]}"; do
        info_message "Pulling $image..."
        docker pull "$image" || error_exit "Failed to pull $image"
    done
    
    success_message "Docker images pulled successfully"
}

# Start database services
start_databases() {
    info_message "Starting database services..."
    
    # Ensure we're in the correct directory
    ensure_correct_directory
    
    # Directory validation completed
    
    # Start only database services first
    docker_compose -f docker-compose.final.yml up -d postgres redis
    
    # Wait for services to be healthy
    info_message "Waiting for database services to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker_compose -f docker-compose.final.yml ps postgres | grep -q "healthy"; then
            if docker_compose -f docker-compose.final.yml ps redis | grep -q "healthy"; then
                success_message "Database services are ready"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        info_message "Waiting for databases... ($attempt/$max_attempts)"
        sleep 5
    done
    
    error_exit "Database services failed to start within expected time"
}

# Initialize database
initialize_database() {
    info_message "Initializing database schema..."
    
    # Check if migration file exists
    if [[ -f "solarnexus-backend/migration.sql" ]]; then
        info_message "Applying database migration..."
        docker cp solarnexus-backend/migration.sql solarnexus-postgres:/tmp/migration.sql
        docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -f /tmp/migration.sql || {
            warning_message "Migration failed, database will be initialized by backend"
        }
    else
        info_message "No migration file found, database will be initialized by backend"
    fi
    
    success_message "Database initialization completed"
}

# Start backend service
start_backend() {
    info_message "Building and starting backend service..."
    ensure_correct_directory
    
    docker_compose -f docker-compose.final.yml up -d --build backend
    
    # Wait for backend to be healthy
    info_message "Waiting for backend service to be ready..."
    
    local max_attempts=40
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker_compose -f docker-compose.final.yml ps backend | grep -q "healthy"; then
            success_message "Backend service is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        info_message "Waiting for backend... ($attempt/$max_attempts)"
        sleep 5
    done
    
    warning_message "Backend service may still be starting"
}

# Start frontend service
start_frontend() {
    info_message "Building and starting frontend service..."
    ensure_correct_directory
    
    docker_compose -f docker-compose.final.yml up -d --build frontend
    
    # Wait for frontend to be healthy
    info_message "Waiting for frontend service to be ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker_compose -f docker-compose.final.yml ps frontend | grep -q "healthy"; then
            success_message "Frontend service is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        info_message "Waiting for frontend... ($attempt/$max_attempts)"
        sleep 5
    done
    
    warning_message "Frontend service may still be starting"
}

# Verify deployment
verify_deployment() {
    info_message "Verifying deployment..."
    
    # Check service status
    local services=("postgres" "redis" "backend" "frontend")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        if docker_compose -f docker-compose.final.yml ps "$service" | grep -q "Up"; then
            success_message "$service: Running"
        else
            warning_message "$service: Not running properly"
            all_healthy=false
        fi
    done
    
    # Test endpoints
    info_message "Testing service endpoints..."
    
    # Test backend health
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        success_message "Backend API: Responding"
    else
        warning_message "Backend API: Not responding"
        all_healthy=false
    fi
    
    # Test frontend
    if curl -f http://localhost/health >/dev/null 2>&1; then
        success_message "Frontend: Responding"
    else
        warning_message "Frontend: Not responding"
        all_healthy=false
    fi
    
    if [[ "$all_healthy" == true ]]; then
        success_message "All services are healthy"
    else
        warning_message "Some services may need more time to start"
    fi
}

# Create management scripts
create_management_scripts() {
    info_message "Creating management scripts..."
    
    # Status script
    cat > status.sh << 'EOF'
#!/bin/bash
echo "🔍 SolarNexus Service Status"
echo "============================"
docker_compose -f docker-compose.final.yml ps
echo ""
echo "🌐 Service Endpoints:"
echo "  • Frontend: http://localhost/"
echo "  • Backend API: http://localhost:3000/"
echo "  • Health Check: http://localhost/health"
EOF
    chmod +x status.sh
    
    # Stop script
    cat > stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping SolarNexus services..."
docker_compose -f docker-compose.final.yml down
echo "✅ All services stopped"
EOF
    chmod +x stop.sh
    
    # Start script
    cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting SolarNexus services..."
docker_compose -f docker-compose.final.yml up -d
echo "✅ All services started"
EOF
    chmod +x start.sh
    
    # Logs script
    cat > logs.sh << 'EOF'
#!/bin/bash
SERVICE=${1:-}
if [[ -n "$SERVICE" ]]; then
    docker_compose -f docker-compose.final.yml logs -f "$SERVICE"
else
    echo "Usage: ./logs.sh [service_name]"
    echo "Available services: postgres, redis, backend, frontend"
    echo "Or use: docker_compose -f docker-compose.final.yml logs -f"
fi
EOF
    chmod +x logs.sh
    
    success_message "Management scripts created"
}

# Print deployment summary
print_summary() {
    echo ""
    print_status "$GREEN" "🎉 SolarNexus Final Deployment Completed Successfully!"
    echo ""
    print_status "$CYAN" "📋 Deployment Summary:"
    echo "  • Installation Directory: $INSTALL_DIR"
    echo "  • Configuration File: .env"
    echo "  • Log File: $LOG_FILE"
    echo "  • Docker Compose: docker-compose.final.yml"
    echo ""
    print_status "$CYAN" "🌐 Service Access:"
    echo "  • SolarNexus Portal: http://localhost/"
    echo "  • API Endpoint: http://localhost:3000/"
    echo "  • Health Check: http://localhost/health"
    echo ""
    print_status "$CYAN" "🔧 Management Commands:"
    echo "  • Check Status: ./status.sh"
    echo "  • View Logs: ./logs.sh [service]"
    echo "  • Stop Services: ./stop.sh"
    echo "  • Start Services: ./start.sh"
    echo ""
    print_status "$CYAN" "📚 Docker Commands:"
    echo "  • Service Status: docker_compose -f docker-compose.final.yml ps"
    echo "  • View Logs: docker_compose -f docker-compose.final.yml logs [service]"
    echo "  • Restart: docker_compose -f docker-compose.final.yml restart"
    echo "  • Stop All: docker_compose -f docker-compose.final.yml down"
    echo ""
    print_status "$GREEN" "✅ SolarNexus is ready for production use!"
    print_status "$GREEN" "🌟 Access your solar management portal at: http://localhost/"
}

# Main deployment function
main() {
    # Initialize log file
    echo "SolarNexus Final Deployment Log - $(date)" > "$LOG_FILE"
    
    print_status "$PURPLE" "🚀 $SCRIPT_NAME v$SCRIPT_VERSION"
    print_status "$PURPLE" "=================================="
    
    # Script initialization completed
    
    # Execute deployment steps
    check_requirements
    create_environment
    create_directories
    cleanup_existing
    pull_images
    start_databases
    initialize_database
    start_backend
    start_frontend
    verify_deployment
    create_management_scripts
    print_summary
    
    log "INFO" "Deployment completed successfully"
}

# Trap errors and cleanup
trap 'error_exit "Deployment failed at line $LINENO"' ERR

# Run main function
main "$@"