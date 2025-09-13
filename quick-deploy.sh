#!/bin/bash

# SolarNexus Quick Deploy - One Command Installation
# Downloads and runs the tested deployment script

set -e

echo "🚀 SolarNexus Quick Deploy"
echo "=========================="
echo ""
echo "Downloading and running the tested deployment script..."
echo ""

# Download the tested deployment script
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy-tested.sh -o /tmp/deploy-tested.sh

# Make it executable
chmod +x /tmp/deploy-tested.sh

# Run it
sudo /tmp/deploy-tested.sh

# Clean up
rm -f /tmp/deploy-tested.sh

echo ""
echo "✅ Quick deployment completed!"