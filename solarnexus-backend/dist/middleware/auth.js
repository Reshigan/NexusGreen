"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = exports.authenticateToken = exports.requireAnyRole = exports.requireOMProvider = exports.requireFunder = exports.requireCustomer = exports.requireSuperAdmin = exports.authorize = exports.authenticate = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const config_1 = require("@/config/config");
const database_1 = require("@/utils/database");
const errorHandler_1 = require("./errorHandler");
const client_1 = require("@prisma/client");
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw (0, errorHandler_1.createError)('Access token required', 401);
        }
        const token = authHeader.substring(7);
        const decoded = jsonwebtoken_1.default.verify(token, config_1.config.jwt.secret);
        const user = await database_1.prisma.user.findUnique({
            where: { id: decoded.userId },
            select: {
                id: true,
                email: true,
                role: true,
                organizationId: true,
                isActive: true,
            },
        });
        if (!user || !user.isActive) {
            throw (0, errorHandler_1.createError)('Invalid or inactive user', 401);
        }
        req.user = user;
        next();
    }
    catch (error) {
        if (error instanceof jsonwebtoken_1.default.JsonWebTokenError) {
            next((0, errorHandler_1.createError)('Invalid token', 401));
        }
        else {
            next(error);
        }
    }
};
exports.authenticate = authenticate;
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next((0, errorHandler_1.createError)('Authentication required', 401));
        }
        if (!roles.includes(req.user.role)) {
            return next((0, errorHandler_1.createError)('Insufficient permissions', 403));
        }
        next();
    };
};
exports.authorize = authorize;
exports.requireSuperAdmin = (0, exports.authorize)(client_1.UserRole.SUPER_ADMIN);
exports.requireCustomer = (0, exports.authorize)(client_1.UserRole.CUSTOMER, client_1.UserRole.SUPER_ADMIN);
exports.requireFunder = (0, exports.authorize)(client_1.UserRole.FUNDER, client_1.UserRole.SUPER_ADMIN);
exports.requireOMProvider = (0, exports.authorize)(client_1.UserRole.OM_PROVIDER, client_1.UserRole.SUPER_ADMIN);
exports.requireAnyRole = (0, exports.authorize)(client_1.UserRole.SUPER_ADMIN, client_1.UserRole.CUSTOMER, client_1.UserRole.FUNDER, client_1.UserRole.OM_PROVIDER);
// Aliases for backward compatibility
exports.authenticateToken = exports.authenticate;
exports.requireRole = exports.requireAnyRole;
//# sourceMappingURL=auth.js.map