#!/bin/bash

# SolarNexus Auto-Upgrade System
# Monitors git repository for updates and automatically upgrades the system
# Version: 1.0

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
PROJECT_DIR="${PROJECT_DIR:-/opt/solarnexus}"
LOG_FILE="${LOG_FILE:-/var/log/solarnexus/updater.log}"
LOCK_FILE="/var/run/solarnexus-updater.lock"
CHECK_INTERVAL=300  # 5 minutes
REPO_URL="https://github.com/Reshigan/SolarNexus.git"
WEBHOOK_PORT=9876
DAEMON_MODE=false
FORCE_UPDATE=false
DRY_RUN=false

# Function to print colored output
print_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "UPDATE")
            echo -e "${PURPLE}[UPDATE]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "WEBHOOK")
            echo -e "${CYAN}[WEBHOOK]${NC} $message" | tee -a "$LOG_FILE"
            ;;
    esac
    
    # Also log to syslog
    logger -t solarnexus-updater "[$level] $message"
}

# Function to create lock file
create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            print_log "WARNING" "Another updater instance is running (PID: $pid)"
            return 1
        else
            print_log "INFO" "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    return 0
}

# Function to remove lock file
remove_lock() {
    rm -f "$LOCK_FILE"
}

# Cleanup on exit
cleanup() {
    print_log "INFO" "Cleaning up..."
    remove_lock
    # Kill webhook server if running
    if [ ! -z "$WEBHOOK_PID" ]; then
        kill "$WEBHOOK_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup EXIT INT TERM

# Function to check for git updates
check_for_updates() {
    cd "$PROJECT_DIR"
    
    # Fetch latest changes
    git fetch origin main 2>/dev/null || {
        print_log "ERROR" "Failed to fetch from remote repository"
        return 1
    }
    
    # Get current and remote commit hashes
    local current_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse origin/main)
    
    if [ "$current_commit" != "$remote_commit" ]; then
        print_log "UPDATE" "New updates available!"
        print_log "INFO" "Current: $current_commit"
        print_log "INFO" "Remote:  $remote_commit"
        
        # Get commit messages for the update
        local commit_messages=$(git log --oneline "$current_commit..$remote_commit" | head -5)
        print_log "INFO" "Recent changes:"
        echo "$commit_messages" | while read line; do
            print_log "INFO" "  - $line"
        done
        
        return 0
    else
        print_log "INFO" "No updates available"
        return 1
    fi
}

# Function to perform the upgrade
perform_upgrade() {
    print_log "UPDATE" "Starting upgrade process..."
    
    if [ "$DRY_RUN" = true ]; then
        print_log "INFO" "DRY RUN: Would perform upgrade but not actually doing it"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    
    # Create backup
    local backup_dir="/opt/solarnexus-backup/auto-backup-$(date +%Y%m%d_%H%M%S)"
    print_log "INFO" "Creating backup at $backup_dir"
    mkdir -p "$backup_dir"
    cp -r "$PROJECT_DIR" "$backup_dir/" || {
        print_log "ERROR" "Failed to create backup"
        return 1
    }
    
    # Stop services gracefully
    print_log "INFO" "Stopping services..."
    docker-compose down --timeout 30 || {
        print_log "WARNING" "Failed to stop services gracefully, forcing stop..."
        docker-compose kill
        docker-compose rm -f
    }
    
    # Pull latest changes
    print_log "INFO" "Pulling latest changes..."
    git reset --hard origin/main || {
        print_log "ERROR" "Failed to pull latest changes"
        return 1
    }
    
    # Clean up old images and containers
    print_log "INFO" "Cleaning up old Docker resources..."
    docker system prune -f --volumes || true
    
    # Rebuild and start services
    print_log "INFO" "Rebuilding and starting services..."
    docker-compose build --no-cache || {
        print_log "ERROR" "Failed to build services"
        return 1
    }
    
    docker-compose up -d || {
        print_log "ERROR" "Failed to start services"
        return 1
    }
    
    # Wait for services to be ready
    print_log "INFO" "Waiting for services to be ready..."
    sleep 30
    
    # Health check
    local max_attempts=12
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost/health > /dev/null 2>&1; then
            print_log "SUCCESS" "Services are healthy after upgrade"
            break
        else
            print_log "INFO" "Health check attempt $attempt/$max_attempts failed, waiting..."
            sleep 10
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_log "ERROR" "Services failed health check after upgrade"
        print_log "INFO" "Service status:"
        docker-compose ps | tee -a "$LOG_FILE"
        print_log "INFO" "Service logs:"
        docker-compose logs --tail=20 | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Run database migrations if needed
    print_log "INFO" "Running database migrations..."
    docker-compose exec -T backend npm run migrate:prod 2>/dev/null || {
        print_log "WARNING" "Database migration failed or not needed"
    }
    
    print_log "SUCCESS" "Upgrade completed successfully!"
    
    # Send notification (if configured)
    send_notification "SolarNexus upgraded successfully to $(git rev-parse --short HEAD)"
    
    return 0
}

# Function to send notifications (placeholder for future implementation)
send_notification() {
    local message="$1"
    print_log "INFO" "Notification: $message"
    
    # Future: Add email, Slack, Discord, or other notification methods
    # Example:
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"$message\"}" \
    #   "$SLACK_WEBHOOK_URL" 2>/dev/null || true
}

# Function to start webhook server
start_webhook_server() {
    print_log "WEBHOOK" "Starting webhook server on port $WEBHOOK_PORT"
    
    # Simple webhook server using netcat
    while true; do
        {
            echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"
            print_log "WEBHOOK" "Received webhook trigger"
            
            # Trigger update check
            if check_for_updates; then
                perform_upgrade &
            fi
        } | nc -l -p "$WEBHOOK_PORT" -q 1
        
        sleep 1
    done &
    
    WEBHOOK_PID=$!
    print_log "WEBHOOK" "Webhook server started with PID $WEBHOOK_PID"
}

# Function to run in daemon mode
run_daemon() {
    print_log "INFO" "Starting SolarNexus Auto-Updater daemon"
    print_log "INFO" "Check interval: ${CHECK_INTERVAL}s"
    print_log "INFO" "Project directory: $PROJECT_DIR"
    print_log "INFO" "Log file: $LOG_FILE"
    
    # Start webhook server
    start_webhook_server
    
    # Main daemon loop
    while true; do
        if check_for_updates; then
            perform_upgrade
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Function to show usage
show_usage() {
    cat << EOF
SolarNexus Auto-Upgrade System

Usage: $0 [OPTIONS]

Options:
    --daemon            Run in daemon mode (continuous monitoring)
    --check             Check for updates once and exit
    --upgrade           Force upgrade regardless of git status
    --dry-run           Show what would be done without actually doing it
    --webhook-only      Only run webhook server (no polling)
    --interval SECONDS  Set check interval for daemon mode (default: 300)
    --port PORT         Set webhook port (default: 9876)
    --help              Show this help message

Examples:
    $0 --daemon                    # Run as daemon with polling and webhook
    $0 --check                     # Check for updates once
    $0 --upgrade --dry-run         # Show what upgrade would do
    $0 --webhook-only --port 8080  # Only webhook server on port 8080

Environment Variables:
    PROJECT_DIR         Project directory (default: /opt/solarnexus)
    LOG_FILE           Log file path (default: /var/log/solarnexus/updater.log)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --daemon)
            DAEMON_MODE=true
            shift
            ;;
        --check)
            if check_for_updates; then
                echo "Updates available"
                exit 0
            else
                echo "No updates available"
                exit 1
            fi
            ;;
        --upgrade)
            FORCE_UPDATE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --webhook-only)
            WEBHOOK_ONLY=true
            shift
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        --port)
            WEBHOOK_PORT="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Ensure we're running as root
if [[ $EUID -ne 0 ]]; then
    print_log "ERROR" "This script must be run as root"
    exit 1
fi

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Create lock file
if ! create_lock; then
    exit 1
fi

# Ensure project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_log "ERROR" "Project directory $PROJECT_DIR does not exist"
    exit 1
fi

# Ensure it's a git repository
if [ ! -d "$PROJECT_DIR/.git" ]; then
    print_log "ERROR" "$PROJECT_DIR is not a git repository"
    exit 1
fi

print_log "INFO" "SolarNexus Auto-Updater starting..."
print_log "INFO" "PID: $$"

# Main execution
if [ "$WEBHOOK_ONLY" = true ]; then
    start_webhook_server
    wait
elif [ "$FORCE_UPDATE" = true ]; then
    perform_upgrade
elif [ "$DAEMON_MODE" = true ]; then
    run_daemon
else
    # Default: check once
    if check_for_updates; then
        perform_upgrade
    fi
fi

print_log "INFO" "SolarNexus Auto-Updater finished"