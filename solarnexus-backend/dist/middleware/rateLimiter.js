"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRateLimiter = exports.rateLimiter = void 0;
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const config_1 = require("@/config/config");
const logger_1 = require("@/utils/logger");
exports.rateLimiter = (0, express_rate_limit_1.default)({
    windowMs: config_1.config.rateLimit.windowMs,
    max: config_1.config.rateLimit.maxRequests,
    message: {
        success: false,
        message: 'Too many requests from this IP, please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger_1.logger.warn('Rate limit exceeded', {
            ip: req.ip,
            userAgent: req.get('User-Agent'),
            url: req.url,
        });
        res.status(429).json({
            success: false,
            message: 'Too many requests from this IP, please try again later.',
            retryAfter: Math.round(config_1.config.rateLimit.windowMs / 1000),
        });
    },
});
// Stricter rate limiting for auth endpoints
exports.authRateLimiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 attempts per window
    message: {
        success: false,
        message: 'Too many authentication attempts, please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true,
});
//# sourceMappingURL=rateLimiter.js.map