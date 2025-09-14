#!/bin/bash

# Quick NexusGreen Deployment Script
# Run this on your server: 13.247.192.38

echo "🚀 Quick NexusGreen Deployment"
echo "=============================="

# One-liner deployment
curl -fsSL https://raw.githubusercontent.com/Reshigan/NexusGreen/main/deploy-nexusgreen-production.sh | bash

echo ""
echo "✅ Deployment complete!"
echo "🌐 Visit: https://nexus.gonxt.tech"