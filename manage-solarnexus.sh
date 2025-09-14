#!/bin/bash

# SolarNexus Management Script
# Comprehensive management tool for SolarNexus deployment, auto-startup, and auto-upgrade

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/opt/solarnexus"
LOG_DIR="/var/log/solarnexus"

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    SolarNexus Manager                       ║${NC}"
    echo -e "${CYAN}║              Solar Energy Management Platform               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status() {
    echo -e "${PURPLE}[STATUS]${NC} $1"
}

# Function to show system status
show_status() {
    print_header
    print_info "System Status Overview"
    echo ""
    
    # Docker Compose Services
    print_status "Docker Services:"
    if [ -d "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
        docker-compose ps 2>/dev/null || print_warning "Docker Compose not available"
    else
        print_warning "Project directory not found: $PROJECT_DIR"
    fi
    
    echo ""
    
    # Systemd Services
    print_status "System Services:"
    for service in solarnexus solarnexus-updater; do
        if systemctl is-active --quiet $service; then
            echo -e "  • $service: ${GREEN}Active${NC}"
        elif systemctl is-enabled --quiet $service 2>/dev/null; then
            echo -e "  • $service: ${YELLOW}Enabled but not running${NC}"
        else
            echo -e "  • $service: ${RED}Inactive${NC}"
        fi
    done
    
    echo ""
    
    # Auto-updater status
    print_status "Auto-Updater Status:"
    if systemctl is-active --quiet solarnexus-updater; then
        echo -e "  • Status: ${GREEN}Running${NC}"
        echo "  • Last check: $(journalctl -u solarnexus-updater --since "1 hour ago" | grep "No updates available" | tail -1 | awk '{print $1, $2, $3}' || echo "Unknown")"
    else
        echo -e "  • Status: ${RED}Not running${NC}"
    fi
    
    echo ""
    
    # Disk usage
    print_status "Disk Usage:"
    df -h "$PROJECT_DIR" 2>/dev/null | tail -1 | awk '{print "  • Project directory: " $3 " used, " $4 " available (" $5 " full)"}'
    
    # Memory usage
    print_status "Memory Usage:"
    free -h | grep "Mem:" | awk '{print "  • Memory: " $3 " used, " $7 " available"}'
    
    echo ""
    
    # Recent logs
    print_status "Recent Activity:"
    if [ -f "$LOG_DIR/updater.log" ]; then
        echo "  • Last updater activity:"
        tail -3 "$LOG_DIR/updater.log" 2>/dev/null | sed 's/^/    /' || echo "    No recent activity"
    else
        echo "  • No updater logs found"
    fi
}

# Function to manage services
manage_services() {
    local action=$1
    
    case $action in
        start)
            print_info "Starting SolarNexus services..."
            systemctl start solarnexus
            systemctl start solarnexus-updater
            print_success "Services started"
            ;;
        stop)
            print_info "Stopping SolarNexus services..."
            systemctl stop solarnexus-updater
            systemctl stop solarnexus
            print_success "Services stopped"
            ;;
        restart)
            print_info "Restarting SolarNexus services..."
            systemctl restart solarnexus
            systemctl restart solarnexus-updater
            print_success "Services restarted"
            ;;
        enable)
            print_info "Enabling SolarNexus services for auto-start..."
            systemctl enable solarnexus
            systemctl enable solarnexus-updater
            print_success "Services enabled for auto-start"
            ;;
        disable)
            print_info "Disabling SolarNexus auto-start..."
            systemctl disable solarnexus-updater
            systemctl disable solarnexus
            print_success "Auto-start disabled"
            ;;
        *)
            print_error "Invalid service action: $action"
            echo "Valid actions: start, stop, restart, enable, disable"
            exit 1
            ;;
    esac
}

# Function to check for updates
check_updates() {
    print_info "Checking for updates..."
    if [ -x "$PROJECT_DIR/auto-upgrade.sh" ]; then
        "$PROJECT_DIR/auto-upgrade.sh" --check
    else
        print_error "Auto-upgrade script not found or not executable"
        exit 1
    fi
}

# Function to perform manual upgrade
manual_upgrade() {
    local dry_run=$1
    
    if [ "$dry_run" = "--dry-run" ]; then
        print_info "Performing dry-run upgrade (no actual changes)..."
        "$PROJECT_DIR/auto-upgrade.sh" --upgrade --dry-run
    else
        print_warning "This will upgrade SolarNexus to the latest version."
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Performing upgrade..."
            "$PROJECT_DIR/auto-upgrade.sh" --upgrade
        else
            print_info "Upgrade cancelled"
        fi
    fi
}

# Function to view logs
view_logs() {
    local log_type=$1
    
    case $log_type in
        updater)
            print_info "Viewing auto-updater logs (press Ctrl+C to exit)..."
            journalctl -u solarnexus-updater -f
            ;;
        services)
            print_info "Viewing service logs (press Ctrl+C to exit)..."
            journalctl -u solarnexus -f
            ;;
        docker)
            print_info "Viewing Docker logs (press Ctrl+C to exit)..."
            if [ -d "$PROJECT_DIR" ]; then
                cd "$PROJECT_DIR"
                docker-compose logs -f
            else
                print_error "Project directory not found"
                exit 1
            fi
            ;;
        all)
            print_info "Viewing all logs (press Ctrl+C to exit)..."
            tail -f "$LOG_DIR"/*.log 2>/dev/null || print_warning "No log files found in $LOG_DIR"
            ;;
        *)
            print_error "Invalid log type: $log_type"
            echo "Valid types: updater, services, docker, all"
            exit 1
            ;;
    esac
}

# Function to setup GitHub webhook
setup_webhook() {
    local server_ip=$1
    local github_token=$2
    
    if [ -z "$server_ip" ] || [ -z "$github_token" ]; then
        print_error "Server IP and GitHub token are required"
        echo "Usage: $0 webhook <server-ip> <github-token>"
        exit 1
    fi
    
    if [ -x "$PROJECT_DIR/setup-github-webhook.sh" ]; then
        "$PROJECT_DIR/setup-github-webhook.sh" --server-ip "$server_ip" --token "$github_token"
    else
        print_error "GitHub webhook setup script not found"
        exit 1
    fi
}

# Function to show configuration
show_config() {
    print_header
    print_info "SolarNexus Configuration"
    echo ""
    
    print_status "Paths:"
    echo "  • Project Directory: $PROJECT_DIR"
    echo "  • Log Directory: $LOG_DIR"
    echo "  • Service Files: /etc/systemd/system/solarnexus*.service"
    
    echo ""
    print_status "Auto-Upgrade Settings:"
    if [ -f "$PROJECT_DIR/auto-upgrade.sh" ]; then
        echo "  • Script: $PROJECT_DIR/auto-upgrade.sh"
        echo "  • Check Interval: 5 minutes (300 seconds)"
        echo "  • Webhook Port: 9876"
        echo "  • Log File: $LOG_DIR/updater.log"
    else
        echo "  • Auto-upgrade not configured"
    fi
    
    echo ""
    print_status "Network Configuration:"
    local server_ip=$(hostname -I | awk '{print $1}')
    echo "  • Server IP: $server_ip"
    echo "  • Webhook URL: http://$server_ip:9876"
    echo "  • Application URL: https://$(hostname -f 2>/dev/null || echo $server_ip)"
    
    echo ""
    print_status "Firewall Status:"
    if command -v ufw >/dev/null 2>&1; then
        ufw status | grep -E "(Status|22|80|443|9876)" | sed 's/^/  • /'
    else
        echo "  • UFW not installed"
    fi
}

# Function to run health check
health_check() {
    print_header
    print_info "Running comprehensive health check..."
    echo ""
    
    local issues=0
    
    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory not found: $PROJECT_DIR"
        ((issues++))
    else
        print_success "Project directory exists"
    fi
    
    # Check if services are running
    for service in solarnexus solarnexus-updater; do
        if systemctl is-active --quiet $service; then
            print_success "Service $service is running"
        else
            print_error "Service $service is not running"
            ((issues++))
        fi
    done
    
    # Check Docker containers
    if [ -d "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
        local running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
        local total_containers=$(docker-compose ps --services 2>/dev/null | wc -l)
        
        if [ "$running_containers" -eq "$total_containers" ] && [ "$total_containers" -gt 0 ]; then
            print_success "All Docker containers are running ($running_containers/$total_containers)"
        else
            print_error "Some Docker containers are not running ($running_containers/$total_containers)"
            ((issues++))
        fi
    fi
    
    # Check web application
    if curl -f -s --max-time 10 http://localhost/health > /dev/null 2>&1; then
        print_success "Web application is responding"
    else
        print_warning "Web application health check failed"
        ((issues++))
    fi
    
    # Check disk space
    local disk_usage=$(df "$PROJECT_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        print_success "Disk usage is acceptable ($disk_usage%)"
    else
        print_warning "Disk usage is high ($disk_usage%)"
        ((issues++))
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        print_success "Health check passed! No issues found."
    else
        print_warning "Health check completed with $issues issue(s) found."
    fi
    
    return $issues
}

# Function to show usage
show_usage() {
    print_header
    cat << EOF
SolarNexus Management Tool

Usage: $0 <command> [options]

Commands:
    status              Show system status overview
    start               Start all SolarNexus services
    stop                Stop all SolarNexus services
    restart             Restart all SolarNexus services
    enable              Enable auto-start on boot
    disable             Disable auto-start on boot
    
    check-updates       Check for available updates
    upgrade             Perform manual upgrade
    upgrade --dry-run   Show what upgrade would do
    
    logs <type>         View logs (types: updater, services, docker, all)
    
    webhook <ip> <token> Setup GitHub webhook for auto-deployment
    
    config              Show current configuration
    health              Run comprehensive health check
    
    help                Show this help message

Examples:
    $0 status                                    # Show system status
    $0 restart                                   # Restart all services
    $0 logs updater                             # View auto-updater logs
    $0 upgrade --dry-run                        # Preview upgrade changes
    $0 webhook 1.2.3.4 ghp_xxxxxxxxxxxx        # Setup GitHub webhook
    $0 health                                   # Run health check

Service Management:
    systemctl status solarnexus                 # Check main service
    systemctl status solarnexus-updater         # Check auto-updater
    journalctl -u solarnexus-updater -f         # Follow updater logs

EOF
}

# Main execution
case "${1:-help}" in
    status)
        show_status
        ;;
    start|stop|restart|enable|disable)
        manage_services "$1"
        ;;
    check-updates)
        check_updates
        ;;
    upgrade)
        manual_upgrade "$2"
        ;;
    logs)
        view_logs "$2"
        ;;
    webhook)
        setup_webhook "$2" "$3"
        ;;
    config)
        show_config
        ;;
    health)
        health_check
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac