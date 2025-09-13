#!/bin/bash

# SolarNexus Installation Fix Script
# Resolves common installation issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 SolarNexus Installation Fix${NC}"
echo -e "${BLUE}==============================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   echo "Run: sudo $0"
   exit 1
fi

INSTALL_DIR="/home/ubuntu/SolarNexus"

echo -e "${BLUE}🗂️  Checking installation directory...${NC}"

if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Directory $INSTALL_DIR already exists${NC}"
    echo -e "${YELLOW}Choose an option:${NC}"
    echo "1. Remove existing directory and reinstall"
    echo "2. Update existing installation"
    echo "3. Cancel"
    
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}🗑️  Removing existing directory...${NC}"
            rm -rf "$INSTALL_DIR"
            echo -e "${GREEN}✅ Directory removed${NC}"
            ;;
        2)
            echo -e "${BLUE}🔄 Updating existing installation...${NC}"
            cd "$INSTALL_DIR"
            git pull origin main || echo -e "${YELLOW}⚠️  Could not update repository${NC}"
            echo -e "${GREEN}✅ Repository updated${NC}"
            exit 0
            ;;
        3)
            echo -e "${YELLOW}❌ Installation cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

echo -e "${BLUE}📁 Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${BLUE}📥 Cloning SolarNexus repository...${NC}"
git clone https://github.com/Reshigan/SolarNexus.git .

echo -e "${BLUE}👤 Setting up permissions...${NC}"
chown -R ubuntu:ubuntu "$INSTALL_DIR"

echo -e "${BLUE}🐳 Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not found. Installing...${NC}"
    
    # Remove conflicting packages
    apt-get remove -y containerd.io docker-ce docker-ce-cli 2>/dev/null || true
    
    # Install Docker
    apt-get update -qq
    apt-get install -y docker.io docker-compose
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    echo -e "${GREEN}✅ Docker installed${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

echo -e "${BLUE}🧪 Testing Docker...${NC}"
if docker --version && docker-compose --version; then
    echo -e "${GREEN}✅ Docker is working${NC}"
else
    echo -e "${RED}❌ Docker installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Installation fix completed!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Log out and log back in (or run: newgrp docker)"
echo "2. Navigate to: cd $INSTALL_DIR"
echo "3. For SSL installation: sudo ./quick-ssl-install.sh your-domain.com your-email@domain.com"
echo "4. For simple installation: sudo ./clean-install.sh"
echo ""
echo -e "${BLUE}🔧 Available scripts:${NC}"
echo "  • SSL Installation: ./quick-ssl-install.sh"
echo "  • Clean Install: ./clean-install.sh"
echo "  • Docker Fix: ./fix-docker.sh"
echo "  • Quick Backend: ./deploy/quick-backend-start.sh"
echo ""