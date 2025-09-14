const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Database connection with retry logic
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false,  // Disable SSL for local Docker deployment
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Database connection retry function
async function connectWithRetry() {
  const maxRetries = 10;
  let retries = 0;
  
  while (retries < maxRetries) {
    try {
      const client = await pool.connect();
      console.log('✅ Database connected successfully');
      client.release();
      return;
    } catch (err) {
      retries++;
      console.log(`❌ Database connection attempt ${retries}/${maxRetries} failed:`, err.message);
      if (retries === maxRetries) {
        console.error('💥 Failed to connect to database after maximum retries');
        process.exit(1);
      }
      // Wait before retrying (exponential backoff)
      await new Promise(resolve => setTimeout(resolve, Math.min(1000 * Math.pow(2, retries), 10000)));
    }
  }
}

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['http://localhost', 'https://nexus.gonxt.tech', 'http://nexus.gonxt.tech']
    : true,
  credentials: true
}));
app.use(express.json());

// Health check endpoints
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    const client = await pool.connect();
    client.release();
    res.status(200).json({ 
      status: 'healthy', 
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

app.get('/api/health', async (req, res) => {
  try {
    // Test database connection
    const client = await pool.connect();
    client.release();
    res.status(200).json({ 
      status: 'healthy', 
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// API status endpoint
app.get('/api/status', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as server_time');
    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: result.rows[0].server_time,
      version: '1.0.0'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Get company info
app.get('/api/company', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, name, registration_number, address, phone, email, website, logo_url
      FROM companies 
      LIMIT 1
    `);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching company:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get installations
app.get('/api/installations', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT i.*, 
             COALESCE(SUM(eg.energy_kwh), 0) as total_generation,
             COALESCE(AVG(eg.energy_kwh), 0) as avg_daily_generation
      FROM installations i
      LEFT JOIN energy_generation eg ON i.id = eg.installation_id 
        AND eg.date >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY i.id
      ORDER BY i.created_at DESC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching installations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get dashboard stats
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    // Total installations
    const installationsResult = await pool.query('SELECT COUNT(*) as count FROM installations');
    const totalInstallations = parseInt(installationsResult.rows[0].count);

    // Total capacity
    const capacityResult = await pool.query('SELECT COALESCE(SUM(capacity_kw), 0) as total FROM installations');
    const totalCapacity = parseFloat(capacityResult.rows[0].total);

    // Today's generation
    const todayResult = await pool.query(`
      SELECT COALESCE(SUM(energy_kwh), 0) as total 
      FROM energy_generation 
      WHERE date = CURRENT_DATE
    `);
    const todayGeneration = parseFloat(todayResult.rows[0].total);

    // Monthly revenue
    const revenueResult = await pool.query(`
      SELECT COALESCE(SUM(revenue), 0) as total 
      FROM financial_data 
      WHERE date >= DATE_TRUNC('month', CURRENT_DATE)
    `);
    const monthlyRevenue = parseFloat(revenueResult.rows[0].total);

    // Active alerts
    const alertsResult = await pool.query(`
      SELECT COUNT(*) as count 
      FROM alerts 
      WHERE is_resolved = false
    `);
    const activeAlerts = parseInt(alertsResult.rows[0].count);

    res.json({
      totalInstallations,
      totalCapacity,
      todayGeneration,
      monthlyRevenue,
      activeAlerts
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get energy generation data
app.get('/api/energy/generation', async (req, res) => {
  try {
    const { period = '7d', installation_id } = req.query;
    
    let dateFilter = "date >= CURRENT_DATE - INTERVAL '7 days'";
    if (period === '30d') dateFilter = "date >= CURRENT_DATE - INTERVAL '30 days'";
    if (period === '1y') dateFilter = "date >= CURRENT_DATE - INTERVAL '1 year'";

    let installationFilter = '';
    const params = [];
    if (installation_id) {
      installationFilter = 'AND installation_id = $1';
      params.push(installation_id);
    }

    const result = await pool.query(`
      SELECT 
        date,
        SUM(energy_kwh) as total_energy,
        AVG(temperature) as avg_temperature,
        AVG(irradiance) as avg_irradiance,
        STRING_AGG(DISTINCT weather_condition, ', ') as weather_conditions
      FROM energy_generation 
      WHERE ${dateFilter} ${installationFilter}
      GROUP BY date
      ORDER BY date DESC
    `, params);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching energy generation:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get financial data
app.get('/api/financial', async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    let dateFilter = "date >= CURRENT_DATE - INTERVAL '30 days'";
    if (period === '1y') dateFilter = "date >= CURRENT_DATE - INTERVAL '1 year'";

    const result = await pool.query(`
      SELECT 
        date,
        SUM(energy_sold_kwh) as total_energy_sold,
        SUM(revenue) as total_revenue,
        SUM(savings) as total_savings,
        AVG(ppa_rate) as avg_ppa_rate
      FROM financial_data 
      WHERE ${dateFilter}
      GROUP BY date
      ORDER BY date DESC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching financial data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get alerts
app.get('/api/alerts', async (req, res) => {
  try {
    const { resolved = 'false' } = req.query;
    
    const result = await pool.query(`
      SELECT a.*, i.name as installation_name
      FROM alerts a
      JOIN installations i ON a.installation_id = i.id
      WHERE is_resolved = $1
      ORDER BY created_at DESC
      LIMIT 50
    `, [resolved === 'true']);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get maintenance records
app.get('/api/maintenance', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT m.*, i.name as installation_name
      FROM maintenance m
      JOIN installations i ON m.installation_id = i.id
      ORDER BY scheduled_date DESC
      LIMIT 50
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching maintenance records:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Authentication endpoints (v1 API)
app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // For demo purposes, accept any email/password combination
    // In production, you would validate against a users table
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email and password are required',
        message: 'Please provide both email and password' 
      });
    }

    // Mock user data - in production, fetch from database
    const user = {
      id: '1',
      email: email,
      firstName: 'Demo',
      lastName: 'User',
      role: 'ADMIN',
      organizationId: '1',
      avatar: null,
      lastLogin: new Date().toISOString(),
      isActive: true,
      permissions: ['read', 'write', 'admin'],
      emailVerified: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const organization = {
      id: '1',
      name: 'NexusGreen Solar',
      slug: 'nexusgreen-solar',
      type: 'INSTALLER',
      logo: null,
      address: '123 Solar Street, Green City',
      country: 'USA',
      timezone: 'America/New_York',
      settings: {
        theme: 'light',
        currency: 'USD',
        timezone: 'America/New_York'
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Mock tokens - in production, use JWT
    const accessToken = 'demo-access-token-' + Date.now();
    const refreshToken = 'demo-refresh-token-' + Date.now();

    res.json({
      accessToken,
      refreshToken,
      user,
      organization,
      message: 'Login successful'
    });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/logout', async (req, res) => {
  try {
    // In production, invalidate the token
    res.json({ message: 'Logout successful' });
  } catch (error) {
    console.error('Error during logout:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    // Mock token refresh - in production, validate and generate new tokens
    const accessToken = 'demo-access-token-' + Date.now();
    const newRefreshToken = 'demo-refresh-token-' + Date.now();

    res.json({
      accessToken,
      refreshToken: newRefreshToken
    });
  } catch (error) {
    console.error('Error during token refresh:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/v1/auth/me', async (req, res) => {
  try {
    // Mock user profile - in production, get from token and database
    const user = {
      id: '1',
      email: 'demo@nexusgreen.com',
      firstName: 'Demo',
      lastName: 'User',
      role: 'ADMIN',
      organizationId: '1',
      avatar: null,
      lastLogin: new Date().toISOString(),
      isActive: true,
      permissions: ['read', 'write', 'admin'],
      emailVerified: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    res.json(user);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Dashboard analytics endpoint (v1 API)
app.get('/api/v1/analytics/dashboard/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    
    // Get dashboard metrics from existing endpoints
    const [installationsResult, capacityResult, todayResult, revenueResult, alertsResult] = await Promise.all([
      pool.query('SELECT COUNT(*) as count FROM installations'),
      pool.query('SELECT COALESCE(SUM(capacity_kw), 0) as total FROM installations'),
      pool.query('SELECT COALESCE(SUM(energy_kwh), 0) as total FROM energy_generation WHERE date = CURRENT_DATE'),
      pool.query('SELECT COALESCE(SUM(revenue), 0) as total FROM financial_data WHERE date >= DATE_TRUNC(\'month\', CURRENT_DATE)'),
      pool.query('SELECT COUNT(*) as count FROM alerts WHERE is_resolved = false')
    ]);

    const metrics = {
      totalSites: parseInt(installationsResult.rows[0].count),
      totalCapacity: parseFloat(capacityResult.rows[0].total),
      totalGeneration: parseFloat(todayResult.rows[0].total),
      totalRevenue: parseFloat(revenueResult.rows[0].total),
      activeAlerts: parseInt(alertsResult.rows[0].count),
      systemHealth: 98.5,
      co2Saved: parseFloat(todayResult.rows[0].total) * 0.0004, // Rough calculation
      lastUpdated: new Date().toISOString()
    };

    res.json(metrics);
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Sites endpoint (v1 API)
app.get('/api/v1/sites', async (req, res) => {
  try {
    const { organizationId } = req.query;
    
    const result = await pool.query(`
      SELECT i.*, 
             COALESCE(SUM(eg.energy_kwh), 0) as total_generation,
             COALESCE(AVG(eg.energy_kwh), 0) as avg_daily_generation
      FROM installations i
      LEFT JOIN energy_generation eg ON i.id = eg.installation_id 
        AND eg.date >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY i.id
      ORDER BY i.created_at DESC
    `);
    
    // Transform to match frontend expectations
    const sites = result.rows.map(row => ({
      id: row.id.toString(),
      name: row.name,
      organizationId: organizationId || '1',
      location: {
        address: row.location || 'Unknown Location',
        latitude: row.latitude || 0,
        longitude: row.longitude || 0,
        timezone: 'America/New_York'
      },
      capacity: parseFloat(row.capacity_kw || 0),
      status: row.status || 'ACTIVE',
      installationDate: row.created_at,
      lastMaintenance: null,
      nextMaintenance: null,
      performance: {
        currentGeneration: parseFloat(row.avg_daily_generation || 0),
        totalGeneration: parseFloat(row.total_generation || 0),
        efficiency: 95.2,
        uptime: 99.1
      },
      alerts: [],
      createdAt: row.created_at,
      updatedAt: row.updated_at || row.created_at
    }));

    res.json(sites);
  } catch (error) {
    console.error('Error fetching sites:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
// Start server with database connection retry
async function startServer() {
  try {
    // Connect to database with retry logic
    await connectWithRetry();
    
    // Start the server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Nexus Green API server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Database: Connected successfully`);
    });
  } catch (error) {
    console.error('💥 Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  pool.end(() => {
    process.exit(0);
  });
});