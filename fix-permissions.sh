#!/bin/bash

# Fix Permissions for Nexus Green Build
# Resolves EACCES permission denied errors during build

echo "🔧 Fixing permissions for Nexus Green build..."

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"

# Fix ownership of the entire nexus-green directory
echo "Setting ownership to $CURRENT_USER..."
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/nexus-green/

# Set proper permissions
echo "Setting proper permissions..."
sudo chmod -R 755 /opt/nexus-green/

# Remove the problematic dist directory completely
echo "Removing existing dist directory..."
sudo rm -rf /opt/nexus-green/dist/

# Create a fresh dist directory with proper ownership
echo "Creating fresh dist directory..."
mkdir -p /opt/nexus-green/dist
chmod 755 /opt/nexus-green/dist

# Ensure node_modules has proper permissions
echo "Fixing node_modules permissions..."
chmod -R 755 /opt/nexus-green/node_modules/ 2>/dev/null || true

# Clean npm cache to avoid permission issues
echo "Cleaning npm cache..."
npm cache clean --force 2>/dev/null || true

echo "✅ Permissions fixed!"
echo ""
echo "Now try building:"
echo "cd /opt/nexus-green"
echo "npm run build"
echo ""
echo "If build succeeds, then fix Nginx permissions:"
echo "sudo chown -R www-data:www-data /opt/nexus-green/dist/"