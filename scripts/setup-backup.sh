#!/bin/bash

# SolarNexus Backup and Recovery Setup Script
# Implements comprehensive backup strategy for production data

set -e

echo "💾 SolarNexus Backup and Recovery Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Configuration
BACKUP_DIR="/opt/solarnexus/backups"
SCRIPTS_DIR="/opt/solarnexus/scripts"
LOG_DIR="/var/log/solarnexus"

echo -e "${BLUE}📁 Creating backup directory structure...${NC}"
mkdir -p "$BACKUP_DIR"/{database,files,configs,full-system}
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$LOG_DIR"
chmod 755 "$BACKUP_DIR" "$SCRIPTS_DIR" "$LOG_DIR"

# Create database backup script
echo -e "${BLUE}🗄️  Creating database backup script...${NC}"

cat > "$SCRIPTS_DIR/backup-database.sh" << 'EOF'
#!/bin/bash
# SolarNexus Database Backup Script

set -e

# Configuration
BACKUP_DIR="/opt/solarnexus/backups/database"
LOG_FILE="/var/log/solarnexus/backup-database.log"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="solarnexus_db_${DATE}.sql"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting database backup..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Perform database backup
log "Creating database dump..."
if docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > "${BACKUP_DIR}/${BACKUP_FILE}"; then
    log "Database dump created successfully: ${BACKUP_FILE}"
else
    log "ERROR: Database dump failed"
    exit 1
fi

# Compress backup
log "Compressing backup..."
if gzip "${BACKUP_DIR}/${BACKUP_FILE}"; then
    log "Backup compressed: ${BACKUP_FILE}.gz"
    BACKUP_FILE="${BACKUP_FILE}.gz"
else
    log "ERROR: Backup compression failed"
    exit 1
fi

# Verify backup integrity
log "Verifying backup integrity..."
if gunzip -t "${BACKUP_DIR}/${BACKUP_FILE}"; then
    log "Backup integrity verified"
else
    log "ERROR: Backup integrity check failed"
    exit 1
fi

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
log "Backup size: ${BACKUP_SIZE}"

# Clean up old backups
log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "$BACKUP_DIR" -name "solarnexus_db_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "solarnexus_db_*.sql.gz" | wc -l)
log "Remaining backups: ${REMAINING_BACKUPS}"

# Upload to cloud storage (if configured)
if [[ -n "$AWS_S3_BUCKET" ]]; then
    log "Uploading to S3..."
    if aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "s3://${AWS_S3_BUCKET}/database/"; then
        log "Backup uploaded to S3 successfully"
    else
        log "WARNING: S3 upload failed"
    fi
fi

log "Database backup completed successfully"

# Send notification email (if configured)
if [[ -n "$NOTIFICATION_EMAIL" ]]; then
    echo "SolarNexus database backup completed successfully on $(date)" | \
    mail -s "SolarNexus Backup Success" "$NOTIFICATION_EMAIL"
fi
EOF

chmod +x "$SCRIPTS_DIR/backup-database.sh"

# Create file backup script
echo -e "${BLUE}📄 Creating file backup script...${NC}"

cat > "$SCRIPTS_DIR/backup-files.sh" << 'EOF'
#!/bin/bash
# SolarNexus File Backup Script

set -e

# Configuration
BACKUP_DIR="/opt/solarnexus/backups/files"
LOG_FILE="/var/log/solarnexus/backup-files.log"
RETENTION_DAYS=14
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="solarnexus_files_${DATE}.tar.gz"

# Files and directories to backup
BACKUP_SOURCES=(
    "/workspace/project/PPA-Frontend"
    "/opt/solarnexus/secrets"
    "/opt/solarnexus/.env.production"
    "/etc/nginx/ssl"
    "/opt/solarnexus/monitoring"
)

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting file backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create file backup
log "Creating file archive..."
if tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" "${BACKUP_SOURCES[@]}" 2>/dev/null; then
    log "File archive created successfully: ${BACKUP_FILE}"
else
    log "ERROR: File archive creation failed"
    exit 1
fi

# Verify backup
log "Verifying backup integrity..."
if tar -tzf "${BACKUP_DIR}/${BACKUP_FILE}" > /dev/null; then
    log "Backup integrity verified"
else
    log "ERROR: Backup integrity check failed"
    exit 1
fi

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
log "Backup size: ${BACKUP_SIZE}"

# Clean up old backups
log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "$BACKUP_DIR" -name "solarnexus_files_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "solarnexus_files_*.tar.gz" | wc -l)
log "Remaining backups: ${REMAINING_BACKUPS}"

# Upload to cloud storage (if configured)
if [[ -n "$AWS_S3_BUCKET" ]]; then
    log "Uploading to S3..."
    if aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "s3://${AWS_S3_BUCKET}/files/"; then
        log "Backup uploaded to S3 successfully"
    else
        log "WARNING: S3 upload failed"
    fi
fi

log "File backup completed successfully"
EOF

chmod +x "$SCRIPTS_DIR/backup-files.sh"

# Create full system backup script
echo -e "${BLUE}🖥️  Creating full system backup script...${NC}"

cat > "$SCRIPTS_DIR/backup-full-system.sh" << 'EOF'
#!/bin/bash
# SolarNexus Full System Backup Script

set -e

# Configuration
BACKUP_DIR="/opt/solarnexus/backups/full-system"
LOG_FILE="/var/log/solarnexus/backup-full-system.log"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="solarnexus_full_${DATE}.tar.gz"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting full system backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Stop services for consistent backup
log "Stopping services for consistent backup..."
systemctl stop solarnexus-monitoring 2>/dev/null || true
docker stop solarnexus-backend solarnexus-frontend 2>/dev/null || true

# Create database dump
log "Creating database backup..."
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > "/tmp/solarnexus_full_db.sql"

# Create full system archive
log "Creating full system archive..."
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    --exclude="/tmp" \
    --exclude="/var/cache" \
    --exclude="/var/log" \
    --exclude="/proc" \
    --exclude="/sys" \
    --exclude="/dev" \
    --exclude="/run" \
    /workspace/project/PPA-Frontend \
    /opt/solarnexus \
    /etc/nginx/ssl \
    /tmp/solarnexus_full_db.sql \
    /etc/systemd/system/solarnexus* \
    /etc/cron.d/solarnexus* 2>/dev/null || true

# Clean up temporary files
rm -f /tmp/solarnexus_full_db.sql

# Restart services
log "Restarting services..."
docker start solarnexus-postgres solarnexus-redis 2>/dev/null || true
sleep 10
docker start solarnexus-backend solarnexus-frontend 2>/dev/null || true
systemctl start solarnexus-monitoring 2>/dev/null || true

# Verify backup
log "Verifying backup integrity..."
if tar -tzf "${BACKUP_DIR}/${BACKUP_FILE}" > /dev/null; then
    log "Backup integrity verified"
else
    log "ERROR: Backup integrity check failed"
    exit 1
fi

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
log "Backup size: ${BACKUP_SIZE}"

# Clean up old backups
log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "$BACKUP_DIR" -name "solarnexus_full_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "solarnexus_full_*.tar.gz" | wc -l)
log "Remaining backups: ${REMAINING_BACKUPS}"

log "Full system backup completed successfully"
EOF

chmod +x "$SCRIPTS_DIR/backup-full-system.sh"

# Create restore script
echo -e "${BLUE}🔄 Creating restore script...${NC}"

cat > "$SCRIPTS_DIR/restore-database.sh" << 'EOF'
#!/bin/bash
# SolarNexus Database Restore Script

set -e

# Configuration
BACKUP_DIR="/opt/solarnexus/backups/database"
LOG_FILE="/var/log/solarnexus/restore-database.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if backup file is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la "$BACKUP_DIR"/solarnexus_db_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [[ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
    log "ERROR: Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

log "Starting database restore from: $BACKUP_FILE"

# Confirm restore operation
read -p "⚠️  This will overwrite the current database. Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log "Restore operation cancelled"
    exit 0
fi

# Stop backend service
log "Stopping backend service..."
docker stop solarnexus-backend 2>/dev/null || true

# Create database backup before restore
log "Creating safety backup of current database..."
SAFETY_BACKUP="solarnexus_db_pre_restore_$(date +%Y%m%d_%H%M%S).sql"
docker exec solarnexus-postgres pg_dump -U solarnexus -d solarnexus > "${BACKUP_DIR}/${SAFETY_BACKUP}"
gzip "${BACKUP_DIR}/${SAFETY_BACKUP}"
log "Safety backup created: ${SAFETY_BACKUP}.gz"

# Drop and recreate database
log "Dropping and recreating database..."
docker exec solarnexus-postgres psql -U solarnexus -c "DROP DATABASE IF EXISTS solarnexus;"
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;"

# Restore database
log "Restoring database..."
if gunzip -c "$BACKUP_DIR/$BACKUP_FILE" | docker exec -i solarnexus-postgres psql -U solarnexus -d solarnexus; then
    log "Database restored successfully"
else
    log "ERROR: Database restore failed"
    exit 1
fi

# Restart backend service
log "Restarting backend service..."
docker start solarnexus-backend

# Wait for service to be ready
log "Waiting for backend service to be ready..."
sleep 30

# Verify restore
log "Verifying database restore..."
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    log "Database restore verified - backend is healthy"
else
    log "WARNING: Backend health check failed after restore"
fi

log "Database restore completed successfully"
EOF

chmod +x "$SCRIPTS_DIR/restore-database.sh"

# Create backup configuration file
echo -e "${BLUE}⚙️  Creating backup configuration...${NC}"

cat > "$SCRIPTS_DIR/backup-config.sh" << 'EOF'
#!/bin/bash
# SolarNexus Backup Configuration

# Backup retention (days)
export DB_RETENTION_DAYS=30
export FILES_RETENTION_DAYS=14
export FULL_SYSTEM_RETENTION_DAYS=7

# Cloud storage configuration (optional)
# export AWS_S3_BUCKET="solarnexus-backups"
# export AWS_ACCESS_KEY_ID="your_access_key"
# export AWS_SECRET_ACCESS_KEY="your_secret_key"
# export AWS_DEFAULT_REGION="us-east-1"

# Notification configuration (optional)
# export NOTIFICATION_EMAIL="admin@nexus.gonxt.tech"

# Backup directories
export BACKUP_BASE_DIR="/opt/solarnexus/backups"
export LOG_DIR="/var/log/solarnexus"

# Database configuration
export DB_CONTAINER="solarnexus-postgres"
export DB_USER="solarnexus"
export DB_NAME="solarnexus"
EOF

# Create backup scheduler
echo -e "${BLUE}📅 Setting up backup schedule...${NC}"

cat > /etc/cron.d/solarnexus-backups << 'EOF'
# SolarNexus Backup Schedule
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Daily database backup at 2:00 AM
0 2 * * * root /opt/solarnexus/scripts/backup-database.sh

# Daily file backup at 3:00 AM
0 3 * * * root /opt/solarnexus/scripts/backup-files.sh

# Weekly full system backup on Sunday at 4:00 AM
0 4 * * 0 root /opt/solarnexus/scripts/backup-full-system.sh

# Monthly backup verification on 1st day at 5:00 AM
0 5 1 * * root /opt/solarnexus/scripts/verify-backups.sh
EOF

# Create backup verification script
echo -e "${BLUE}✅ Creating backup verification script...${NC}"

cat > "$SCRIPTS_DIR/verify-backups.sh" << 'EOF'
#!/bin/bash
# SolarNexus Backup Verification Script

set -e

# Configuration
BACKUP_DIR="/opt/solarnexus/backups"
LOG_FILE="/var/log/solarnexus/verify-backups.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting backup verification..."

# Verify database backups
log "Verifying database backups..."
DB_BACKUPS=$(find "$BACKUP_DIR/database" -name "solarnexus_db_*.sql.gz" -mtime -7 | wc -l)
if [[ $DB_BACKUPS -gt 0 ]]; then
    log "✅ Found $DB_BACKUPS recent database backups"
    
    # Test latest backup integrity
    LATEST_DB_BACKUP=$(find "$BACKUP_DIR/database" -name "solarnexus_db_*.sql.gz" -mtime -1 | head -1)
    if [[ -n "$LATEST_DB_BACKUP" ]]; then
        if gunzip -t "$LATEST_DB_BACKUP"; then
            log "✅ Latest database backup integrity verified"
        else
            log "❌ Latest database backup integrity check failed"
        fi
    fi
else
    log "❌ No recent database backups found"
fi

# Verify file backups
log "Verifying file backups..."
FILE_BACKUPS=$(find "$BACKUP_DIR/files" -name "solarnexus_files_*.tar.gz" -mtime -7 | wc -l)
if [[ $FILE_BACKUPS -gt 0 ]]; then
    log "✅ Found $FILE_BACKUPS recent file backups"
    
    # Test latest backup integrity
    LATEST_FILE_BACKUP=$(find "$BACKUP_DIR/files" -name "solarnexus_files_*.tar.gz" -mtime -1 | head -1)
    if [[ -n "$LATEST_FILE_BACKUP" ]]; then
        if tar -tzf "$LATEST_FILE_BACKUP" > /dev/null; then
            log "✅ Latest file backup integrity verified"
        else
            log "❌ Latest file backup integrity check failed"
        fi
    fi
else
    log "❌ No recent file backups found"
fi

# Verify full system backups
log "Verifying full system backups..."
FULL_BACKUPS=$(find "$BACKUP_DIR/full-system" -name "solarnexus_full_*.tar.gz" -mtime -7 | wc -l)
if [[ $FULL_BACKUPS -gt 0 ]]; then
    log "✅ Found $FULL_BACKUPS recent full system backups"
else
    log "❌ No recent full system backups found"
fi

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Total backup size: $TOTAL_SIZE"

# Check disk space
AVAILABLE_SPACE=$(df -h "$BACKUP_DIR" | awk 'NR==2{print $4}')
log "Available disk space: $AVAILABLE_SPACE"

log "Backup verification completed"

# Send notification email (if configured)
if [[ -n "$NOTIFICATION_EMAIL" ]]; then
    {
        echo "SolarNexus Backup Verification Report - $(date)"
        echo "=============================================="
        echo ""
        echo "Database backups (last 7 days): $DB_BACKUPS"
        echo "File backups (last 7 days): $FILE_BACKUPS"
        echo "Full system backups (last 7 days): $FULL_BACKUPS"
        echo "Total backup size: $TOTAL_SIZE"
        echo "Available disk space: $AVAILABLE_SPACE"
        echo ""
        echo "For detailed logs, check: $LOG_FILE"
    } | mail -s "SolarNexus Backup Verification Report" "$NOTIFICATION_EMAIL"
fi
EOF

chmod +x "$SCRIPTS_DIR/verify-backups.sh"

# Create backup management script
echo -e "${BLUE}🎛️  Creating backup management script...${NC}"

cat > "$SCRIPTS_DIR/backup-manager.sh" << 'EOF'
#!/bin/bash
# SolarNexus Backup Manager

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="/opt/solarnexus/backups"
SCRIPTS_DIR="/opt/solarnexus/scripts"

show_menu() {
    echo -e "${BLUE}🎛️  SolarNexus Backup Manager${NC}"
    echo "================================"
    echo "1. Create database backup"
    echo "2. Create file backup"
    echo "3. Create full system backup"
    echo "4. List available backups"
    echo "5. Restore database"
    echo "6. Verify backups"
    echo "7. Clean old backups"
    echo "8. View backup logs"
    echo "9. Exit"
    echo ""
}

list_backups() {
    echo -e "${BLUE}📋 Available Backups:${NC}"
    echo ""
    
    echo -e "${GREEN}Database Backups:${NC}"
    ls -lah "$BACKUP_DIR/database/"*.gz 2>/dev/null | tail -10 || echo "No database backups found"
    
    echo -e "\n${GREEN}File Backups:${NC}"
    ls -lah "$BACKUP_DIR/files/"*.gz 2>/dev/null | tail -5 || echo "No file backups found"
    
    echo -e "\n${GREEN}Full System Backups:${NC}"
    ls -lah "$BACKUP_DIR/full-system/"*.gz 2>/dev/null | tail -3 || echo "No full system backups found"
}

clean_old_backups() {
    echo -e "${YELLOW}🧹 Cleaning old backups...${NC}"
    
    # Clean database backups older than 30 days
    find "$BACKUP_DIR/database" -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Clean file backups older than 14 days
    find "$BACKUP_DIR/files" -name "*.gz" -mtime +14 -delete 2>/dev/null || true
    
    # Clean full system backups older than 7 days
    find "$BACKUP_DIR/full-system" -name "*.gz" -mtime +7 -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Old backups cleaned${NC}"
}

view_logs() {
    echo -e "${BLUE}📝 Recent Backup Logs:${NC}"
    echo ""
    
    echo -e "${GREEN}Database Backup Log:${NC}"
    tail -20 /var/log/solarnexus/backup-database.log 2>/dev/null || echo "No database backup logs found"
    
    echo -e "\n${GREEN}File Backup Log:${NC}"
    tail -20 /var/log/solarnexus/backup-files.log 2>/dev/null || echo "No file backup logs found"
    
    echo -e "\n${GREEN}Full System Backup Log:${NC}"
    tail -20 /var/log/solarnexus/backup-full-system.log 2>/dev/null || echo "No full system backup logs found"
}

while true; do
    show_menu
    read -p "Select an option (1-9): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}Creating database backup...${NC}"
            "$SCRIPTS_DIR/backup-database.sh"
            ;;
        2)
            echo -e "${BLUE}Creating file backup...${NC}"
            "$SCRIPTS_DIR/backup-files.sh"
            ;;
        3)
            echo -e "${BLUE}Creating full system backup...${NC}"
            "$SCRIPTS_DIR/backup-full-system.sh"
            ;;
        4)
            list_backups
            ;;
        5)
            echo -e "${BLUE}Available database backups:${NC}"
            ls -1 "$BACKUP_DIR/database/"*.gz 2>/dev/null | xargs -n1 basename || echo "No backups found"
            read -p "Enter backup filename to restore: " backup_file
            "$SCRIPTS_DIR/restore-database.sh" "$backup_file"
            ;;
        6)
            echo -e "${BLUE}Verifying backups...${NC}"
            "$SCRIPTS_DIR/verify-backups.sh"
            ;;
        7)
            clean_old_backups
            ;;
        8)
            view_logs
            ;;
        9)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
EOF

chmod +x "$SCRIPTS_DIR/backup-manager.sh"

# Create systemd service for backup monitoring
echo -e "${BLUE}⚙️  Creating backup monitoring service...${NC}"

cat > /etc/systemd/system/solarnexus-backup-monitor.service << EOF
[Unit]
Description=SolarNexus Backup Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPTS_DIR/verify-backups.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable solarnexus-backup-monitor.service

# Set up log rotation for backup logs
echo -e "${BLUE}📝 Setting up log rotation...${NC}"

cat > /etc/logrotate.d/solarnexus-backups << 'EOF'
/var/log/solarnexus/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Create backup summary
echo -e "\n${GREEN}✅ Backup and Recovery Setup Complete!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   • Backup directory: $BACKUP_DIR"
echo "   • Scripts directory: $SCRIPTS_DIR"
echo "   • Log directory: $LOG_DIR"
echo "   • Backup manager: $SCRIPTS_DIR/backup-manager.sh"

echo -e "\n${BLUE}📅 Backup Schedule:${NC}"
echo "   • Database: Daily at 2:00 AM (30 days retention)"
echo "   • Files: Daily at 3:00 AM (14 days retention)"
echo "   • Full System: Weekly on Sunday at 4:00 AM (7 days retention)"
echo "   • Verification: Monthly on 1st day at 5:00 AM"

echo -e "\n${BLUE}🎛️  Management Commands:${NC}"
echo "   • Interactive manager: sudo $SCRIPTS_DIR/backup-manager.sh"
echo "   • Manual database backup: sudo $SCRIPTS_DIR/backup-database.sh"
echo "   • Manual file backup: sudo $SCRIPTS_DIR/backup-files.sh"
echo "   • Full system backup: sudo $SCRIPTS_DIR/backup-full-system.sh"
echo "   • Restore database: sudo $SCRIPTS_DIR/restore-database.sh <backup_file>"
echo "   • Verify backups: sudo $SCRIPTS_DIR/verify-backups.sh"

echo -e "\n${BLUE}📊 Monitoring:${NC}"
echo "   • Backup logs: /var/log/solarnexus/"
echo "   • Cron schedule: /etc/cron.d/solarnexus-backups"
echo "   • Service status: systemctl status solarnexus-backup-monitor"

echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
echo "   1. Configure cloud storage (AWS S3) in backup-config.sh"
echo "   2. Set up email notifications for backup reports"
echo "   3. Test backup and restore procedures"
echo "   4. Monitor backup logs regularly"
echo "   5. Verify backup integrity monthly"

echo -e "\n${GREEN}🎉 Backup and recovery system is ready!${NC}"