"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.io = exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const compression_1 = __importDefault(require("compression"));
const morgan_1 = __importDefault(require("morgan"));
const http_1 = require("http");
const socket_io_1 = require("socket.io");
const dotenv_1 = __importDefault(require("dotenv"));
const config_1 = require("@/config/config");
const logger_1 = require("@/utils/logger");
const errorHandler_1 = require("@/middleware/errorHandler");
const rateLimiter_1 = require("@/middleware/rateLimiter");
const requestLogger_1 = require("@/middleware/requestLogger");
const multiTenant_1 = require("@/middleware/multiTenant");
const dataSyncService_1 = require("@/services/dataSyncService");
// Import routes
const auth_1 = __importDefault(require("@/routes/auth"));
const users_1 = __importDefault(require("@/routes/users"));
const organizations_1 = __importDefault(require("@/routes/organizations"));
const sites_1 = __importDefault(require("@/routes/sites"));
const devices_1 = __importDefault(require("@/routes/devices"));
const energy_1 = __importDefault(require("@/routes/energy"));
const analytics_1 = __importDefault(require("@/routes/analytics"));
const alerts_1 = __importDefault(require("@/routes/alerts"));
const sdg_1 = __importDefault(require("@/routes/sdg"));
const financial_1 = __importDefault(require("@/routes/financial"));
const predictions_1 = __importDefault(require("@/routes/predictions"));
const solar_1 = __importDefault(require("@/routes/solar"));
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
exports.app = app;
const server = (0, http_1.createServer)(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: process.env.NODE_ENV === 'production'
            ? ['https://solarnexus.com', 'https://www.solarnexus.com']
            : ['http://localhost:3000', 'http://localhost:5173'],
        credentials: true
    }
});
exports.io = io;
// Security middleware
app.use((0, helmet_1.default)({
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
app.use((0, cors_1.default)({
    origin: process.env.NODE_ENV === 'production'
        ? ['https://solarnexus.com', 'https://www.solarnexus.com']
        : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:12000', 'http://localhost:12001'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Organization-Id']
}));
// General middleware
app.use((0, compression_1.default)());
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
// Logging
if (process.env.NODE_ENV !== 'test') {
    app.use((0, morgan_1.default)('combined', { stream: { write: (message) => logger_1.logger.info(message.trim()) } }));
}
app.use(requestLogger_1.requestLogger);
// Rate limiting
app.use(rateLimiter_1.rateLimiter);
// Multi-tenant middleware
app.use(multiTenant_1.multiTenantMiddleware);
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
app.use('/api/auth', auth_1.default);
app.use('/api/users', users_1.default);
app.use('/api/organizations', organizations_1.default);
app.use('/api/sites', sites_1.default);
app.use('/api/devices', devices_1.default);
app.use('/api/energy', energy_1.default);
app.use('/api/analytics', analytics_1.default);
app.use('/api/alerts', alerts_1.default);
app.use('/api/sdg', sdg_1.default);
app.use('/api/financial', financial_1.default);
app.use('/api/predictions', predictions_1.default);
app.use('/api/solar', solar_1.default);
// Socket.IO for real-time updates
io.on('connection', (socket) => {
    logger_1.logger.info(`Client connected: ${socket.id}`);
    socket.on('join-organization', (organizationId) => {
        socket.join(`org-${organizationId}`);
        logger_1.logger.info(`Client ${socket.id} joined organization ${organizationId}`);
    });
    socket.on('join-site', (siteId) => {
        socket.join(`site-${siteId}`);
        logger_1.logger.info(`Client ${socket.id} joined site ${siteId}`);
    });
    socket.on('disconnect', () => {
        logger_1.logger.info(`Client disconnected: ${socket.id}`);
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
app.use(errorHandler_1.errorHandler);
const PORT = config_1.config.port || 3000;
const HOST = config_1.config.host || '0.0.0.0';
server.listen(PORT, HOST, () => {
    logger_1.logger.info(`🚀 SolarNexus server running on ${HOST}:${PORT}`);
    logger_1.logger.info(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    logger_1.logger.info(`🔗 Health check: http://${HOST}:${PORT}/health`);
    // Start data synchronization service
    try {
        dataSyncService_1.dataSyncService.start();
        logger_1.logger.info('📡 Data synchronization service started');
    }
    catch (error) {
        logger_1.logger.error('Failed to start data sync service:', error);
    }
});
// Graceful shutdown
process.on('SIGTERM', () => {
    logger_1.logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger_1.logger.info('Process terminated');
        process.exit(0);
    });
});
process.on('SIGINT', () => {
    logger_1.logger.info('SIGINT received, shutting down gracefully');
    server.close(() => {
        logger_1.logger.info('Process terminated');
        process.exit(0);
    });
});
//# sourceMappingURL=server.js.map