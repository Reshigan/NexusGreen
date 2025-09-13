#!/bin/bash

# SolarNexus Monitoring Script
# Monitors system health and sends alerts
# Version: 1.0.0

set -euo pipefail

# Configuration
readonly LOG_FILE="/var/log/solarnexus/monitor.log"
readonly ALERT_EMAIL="${ALERT_EMAIL:-admin@localhost}"
readonly CHECK_INTERVAL="${CHECK_INTERVAL:-300}"  # 5 minutes
readonly SERVER_IP="13.245.249.110"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $1" | tee -a "$LOG_FILE"
}

# Send alert function
send_alert() {
    local subject="$1"
    local message="$2"
    
    # Log alert
    error "ALERT: $subject - $message"
    
    # Send email if mail is configured
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "SolarNexus Alert: $subject" "$ALERT_EMAIL"
    fi
    
    # Write to syslog
    logger -t solarnexus-monitor "ALERT: $subject - $message"
}

# Check service status
check_service() {
    local service="$1"
    local description="$2"
    
    if systemctl is-active --quiet "$service"; then
        log "✅ $description is running"
        return 0
    else
        send_alert "$description Down" "$description service is not running"
        return 1
    fi
}

# Check HTTP endpoint
check_http() {
    local url="$1"
    local description="$2"
    local timeout="${3:-10}"
    
    if curl -f -s --max-time "$timeout" "$url" >/dev/null 2>&1; then
        log "✅ $description is responding"
        return 0
    else
        send_alert "$description Unreachable" "$description is not responding at $url"
        return 1
    fi
}

# Check database connection
check_database() {
    if sudo -u postgres psql -d solarnexus -c "SELECT 1;" >/dev/null 2>&1; then
        log "✅ Database is accessible"
        return 0
    else
        send_alert "Database Down" "PostgreSQL database is not accessible"
        return 1
    fi
}

# Check Redis connection
check_redis() {
    if redis-cli ping >/dev/null 2>&1; then
        log "✅ Redis is responding"
        return 0
    else
        send_alert "Redis Down" "Redis server is not responding"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local threshold="${1:-90}"  # Default 90%
    local usage=$(df / | awk 'NR==2{print int($5)}')
    
    if [[ $usage -lt $threshold ]]; then
        log "✅ Disk usage: ${usage}%"
        return 0
    else
        send_alert "High Disk Usage" "Disk usage is at ${usage}% (threshold: ${threshold}%)"
        return 1
    fi
}

# Check memory usage
check_memory() {
    local threshold="${1:-90}"  # Default 90%
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [[ $usage -lt $threshold ]]; then
        log "✅ Memory usage: ${usage}%"
        return 0
    else
        send_alert "High Memory Usage" "Memory usage is at ${usage}% (threshold: ${threshold}%)"
        return 1
    fi
}

# Check CPU load
check_cpu_load() {
    local threshold="${1:-5.0}"  # Default load average of 5.0
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    if (( $(echo "$load < $threshold" | bc -l) )); then
        log "✅ CPU load: $load"
        return 0
    else
        send_alert "High CPU Load" "CPU load is at $load (threshold: $threshold)"
        return 1
    fi
}

# Check log file sizes
check_log_sizes() {
    local max_size_mb="${1:-100}"  # Default 100MB
    local log_dir="/var/log/solarnexus"
    
    find "$log_dir" -name "*.log" -size +${max_size_mb}M | while read -r logfile; do
        local size=$(du -m "$logfile" | cut -f1)
        warn "Large log file: $logfile (${size}MB)"
        
        # Rotate log if too large
        if [[ $size -gt $((max_size_mb * 2)) ]]; then
            mv "$logfile" "${logfile}.old"
            touch "$logfile"
            chown solarnexus:solarnexus "$logfile"
            log "Rotated large log file: $logfile"
        fi
    done
}

# Check SSL certificate expiry
check_ssl_expiry() {
    local domain="${1:-$SERVER_IP}"
    local days_threshold="${2:-30}"
    
    if command -v openssl >/dev/null 2>&1; then
        local expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
        
        if [[ -n "$expiry_date" ]]; then
            local expiry_epoch=$(date -d "$expiry_date" +%s)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [[ $days_until_expiry -gt $days_threshold ]]; then
                log "✅ SSL certificate expires in $days_until_expiry days"
            else
                send_alert "SSL Certificate Expiring" "SSL certificate for $domain expires in $days_until_expiry days"
            fi
        fi
    fi
}

# Generate system report
generate_report() {
    local report_file="/var/log/solarnexus/system-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
SolarNexus System Report
Generated: $(date)
Server: $SERVER_IP

=== System Information ===
Uptime: $(uptime)
Load Average: $(uptime | awk -F'load average:' '{print $2}')
Memory Usage: $(free -h)
Disk Usage: $(df -h /)

=== Service Status ===
Backend: $(systemctl is-active solarnexus-backend)
Frontend: $(systemctl is-active solarnexus-frontend)
PostgreSQL: $(systemctl is-active postgresql)
Redis: $(systemctl is-active redis-server)

=== Network Status ===
Backend API: $(curl -f -s http://localhost:5000/health && echo "OK" || echo "FAILED")
Frontend: $(curl -f -s http://localhost:3000/health && echo "OK" || echo "FAILED")

=== Recent Logs ===
Backend Errors (last 10):
$(journalctl -u solarnexus-backend --since "1 hour ago" -p err --no-pager -n 10)

Frontend Errors (last 10):
$(journalctl -u solarnexus-frontend --since "1 hour ago" -p err --no-pager -n 10)

=== Database Status ===
Active Connections: $(sudo -u postgres psql -d solarnexus -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "N/A")
Database Size: $(sudo -u postgres psql -d solarnexus -t -c "SELECT pg_size_pretty(pg_database_size('solarnexus'));" 2>/dev/null || echo "N/A")

=== Redis Status ===
Connected Clients: $(redis-cli info clients | grep connected_clients | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "N/A")
Memory Usage: $(redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "N/A")
EOF
    
    log "System report generated: $report_file"
}

# Main monitoring function
run_checks() {
    log "🔍 Starting system health checks..."
    
    local failed_checks=0
    
    # Service checks
    check_service "solarnexus-backend" "Backend Service" || ((failed_checks++))
    check_service "solarnexus-frontend" "Frontend Service" || ((failed_checks++))
    check_service "postgresql" "PostgreSQL" || ((failed_checks++))
    check_service "redis-server" "Redis" || ((failed_checks++))
    
    # Application checks
    check_http "http://localhost:5000/health" "Backend API" || ((failed_checks++))
    check_http "http://localhost:3000/health" "Frontend" || ((failed_checks++))
    check_database || ((failed_checks++))
    check_redis || ((failed_checks++))
    
    # System resource checks
    check_disk_space 85 || ((failed_checks++))
    check_memory 85 || ((failed_checks++))
    check_cpu_load 4.0 || ((failed_checks++))
    
    # Maintenance checks
    check_log_sizes 50
    check_ssl_expiry "$SERVER_IP" 30
    
    if [[ $failed_checks -eq 0 ]]; then
        log "✅ All health checks passed"
    else
        error "❌ $failed_checks health checks failed"
    fi
    
    log "🔍 Health checks completed"
}

# Continuous monitoring mode
monitor_continuous() {
    log "Starting continuous monitoring (interval: ${CHECK_INTERVAL}s)"
    
    while true; do
        run_checks
        
        # Generate daily report at midnight
        if [[ $(date +%H%M) == "0000" ]]; then
            generate_report
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --continuous    Run continuous monitoring"
    echo "  -r, --report        Generate system report"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ALERT_EMAIL         Email address for alerts (default: admin@localhost)"
    echo "  CHECK_INTERVAL      Check interval in seconds (default: 300)"
    echo ""
    echo "Examples:"
    echo "  $0                  Run single health check"
    echo "  $0 -c               Run continuous monitoring"
    echo "  $0 -r               Generate system report"
}

# Main function
main() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        -c|--continuous)
            monitor_continuous
            ;;
        -r|--report)
            generate_report
            ;;
        -h|--help)
            usage
            ;;
        "")
            run_checks
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"