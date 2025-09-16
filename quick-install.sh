#!/bin/bash

# Quick NexusGreen Production Setup
# Run this on your production server: curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/quick-install.sh | bash

echo "🚀 Quick NexusGreen Production Setup"
echo "===================================="

# Download and run the full installation script
curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/install-production.sh -o install-production.sh
chmod +x install-production.sh
./install-production.sh