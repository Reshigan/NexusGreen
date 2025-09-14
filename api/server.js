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

// Individual site endpoint (v1 API)
app.get('/api/v1/sites/:siteId', async (req, res) => {
  try {
    const { siteId } = req.params;
    
    const result = await pool.query(`
      SELECT i.*, 
             COALESCE(SUM(eg.energy_kwh), 0) as total_generation,
             COALESCE(AVG(eg.energy_kwh), 0) as avg_daily_generation
      FROM installations i
      LEFT JOIN energy_generation eg ON i.id = eg.installation_id 
        AND eg.date >= CURRENT_DATE - INTERVAL '30 days'
      WHERE i.id = $1
      GROUP BY i.id
    `, [siteId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Site not found' });
    }

    const row = result.rows[0];
    const site = {
      id: row.id.toString(),
      name: row.name,
      organizationId: '1',
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
    };

    res.json(site);
  } catch (error) {
    console.error('Error fetching site:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create site endpoint (v1 API)
app.post('/api/v1/sites', async (req, res) => {
  try {
    const { name, location, capacity, organizationId } = req.body;
    
    if (!name || !location || !capacity) {
      return res.status(400).json({ error: 'Name, location, and capacity are required' });
    }

    // For demo purposes, create a mock site
    const site = {
      id: Date.now().toString(),
      name,
      organizationId: organizationId || '1',
      location: {
        address: location.address || 'Unknown Location',
        latitude: location.latitude || 0,
        longitude: location.longitude || 0,
        timezone: location.timezone || 'America/New_York'
      },
      capacity: parseFloat(capacity),
      status: 'ACTIVE',
      installationDate: new Date().toISOString(),
      lastMaintenance: null,
      nextMaintenance: null,
      performance: {
        currentGeneration: 0,
        totalGeneration: 0,
        efficiency: 95.2,
        uptime: 99.1
      },
      alerts: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    res.status(201).json(site);
  } catch (error) {
    console.error('Error creating site:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update site endpoint (v1 API)
app.put('/api/v1/sites/:siteId', async (req, res) => {
  try {
    const { siteId } = req.params;
    const updateData = req.body;
    
    // For demo purposes, return updated mock data
    const site = {
      id: siteId,
      ...updateData,
      updatedAt: new Date().toISOString()
    };

    res.json(site);
  } catch (error) {
    console.error('Error updating site:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete site endpoint (v1 API)
app.delete('/api/v1/sites/:siteId', async (req, res) => {
  try {
    const { siteId } = req.params;
    
    // For demo purposes, just return success
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting site:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Alerts endpoint (v1 API)
app.get('/api/v1/alerts', async (req, res) => {
  try {
    const { organizationId, status } = req.query;
    
    let query = `
      SELECT a.*, i.name as installation_name
      FROM alerts a
      JOIN installations i ON a.installation_id = i.id
    `;
    
    const params = [];
    const conditions = [];
    
    if (status) {
      if (status === 'ACTIVE') {
        conditions.push('is_resolved = false');
      } else if (status === 'RESOLVED') {
        conditions.push('is_resolved = true');
      }
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY created_at DESC LIMIT 50';
    
    const result = await pool.query(query, params);
    
    // Transform to match frontend expectations
    const alerts = result.rows.map(row => ({
      id: row.id.toString(),
      siteId: row.installation_id.toString(),
      siteName: row.installation_name,
      type: row.alert_type || 'PERFORMANCE',
      severity: row.severity || 'MEDIUM',
      title: row.message || 'Alert',
      description: row.description || row.message || 'System alert',
      status: row.is_resolved ? 'RESOLVED' : 'ACTIVE',
      createdAt: row.created_at,
      acknowledgedAt: row.acknowledged_at,
      resolvedAt: row.resolved_at,
      organizationId: organizationId || '1'
    }));

    res.json(alerts);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Acknowledge alert endpoint (v1 API)
app.put('/api/v1/alerts/:alertId/acknowledge', async (req, res) => {
  try {
    const { alertId } = req.params;
    
    // For demo purposes, return mock acknowledged alert
    const alert = {
      id: alertId,
      status: 'ACKNOWLEDGED',
      acknowledgedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    res.json(alert);
  } catch (error) {
    console.error('Error acknowledging alert:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Resolve alert endpoint (v1 API)
app.put('/api/v1/alerts/:alertId/resolve', async (req, res) => {
  try {
    const { alertId } = req.params;
    const { resolution } = req.body;
    
    // For demo purposes, return mock resolved alert
    const alert = {
      id: alertId,
      status: 'RESOLVED',
      resolution: resolution || 'Resolved by user',
      resolvedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    res.json(alert);
  } catch (error) {
    console.error('Error resolving alert:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Energy data endpoint (v1 API)
app.get('/api/v1/energy/:siteId', async (req, res) => {
  try {
    const { siteId } = req.params;
    const { startDate, endDate, interval = 'hour' } = req.query;
    
    let dateFilter = "date >= CURRENT_DATE - INTERVAL '7 days'";
    const params = [siteId];
    
    if (startDate && endDate) {
      dateFilter = "date >= $2 AND date <= $3";
      params.push(startDate, endDate);
    }

    const result = await pool.query(`
      SELECT 
        date,
        energy_kwh,
        temperature,
        irradiance,
        weather_condition
      FROM energy_generation 
      WHERE installation_id = $1 AND ${dateFilter}
      ORDER BY date DESC
    `, params);
    
    // Transform to match frontend expectations
    const energyData = result.rows.map(row => ({
      timestamp: row.date,
      generation: parseFloat(row.energy_kwh || 0),
      consumption: parseFloat(row.energy_kwh || 0) * 0.8, // Mock consumption
      temperature: parseFloat(row.temperature || 25),
      irradiance: parseFloat(row.irradiance || 800),
      weather: row.weather_condition || 'sunny'
    }));

    res.json(energyData);
  } catch (error) {
    console.error('Error fetching energy data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Real-time energy data endpoint (v1 API)
app.get('/api/v1/energy/:siteId/realtime', async (req, res) => {
  try {
    const { siteId } = req.params;
    
    // Mock real-time data
    const realtimeData = {
      timestamp: new Date().toISOString(),
      generation: Math.random() * 100 + 50, // Random generation between 50-150 kW
      consumption: Math.random() * 80 + 40,  // Random consumption between 40-120 kW
      temperature: Math.random() * 10 + 20,  // Random temp between 20-30°C
      irradiance: Math.random() * 200 + 700, // Random irradiance between 700-900 W/m²
      weather: ['sunny', 'partly_cloudy', 'cloudy'][Math.floor(Math.random() * 3)]
    };

    res.json(realtimeData);
  } catch (error) {
    console.error('Error fetching real-time energy data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Performance analytics endpoint (v1 API)
app.get('/api/v1/analytics/performance/:siteId', async (req, res) => {
  try {
    const { siteId } = req.params;
    const { startDate, endDate } = req.query;
    
    // Mock performance analytics data
    const analytics = {
      siteId,
      period: { startDate, endDate },
      metrics: {
        totalGeneration: Math.random() * 10000 + 5000,
        averageEfficiency: Math.random() * 10 + 90,
        uptime: Math.random() * 5 + 95,
        peakGeneration: Math.random() * 200 + 100,
        co2Saved: Math.random() * 1000 + 500
      },
      trends: {
        generationTrend: Math.random() > 0.5 ? 'increasing' : 'decreasing',
        efficiencyTrend: Math.random() > 0.5 ? 'improving' : 'declining'
      }
    };

    res.json(analytics);
  } catch (error) {
    console.error('Error fetching performance analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Financial analytics endpoint (v1 API)
app.get('/api/v1/analytics/financial/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    const { startDate, endDate } = req.query;
    
    // Get financial data from existing endpoint
    const result = await pool.query(`
      SELECT 
        date,
        SUM(energy_sold_kwh) as total_energy_sold,
        SUM(revenue) as total_revenue,
        SUM(savings) as total_savings,
        AVG(ppa_rate) as avg_ppa_rate
      FROM financial_data 
      WHERE date >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY date
      ORDER BY date DESC
    `);
    
    const totalRevenue = result.rows.reduce((sum, row) => sum + parseFloat(row.total_revenue || 0), 0);
    const totalSavings = result.rows.reduce((sum, row) => sum + parseFloat(row.total_savings || 0), 0);
    
    const analytics = {
      organizationId,
      period: { startDate, endDate },
      metrics: {
        totalRevenue,
        totalSavings,
        totalProfit: totalRevenue - (totalRevenue * 0.3), // Mock cost calculation
        averagePpaRate: result.rows.length > 0 ? result.rows[0].avg_ppa_rate : 0.12,
        roi: ((totalRevenue - (totalRevenue * 0.3)) / (totalRevenue * 0.3)) * 100
      },
      trends: result.rows.map(row => ({
        date: row.date,
        revenue: parseFloat(row.total_revenue || 0),
        savings: parseFloat(row.total_savings || 0)
      }))
    };

    res.json(analytics);
  } catch (error) {
    console.error('Error fetching financial analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Environmental impact endpoint (v1 API)
app.get('/api/v1/analytics/environmental/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    
    // Calculate environmental impact from energy generation
    const result = await pool.query(`
      SELECT COALESCE(SUM(energy_kwh), 0) as total_generation
      FROM energy_generation 
      WHERE date >= CURRENT_DATE - INTERVAL '1 year'
    `);
    
    const totalGeneration = parseFloat(result.rows[0].total_generation || 0);
    const co2Factor = 0.0004; // kg CO2 per kWh saved
    
    const impact = {
      organizationId,
      metrics: {
        totalEnergyGenerated: totalGeneration,
        co2Saved: totalGeneration * co2Factor,
        treesEquivalent: Math.floor((totalGeneration * co2Factor) / 21), // Rough calculation
        carsOffRoad: Math.floor((totalGeneration * co2Factor) / 4600), // Rough calculation
        homesEquivalent: Math.floor(totalGeneration / 10950) // Average home consumption
      },
      trends: {
        monthlyGeneration: [], // Would be populated with monthly data
        monthlyCo2Saved: []
      }
    };

    res.json(impact);
  } catch (error) {
    console.error('Error fetching environmental impact:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Users endpoint (v1 API)
app.get('/api/v1/users', async (req, res) => {
  try {
    const { organizationId } = req.query;
    
    // Mock users data
    const users = [
      {
        id: '1',
        email: 'admin@nexusgreen.com',
        firstName: 'Admin',
        lastName: 'User',
        role: 'ADMIN',
        organizationId: organizationId || '1',
        avatar: null,
        lastLogin: new Date().toISOString(),
        isActive: true,
        permissions: ['read', 'write', 'admin'],
        emailVerified: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        id: '2',
        email: 'manager@nexusgreen.com',
        firstName: 'Manager',
        lastName: 'User',
        role: 'MANAGER',
        organizationId: organizationId || '1',
        avatar: null,
        lastLogin: new Date().toISOString(),
        isActive: true,
        permissions: ['read', 'write'],
        emailVerified: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];

    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create user endpoint (v1 API)
app.post('/api/v1/users', async (req, res) => {
  try {
    const userData = req.body;
    
    // Mock user creation
    const user = {
      id: Date.now().toString(),
      ...userData,
      isActive: true,
      emailVerified: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    res.status(201).json(user);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user endpoint (v1 API)
app.put('/api/v1/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;
    
    // Mock user update
    const user = {
      id: userId,
      ...updateData,
      updatedAt: new Date().toISOString()
    };

    res.json(user);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete user endpoint (v1 API)
app.delete('/api/v1/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Mock user deletion
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Organization endpoint (v1 API)
app.get('/api/v1/organizations/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    
    // Mock organization data
    const organization = {
      id: organizationId,
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

    res.json(organization);
  } catch (error) {
    console.error('Error fetching organization:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update organization endpoint (v1 API)
app.put('/api/v1/organizations/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    const updateData = req.body;
    
    // Mock organization update
    const organization = {
      id: organizationId,
      ...updateData,
      updatedAt: new Date().toISOString()
    };

    res.json(organization);
  } catch (error) {
    console.error('Error updating organization:', error);
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