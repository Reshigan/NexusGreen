#!/bin/bash

# SolarNexus Production API Keys Setup Script
# This script helps configure production API keys securely

set -e

echo "🔐 SolarNexus Production API Keys Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ This script should not be run as root${NC}"
   exit 1
fi

# Create secure directory for secrets
SECRETS_DIR="/opt/solarnexus/secrets"
ENV_FILE="/opt/solarnexus/.env.production"

echo -e "${BLUE}📁 Creating secure secrets directory...${NC}"
sudo mkdir -p "$SECRETS_DIR"
sudo chmod 700 "$SECRETS_DIR"

# Function to securely read input
read_secret() {
    local prompt="$1"
    local var_name="$2"
    local current_value="$3"
    
    if [[ -n "$current_value" ]]; then
        echo -e "${YELLOW}Current value for $var_name: [HIDDEN]${NC}"
        read -p "Keep current value? (y/n): " keep_current
        if [[ "$keep_current" =~ ^[Yy]$ ]]; then
            echo "$current_value"
            return
        fi
    fi
    
    echo -n "$prompt"
    read -s secret_value
    echo
    echo "$secret_value"
}

# Function to generate secure random string
generate_secure_key() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

echo -e "${BLUE}🔑 Configuring API Keys...${NC}"

# Load existing environment if it exists
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}📄 Loading existing configuration...${NC}"
    source "$ENV_FILE"
fi

# SolaX API Token
echo -e "\n${GREEN}1. SolaX API Configuration${NC}"
echo "   Get your token from: https://www.solaxcloud.com/"
SOLAX_API_TOKEN=$(read_secret "Enter SolaX API Token: " "SOLAX_API_TOKEN" "$SOLAX_API_TOKEN")

# OpenWeatherMap API Key
echo -e "\n${GREEN}2. OpenWeatherMap API Configuration${NC}"
echo "   Get your key from: https://openweathermap.org/api"
OPENWEATHER_API_KEY=$(read_secret "Enter OpenWeatherMap API Key: " "OPENWEATHER_API_KEY" "$OPENWEATHER_API_KEY")

# Email Configuration
echo -e "\n${GREEN}3. Email Service Configuration${NC}"
echo "   For Gmail, use App Passwords: https://support.google.com/accounts/answer/185833"
EMAIL_USER=$(read_secret "Enter Email User (e.g., alerts@nexus.gonxt.tech): " "EMAIL_USER" "$EMAIL_USER")
EMAIL_PASS=$(read_secret "Enter Email Password/App Password: " "EMAIL_PASS" "$EMAIL_PASS")

# JWT Secret
echo -e "\n${GREEN}4. Security Configuration${NC}"
if [[ -z "$JWT_SECRET" ]]; then
    echo "   Generating secure JWT secret..."
    JWT_SECRET=$(generate_secure_key 64)
    echo -e "${GREEN}✅ Generated secure JWT secret${NC}"
else
    echo -e "${YELLOW}   Using existing JWT secret${NC}"
fi

# Database Password
if [[ -z "$POSTGRES_PASSWORD" ]]; then
    echo "   Generating secure database password..."
    POSTGRES_PASSWORD=$(generate_secure_key 32)
    echo -e "${GREEN}✅ Generated secure database password${NC}"
else
    echo -e "${YELLOW}   Using existing database password${NC}"
fi

# Municipal Rate API (optional)
echo -e "\n${GREEN}5. Municipal Rate API (Optional)${NC}"
read -p "Do you have a municipal rate API key? (y/n): " has_municipal_api
if [[ "$has_municipal_api" =~ ^[Yy]$ ]]; then
    MUNICIPAL_RATE_API_KEY=$(read_secret "Enter Municipal Rate API Key: " "MUNICIPAL_RATE_API_KEY" "$MUNICIPAL_RATE_API_KEY")
    read -p "Enter Municipal Rate API Endpoint: " MUNICIPAL_RATE_ENDPOINT
fi

# Create production environment file
echo -e "\n${BLUE}📝 Creating production environment file...${NC}"

cat > "$ENV_FILE" << EOF
# SolarNexus Production Environment
# Generated on $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

# Database Configuration
DATABASE_URL="postgresql://solarnexus:${POSTGRES_PASSWORD}@solarnexus-postgres:5432/solarnexus"
POSTGRES_USER="solarnexus"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DB="solarnexus"

# Redis Configuration
REDIS_URL="redis://solarnexus-redis:6379"

# Security
JWT_SECRET="${JWT_SECRET}"
JWT_EXPIRES_IN="24h"
BCRYPT_ROUNDS="12"

# Solar Data APIs
SOLAX_API_TOKEN="${SOLAX_API_TOKEN}"
SOLAX_API_BASE_URL="https://www.solaxcloud.com:9443/proxy/api/getRealtimeInfo.do"

# Weather API
OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY}"
OPENWEATHER_BASE_URL="https://api.openweathermap.org/data/2.5"

# Email Configuration
EMAIL_HOST="smtp.gmail.com"
EMAIL_PORT="587"
EMAIL_SECURE="false"
EMAIL_USER="${EMAIL_USER}"
EMAIL_PASS="${EMAIL_PASS}"

# Municipal Rate API
MUNICIPAL_RATE_API_KEY="${MUNICIPAL_RATE_API_KEY:-}"
MUNICIPAL_RATE_ENDPOINT="${MUNICIPAL_RATE_ENDPOINT:-}"

# Application Configuration
NODE_ENV="production"
PORT="3000"
API_BASE_URL="https://nexus.gonxt.tech/api"
FRONTEND_URL="https://nexus.gonxt.tech"

# Monitoring
LOG_LEVEL="info"
ENABLE_REQUEST_LOGGING="true"
ENABLE_PERFORMANCE_MONITORING="true"

# Rate Limiting
RATE_LIMIT_WINDOW_MS="900000"
RATE_LIMIT_MAX_REQUESTS="100"
AUTH_RATE_LIMIT_MAX="5"

# CORS
CORS_ORIGIN="https://nexus.gonxt.tech,https://www.nexus.gonxt.tech"
CORS_CREDENTIALS="true"

# Features
ENABLE_ANALYTICS="true"
ENABLE_PREDICTIVE_MAINTENANCE="true"
ENABLE_REAL_TIME_SYNC="true"
ENABLE_EMAIL_NOTIFICATIONS="true"

# Cache TTL (seconds)
CACHE_TTL_SOLAR_DATA="300"
CACHE_TTL_WEATHER_DATA="1800"
CACHE_TTL_TARIFF_DATA="3600"
CACHE_TTL_ANALYTICS="900"

# Security Headers
SECURITY_HEADERS_ENABLED="true"
HSTS_MAX_AGE="31536000"
CSP_ENABLED="true"
FORCE_HTTPS="true"

# Timezone
TZ="UTC"
DEFAULT_LOCALE="en-US"
EOF

# Set secure permissions
sudo chmod 600 "$ENV_FILE"
sudo chown root:root "$ENV_FILE"

# Create Docker secrets
echo -e "\n${BLUE}🐳 Creating Docker secrets...${NC}"

echo "$SOLAX_API_TOKEN" | sudo tee "$SECRETS_DIR/solax_token" > /dev/null
echo "$OPENWEATHER_API_KEY" | sudo tee "$SECRETS_DIR/openweather_key" > /dev/null
echo "$EMAIL_PASS" | sudo tee "$SECRETS_DIR/email_password" > /dev/null
echo "$JWT_SECRET" | sudo tee "$SECRETS_DIR/jwt_secret" > /dev/null
echo "$POSTGRES_PASSWORD" | sudo tee "$SECRETS_DIR/db_password" > /dev/null

# Set secure permissions on secrets
sudo chmod 600 "$SECRETS_DIR"/*
sudo chown root:root "$SECRETS_DIR"/*

# Create restart script with new environment
echo -e "\n${BLUE}🔄 Creating restart script...${NC}"

sudo tee /opt/solarnexus/restart-with-secrets.sh > /dev/null << EOF
#!/bin/bash
# Restart SolarNexus with production secrets

cd /workspace/project/PPA-Frontend

echo "🛑 Stopping services..."
docker stop solarnexus-backend solarnexus-frontend 2>/dev/null || true

echo "🔄 Starting with production environment..."
docker run -d --name solarnexus-backend \\
    --network project_solarnexus-network \\
    -p 3000:3000 \\
    --env-file $ENV_FILE \\
    ppa-frontend-backend

docker run -d --name solarnexus-frontend \\
    --network project_solarnexus-network \\
    -p 8080:80 \\
    ppa-frontend-frontend

echo "✅ Services restarted with production configuration"
docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
EOF

sudo chmod +x /opt/solarnexus/restart-with-secrets.sh

# Summary
echo -e "\n${GREEN}✅ Production API Keys Setup Complete!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   • Environment file: $ENV_FILE"
echo "   • Secrets directory: $SECRETS_DIR"
echo "   • Restart script: /opt/solarnexus/restart-with-secrets.sh"

echo -e "\n${YELLOW}🔐 Security Notes:${NC}"
echo "   • All secrets are stored with 600 permissions (root only)"
echo "   • Environment file is excluded from version control"
echo "   • Use the restart script to apply new configuration"

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo "   1. Run: sudo /opt/solarnexus/restart-with-secrets.sh"
echo "   2. Verify services: docker ps"
echo "   3. Test API endpoints: curl http://localhost:3000/health"
echo "   4. Set up SSL certificate (see PRODUCTION_SETUP.md)"
echo "   5. Configure monitoring and backups"

echo -e "\n${GREEN}🎉 Ready for production deployment!${NC}"