import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '@/config/config';
import { prisma } from '@/utils/database';
import { createError } from './errorHandler';
import { UserRole } from '@prisma/client';
import type { AuthenticatedRequest } from '@/types/express';

export type { AuthenticatedRequest };

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw createError('Access token required', 401);
    }

    const token = authHeader.substring(7);
    
    const decoded = jwt.verify(token, config.jwt.secret) as any;
    
    const user = await prisma.user.findUnique({
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
      throw createError('Invalid or inactive user', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(createError('Invalid token', 401));
    } else {
      next(error);
    }
  }
};

export const authorize = (...roles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(createError('Authentication required', 401));
    }

    if (!roles.includes(req.user.role)) {
      return next(createError('Insufficient permissions', 403));
    }

    next();
  };
};

export const requireSuperAdmin = authorize(UserRole.SUPER_ADMIN);
export const requireCustomer = authorize(UserRole.CUSTOMER, UserRole.SUPER_ADMIN);
export const requireFunder = authorize(UserRole.FUNDER, UserRole.SUPER_ADMIN);
export const requireOMProvider = authorize(UserRole.OM_PROVIDER, UserRole.SUPER_ADMIN);

export const requireAnyRole = authorize(
  UserRole.SUPER_ADMIN,
  UserRole.CUSTOMER,
  UserRole.FUNDER,
  UserRole.OM_PROVIDER
);

// Aliases for backward compatibility
export const authenticateToken = authenticate;
export const requireRole = requireAnyRole;