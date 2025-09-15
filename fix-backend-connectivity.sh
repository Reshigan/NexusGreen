#!/bin/bash
# Fix backend connectivity and timeout issues

echo "🔧 Fixing Backend Connectivity and Timeout Issues..."

# Stop containers
echo "=== Stopping containers ==="
sudo docker-compose -f docker-compose.public.yml down

# Check if database schema exists and create if needed
echo "=== Setting up database schema ==="
sudo docker-compose -f docker-compose.public.yml up -d nexus-db
sleep 10

# Create database schema if it doesn't exist
echo "Creating database schema..."
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(50) UNIQUE,
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) NOT NULL CHECK (role IN ('super_admin', 'company_admin', 'customer', 'operator', 'funder')),
    company_id UUID REFERENCES companies(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    company_id UUID REFERENCES companies(id) NOT NULL,
    location VARCHAR(255),
    capacity_kw DECIMAL(10,2),
    installation_date DATE,
    ppa_rate DECIMAL(6,4),
    municipal_rate DECIMAL(6,4),
    project_admin_id UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    project_id UUID REFERENCES projects(id) NOT NULL,
    location VARCHAR(255),
    capacity_kw DECIMAL(10,2),
    panel_count INTEGER,
    inverter_type VARCHAR(100),
    installation_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS energy_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    energy_produced_kwh DECIMAL(10,3),
    energy_consumed_kwh DECIMAL(10,3),
    grid_import_kwh DECIMAL(10,3),
    grid_export_kwh DECIMAL(10,3),
    battery_charge_kwh DECIMAL(10,3),
    battery_discharge_kwh DECIMAL(10,3),
    efficiency_percentage DECIMAL(5,2),
    irradiance_kwh_m2 DECIMAL(6,3),
    temperature_celsius DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS financial_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id) NOT NULL,
    record_date DATE NOT NULL,
    energy_cost_saved DECIMAL(10,2),
    municipal_rate DECIMAL(6,4),
    ppa_rate DECIMAL(6,4),
    revenue_generated DECIMAL(10,2),
    maintenance_cost DECIMAL(10,2),
    roi_percentage DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS site_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id) NOT NULL,
    date DATE NOT NULL,
    performance_ratio DECIMAL(5,2),
    availability_percentage DECIMAL(5,2),
    capacity_factor DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS maintenance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id) NOT NULL,
    maintenance_date DATE NOT NULL,
    maintenance_type VARCHAR(100),
    description TEXT,
    cost DECIMAL(10,2),
    technician VARCHAR(100),
    status VARCHAR(50) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_energy_data_site_timestamp ON energy_data(site_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_financial_records_site_date ON financial_records(site_id, record_date);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_projects_company ON projects(company_id);
CREATE INDEX IF NOT EXISTS idx_sites_project ON sites(project_id);
"

echo "✅ Database schema created"

# Update API configuration for better timeout handling
echo "=== Updating API configuration ==="
cat > src/config/database.js << 'EOF'
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'nexus_user',
  host: process.env.DB_HOST || 'nexus-db',
  database: process.env.DB_NAME || 'nexus_green',
  password: process.env.DB_PASSWORD || 'nexus_secure_password_2024',
  port: process.env.DB_PORT || 5432,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  statement_timeout: 30000,
  query_timeout: 30000,
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Database connection error:', err);
});

module.exports = pool;
EOF

# Update API server configuration
echo "=== Updating API server configuration ==="
cat > src/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const pool = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'http://13.245.181.202', 'http://localhost'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Body parsing middleware
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request timeout middleware
app.use((req, res, next) => {
  req.setTimeout(30000, () => {
    res.status(408).json({ error: 'Request timeout' });
  });
  res.setTimeout(30000, () => {
    res.status(408).json({ error: 'Response timeout' });
  });
  next();
});

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as timestamp, version() as db_version');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
      db_timestamp: result.rows[0].timestamp,
      db_version: result.rows[0].db_version.split(' ')[0]
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});

// Dashboard overview endpoint
app.get('/api/dashboard/overview', async (req, res) => {
  try {
    const companiesResult = await pool.query('SELECT COUNT(*) as count FROM companies');
    const projectsResult = await pool.query('SELECT COUNT(*) as count FROM projects');
    const sitesResult = await pool.query('SELECT COUNT(*) as count FROM sites');
    const usersResult = await pool.query('SELECT COUNT(*) as count FROM users');
    
    // Get recent energy data
    const energyResult = await pool.query(`
      SELECT 
        SUM(energy_produced_kwh) as total_produced,
        SUM(energy_consumed_kwh) as total_consumed,
        AVG(efficiency_percentage) as avg_efficiency
      FROM energy_data 
      WHERE timestamp >= NOW() - INTERVAL '30 days'
    `);
    
    res.json({
      companies: parseInt(companiesResult.rows[0].count),
      projects: parseInt(projectsResult.rows[0].count),
      sites: parseInt(sitesResult.rows[0].count),
      users: parseInt(usersResult.rows[0].count),
      energy: {
        total_produced: parseFloat(energyResult.rows[0].total_produced || 0),
        total_consumed: parseFloat(energyResult.rows[0].total_consumed || 0),
        avg_efficiency: parseFloat(energyResult.rows[0].avg_efficiency || 0)
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Dashboard overview error:', error);
    res.status(500).json({
      error: 'Failed to fetch dashboard overview',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Companies endpoint
app.get('/api/companies', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.*, 
        COUNT(DISTINCT p.id) as project_count,
        COUNT(DISTINCT s.id) as site_count,
        SUM(s.capacity_kw) as total_capacity
      FROM companies c
      LEFT JOIN projects p ON c.id = p.company_id
      LEFT JOIN sites s ON p.id = s.project_id
      GROUP BY c.id, c.name, c.registration_number, c.address, c.contact_email, c.contact_phone, c.created_at, c.updated_at
      ORDER BY c.name
    `);
    
    res.json({
      companies: result.rows,
      count: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Companies fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch companies',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Projects endpoint
app.get('/api/projects', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, c.name as company_name,
        COUNT(DISTINCT s.id) as site_count,
        SUM(s.capacity_kw) as total_capacity
      FROM projects p
      LEFT JOIN companies c ON p.company_id = c.id
      LEFT JOIN sites s ON p.id = s.project_id
      GROUP BY p.id, p.name, p.description, p.company_id, p.location, p.capacity_kw, 
               p.installation_date, p.ppa_rate, p.municipal_rate, p.project_admin_id, 
               p.status, p.created_at, p.updated_at, c.name
      ORDER BY p.name
    `);
    
    res.json({
      projects: result.rows,
      count: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Projects fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch projects',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Sites endpoint
app.get('/api/sites', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*, p.name as project_name, c.name as company_name
      FROM sites s
      LEFT JOIN projects p ON s.project_id = p.id
      LEFT JOIN companies c ON p.company_id = c.id
      ORDER BY s.name
      LIMIT 50
    `);
    
    res.json({
      sites: result.rows,
      count: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Sites fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch sites',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Users endpoint
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.is_active, 
             u.created_at, u.updated_at, c.name as company_name
      FROM users u
      LEFT JOIN companies c ON u.company_id = c.id
      ORDER BY u.email
    `);
    
    res.json({
      users: result.rows,
      count: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Users fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch users',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 NexusGreen API server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🌐 CORS enabled for: http://13.245.181.202, http://localhost`);
});

module.exports = app;
EOF

# Update package.json to include required dependencies
echo "=== Updating package.json ==="
cat > package.json << 'EOF'
{
  "name": "nexus-green-api",
  "version": "6.1.0",
  "description": "NexusGreen Solar Energy Management API",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "compression": "^1.7.4",
    "pg": "^8.11.3",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "dotenv": "^16.3.1",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Rebuild and restart all containers
echo "=== Rebuilding containers with fixes ==="
sudo docker-compose -f docker-compose.public.yml build --no-cache

echo "=== Starting all containers ==="
sudo docker-compose -f docker-compose.public.yml up -d

# Wait for containers to be ready
echo "=== Waiting for containers to initialize ==="
sleep 15

# Test connectivity
echo "=== Testing connectivity ==="
echo "API Health:"
curl -s http://localhost/api/health | jq . || curl -s http://localhost/api/health

echo -e "\nDashboard Overview:"
curl -s http://localhost/api/dashboard/overview | jq . || curl -s http://localhost/api/dashboard/overview

echo -e "\n✅ Backend connectivity fixes applied!"
echo -e "\n🌐 Your application should now work at: http://13.245.181.202"
echo -e "\n📋 Next steps:"
echo "1. Test the main application: http://13.245.181.202"
echo "2. If data is missing, run: sudo ./seed-database.sh"
echo "3. Check API health: http://13.245.181.202/api/health"