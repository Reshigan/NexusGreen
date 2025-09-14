#!/bin/bash

# Fix timezone issue in production deployment
# This script handles different Ubuntu configurations for timezone setup

echo "🔧 Fixing timezone configuration issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

print_status "Setting timezone to South Africa (SAST)..."

# Method 1: Use timedatectl (most common)
if command -v timedatectl &> /dev/null; then
    print_status "Using timedatectl to set timezone..."
    $SUDO timedatectl set-timezone Africa/Johannesburg
    
    # Try to restart systemd-timesyncd if it exists
    if systemctl list-unit-files | grep -q systemd-timesyncd; then
        print_status "Restarting systemd-timesyncd..."
        $SUDO systemctl restart systemd-timesyncd 2>/dev/null || print_warning "systemd-timesyncd restart failed (this is usually OK)"
    else
        print_warning "systemd-timesyncd not found, using alternative time sync"
        
        # Try to install and enable ntp as alternative
        if command -v apt &> /dev/null; then
            print_status "Installing ntp as alternative time synchronization..."
            $SUDO apt update
            $SUDO apt install -y ntp
            $SUDO systemctl enable ntp
            $SUDO systemctl start ntp
        fi
    fi
    
    # Verify timezone setting
    CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
    if [[ "$CURRENT_TZ" == "Africa/Johannesburg" ]]; then
        print_success "Timezone successfully set to South Africa (SAST)"
        print_status "Current time: $(date)"
    else
        print_error "Failed to set timezone properly"
        exit 1
    fi
    
# Method 2: Fallback to manual timezone setting
else
    print_status "timedatectl not available, using manual method..."
    
    # Set timezone manually
    $SUDO ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
    echo "Africa/Johannesburg" | $SUDO tee /etc/timezone > /dev/null
    
    # Update system time
    if command -v ntpdate &> /dev/null; then
        print_status "Synchronizing time with NTP..."
        $SUDO ntpdate -s time.nist.gov 2>/dev/null || print_warning "NTP sync failed"
    fi
    
    print_success "Timezone manually set to South Africa (SAST)"
    print_status "Current time: $(date)"
fi

# Verify the timezone is correct
print_status "Timezone verification:"
echo "System timezone: $(cat /etc/timezone 2>/dev/null || echo 'Not set in /etc/timezone')"
echo "Current time: $(date)"
echo "UTC offset: $(date +%z)"

print_success "Timezone configuration completed!"

# Continue with the rest of the deployment
print_status "You can now continue with the production deployment..."
echo "The deployment script should continue from Step 2."