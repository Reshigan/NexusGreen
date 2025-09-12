import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';

import { config } from '@/config/config';
import { logger } from '@/utils/logger';
import { errorHandler } from '@/middleware/errorHandler';
import { rateLimiter } from '@/middleware/rateLimiter';
import { requestLogger } from '@/middleware/requestLogger';
import { multiTenantMiddleware } from '@/middleware/multiTenant';
import { dataSyncService } from '@/services/dataSyncService';

// Import routes
import authRoutes from '@/routes/auth';
import userRoutes from '@/routes/users';
import organizationRoutes from '@/routes/organizations';
import siteRoutes from '@/routes/sites';
import deviceRoutes from '@/routes/devices';
import energyRoutes from '@/routes/energy';
import analyticsRoutes from '@/routes/analytics';
import alertRoutes from '@/routes/alerts';
import sdgRoutes from '@/routes/sdg';
import financialRoutes from '@/routes/financial';
import predictionRoutes from '@/routes/predictions';
import solarRoutes from '@/routes/solar';

// Load environment variables
dotenv.config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.NODE_ENV === 'production' 
      ? ['https://solarnexus.com', 'https://www.solarnexus.com']
      : ['http://localhost:3000', 'http://localhost:5173'],
    credentials: true
  }
});

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "wss:", "ws:"],
    },
  },
  crossOriginEmbedderPolicy: false
}));

// CORS configuration
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://solarnexus.com', 'https://www.solarnexus.com']
    : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:12000', 'http://localhost:12001'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Organization-Id']
}));

// General middleware
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));
}
app.use(requestLogger);

// Rate limiting
app.use(rateLimiter);

// Multi-tenant middleware
app.use(multiTenantMiddleware);

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/organizations', organizationRoutes);
app.use('/api/sites', siteRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/energy', energyRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/sdg', sdgRoutes);
app.use('/api/financial', financialRoutes);
app.use('/api/predictions', predictionRoutes);
app.use('/api/solar', solarRoutes);

// Socket.IO for real-time updates
io.on('connection', (socket) => {
  logger.info(`Client connected: ${socket.id}`);
  
  socket.on('join-organization', (organizationId: string) => {
    socket.join(`org-${organizationId}`);
    logger.info(`Client ${socket.id} joined organization ${organizationId}`);
  });

  socket.on('join-site', (siteId: string) => {
    socket.join(`site-${siteId}`);
    logger.info(`Client ${socket.id} joined site ${siteId}`);
  });

  socket.on('disconnect', () => {
    logger.info(`Client disconnected: ${socket.id}`);
  });
});

// Make io available to other modules
app.set('io', io);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl
  });
});

// Error handling middleware (must be last)
app.use(errorHandler);

const PORT = config.port || 3000;
const HOST = config.host || '0.0.0.0';

server.listen(PORT, HOST, () => {
  logger.info(`🚀 SolarNexus server running on ${HOST}:${PORT}`);
  logger.info(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`🔗 Health check: http://${HOST}:${PORT}/health`);
  
  // Start data synchronization service
  try {
    dataSyncService.start();
    logger.info('📡 Data synchronization service started');
  } catch (error) {
    logger.error('Failed to start data sync service:', error);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

export { app, io };