#!/bin/bash

# =============================================================================
# NEXUS GREEN - SSH ACCESS SETUP SCRIPT
# =============================================================================
# This script sets up secure SSH access for remote production deployment assistance
# Compatible with: Ubuntu 20.04+ on AWS EC2
# Usage: sudo ./setup-ssh-access.sh
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
echo -e "${GREEN}🔑 NEXUS GREEN - SSH ACCESS SETUP${NC}"
echo "================================================================================"
echo ""

print_status "Setting up SSH access for user: $ACTUAL_USER"

# =============================================================================
# STEP 1: SYSTEM UPDATES AND SSH CONFIGURATION
# =============================================================================

print_status "Step 1: Configuring SSH server..."

# Update system
apt update -y

# Install required packages
apt install -y openssh-server ufw fail2ban

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Configure SSH for security and convenience
cat > /etc/ssh/sshd_config << 'EOF'
# NexusGreen SSH Configuration for Remote Support
Port 22
Protocol 2

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Security settings
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10

# Allow specific users
AllowUsers ubuntu root

# Logging
SyslogFacility AUTH
LogLevel INFO
EOF

print_success "✅ SSH server configured"

# =============================================================================
# STEP 2: GENERATE SSH KEY PAIR FOR REMOTE SUPPORT
# =============================================================================

print_status "Step 2: Generating SSH key pair for remote support..."

# Create SSH directory for the user
USER_HOME="/home/$ACTUAL_USER"
if [ "$ACTUAL_USER" = "root" ]; then
    USER_HOME="/root"
fi

SSH_DIR="$USER_HOME/.ssh"
mkdir -p "$SSH_DIR"

# Generate a new SSH key pair specifically for remote support
SUPPORT_KEY_NAME="nexus-support-key"
SUPPORT_KEY_PATH="$SSH_DIR/$SUPPORT_KEY_NAME"

# Generate ED25519 key (more secure than RSA)
ssh-keygen -t ed25519 -f "$SUPPORT_KEY_PATH" -C "nexus-support@$(hostname)-$(date +%Y%m%d)" -N ""

print_success "✅ SSH key pair generated"

# =============================================================================
# STEP 3: CONFIGURE AUTHORIZED KEYS
# =============================================================================

print_status "Step 3: Configuring authorized keys..."

# Add the public key to authorized_keys
cat "$SUPPORT_KEY_PATH.pub" >> "$SSH_DIR/authorized_keys"

# Set proper permissions
chown -R $ACTUAL_USER:$ACTUAL_USER "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chmod 600 "$SUPPORT_KEY_PATH"
chmod 644 "$SUPPORT_KEY_PATH.pub"

print_success "✅ Authorized keys configured"

# =============================================================================
# STEP 4: CONFIGURE FIREWALL AND SECURITY
# =============================================================================

print_status "Step 4: Configuring firewall and security..."

# Enable UFW if not already enabled
ufw --force enable

# Allow SSH
ufw allow ssh
ufw allow 22

# Allow HTTP and HTTPS
ufw allow 80
ufw allow 443

# Allow NexusGreen application ports
ufw allow 3001  # API
ufw allow 8080  # Frontend

# Configure fail2ban for SSH protection
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

# Start and enable fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

print_success "✅ Firewall and security configured"

# =============================================================================
# STEP 5: RESTART SSH SERVICE
# =============================================================================

print_status "Step 5: Restarting SSH service..."

# Test SSH configuration
sshd -t || {
    print_error "SSH configuration test failed!"
    exit 1
}

# Restart SSH service
systemctl restart sshd
systemctl enable sshd

print_success "✅ SSH service restarted"

# =============================================================================
# STEP 6: GET SERVER INFORMATION
# =============================================================================

print_status "Step 6: Gathering server information..."

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to determine public IP")

# Get private IP
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Get SSH port
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")

print_success "✅ Server information gathered"

# =============================================================================
# STEP 7: CREATE ACCESS INFORMATION
# =============================================================================

print_status "Step 7: Creating access information..."

# Create comprehensive access information file
ACCESS_INFO_FILE="$USER_HOME/nexus-ssh-access-info.txt"

cat > "$ACCESS_INFO_FILE" << EOF
================================================================================
NEXUS GREEN - SSH ACCESS INFORMATION
================================================================================
Generated: $(date)
Server: $(hostname)
User: $ACTUAL_USER

🌐 SERVER CONNECTION INFO:
Public IP:     $PUBLIC_IP
Private IP:    $PRIVATE_IP
SSH Port:      $SSH_PORT
SSH User:      $ACTUAL_USER

🔑 SSH ACCESS METHODS:

Method 1 - Using Private Key (Most Secure):
-------------------------------------------
1. Copy the private key from this server:
   $SUPPORT_KEY_PATH

2. Save it on your local machine as: nexus-support-key

3. Set proper permissions:
   chmod 600 nexus-support-key

4. Connect using:
   ssh -i nexus-support-key $ACTUAL_USER@$PUBLIC_IP

Method 2 - Password Authentication:
----------------------------------
ssh $ACTUAL_USER@$PUBLIC_IP
(You'll be prompted for the user password)

Method 3 - AWS EC2 Key Pair (if available):
-------------------------------------------
ssh -i your-aws-key.pem $ACTUAL_USER@$PUBLIC_IP

🔧 SSH CONFIGURATION FOR EASY ACCESS:
Add this to your local ~/.ssh/config file:

Host nexus-production
    HostName $PUBLIC_IP
    User $ACTUAL_USER
    IdentityFile ~/.ssh/nexus-support-key
    Port $SSH_PORT
    ServerAliveInterval 60
    ServerAliveCountMax 2

Then connect with: ssh nexus-production

🚀 NEXUS GREEN APPLICATION:
Frontend:      http://$PUBLIC_IP:8080
API:           http://$PUBLIC_IP:3001
API Health:    http://$PUBLIC_IP:3001/api/health

📋 USEFUL COMMANDS FOR REMOTE SUPPORT:
- Navigate to project:    cd ~/NexusGreen
- Run deployment:         sudo ./ultimate-clean-install.sh
- Check Docker status:    docker ps
- View application logs:  docker-compose logs -f
- Check system status:    systemctl status
- Monitor resources:      htop
- Check firewall:         sudo ufw status

🔒 SECURITY FEATURES:
- SSH key-based authentication enabled
- Fail2ban protection against brute force attacks
- Firewall configured with necessary ports only
- Root login disabled for security
- Connection timeout configured

🛡️ SECURITY NOTES:
- Private key provides passwordless access
- Keep the private key secure and delete after support
- Monitor SSH access logs: sudo tail -f /var/log/auth.log
- Fail2ban will block repeated failed login attempts

📞 SUPPORT WORKFLOW:
1. Share this access information with support
2. Support connects via SSH using provided methods
3. Support runs deployment and troubleshooting commands
4. Monitor progress and verify fixes
5. Revoke access when support is complete

🚨 TO REVOKE ACCESS AFTER SUPPORT:
# Remove the support key from authorized_keys
sed -i '/nexus-support@/d' ~/.ssh/authorized_keys

# Or run the disable script:
sudo ./disable-ssh-access.sh

================================================================================
PRIVATE KEY CONTENT (COPY THIS TO YOUR LOCAL MACHINE):
================================================================================
EOF

# Add the private key content to the file
echo "" >> "$ACCESS_INFO_FILE"
cat "$SUPPORT_KEY_PATH" >> "$ACCESS_INFO_FILE"
echo "" >> "$ACCESS_INFO_FILE"

echo "================================================================================
PUBLIC KEY (FOR REFERENCE):
================================================================================" >> "$ACCESS_INFO_FILE"
cat "$SUPPORT_KEY_PATH.pub" >> "$ACCESS_INFO_FILE"

# Set proper ownership
chown $ACTUAL_USER:$ACTUAL_USER "$ACCESS_INFO_FILE"
chmod 600 "$ACCESS_INFO_FILE"

print_success "✅ Access information created"

# =============================================================================
# STEP 8: FINAL VERIFICATION
# =============================================================================

print_status "Step 8: Final verification..."

# Check if SSH service is running
if systemctl is-active --quiet sshd; then
    print_success "✅ SSH service is running"
else
    print_error "❌ SSH service failed to start"
    systemctl status sshd
fi

# Check if fail2ban is running
if systemctl is-active --quiet fail2ban; then
    print_success "✅ Fail2ban is running"
else
    print_warning "⚠️  Fail2ban may not be running properly"
fi

# Test SSH key
if [ -f "$SUPPORT_KEY_PATH" ] && [ -f "$SUPPORT_KEY_PATH.pub" ]; then
    print_success "✅ SSH key pair created successfully"
else
    print_error "❌ SSH key pair creation failed"
fi

# Test SSH configuration
if sshd -t; then
    print_success "✅ SSH configuration is valid"
else
    print_error "❌ SSH configuration has errors"
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}🎉 NEXUS GREEN SSH ACCESS SETUP COMPLETE!${NC}"
echo "================================================================================"
echo ""
echo -e "${BLUE}📋 CONNECTION INFORMATION:${NC}"
echo -e "Server IP:    ${YELLOW}$PUBLIC_IP${NC}"
echo -e "SSH User:     ${YELLOW}$ACTUAL_USER${NC}"
echo -e "SSH Port:     ${YELLOW}$SSH_PORT${NC}"
echo ""
echo -e "${BLUE}🔑 QUICK CONNECT COMMANDS:${NC}"
echo -e "With key:     ${YELLOW}ssh -i nexus-support-key $ACTUAL_USER@$PUBLIC_IP${NC}"
echo -e "With password: ${YELLOW}ssh $ACTUAL_USER@$PUBLIC_IP${NC}"
echo ""
echo -e "${BLUE}📁 Full access details:${NC} $ACCESS_INFO_FILE"
echo ""
echo -e "${GREEN}✅ Ready for secure SSH-based remote support!${NC}"
echo ""
echo -e "${YELLOW}🔒 SECURITY REMINDERS:${NC}"
echo "- Private key provides passwordless access"
echo "- Share access information securely"
echo "- Monitor SSH access logs during support"
echo "- Revoke access after support is complete"
echo "- Keep the private key secure"
echo ""
echo "================================================================================"

# Display quick access info
echo ""
echo -e "${RED}🔑 IMPORTANT - PRIVATE KEY LOCATION:${NC}"
echo "Private key: $SUPPORT_KEY_PATH"
echo "Public key:  $SUPPORT_KEY_PATH.pub"
echo "Access info: $ACCESS_INFO_FILE"
echo ""