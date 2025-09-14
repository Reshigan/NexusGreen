"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireOrganization = exports.multiTenantMiddleware = void 0;
const database_1 = require("@/utils/database");
const logger_1 = require("@/utils/logger");
const multiTenantMiddleware = async (req, res, next) => {
    try {
        // Skip multi-tenant for certain routes
        const skipRoutes = ['/health', '/api/auth/login', '/api/auth/signup'];
        if (skipRoutes.some(route => req.path.startsWith(route))) {
            return next();
        }
        // Get organization ID from header or subdomain
        let organizationId = req.headers['x-organization-id'];
        // If no organization ID in header, try to extract from subdomain
        if (!organizationId) {
            const host = req.get('host');
            if (host) {
                const subdomain = host.split('.')[0];
                if (subdomain && subdomain !== 'www' && subdomain !== 'api') {
                    // Look up organization by slug
                    const org = await database_1.prisma.organization.findUnique({
                        where: { slug: subdomain },
                        select: { id: true, name: true, slug: true, settings: true, isActive: true },
                    });
                    if (org && org.isActive) {
                        req.organization = org;
                        organizationId = org.id;
                    }
                }
            }
        }
        else {
            // Look up organization by ID
            const org = await database_1.prisma.organization.findUnique({
                where: { id: organizationId },
                select: { id: true, name: true, slug: true, settings: true, isActive: true },
            });
            if (org && org.isActive) {
                req.organization = org;
            }
        }
        // Log organization context
        if (req.organization) {
            logger_1.logger.debug('Multi-tenant context', {
                organizationId: req.organization.id,
                organizationName: req.organization.name,
                path: req.path,
            });
        }
        next();
    }
    catch (error) {
        logger_1.logger.error('Multi-tenant middleware error', { error });
        next(error);
    }
};
exports.multiTenantMiddleware = multiTenantMiddleware;
const requireOrganization = (req, res, next) => {
    if (!req.organization) {
        return res.status(400).json({
            success: false,
            message: 'Organization context required',
        });
    }
    next();
};
exports.requireOrganization = requireOrganization;
//# sourceMappingURL=multiTenant.js.map