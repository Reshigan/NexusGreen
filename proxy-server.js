const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from the frontend build
app.use(express.static(path.join(__dirname, 'frontend')));

// API proxy middleware
const apiProxy = createProxyMiddleware({
  target: 'http://localhost:3001',
  changeOrigin: true,
  timeout: 30000, // 30 second timeout
  proxyTimeout: 30000,
  pathRewrite: {
    '^/api': '/api', // Keep the /api prefix
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    console.error('Request URL:', req.url);
    console.error('Original URL:', req.originalUrl);
    console.error('Target:', 'http://localhost:3001');
    console.error('Error code:', err.code);
    res.status(500).json({ error: 'Backend service unavailable', details: err.message });
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying ${req.method} ${req.url} to backend`);
    console.log(`Target URL: ${proxyReq.path}`);
  }
});

// Apply API proxy for all /api routes
app.use('/api', apiProxy);

// Catch-all handler: send back React's index.html file for client-side routing
app.use((req, res) => {
  res.sendFile(path.join(__dirname, 'frontend', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Proxy server running on port ${PORT}`);
  console.log(`📱 Frontend: http://localhost:${PORT}`);
  console.log(`🔗 API Proxy: http://localhost:${PORT}/api -> http://localhost:3001/api`);
});