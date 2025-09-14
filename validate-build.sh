#!/bin/bash

# SolarNexus Build Validation Script
# Validates that all necessary files are present for deployment

set -e

echo "🔍 Validating SolarNexus build..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

ERRORS=0

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root."
    exit 1
fi

print_status "Validating project structure..."

# Check frontend build
if [ -d "dist" ]; then
    print_success "Frontend build directory exists"
    
    # Check for essential frontend files
    if [ -f "dist/index.html" ]; then
        print_success "Frontend index.html exists"
    else
        print_error "Frontend index.html missing"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ -d "dist/assets" ]; then
        print_success "Frontend assets directory exists"
    else
        print_warning "Frontend assets directory missing (might be normal)"
    fi
else
    print_error "Frontend build directory (dist) missing"
    ERRORS=$((ERRORS + 1))
fi

# Check backend build
if [ -d "solarnexus-backend/dist" ]; then
    print_success "Backend build directory exists"
    
    # Check for essential backend files
    if [ -f "solarnexus-backend/dist/index.js" ] || [ -f "solarnexus-backend/dist/server.js" ] || [ -f "solarnexus-backend/dist/app.js" ]; then
        print_success "Backend entry point exists"
    else
        print_warning "Backend entry point not found (checking for any .js files)"
        if ls solarnexus-backend/dist/*.js 1> /dev/null 2>&1; then
            print_success "Backend JavaScript files found"
        else
            print_error "No backend JavaScript files found"
            ERRORS=$((ERRORS + 1))
        fi
    fi
else
    print_error "Backend build directory missing"
    ERRORS=$((ERRORS + 1))
fi

# Check configuration files
print_status "Validating configuration files..."

if [ -f "docker-compose.yml" ]; then
    print_success "docker-compose.yml exists"
else
    print_error "docker-compose.yml missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "Dockerfile" ]; then
    print_success "Frontend Dockerfile exists"
else
    print_error "Frontend Dockerfile missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "solarnexus-backend/Dockerfile" ] || [ -f "solarnexus-backend/Dockerfile.debian" ]; then
    print_success "Backend Dockerfile exists"
else
    print_error "Backend Dockerfile missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f ".env.production.template" ]; then
    print_success "Environment template exists"
else
    print_error "Environment template missing"
    ERRORS=$((ERRORS + 1))
fi

# Check deployment scripts
print_status "Validating deployment scripts..."

if [ -f "deploy.sh" ] && [ -x "deploy.sh" ]; then
    print_success "Deployment script exists and is executable"
else
    print_error "Deployment script missing or not executable"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "test-deployment.sh" ] && [ -x "test-deployment.sh" ]; then
    print_success "Test deployment script exists and is executable"
else
    print_warning "Test deployment script missing or not executable"
fi

# Check documentation
print_status "Validating documentation..."

if [ -f "DEPLOYMENT.md" ]; then
    print_success "Deployment documentation exists"
else
    print_warning "Deployment documentation missing"
fi

if [ -f "REQUIREMENTS.md" ]; then
    print_success "Requirements documentation exists"
else
    print_warning "Requirements documentation missing"
fi

if [ -f "README.md" ]; then
    print_success "README exists"
else
    print_warning "README missing"
fi

# Check package files
print_status "Validating package configurations..."

if [ -f "package.json" ]; then
    print_success "Frontend package.json exists"
    
    # Check if build script exists
    if grep -q '"build"' package.json; then
        print_success "Frontend build script defined"
    else
        print_warning "Frontend build script not found in package.json"
    fi
else
    print_error "Frontend package.json missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "solarnexus-backend/package.json" ]; then
    print_success "Backend package.json exists"
    
    # Check if build script exists
    if grep -q '"build"' solarnexus-backend/package.json; then
        print_success "Backend build script defined"
    else
        print_warning "Backend build script not found in package.json"
    fi
else
    print_error "Backend package.json missing"
    ERRORS=$((ERRORS + 1))
fi

# Check for common issues
print_status "Checking for common issues..."

# Check for node_modules in git (should be ignored)
if [ -d "node_modules" ]; then
    if git check-ignore node_modules > /dev/null 2>&1; then
        print_success "node_modules is properly ignored by git"
    else
        print_warning "node_modules should be added to .gitignore"
    fi
fi

# Check .gitignore
if [ -f ".gitignore" ]; then
    print_success ".gitignore exists"
    
    # Check for essential ignores
    if grep -q "node_modules" .gitignore; then
        print_success "node_modules ignored"
    else
        print_warning "node_modules should be in .gitignore"
    fi
    
    if grep -q ".env" .gitignore; then
        print_success "Environment files ignored"
    else
        print_warning ".env files should be in .gitignore"
    fi
else
    print_warning ".gitignore missing"
fi

# Check file sizes (warn about large files)
print_status "Checking for large files..."

# Check if any files are larger than 50MB
if find . -type f -size +50M -not -path "./node_modules/*" -not -path "./.git/*" | head -1 | grep -q .; then
    print_warning "Large files detected (>50MB):"
    find . -type f -size +50M -not -path "./node_modules/*" -not -path "./.git/*" -exec ls -lh {} \;
else
    print_success "No unusually large files detected"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "🎉 Build validation completed successfully!"
    echo ""
    echo "✅ All critical files are present"
    echo "✅ Build artifacts exist"
    echo "✅ Configuration files are ready"
    echo "✅ Deployment scripts are available"
    echo ""
    echo "🚀 Your project is ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "  1. Commit and push all changes to GitHub"
    echo "  2. Run the deployment script on your AWS server:"
    echo "     ssh root@13.245.249.110"
    echo "     git clone https://github.com/Reshigan/SolarNexus.git /opt/solarnexus"
    echo "     cd /opt/solarnexus && ./deploy.sh"
    echo ""
else
    echo "❌ Build validation failed with $ERRORS critical errors"
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi