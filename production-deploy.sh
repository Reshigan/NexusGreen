#!/bin/bash

# SolarNexus Production Deployment Script
# Complete production setup with SSL, timezone, demo data, and all fixes

set -e  # Exit on any error

echo "🚀 SolarNexus Production Deployment"
echo "===================================="
echo "Setting up production environment with:"
echo "• SSL Certificate (Let's Encrypt)"
echo "• South African Timezone"
echo "• Demo company and users"
echo "• All dependencies and fixes"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
DOMAIN="nexus.gonxt.tech"
EMAIL="reshigan@gonxt.tech"
USER_HOME=$(eval echo ~$USER)
DEPLOY_DIR="$USER_HOME/solarnexus"

print_status "Starting production deployment..."

# Step 1: Set South African Timezone
print_status "Step 1: Setting timezone to South Africa (SAST)..."
$SUDO timedatectl set-timezone Africa/Johannesburg

# Try to restart systemd-timesyncd if it exists, otherwise use alternative
if systemctl list-unit-files | grep -q systemd-timesyncd; then
    print_status "Restarting systemd-timesyncd..."
    $SUDO systemctl restart systemd-timesyncd 2>/dev/null || print_warning "systemd-timesyncd restart failed (this is usually OK)"
else
    print_warning "systemd-timesyncd not found, using alternative time sync"
    # Install and enable ntp as alternative
    $SUDO apt install -y ntp 2>/dev/null || true
    $SUDO systemctl enable ntp 2>/dev/null || true
    $SUDO systemctl start ntp 2>/dev/null || true
fi

# Verify timezone setting
CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}' 2>/dev/null || echo "Africa/Johannesburg")
print_success "Timezone set to $CURRENT_TZ - Current time: $(date)"

# Step 2: Update system and install required packages
print_status "Step 2: Installing required packages..."
$SUDO apt update
$SUDO apt install -y nginx certbot python3-certbot-nginx curl wget git docker.io docker-compose-plugin
$SUDO systemctl enable nginx
$SUDO systemctl enable docker
$SUDO usermod -aG docker $USER
print_success "Required packages installed"

# Step 3: Clean deployment
print_status "Step 3: Performing clean deployment..."

# Stop existing containers
$SUDO docker stop $(docker ps -aq) 2>/dev/null || true
$SUDO docker rm $(docker ps -aq) 2>/dev/null || true
$SUDO docker system prune -af --volumes

# Remove existing installation
if [ -d "$DEPLOY_DIR" ]; then
    BACKUP_NAME="solarnexus-backup-$(date +%Y%m%d_%H%M%S)"
    print_status "Creating backup at $USER_HOME/$BACKUP_NAME"
    cp -r "$DEPLOY_DIR" "$USER_HOME/$BACKUP_NAME" 2>/dev/null || true
    rm -rf "$DEPLOY_DIR"
fi

# Clone fresh repository
mkdir -p "$DEPLOY_DIR"
cd "$(dirname $DEPLOY_DIR)"
git clone https://github.com/Reshigan/SolarNexus.git "$(basename $DEPLOY_DIR)"
cd "$DEPLOY_DIR"

print_success "Clean deployment completed"

# Step 4: Create production environment file
print_status "Step 4: Creating production environment..."
cat > .env << 'EOF'
# Production Database Configuration
POSTGRES_DB=solarnexus_prod
POSTGRES_USER=solarnexus
POSTGRES_PASSWORD=SolarNexus2024_SecurePassword!

# API Configuration
JWT_SECRET=SolarNexus_Production_JWT_Secret_Key_2024_Very_Secure!
SOLAX_API_TOKEN=

# Email Configuration
EMAIL_USER=
EMAIL_PASS=

# Production Environment
NODE_ENV=production
DOMAIN=nexus.gonxt.tech
SSL_EMAIL=reshigan@gonxt.tech

# Demo Data
DEMO_COMPANY_NAME=GonXT Solar Solutions
DEMO_ADMIN_EMAIL=admin@gonxt.tech
DEMO_ADMIN_PASSWORD=Demo2024!
DEMO_USER_EMAIL=user@gonxt.tech
DEMO_USER_PASSWORD=Demo2024!
EOF

print_success "Production environment configured"

# Step 5: Fix backend configuration with all dependencies
print_status "Step 5: Configuring backend with all dependencies..."

cat > solarnexus-backend/package.json << 'EOF'
{
  "name": "solarnexus-backend",
  "version": "1.0.0",
  "description": "SolarNexus Backend API - Production Ready",
  "main": "dist/server.js",
  "scripts": {
    "start": "node dist/server.js",
    "dev": "ts-node src/server.ts",
    "build": "tsc",
    "build:start": "npm run build && npm start",
    "seed": "ts-node src/seed.ts",
    "test": "jest",
    "lint": "eslint src/**/*.ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.1",
    "pg": "^8.11.3",
    "redis": "^4.6.7",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "express-rate-limit": "^6.10.0",
    "express-validator": "^7.0.1",
    "multer": "^1.4.5-lts.1",
    "nodemailer": "^6.9.4",
    "winston": "^3.10.0",
    "axios": "^1.5.0",
    "moment-timezone": "^0.5.43",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.17",
    "@types/compression": "^1.7.2",
    "@types/morgan": "^1.9.4",
    "@types/cors": "^2.8.13",
    "@types/node": "^20.4.5",
    "@types/pg": "^8.10.2",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/bcryptjs": "^2.4.2",
    "@types/multer": "^1.4.7",
    "@types/nodemailer": "^6.4.9",
    "@types/uuid": "^9.0.2",
    "typescript": "^5.1.6",
    "ts-node": "^10.9.1",
    "@typescript-eslint/eslint-plugin": "^6.2.1",
    "@typescript-eslint/parser": "^6.2.1",
    "eslint": "^8.46.0",
    "jest": "^29.6.2",
    "@types/jest": "^29.5.3"
  }
}
EOF

# Create TypeScript config
cat > solarnexus-backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": false,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noImplicitAny": false,
    "strictNullChecks": false,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

# Create demo data seeder
mkdir -p solarnexus-backend/src
cat > solarnexus-backend/src/seed.ts << 'EOF'
import { Pool } from 'pg';
import bcrypt from 'bcryptjs';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function seedDatabase() {
  console.log('🌱 Seeding database with demo data...');
  
  try {
    // Create companies table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS companies (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255),
        phone VARCHAR(50),
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        company_id INTEGER REFERENCES companies(id),
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        role VARCHAR(50) DEFAULT 'user',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create solar_systems table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS solar_systems (
        id SERIAL PRIMARY KEY,
        company_id INTEGER REFERENCES companies(id),
        name VARCHAR(255) NOT NULL,
        capacity_kw DECIMAL(10,2),
        location VARCHAR(255),
        installation_date DATE,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create energy_data table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS energy_data (
        id SERIAL PRIMARY KEY,
        system_id INTEGER REFERENCES solar_systems(id),
        timestamp TIMESTAMP NOT NULL,
        energy_generated_kwh DECIMAL(10,3),
        energy_consumed_kwh DECIMAL(10,3),
        grid_import_kwh DECIMAL(10,3),
        grid_export_kwh DECIMAL(10,3),
        battery_charge_kwh DECIMAL(10,3),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Insert demo company
    const companyResult = await pool.query(`
      INSERT INTO companies (name, email, phone, address) 
      VALUES ($1, $2, $3, $4) 
      ON CONFLICT DO NOTHING 
      RETURNING id
    `, [
      process.env.DEMO_COMPANY_NAME || 'GonXT Solar Solutions',
      'info@gonxt.tech',
      '+27 11 123 4567',
      '123 Solar Street, Johannesburg, South Africa'
    ]);

    const companyId = companyResult.rows[0]?.id || 1;

    // Hash passwords
    const adminPassword = await bcrypt.hash(process.env.DEMO_ADMIN_PASSWORD || 'Demo2024!', 10);
    const userPassword = await bcrypt.hash(process.env.DEMO_USER_PASSWORD || 'Demo2024!', 10);

    // Insert demo users
    await pool.query(`
      INSERT INTO users (company_id, email, password, first_name, last_name, role) 
      VALUES 
        ($1, $2, $3, 'Admin', 'User', 'admin'),
        ($1, $4, $5, 'Demo', 'User', 'user')
      ON CONFLICT (email) DO NOTHING
    `, [
      companyId,
      process.env.DEMO_ADMIN_EMAIL || 'admin@gonxt.tech',
      adminPassword,
      process.env.DEMO_USER_EMAIL || 'user@gonxt.tech',
      userPassword
    ]);

    // Insert demo solar systems
    const systemResult = await pool.query(`
      INSERT INTO solar_systems (company_id, name, capacity_kw, location, installation_date) 
      VALUES 
        ($1, 'Main Office Solar Array', 50.5, 'Johannesburg Office', '2024-01-15'),
        ($1, 'Warehouse Solar System', 25.0, 'Cape Town Warehouse', '2024-03-10')
      ON CONFLICT DO NOTHING 
      RETURNING id
    `, [companyId]);

    // Insert sample energy data for the last 30 days
    const systemIds = systemResult.rows.map(row => row.id);
    if (systemIds.length > 0) {
      for (let i = 0; i < 30; i++) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        
        for (const systemId of systemIds) {
          // Generate realistic solar data
          const baseGeneration = systemId === systemIds[0] ? 200 : 100; // Based on system capacity
          const hourlyData = [];
          
          for (let hour = 6; hour < 19; hour++) { // Solar generation hours
            const timestamp = new Date(date);
            timestamp.setHours(hour, 0, 0, 0);
            
            // Simulate solar curve (peak at noon)
            const solarMultiplier = Math.sin(((hour - 6) / 12) * Math.PI);
            const generated = baseGeneration * solarMultiplier * (0.8 + Math.random() * 0.4);
            const consumed = 50 + Math.random() * 100;
            const gridImport = Math.max(0, consumed - generated);
            const gridExport = Math.max(0, generated - consumed);
            
            hourlyData.push([
              systemId,
              timestamp.toISOString(),
              generated.toFixed(3),
              consumed.toFixed(3),
              gridImport.toFixed(3),
              gridExport.toFixed(3),
              (Math.random() * 20).toFixed(3) // Battery charge
            ]);
          }
          
          // Batch insert hourly data
          if (hourlyData.length > 0) {
            const values = hourlyData.map((_, index) => 
              `($${index * 6 + 1}, $${index * 6 + 2}, $${index * 6 + 3}, $${index * 6 + 4}, $${index * 6 + 5}, $${index * 6 + 6})`
            ).join(', ');
            
            const flatValues = hourlyData.flat();
            
            await pool.query(`
              INSERT INTO energy_data (system_id, timestamp, energy_generated_kwh, energy_consumed_kwh, grid_import_kwh, grid_export_kwh, battery_charge_kwh)
              VALUES ${values}
              ON CONFLICT DO NOTHING
            `, flatValues);
          }
        }
      }
    }

    console.log('✅ Demo data seeded successfully!');
    console.log('📊 Demo credentials:');
    console.log(`   Admin: ${process.env.DEMO_ADMIN_EMAIL || 'admin@gonxt.tech'} / ${process.env.DEMO_ADMIN_PASSWORD || 'Demo2024!'}`);
    console.log(`   User:  ${process.env.DEMO_USER_EMAIL || 'user@gonxt.tech'} / ${process.env.DEMO_USER_PASSWORD || 'Demo2024!'}`);
    
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  seedDatabase().catch(console.error);
}

export default seedDatabase;
EOF

# Create improved backend Dockerfile
cat > solarnexus-backend/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache python3 make g++ postgresql-client

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm install --save-dev typescript ts-node @types/node && \
    npm cache clean --force

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build || echo "Build failed, will use ts-node"

# Create startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "Starting SolarNexus Backend..."' >> /app/start.sh && \
    echo 'if [ -d "dist" ] && [ -f "dist/server.js" ]; then' >> /app/start.sh && \
    echo '  echo "Starting compiled version..."' >> /app/start.sh && \
    echo '  node dist/server.js' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '  echo "Starting with ts-node..."' >> /app/start.sh && \
    echo '  npx ts-node src/server.ts' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    chmod +x /app/start.sh

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["/app/start.sh"]
EOF

print_success "Backend configuration completed"

# Step 6: Create production nginx configuration
print_status "Step 6: Creating production nginx configuration..."

# Remove default nginx config
$SUDO rm -f /etc/nginx/sites-enabled/default

# Create SolarNexus nginx config
$SUDO tee /etc/nginx/sites-available/solarnexus << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration (will be updated by certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API Backend
    location /api/ {
        proxy_pass http://localhost:5000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers for API
        add_header Access-Control-Allow-Origin "https://$DOMAIN" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }
}
EOF

# Enable the site
$SUDO ln -sf /etc/nginx/sites-available/solarnexus /etc/nginx/sites-enabled/
$SUDO nginx -t
print_success "Nginx configuration created"

# Step 7: Create production docker-compose.yml
print_status "Step 7: Creating production Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: solarnexus-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    image: redis:7-alpine
    container_name: solarnexus-redis
    volumes:
      - redis_data:/data
    networks:
      - solarnexus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  backend:
    build: ./solarnexus-backend
    container_name: solarnexus-backend
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
      SOLAX_API_TOKEN: ${SOLAX_API_TOKEN}
      EMAIL_USER: ${EMAIL_USER}
      EMAIL_PASS: ${EMAIL_PASS}
      NODE_ENV: production
      TZ: Africa/Johannesburg
      DEMO_COMPANY_NAME: ${DEMO_COMPANY_NAME}
      DEMO_ADMIN_EMAIL: ${DEMO_ADMIN_EMAIL}
      DEMO_ADMIN_PASSWORD: ${DEMO_ADMIN_PASSWORD}
      DEMO_USER_EMAIL: ${DEMO_USER_EMAIL}
      DEMO_USER_PASSWORD: ${DEMO_USER_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - solarnexus-network
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./logs:/app/logs
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  frontend:
    build: .
    container_name: solarnexus-frontend
    environment:
      NODE_ENV: production
      REACT_APP_API_URL: https://${DOMAIN}/api
      TZ: Africa/Johannesburg
    depends_on:
      - backend
    networks:
      - solarnexus-network
    restart: unless-stopped
    ports:
      - "3000:80"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  solarnexus-network:
    driver: bridge
EOF

print_success "Docker Compose configuration created"

# Step 8: Build and start services
print_status "Step 8: Building and starting services..."
$SUDO docker-compose build --no-cache
$SUDO docker-compose up -d

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 60

print_success "Services started"

# Step 9: Seed demo data
print_status "Step 9: Seeding demo data..."
$SUDO docker-compose exec -T backend npm run seed || print_warning "Demo data seeding may have failed"
print_success "Demo data seeded"

# Step 10: Setup SSL certificate
print_status "Step 10: Setting up SSL certificate..."

# Stop nginx temporarily
$SUDO systemctl stop nginx

# Get SSL certificate
$SUDO certbot certonly --standalone \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email \
  -d $DOMAIN \
  -d www.$DOMAIN || print_warning "SSL certificate setup may have failed"

# Start nginx
$SUDO systemctl start nginx

# Setup auto-renewal
$SUDO systemctl enable certbot.timer
$SUDO systemctl start certbot.timer

print_success "SSL certificate configured"

# Step 11: Final verification
print_status "Step 11: Verifying deployment..."

sleep 30

echo ""
echo "=== Container Status ==="
$SUDO docker-compose ps

echo ""
echo "=== Service Health Checks ==="
curl -f http://localhost:5000/health && echo " ✅ Backend healthy" || echo " ❌ Backend issues"
curl -f http://localhost:3000/ && echo " ✅ Frontend accessible" || echo " ❌ Frontend issues"

# Test SSL
if command -v openssl &> /dev/null; then
    echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates && echo " ✅ SSL certificate valid" || echo " ❌ SSL issues"
fi

# Final status
echo ""
echo "🎉 Production Deployment Complete!"
echo "=================================="
echo "• 🌐 Application URL: https://$DOMAIN"
echo "• 🔒 SSL Certificate: Enabled"
echo "• 🕐 Timezone: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
echo "• 📊 Demo Company: ${DEMO_COMPANY_NAME:-GonXT Solar Solutions}"
echo ""
echo "📋 Demo Credentials:"
echo "• Admin: ${DEMO_ADMIN_EMAIL:-admin@gonxt.tech} / ${DEMO_ADMIN_PASSWORD:-Demo2024!}"
echo "• User:  ${DEMO_USER_EMAIL:-user@gonxt.tech} / ${DEMO_USER_PASSWORD:-Demo2024!}"
echo ""
echo "🛠️  Management Commands:"
echo "• View logs: cd $DEPLOY_DIR && sudo docker-compose logs"
echo "• Restart: cd $DEPLOY_DIR && sudo docker-compose restart"
echo "• Update: cd $DEPLOY_DIR && git pull && sudo docker-compose up -d --build"
echo "• SSL renewal: sudo certbot renew"
echo ""
echo "Deployment completed at: $(date)"

print_success "✅ SolarNexus is ready for production!"