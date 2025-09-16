#!/bin/bash

# =============================================================================
# NEXUS GREEN - DISABLE SSH ACCESS SCRIPT
# =============================================================================
# This script disables the SSH access setup for security after support is complete
# Usage: sudo ./disable-ssh-access.sh
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_status() {
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get the actual user (not root when using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" = "root" ]; then
    ACTUAL_USER="ubuntu"  # Default for AWS EC2
fi

echo ""
echo "================================================================================"
echo -e "${YELLOW}🔒 NEXUS GREEN - DISABLE SSH ACCESS${NC}"
echo "================================================================================"
echo ""

print_warning "This will disable remote SSH access keys for security."
echo -n "Are you sure you want to continue? (y/N): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled."
    exit 0
fi

print_status "Disabling SSH access for user: $ACTUAL_USER"

# =============================================================================
# STEP 1: REMOVE SUPPORT SSH KEYS
# =============================================================================

print_status "Step 1: Removing support SSH keys..."

USER_HOME="/home/$ACTUAL_USER"
if [ "$ACTUAL_USER" = "root" ]; then
    USER_HOME="/root"
fi

SSH_DIR="$USER_HOME/.ssh"
SUPPORT_KEY_NAME="nexus-support-key"
SUPPORT_KEY_PATH="$SSH_DIR/$SUPPORT_KEY_NAME"

# Remove support keys from authorized_keys
if [ -f "$SSH_DIR/authorized_keys" ]; then
    print_status "Removing support keys from authorized_keys..."
    # Remove lines containing nexus-support
    sed -i '/nexus-support@/d' "$SSH_DIR/authorized_keys"
    print_success "✅ Support keys removed from authorized_keys"
fi

# Remove the support key files
if [ -f "$SUPPORT_KEY_PATH" ]; then
    print_status "Removing private key file..."
    rm -f "$SUPPORT_KEY_PATH"
    print_success "✅ Private key file removed"
fi

if [ -f "$SUPPORT_KEY_PATH.pub" ]; then
    print_status "Removing public key file..."
    rm -f "$SUPPORT_KEY_PATH.pub"
    print_success "✅ Public key file removed"
fi

# =============================================================================
# STEP 2: RESTORE ORIGINAL SSH CONFIGURATION (OPTIONAL)
# =============================================================================

print_status "Step 2: SSH configuration options..."

echo -n "Restore original SSH configuration? (y/N): "
read -r restore_ssh

if [[ "$restore_ssh" =~ ^[Yy]$ ]]; then
    # Find the most recent backup
    BACKUP_FILE=$(ls -t /etc/ssh/sshd_config.backup.* 2>/dev/null | head -1)
    
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        print_status "Restoring SSH configuration from: $BACKUP_FILE"
        cp "$BACKUP_FILE" /etc/ssh/sshd_config
        
        # Test the configuration
        if sshd -t; then
            print_success "✅ Original SSH configuration restored"
            systemctl restart sshd
        else
            print_error "❌ Backup configuration is invalid, keeping current config"
        fi
    else
        print_warning "⚠️  No backup configuration found"
    fi
else
    print_status "Keeping current SSH configuration"
fi

# =============================================================================
# STEP 3: SECURITY CLEANUP OPTIONS
# =============================================================================

print_status "Step 3: Security cleanup options..."

# Option to disable password authentication
echo -n "Disable SSH password authentication for extra security? (y/N): "
read -r disable_password

if [[ "$disable_password" =~ ^[Yy]$ ]]; then
    print_status "Disabling SSH password authentication..."
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    
    # Test and restart SSH
    if sshd -t; then
        systemctl restart sshd
        print_success "✅ Password authentication disabled"
        print_warning "⚠️  Only key-based authentication is now allowed"
    else
        print_error "❌ SSH configuration error, password auth not disabled"
    fi
fi

# =============================================================================
# STEP 4: REMOVE ACCESS INFORMATION FILES
# =============================================================================

print_status "Step 4: Cleaning up access information files..."

ACCESS_INFO_FILE="$USER_HOME/nexus-ssh-access-info.txt"

if [ -f "$ACCESS_INFO_FILE" ]; then
    echo -n "Remove access information file? (y/N): "
    read -r remove_info
    
    if [[ "$remove_info" =~ ^[Yy]$ ]]; then
        # Securely delete the file (overwrite before deletion)
        shred -vfz -n 3 "$ACCESS_INFO_FILE" 2>/dev/null || rm -f "$ACCESS_INFO_FILE"
        print_success "✅ Access information file securely removed"
    else
        print_status "Access information file preserved"
    fi
fi

# =============================================================================
# STEP 5: FAIL2BAN STATUS
# =============================================================================

print_status "Step 5: Checking security services..."

# Check fail2ban status
if systemctl is-active --quiet fail2ban; then
    print_success "✅ Fail2ban is still protecting SSH"
    
    # Show current bans
    BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" | cut -d: -f2 | xargs)
    if [ -n "$BANNED_IPS" ] && [ "$BANNED_IPS" != "" ]; then
        print_status "Currently banned IPs: $BANNED_IPS"
    fi
else
    print_warning "⚠️  Fail2ban is not running"
fi

# =============================================================================
# STEP 6: FINAL VERIFICATION
# =============================================================================

print_status "Step 6: Final verification..."

# Check SSH service
if systemctl is-active --quiet sshd; then
    print_success "✅ SSH service is running"
else
    print_error "❌ SSH service is not running"
fi

# Check for remaining support keys
REMAINING_KEYS=$(grep -c "nexus-support@" "$SSH_DIR/authorized_keys" 2>/dev/null || echo "0")
if [ "$REMAINING_KEYS" -eq 0 ]; then
    print_success "✅ All support keys removed"
else
    print_warning "⚠️  $REMAINING_KEYS support keys still present"
fi

# Check SSH configuration
if sshd -t; then
    print_success "✅ SSH configuration is valid"
else
    print_error "❌ SSH configuration has errors"
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}🔒 SSH ACCESS SUCCESSFULLY DISABLED${NC}"
echo "================================================================================"
echo ""
echo -e "${BLUE}✅ Actions completed:${NC}"
echo "- Support SSH keys removed from authorized_keys"
echo "- Support key files deleted from server"
echo "- SSH service verified and running"
echo "- Fail2ban protection maintained"

if [[ "$restore_ssh" =~ ^[Yy]$ ]]; then
    echo "- Original SSH configuration restored"
fi

if [[ "$disable_password" =~ ^[Yy]$ ]]; then
    echo "- Password authentication disabled"
fi

if [[ "$remove_info" =~ ^[Yy]$ ]]; then
    echo "- Access information file securely removed"
fi

echo ""
echo -e "${YELLOW}📋 Security Status:${NC}"
echo "- Remote support SSH access is now disabled"
echo "- Regular SSH access remains available"
echo "- Firewall rules maintained for NexusGreen (ports 80, 443, 3001, 8080)"
echo "- Fail2ban continues protecting against brute force attacks"
echo ""
echo -e "${GREEN}🛡️  Your server SSH access is now secured.${NC}"
echo ""
echo -e "${BLUE}📋 Remaining SSH access methods:${NC}"
echo "- Your original SSH keys (if any)"
echo "- AWS EC2 key pair (if applicable)"
echo "- Password authentication (if not disabled)"
echo ""
echo "================================================================================"