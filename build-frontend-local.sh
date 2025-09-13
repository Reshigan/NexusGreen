#!/bin/bash

# SolarNexus Frontend Local Build Script
# Builds frontend outside Docker to avoid build issues

set -e

SERVER_IP="13.245.249.110"
FRONTEND_DIR="solarnexus-frontend"

echo "🏗️ Building SolarNexus Frontend Locally"
echo "======================================="

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Check if we're in the right directory
if [[ ! -d "$FRONTEND_DIR" ]]; then
    echo "❌ Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

echo "📦 Installing dependencies..."
npm ci

echo "🔧 Creating production build..."
VITE_API_BASE_URL="http://$SERVER_IP:5000" npm run build

echo "✅ Frontend build completed!"
echo "📁 Build output: $(pwd)/dist"

# Verify build
if [[ -f "dist/index.html" ]]; then
    echo "✅ Build verification successful"
    echo "📊 Build size:"
    du -sh dist/
else
    echo "❌ Build verification failed"
    exit 1
fi