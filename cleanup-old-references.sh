#!/bin/bash

# Cleanup Old References Script for NexusGreen
# Removes old configuration files and references that might conflict

set -e

echo "🧹 Cleaning up old references for NexusGreen..."

# Function to safely remove files
safe_remove() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "🗑️ Removing: $file"
        rm -f "$file"
    fi
}

# Function to safely remove directories
safe_remove_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "🗑️ Removing directory: $dir"
        rm -rf "$dir"
    fi
}

# Clean up old nginx configurations
echo "📝 Cleaning up old nginx configurations..."
safe_remove "nginx-custom.conf"
safe_remove "nginx.conf.old"
safe_remove "nginx-fix.conf"
safe_remove "nginx-production.conf"
safe_remove "docker/default.conf.old"
safe_remove "docker/nginx.conf.old"

# Clean up old deployment scripts
echo "🚀 Cleaning up old deployment scripts..."
safe_remove "deploy.sh.old"
safe_remove "deploy-old.sh"
safe_remove "deploy-production.sh.old"
safe_remove "deploy-nexusgreen-fixed.sh.old"
safe_remove "deploy-nexusgreen-production.sh.old"
safe_remove "deploy-production-complete.sh.old"
safe_remove "deploy-working-ui.sh.old"

# Clean up old SSL files
echo "🔒 Cleaning up old SSL files..."
find docker/ssl -name "*.old" -delete 2>/dev/null || true
find docker/ssl -name "*.bak" -delete 2>/dev/null || true
find docker/ssl -name "*.backup" -delete 2>/dev/null || true

# Clean up old Docker files
echo "🐳 Cleaning up old Docker files..."
safe_remove "Dockerfile.old"
safe_remove "docker-compose.yml.old"
safe_remove "frontend-production.Dockerfile.old"

# Clean up old environment files
echo "🌍 Cleaning up old environment files..."
safe_remove ".env.old"
safe_remove ".env.production.old"
safe_remove ".env.backup"

# Clean up old build artifacts
echo "🔨 Cleaning up old build artifacts..."
safe_remove_dir "dist.old"
safe_remove_dir "build.old"

# Clean up old log files
echo "📋 Cleaning up old log files..."
find . -name "*.log.old" -delete 2>/dev/null || true
find . -name "*.log.backup" -delete 2>/dev/null || true
find docker/logs -name "*.old" -delete 2>/dev/null || true

# Clean up old documentation that might be outdated
echo "📚 Cleaning up outdated documentation..."
safe_remove "DEPLOYMENT-STATUS.md"
safe_remove "DEPLOYMENT_STATUS_FINAL.md"
safe_remove "NGINX-PRODUCTION.md"
safe_remove "PRODUCTION_DEPLOYMENT_SUMMARY.md"

# Clean up old installation scripts that might conflict
echo "⚙️ Cleaning up old installation scripts..."
safe_remove "auto-clean-install.sh"
safe_remove "auto-upgrade.sh"
safe_remove "clean-and-deploy-home.sh"
safe_remove "clean-deploy.sh"
safe_remove "clean-install-simple.sh"
safe_remove "complete-nginx-fix.sh"
safe_remove "complete-ui-fix.sh"
safe_remove "deploy-nexusgreen-fixed.sh"
safe_remove "deploy-nexusgreen-production.sh"
safe_remove "deploy-production-complete.sh"
safe_remove "deploy-production.sh"
safe_remove "deploy-working-ui.sh"
safe_remove "emergency-nginx-fix.sh"
safe_remove "fix-403-error.sh"
safe_remove "fix-docker-installation.sh"
safe_remove "fix-nginx.sh"
safe_remove "fix-permissions.sh"
safe_remove "fix-ssl-nginx-issue.sh"
safe_remove "fix-timezone-issue.sh"
safe_remove "fix-ui-and-services.sh"
safe_remove "force-home-deploy.sh"
safe_remove "home-build-deploy.sh"
safe_remove "home-install.sh"
safe_remove "install-solarnexus.sh"
safe_remove "interactive-clean-install.sh"
safe_remove "manage-installations.sh"
safe_remove "manage-solarnexus.sh"

# Clean up old Docker cleanup scripts
echo "🧽 Cleaning up old Docker cleanup scripts..."
safe_remove "docker-cleanup.sh"
safe_remove "docker-install.sh"
safe_remove "github-cleanup.sh"

# Clean up temporary files
echo "🗂️ Cleaning up temporary files..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.temp" -delete 2>/dev/null || true
find . -name "*~" -delete 2>/dev/null || true

# Clean up old backup files
echo "💾 Cleaning up old backup files..."
find . -name "*.backup.*" -mtime +7 -delete 2>/dev/null || true

# Clean up Docker system (optional - commented out for safety)
echo "🐳 Docker cleanup (optional)..."
echo "   To clean up Docker system, run:"
echo "   docker system prune -f"
echo "   docker volume prune -f"
echo "   docker image prune -f"

# List remaining important files
echo ""
echo "📋 Important files remaining:"
echo "✅ docker-compose.yml (current)"
echo "✅ Dockerfile (updated for SSL)"
echo "✅ setup-ssl-nexus.sh (SSL setup)"
echo "✅ deploy-ssl-nexus.sh (SSL deployment)"
echo "✅ docker/nginx.conf (nginx config)"
echo "✅ docker/ssl/ (SSL directory)"

# Show current directory structure
echo ""
echo "📁 Current project structure:"
ls -la | grep -E "(docker|ssl|deploy|setup|\.sh|\.yml|Dockerfile)" || true

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Run SSL deployment: ./deploy-ssl-nexus.sh"
echo "2. Or setup SSL certificates: ./setup-ssl-nexus.sh"
echo "3. Monitor deployment: docker-compose logs -f"
echo ""
echo "🔧 Key files for SSL deployment:"
echo "- ./deploy-ssl-nexus.sh - Main deployment script"
echo "- ./setup-ssl-nexus.sh - SSL certificate setup"
echo "- docker-compose.yml - Updated for SSL"
echo "- Dockerfile - Updated for SSL support"
echo "- docker/nginx.conf - Nginx configuration"
echo "- docker/ssl/ - SSL certificates directory"