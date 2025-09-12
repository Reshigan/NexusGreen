import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/utils/database';
import { logger } from '@/utils/logger';

export interface MultiTenantRequest extends Request {
  organization?: {
    id: string;
    name: string;
    slug: string;
    settings?: any;
  };
}

export const multiTenantMiddleware = async (
  req: MultiTenantRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    // Skip multi-tenant for certain routes
    const skipRoutes = ['/health', '/api/auth/login', '/api/auth/signup'];
    if (skipRoutes.some(route => req.path.startsWith(route))) {
      return next();
    }

    // Get organization ID from header or subdomain
    let organizationId = req.headers['x-organization-id'] as string;
    
    // If no organization ID in header, try to extract from subdomain
    if (!organizationId) {
      const host = req.get('host');
      if (host) {
        const subdomain = host.split('.')[0];
        if (subdomain && subdomain !== 'www' && subdomain !== 'api') {
          // Look up organization by slug
          const org = await prisma.organization.findUnique({
            where: { slug: subdomain },
            select: { id: true, name: true, slug: true, settings: true, isActive: true },
          });
          
          if (org && org.isActive) {
            req.organization = org;
            organizationId = org.id;
          }
        }
      }
    } else {
      // Look up organization by ID
      const org = await prisma.organization.findUnique({
        where: { id: organizationId },
        select: { id: true, name: true, slug: true, settings: true, isActive: true },
      });
      
      if (org && org.isActive) {
        req.organization = org;
      }
    }

    // Log organization context
    if (req.organization) {
      logger.debug('Multi-tenant context', {
        organizationId: req.organization.id,
        organizationName: req.organization.name,
        path: req.path,
      });
    }

    next();
  } catch (error) {
    logger.error('Multi-tenant middleware error', { error });
    next(error);
  }
};

export const requireOrganization = (
  req: MultiTenantRequest,
  res: Response,
  next: NextFunction
) => {
  if (!req.organization) {
    return res.status(400).json({
      success: false,
      message: 'Organization context required',
    });
  }
  next();
};