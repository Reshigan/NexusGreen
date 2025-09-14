"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.asyncHandler = exports.errorHandler = exports.createError = void 0;
const logger_1 = require("@/utils/logger");
const createError = (message, statusCode = 500) => {
    const error = new Error(message);
    error.statusCode = statusCode;
    error.isOperational = true;
    return error;
};
exports.createError = createError;
const errorHandler = (error, req, res, next) => {
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';
    // Log error
    logger_1.logger.error('Error occurred', {
        error: message,
        stack: error.stack,
        url: req.url,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        statusCode,
    });
    // Don't leak error details in production
    const isDevelopment = process.env.NODE_ENV === 'development';
    res.status(statusCode).json({
        success: false,
        message: isDevelopment ? message : 'Something went wrong',
        ...(isDevelopment && { stack: error.stack }),
        timestamp: new Date().toISOString(),
    });
};
exports.errorHandler = errorHandler;
const asyncHandler = (fn) => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};
exports.asyncHandler = asyncHandler;
//# sourceMappingURL=errorHandler.js.map