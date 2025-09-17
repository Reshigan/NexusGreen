import express from 'express';
import cors from 'cors';
import bcrypt from 'bcrypt';
import pkg from 'pg';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
const { Pool } = pkg;

const app = express();
const port = process.env.PORT || 3001;

// Database configuration
const pool = new Pool({
  user: process.env.DB_USER || 'nexusgreen',
  host: process.env.DB_HOST || 'postgres-service',
  database: process.env.DB_NAME || 'nexusgreen',
  password: process.env.DB_PASSWORD || 'nexusgreen',
  port: process.env.DB_PORT || 5432,
});

// CORS configuration - allow all origins for now
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

app.use(express.json());

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString(),
      dbTime: result.rows[0].now
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(500).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Username and password are required' 
      });
    }

    // Query user from database
    const result = await pool.query(
      'SELECT id, username, password_hash, email, role FROM users WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid credentials' 
      });
    }

    const user = result.rows[0];
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid credentials' 
      });
    }

    // Return user data (excluding password)
    res.json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
});

// Dashboard data endpoint
app.get('/api/dashboard', async (req, res) => {
  try {
    // Mock dashboard data for now
    const dashboardData = {
      energyProduction: {
        current: 2847.5,
        target: 3000,
        efficiency: 94.9
      },
      revenue: {
        today: 1423.75,
        month: 42712.50,
        year: 512550.00
      },
      performance: {
        uptime: 99.2,
        capacity: 85.7,
        maintenance: 2
      },
      alerts: [
        { id: 1, type: 'warning', message: 'Panel efficiency below optimal in Sector 3', timestamp: new Date() },
        { id: 2, type: 'info', message: 'Scheduled maintenance completed for Inverter Bank A', timestamp: new Date() }
      ]
    };

    res.json(dashboardData);
  } catch (error) {
    console.error('Dashboard data error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch dashboard data' 
    });
  }
});

// Dashboard metrics endpoint (for Phase 1 enhanced metrics)
app.get('/api/dashboard/metrics', async (req, res) => {
  try {
    const metrics = {
      totalEnergyProduction: 2847.5,
      currentEfficiency: 94.9,
      dailyRevenue: 1423.75,
      systemUptime: 99.2,
      activeAlerts: 2,
      carbonOffset: 1.8,
      peakPowerOutput: 3200,
      averageTemperature: 28.5,
      weatherCondition: 'Sunny',
      maintenanceScheduled: 1,
      energyStorageLevel: 87.3,
      gridConnectionStatus: 'Connected'
    };
    res.json(metrics);
  } catch (error) {
    console.error('Dashboard metrics error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch dashboard metrics' 
    });
  }
});

// Dashboard KPIs endpoint
app.get('/api/dashboard/kpis', async (req, res) => {
  try {
    const kpis = {
      energyEfficiency: { value: 94.9, trend: 'up', change: 2.1 },
      costSavings: { value: 15420, trend: 'up', change: 8.5 },
      carbonReduction: { value: 1.8, trend: 'up', change: 3.2 },
      systemReliability: { value: 99.2, trend: 'stable', change: 0.1 },
      maintenanceCosts: { value: 2340, trend: 'down', change: -12.3 },
      energyYield: { value: 87.6, trend: 'up', change: 4.7 }
    };
    res.json(kpis);
  } catch (error) {
    console.error('Dashboard KPIs error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch dashboard KPIs' 
    });
  }
});

// Chart data endpoints
app.get('/api/charts/energy-production', (req, res) => {
  const data = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [{
      label: 'Energy Production (kWh)',
      data: [2400, 2600, 2800, 2900, 3100, 2847],
      borderColor: 'rgb(34, 197, 94)',
      backgroundColor: 'rgba(34, 197, 94, 0.1)',
      tension: 0.4
    }]
  };
  res.json(data);
});

app.get('/api/charts/revenue-trends', (req, res) => {
  const data = {
    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    datasets: [{
      label: 'Revenue ($)',
      data: [8500, 9200, 8800, 9500],
      borderColor: 'rgb(59, 130, 246)',
      backgroundColor: 'rgba(59, 130, 246, 0.1)',
      tension: 0.4
    }]
  };
  res.json(data);
});

app.get('/api/charts/performance-analytics', (req, res) => {
  const data = {
    labels: ['System A', 'System B', 'System C', 'System D'],
    datasets: [{
      label: 'Efficiency (%)',
      data: [94, 87, 92, 89],
      backgroundColor: [
        'rgba(34, 197, 94, 0.8)',
        'rgba(251, 191, 36, 0.8)',
        'rgba(59, 130, 246, 0.8)',
        'rgba(168, 85, 247, 0.8)'
      ]
    }]
  };
  res.json(data);
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`Backend API server running on port ${port}`);
  console.log(`Health check: http://localhost:${port}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    process.exit(0);
  });
});