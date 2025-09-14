"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestLogger = void 0;
const uuid_1 = require("uuid");
const logger_1 = require("@/utils/logger");
const requestLogger = (req, res, next) => {
    // Generate unique request ID
    req.requestId = (0, uuid_1.v4)();
    // Add request ID to response headers
    res.setHeader('X-Request-ID', req.requestId);
    // Log request start
    const startTime = Date.now();
    logger_1.logger.info('Request started', {
        requestId: req.requestId,
        method: req.method,
        url: req.url,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        organizationId: req.headers['x-organization-id'],
    });
    // Override res.json to log response
    const originalJson = res.json;
    res.json = function (body) {
        const duration = Date.now() - startTime;
        logger_1.logger.info('Request completed', {
            requestId: req.requestId,
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            responseSize: JSON.stringify(body).length,
        });
        return originalJson.call(this, body);
    };
    next();
};
exports.requestLogger = requestLogger;
//# sourceMappingURL=requestLogger.js.map