const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false  // Disable SSL for local Docker deployment
});

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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('healthy');
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
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Nexus Green API server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.DATABASE_URL ? 'Connected' : 'Not configured'}`);
});

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