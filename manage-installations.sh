#!/bin/bash

# Nexus Green Installation Management Script
# Handles installation, removal, and cleanup of all SolarNexus/Nexus Green instances
# Version: 4.0.0
# Last Updated: 2024-09-14

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="4.0.0"
REPO_URL="https://github.com/Reshigan/SolarNexus.git"
NEW_REPO_URL="https://github.com/Reshigan/NexusGreen.git"
PRODUCTION_TAG="v4.0.0-production"

# Common installation paths to check
COMMON_PATHS=(
    "/opt/solarnexus"
    "/opt/nexus-green"
    "/opt/SolarNexus"
    "/opt/NexusGreen"
    "/var/www/solarnexus"
    "/var/www/nexus-green"
    "/home/*/solarnexus"
    "/home/*/SolarNexus"
    "/home/*/nexus-green"
    "/home/*/NexusGreen"
    "/usr/local/solarnexus"
    "/usr/local/nexus-green"
    "~/solarnexus"
    "~/SolarNexus"
    "~/nexus-green"
    "~/NexusGreen"
)

# Docker container and image names to check
DOCKER_CONTAINERS=(
    "solarnexus"
    "nexus-green"
    "solarnexus-frontend"
    "solarnexus-backend"
    "solarnexus-db"
    "solarnexus-redis"
    "nexus-green-frontend"
    "nexus-green-backend"
    "nexus-green-db"
    "nexus-green-redis"
)

DOCKER_IMAGES=(
    "solarnexus"
    "nexus-green"
    "solarnexus-frontend"
    "solarnexus-backend"
    "nexus-green-frontend"
    "nexus-green-backend"
)

# System services to check
SYSTEM_SERVICES=(
    "solarnexus"
    "nexus-green"
    "solarnexus-frontend"
    "solarnexus-backend"
    "nexus-green-frontend"
    "nexus-green-backend"
)

# Nginx configurations to check
NGINX_CONFIGS=(
    "/etc/nginx/sites-available/solarnexus"
    "/etc/nginx/sites-available/nexus-green"
    "/etc/nginx/sites-available/nexus.gonxt.tech"
    "/etc/nginx/sites-enabled/solarnexus"
    "/etc/nginx/sites-enabled/nexus-green"
    "/etc/nginx/sites-enabled/nexus.gonxt.tech"
    "/etc/nginx/conf.d/solarnexus.conf"
    "/etc/nginx/conf.d/nexus-green.conf"
)

# SSL certificates to check
SSL_PATHS=(
    "/etc/letsencrypt/live/nexus.gonxt.tech"
    "/etc/nginx/ssl/nexus.gonxt.tech*"
    "/etc/ssl/certs/nexus.gonxt.tech*"
    "/etc/ssl/private/nexus.gonxt.tech*"
)

# Database names to check
DATABASE_NAMES=(
    "solarnexus"
    "nexus_green"
    "nexusgreen"
    "solar_nexus"
)

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. Some operations may require elevated privileges."
    fi
}

# Display banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 NEXUS GREEN INSTALLATION MANAGER             ║"
    echo "║                        Version $SCRIPT_VERSION                        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Comprehensive SolarNexus/Nexus Green Installation Manager  ║"
    echo "║  • Clean installation of latest version                     ║"
    echo "║  • Complete removal of existing installations               ║"
    echo "║  • System cleanup and optimization                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Scan for existing installations
scan_installations() {
    log "Scanning system for existing SolarNexus/Nexus Green installations..."
    
    local found_installations=()
    
    # Check file system paths
    info "Checking common installation paths..."
    for path in "${COMMON_PATHS[@]}"; do
        # Expand wildcards and home directory
        expanded_paths=$(eval echo "$path" 2>/dev/null || echo "$path")
        for expanded_path in $expanded_paths; do
            if [[ -d "$expanded_path" ]]; then
                found_installations+=("DIR: $expanded_path")
                warning "Found installation directory: $expanded_path"
            fi
        done
    done
    
    # Check Docker containers
    info "Checking Docker containers..."
    if command -v docker &> /dev/null; then
        for container in "${DOCKER_CONTAINERS[@]}"; do
            if docker ps -a --format "table {{.Names}}" | grep -q "^$container$" 2>/dev/null; then
                found_installations+=("DOCKER_CONTAINER: $container")
                warning "Found Docker container: $container"
            fi
        done
        
        # Check Docker images
        for image in "${DOCKER_IMAGES[@]}"; do
            if docker images --format "table {{.Repository}}" | grep -q "^$image$" 2>/dev/null; then
                found_installations+=("DOCKER_IMAGE: $image")
                warning "Found Docker image: $image"
            fi
        done
    fi
    
    # Check system services
    info "Checking system services..."
    for service in "${SYSTEM_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service" 2>/dev/null; then
            found_installations+=("SERVICE: $service")
            warning "Found system service: $service"
        fi
    done
    
    # Check Nginx configurations
    info "Checking Nginx configurations..."
    for config in "${NGINX_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            found_installations+=("NGINX: $config")
            warning "Found Nginx config: $config"
        fi
    done
    
    # Check processes
    info "Checking running processes..."
    if pgrep -f "solarnexus\|nexus-green" > /dev/null 2>&1; then
        local processes=$(pgrep -f "solarnexus\|nexus-green" | wc -l)
        found_installations+=("PROCESSES: $processes running")
        warning "Found $processes running processes related to SolarNexus/Nexus Green"
    fi
    
    # Check databases
    info "Checking databases..."
    if command -v psql &> /dev/null; then
        for db in "${DATABASE_NAMES[@]}"; do
            if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db"; then
                found_installations+=("DATABASE: $db")
                warning "Found PostgreSQL database: $db"
            fi
        done
    fi
    
    # Check ports
    info "Checking common ports..."
    local common_ports=(3000 8080 5432 6379 80 443)
    for port in "${common_ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; then
            local process=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | head -1)
            if [[ "$process" == *"solarnexus"* ]] || [[ "$process" == *"nexus-green"* ]]; then
                found_installations+=("PORT: $port ($process)")
                warning "Found service on port $port: $process"
            fi
        fi
    done
    
    # Summary
    if [[ ${#found_installations[@]} -eq 0 ]]; then
        success "No existing SolarNexus/Nexus Green installations found."
        return 0
    else
        echo ""
        error "Found ${#found_installations[@]} existing installation(s):"
        for installation in "${found_installations[@]}"; do
            echo -e "  ${RED}•${NC} $installation"
        done
        echo ""
        return 1
    fi
}

# Remove existing installations
remove_installations() {
    log "Starting complete removal of all SolarNexus/Nexus Green installations..."
    
    # Stop all related processes
    info "Stopping all related processes..."
    pkill -f "solarnexus\|nexus-green" 2>/dev/null || true
    
    # Stop and remove Docker containers
    info "Stopping and removing Docker containers..."
    if command -v docker &> /dev/null; then
        for container in "${DOCKER_CONTAINERS[@]}"; do
            if docker ps -a --format "table {{.Names}}" | grep -q "^$container$" 2>/dev/null; then
                log "Stopping and removing Docker container: $container"
                docker stop "$container" 2>/dev/null || true
                docker rm "$container" 2>/dev/null || true
            fi
        done
        
        # Remove Docker images
        for image in "${DOCKER_IMAGES[@]}"; do
            if docker images --format "table {{.Repository}}" | grep -q "^$image$" 2>/dev/null; then
                log "Removing Docker image: $image"
                docker rmi "$image" 2>/dev/null || true
            fi
        done
        
        # Remove Docker volumes
        log "Removing related Docker volumes..."
        docker volume ls -q | grep -E "(solarnexus|nexus-green)" | xargs -r docker volume rm 2>/dev/null || true
        
        # Remove Docker networks
        log "Removing related Docker networks..."
        docker network ls --format "table {{.Name}}" | grep -E "(solarnexus|nexus-green)" | xargs -r docker network rm 2>/dev/null || true
    fi
    
    # Stop and disable system services
    info "Stopping and disabling system services..."
    for service in "${SYSTEM_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service" 2>/dev/null; then
            log "Stopping and disabling service: $service"
            sudo systemctl stop "$service" 2>/dev/null || true
            sudo systemctl disable "$service" 2>/dev/null || true
            sudo rm -f "/etc/systemd/system/$service.service" 2>/dev/null || true
        fi
    done
    
    # Reload systemd
    sudo systemctl daemon-reload 2>/dev/null || true
    
    # Remove installation directories
    info "Removing installation directories..."
    for path in "${COMMON_PATHS[@]}"; do
        expanded_paths=$(eval echo "$path" 2>/dev/null || echo "$path")
        for expanded_path in $expanded_paths; do
            if [[ -d "$expanded_path" ]]; then
                log "Removing directory: $expanded_path"
                sudo rm -rf "$expanded_path" 2>/dev/null || true
            fi
        done
    done
    
    # Remove Nginx configurations
    info "Removing Nginx configurations..."
    for config in "${NGINX_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            log "Removing Nginx config: $config"
            sudo rm -f "$config"
        fi
    done
    
    # Reload Nginx if it's running
    if systemctl is-active --quiet nginx 2>/dev/null; then
        log "Reloading Nginx configuration..."
        sudo nginx -t && sudo systemctl reload nginx 2>/dev/null || true
    fi
    
    # Remove SSL certificates (optional - ask user)
    read -p "Remove SSL certificates for nexus.gonxt.tech? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Removing SSL certificates..."
        for ssl_path in "${SSL_PATHS[@]}"; do
            sudo rm -rf $ssl_path 2>/dev/null || true
        done
        
        # Remove from certbot if installed
        if command -v certbot &> /dev/null; then
            sudo certbot delete --cert-name nexus.gonxt.tech 2>/dev/null || true
        fi
    fi
    
    # Remove databases (optional - ask user)
    read -p "Remove databases? This will delete all data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Removing databases..."
        if command -v psql &> /dev/null; then
            for db in "${DATABASE_NAMES[@]}"; do
                if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db"; then
                    log "Dropping database: $db"
                    sudo -u postgres dropdb "$db" 2>/dev/null || true
                fi
            done
        fi
        
        # Remove Redis data
        if command -v redis-cli &> /dev/null; then
            log "Flushing Redis data..."
            redis-cli flushall 2>/dev/null || true
        fi
    fi
    
    # Clean up package manager installations
    info "Cleaning up package installations..."
    
    # Remove npm global packages
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 2>/dev/null | grep -E "(solarnexus|nexus-green)" | awk '{print $2}' | cut -d@ -f1 | xargs -r npm uninstall -g 2>/dev/null || true
    fi
    
    # Remove pip packages
    if command -v pip &> /dev/null; then
        pip list 2>/dev/null | grep -E "(solarnexus|nexus-green)" | awk '{print $1}' | xargs -r pip uninstall -y 2>/dev/null || true
    fi
    
    # Clean up logs
    info "Cleaning up log files..."
    sudo find /var/log -name "*solarnexus*" -o -name "*nexus-green*" -type f -delete 2>/dev/null || true
    
    # Clean up temporary files
    info "Cleaning up temporary files..."
    sudo find /tmp -name "*solarnexus*" -o -name "*nexus-green*" -type f -delete 2>/dev/null || true
    
    # Clean up user configurations
    info "Cleaning up user configurations..."
    find ~/.config -name "*solarnexus*" -o -name "*nexus-green*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    success "Complete removal finished!"
}

# Install fresh Nexus Green
install_nexus_green() {
    local install_path="${1:-/opt/nexus-green}"
    
    log "Starting fresh installation of Nexus Green v$SCRIPT_VERSION..."
    
    # Check dependencies
    info "Checking dependencies..."
    local deps=("git" "node" "npm")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            error "$dep is not installed. Please install it first."
            return 1
        fi
    done
    
    # Create installation directory
    log "Creating installation directory: $install_path"
    sudo mkdir -p "$install_path"
    sudo chown $USER:$USER "$install_path"
    
    # Clone repository
    log "Cloning Nexus Green repository..."
    if [[ -d "$install_path/.git" ]]; then
        cd "$install_path"
        git fetch origin
        git reset --hard origin/main
        git clean -fd
    else
        git clone "$REPO_URL" "$install_path"
        cd "$install_path"
    fi
    
    # Checkout production version
    log "Checking out production version: $PRODUCTION_TAG"
    git checkout "$PRODUCTION_TAG"
    
    # Install dependencies
    log "Installing Node.js dependencies..."
    npm ci --production
    
    # Build application
    log "Building application for production..."
    npm run build
    
    # Set up environment
    log "Setting up production environment..."
    if [[ -f ".env.production" ]]; then
        cp .env.production .env
        info "Production environment configuration applied"
    fi
    
    # Set permissions
    log "Setting proper permissions..."
    sudo chown -R $USER:$USER "$install_path"
    sudo chmod +x "$install_path/deploy-production.sh" 2>/dev/null || true
    sudo chmod +x "$install_path/manage-installations.sh" 2>/dev/null || true
    
    success "Fresh installation completed at: $install_path"
    
    # Display next steps
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Configure your environment variables in: $install_path/.env"
    echo "2. Set up your database and API endpoints"
    echo "3. Configure Nginx for your domain"
    echo "4. Run the deployment script: $install_path/deploy-production.sh"
    echo ""
    echo -e "${GREEN}Installation Path: $install_path${NC}"
    echo -e "${GREEN}Version: Nexus Green v$SCRIPT_VERSION${NC}"
    echo -e "${GREEN}Status: Ready for configuration${NC}"
}

# System cleanup
cleanup_system() {
    log "Performing system cleanup..."
    
    # Clean Docker system
    if command -v docker &> /dev/null; then
        info "Cleaning Docker system..."
        docker system prune -f 2>/dev/null || true
        docker volume prune -f 2>/dev/null || true
        docker network prune -f 2>/dev/null || true
    fi
    
    # Clean package caches
    info "Cleaning package caches..."
    if command -v apt &> /dev/null; then
        sudo apt autoremove -y 2>/dev/null || true
        sudo apt autoclean 2>/dev/null || true
    fi
    
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
    fi
    
    # Clean logs
    info "Cleaning old logs..."
    sudo journalctl --vacuum-time=7d 2>/dev/null || true
    
    success "System cleanup completed!"
}

# Backup existing installation
backup_installation() {
    local backup_dir="/opt/nexus-green-backups/manual-backup-$(date +%Y%m%d-%H%M%S)"
    
    log "Creating backup of existing installations..."
    
    sudo mkdir -p "$backup_dir"
    
    # Backup installation directories
    for path in "${COMMON_PATHS[@]}"; do
        expanded_paths=$(eval echo "$path" 2>/dev/null || echo "$path")
        for expanded_path in $expanded_paths; do
            if [[ -d "$expanded_path" ]]; then
                local dir_name=$(basename "$expanded_path")
                log "Backing up: $expanded_path"
                sudo cp -r "$expanded_path" "$backup_dir/$dir_name" 2>/dev/null || true
            fi
        done
    done
    
    # Backup databases
    if command -v pg_dump &> /dev/null; then
        for db in "${DATABASE_NAMES[@]}"; do
            if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db"; then
                log "Backing up database: $db"
                sudo -u postgres pg_dump "$db" > "$backup_dir/$db.sql" 2>/dev/null || true
            fi
        done
    fi
    
    # Backup Nginx configs
    sudo mkdir -p "$backup_dir/nginx"
    for config in "${NGINX_CONFIGS[@]}"; do
        if [[ -f "$config" ]]; then
            sudo cp "$config" "$backup_dir/nginx/" 2>/dev/null || true
        fi
    done
    
    success "Backup created at: $backup_dir"
}

# Show help
show_help() {
    echo -e "${CYAN}Nexus Green Installation Manager v$SCRIPT_VERSION${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  scan              Scan for existing installations"
    echo "  remove            Remove all existing installations"
    echo "  install [PATH]    Install fresh Nexus Green (default: /opt/nexus-green)"
    echo "  clean-install     Remove existing + install fresh"
    echo "  backup            Backup existing installations"
    echo "  cleanup           Clean up system (Docker, caches, logs)"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 scan                           # Scan for installations"
    echo "  $0 remove                         # Remove all installations"
    echo "  $0 install                        # Install to /opt/nexus-green"
    echo "  $0 install /var/www/nexus-green   # Install to custom path"
    echo "  $0 clean-install                  # Complete clean installation"
    echo "  $0 backup                         # Backup before changes"
    echo ""
    echo "Options:"
    echo "  --force           Skip confirmation prompts"
    echo "  --no-backup       Skip backup creation"
    echo "  --verbose         Show detailed output"
    echo ""
}

# Main function
main() {
    show_banner
    check_root
    
    local command="${1:-help}"
    local install_path="${2:-/opt/nexus-green}"
    
    case "$command" in
        "scan")
            scan_installations
            ;;
        "remove")
            if scan_installations; then
                info "No installations found to remove."
            else
                echo ""
                read -p "Remove all found installations? This cannot be undone! (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_installations
                    cleanup_system
                else
                    info "Removal cancelled."
                fi
            fi
            ;;
        "install")
            install_nexus_green "$install_path"
            ;;
        "clean-install")
            log "Starting clean installation process..."
            
            # Backup first
            if ! scan_installations; then
                read -p "Create backup before removal? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    backup_installation
                fi
                
                # Remove existing
                echo ""
                read -p "Proceed with removal of existing installations? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_installations
                    cleanup_system
                else
                    error "Clean installation cancelled."
                    exit 1
                fi
            fi
            
            # Install fresh
            echo ""
            install_nexus_green "$install_path"
            ;;
        "backup")
            backup_installation
            ;;
        "cleanup")
            cleanup_system
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo -e "\n${RED}Script interrupted!${NC}"; exit 1' INT TERM

# Run main function with all arguments
main "$@"