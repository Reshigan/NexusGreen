#!/bin/bash

# Quick Nexus Green Installation Script
# This script will download and install Nexus Green v4.0.0
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
REPO_URL="https://github.com/Reshigan/NexusGreen.git"
PRODUCTION_TAG="v4.0.0-production"
DEFAULT_INSTALL_PATH="/opt/nexus-green"

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

# Display banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    NEXUS GREEN INSTALLER                     ║"
    echo "║                        Version 4.0.0                        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║           Quick Installation for Production Deployment      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check dependencies
check_dependencies() {
    log "Checking system dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    local required_commands=("git" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Install missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        warning "Missing dependencies: ${missing_deps[*]}"
        log "Installing missing dependencies..."
        
        if command -v apt &> /dev/null; then
            sudo apt update
            for dep in "${missing_deps[@]}"; do
                sudo apt install -y "$dep"
            done
        elif command -v yum &> /dev/null; then
            for dep in "${missing_deps[@]}"; do
                sudo yum install -y "$dep"
            done
        else
            error "Cannot install dependencies automatically. Please install: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    success "All dependencies are available"
}

# Clean up failed installation
cleanup_failed_install() {
    local install_path="$1"
    
    if [[ -d "$install_path" ]]; then
        warning "Cleaning up failed installation at: $install_path"
        sudo rm -rf "$install_path"
    fi
}

# Download and install Nexus Green
install_nexus_green() {
    local install_path="${1:-$DEFAULT_INSTALL_PATH}"
    
    log "Starting Nexus Green installation to: $install_path"
    
    # Clean up any existing failed installation
    cleanup_failed_install "$install_path"
    
    # Create parent directory if it doesn't exist
    local parent_dir=$(dirname "$install_path")
    if [[ ! -d "$parent_dir" ]]; then
        log "Creating parent directory: $parent_dir"
        sudo mkdir -p "$parent_dir"
    fi
    
    # Create installation directory with proper permissions
    log "Creating installation directory: $install_path"
    sudo mkdir -p "$install_path"
    sudo chown "$USER:$USER" "$install_path"
    
    # Change to a safe directory first
    cd /tmp
    
    # Clone repository to temporary location first
    local temp_dir="/tmp/nexus-green-$(date +%s)"
    log "Cloning repository to temporary location: $temp_dir"
    
    if ! git clone "$REPO_URL" "$temp_dir"; then
        error "Failed to clone repository"
        cleanup_failed_install "$install_path"
        exit 1
    fi
    
    # Move to installation directory
    log "Moving files to installation directory..."
    sudo mv "$temp_dir"/* "$install_path/" 2>/dev/null || true
    sudo mv "$temp_dir"/.* "$install_path/" 2>/dev/null || true
    sudo rm -rf "$temp_dir"
    
    # Change to installation directory
    cd "$install_path"
    
    # Checkout production version
    log "Checking out production version: $PRODUCTION_TAG"
    if ! git checkout "$PRODUCTION_TAG"; then
        warning "Could not checkout $PRODUCTION_TAG, using main branch"
        git checkout main
    fi
    
    # Set proper ownership
    sudo chown -R "$USER:$USER" "$install_path"
    
    # Make scripts executable
    if [[ -f "manage-installations.sh" ]]; then
        chmod +x manage-installations.sh
        success "Made manage-installations.sh executable"
    fi
    
    if [[ -f "deploy-production.sh" ]]; then
        chmod +x deploy-production.sh
        success "Made deploy-production.sh executable"
    fi
    
    success "Nexus Green installed successfully to: $install_path"
    
    # Display next steps
    echo ""
    echo -e "${CYAN}🎉 INSTALLATION COMPLETE! 🎉${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Navigate to installation directory:"
    echo -e "   ${GREEN}cd $install_path${NC}"
    echo ""
    echo "2. Install Node.js dependencies (if not already installed):"
    echo -e "   ${GREEN}curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -${NC}"
    echo -e "   ${GREEN}sudo apt-get install -y nodejs${NC}"
    echo ""
    echo "3. Install application dependencies:"
    echo -e "   ${GREEN}npm install${NC}"
    echo ""
    echo "4. Build the application:"
    echo -e "   ${GREEN}npm run build${NC}"
    echo ""
    echo "5. Configure environment:"
    echo -e "   ${GREEN}cp .env.production .env${NC}"
    echo -e "   ${GREEN}nano .env  # Edit configuration${NC}"
    echo ""
    echo "6. Run deployment script:"
    echo -e "   ${GREEN}./deploy-production.sh${NC}"
    echo ""
    echo -e "${BLUE}Available Management Commands:${NC}"
    echo -e "• ${GREEN}./manage-installations.sh scan${NC}     - Scan for existing installations"
    echo -e "• ${GREEN}./manage-installations.sh remove${NC}   - Remove all installations"
    echo -e "• ${GREEN}./manage-installations.sh backup${NC}   - Create backup"
    echo -e "• ${GREEN}./manage-installations.sh cleanup${NC}  - Clean system resources"
    echo ""
    echo -e "${GREEN}Installation Path: $install_path${NC}"
    echo -e "${GREEN}Version: Nexus Green v4.0.0${NC}"
    echo -e "${GREEN}Repository: $REPO_URL${NC}"
    echo ""
}

# Remove existing installations
remove_existing() {
    log "Scanning for existing installations..."
    
    local found_paths=()
    local common_paths=(
        "/opt/solarnexus"
        "/opt/nexus-green"
        "/opt/SolarNexus"
        "/opt/NexusGreen"
        "/var/www/solarnexus"
        "/var/www/nexus-green"
    )
    
    for path in "${common_paths[@]}"; do
        if [[ -d "$path" ]]; then
            found_paths+=("$path")
            warning "Found existing installation: $path"
        fi
    done
    
    if [[ ${#found_paths[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Found ${#found_paths[@]} existing installation(s):${NC}"
        for path in "${found_paths[@]}"; do
            echo -e "  ${RED}•${NC} $path"
        done
        echo ""
        
        read -p "Remove existing installations? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for path in "${found_paths[@]}"; do
                log "Removing: $path"
                sudo rm -rf "$path"
            done
            success "Existing installations removed"
        else
            info "Keeping existing installations"
        fi
    else
        info "No existing installations found"
    fi
}

# Install Node.js if not present
install_nodejs() {
    if ! command -v node &> /dev/null; then
        log "Node.js not found, installing..."
        
        if command -v apt &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs npm
        else
            warning "Please install Node.js 18+ manually"
            return 1
        fi
        
        success "Node.js installed successfully"
    else
        local node_version=$(node --version)
        info "Node.js already installed: $node_version"
    fi
}

# Show help
show_help() {
    echo -e "${CYAN}Nexus Green Quick Installer${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [PATH]"
    echo ""
    echo "Commands:"
    echo "  install [PATH]    Install Nexus Green (default: $DEFAULT_INSTALL_PATH)"
    echo "  clean-install     Remove existing + install fresh"
    echo "  remove            Remove existing installations only"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install                        # Install to $DEFAULT_INSTALL_PATH"
    echo "  $0 install /var/www/nexus-green   # Install to custom path"
    echo "  $0 clean-install                  # Remove existing + fresh install"
    echo "  $0 remove                         # Remove existing installations"
    echo ""
}

# Main function
main() {
    show_banner
    
    local command="${1:-install}"
    local install_path="${2:-$DEFAULT_INSTALL_PATH}"
    
    case "$command" in
        "install")
            check_dependencies
            install_nodejs
            install_nexus_green "$install_path"
            ;;
        "clean-install")
            check_dependencies
            remove_existing
            install_nodejs
            install_nexus_green "$install_path"
            ;;
        "remove")
            remove_existing
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
trap 'echo -e "\n${RED}Installation interrupted!${NC}"; exit 1' INT TERM

# Run main function with all arguments
main "$@"