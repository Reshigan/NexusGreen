import { Request, Response, NextFunction } from 'express';
import { UserRole } from '@prisma/client';
import { AuthenticatedRequest } from '../types/express';

export interface RolePermissions {
  [key: string]: {
    allowedRoles: UserRole[];
    requiresOwnResource?: boolean;
    requiresProjectAccess?: boolean;
  };
}

// Define role-based permissions for different endpoints
export const rolePermissions: RolePermissions = {
  // Super Admin routes
  '/api/dashboard/super-admin': {
    allowedRoles: [UserRole.SUPER_ADMIN]
  },
  '/api/organizations': {
    allowedRoles: [UserRole.SUPER_ADMIN]
  },
  '/api/users/create': {
    allowedRoles: [UserRole.SUPER_ADMIN, UserRole.PROJECT_ADMIN]
  },
  
  // Customer routes
  '/api/dashboard/customer': {
    allowedRoles: [UserRole.CUSTOMER],
    requiresOwnResource: true
  },
  
  // Operator routes
  '/api/dashboard/operator': {
    allowedRoles: [UserRole.OPERATOR],
    requiresOwnResource: true
  },
  '/api/sites': {
    allowedRoles: [UserRole.OPERATOR, UserRole.PROJECT_ADMIN, UserRole.SUPER_ADMIN],
    requiresProjectAccess: true
  },
  
  // Funder routes
  '/api/dashboard/funder': {
    allowedRoles: [UserRole.FUNDER],
    requiresOwnResource: true
  },
  '/api/financial': {
    allowedRoles: [UserRole.FUNDER, UserRole.SUPER_ADMIN],
    requiresOwnResource: true
  },
  
  // Project Admin routes
  '/api/dashboard/project-admin': {
    allowedRoles: [UserRole.PROJECT_ADMIN],
    requiresProjectAccess: true
  }
};

export function checkRolePermission(requiredRoles: UserRole[], options?: {
  requiresOwnResource?: boolean;
  requiresProjectAccess?: boolean;
}) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { user } = req;
    
    if (!user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    // Check if user has required role
    if (!requiredRoles.includes(user.role)) {
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        required: requiredRoles,
        current: user.role
      });
    }

    // Additional checks based on options
    if (options?.requiresOwnResource) {
      // For organization-scoped resources, ensure user belongs to the organization
      const organizationId = req.params.organizationId || req.body.organizationId || req.query.organizationId;
      if (organizationId && organizationId !== user.organizationId && user.role !== UserRole.SUPER_ADMIN) {
        return res.status(403).json({ error: 'Access denied to this organization' });
      }
    }

    if (options?.requiresProjectAccess) {
      // For project-scoped resources, ensure user has access to the project
      const projectId = req.params.projectId || req.body.projectId || req.query.projectId;
      if (projectId) {
        if (user.role === UserRole.PROJECT_ADMIN && user.projectId !== projectId) {
          return res.status(403).json({ error: 'Access denied to this project' });
        }
        // Super admins and operators can access any project in their organization
      }
    }

    next();
  };
}

// Middleware to enforce multi-tenant isolation
export function enforceMultiTenancy(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const { user } = req;
  
  if (!user) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  // Super admins can access all data
  if (user.role === UserRole.SUPER_ADMIN) {
    return next();
  }

  // Add organization filter to query for non-super-admin users
  if (req.method === 'GET') {
    req.query.organizationId = user.organizationId;
  } else if (req.method === 'POST' || req.method === 'PUT' || req.method === 'PATCH') {
    if (!req.body.organizationId) {
      req.body.organizationId = user.organizationId;
    } else if (req.body.organizationId !== user.organizationId) {
      return res.status(403).json({ error: 'Cannot access resources from other organizations' });
    }
  }

  next();
}

// Role hierarchy for permission inheritance
export const roleHierarchy: { [key in UserRole]: UserRole[] } = {
  [UserRole.SUPER_ADMIN]: [UserRole.SUPER_ADMIN, UserRole.PROJECT_ADMIN, UserRole.OPERATOR, UserRole.CUSTOMER, UserRole.FUNDER],
  [UserRole.PROJECT_ADMIN]: [UserRole.PROJECT_ADMIN, UserRole.OPERATOR],
  [UserRole.OPERATOR]: [UserRole.OPERATOR],
  [UserRole.CUSTOMER]: [UserRole.CUSTOMER],
  [UserRole.FUNDER]: [UserRole.FUNDER]
};

export function hasPermission(userRole: UserRole, requiredRole: UserRole): boolean {
  return roleHierarchy[userRole].includes(requiredRole);
}

// Dynamic permission checker based on resource type
export function checkResourcePermission(resourceType: string) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { user } = req;
    
    if (!user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const permissions = getResourcePermissions(resourceType, user.role);
    
    if (!permissions.canRead && req.method === 'GET') {
      return res.status(403).json({ error: 'Read access denied' });
    }
    
    if (!permissions.canWrite && ['POST', 'PUT', 'PATCH'].includes(req.method)) {
      return res.status(403).json({ error: 'Write access denied' });
    }
    
    if (!permissions.canDelete && req.method === 'DELETE') {
      return res.status(403).json({ error: 'Delete access denied' });
    }

    next();
  };
}

interface ResourcePermissions {
  canRead: boolean;
  canWrite: boolean;
  canDelete: boolean;
}

function getResourcePermissions(resourceType: string, userRole: UserRole): ResourcePermissions {
  const permissionMatrix: { [key: string]: { [key in UserRole]: ResourcePermissions } } = {
    organization: {
      [UserRole.SUPER_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.PROJECT_ADMIN]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.OPERATOR]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.CUSTOMER]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.FUNDER]: { canRead: true, canWrite: false, canDelete: false }
    },
    project: {
      [UserRole.SUPER_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.PROJECT_ADMIN]: { canRead: true, canWrite: true, canDelete: false },
      [UserRole.OPERATOR]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.CUSTOMER]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.FUNDER]: { canRead: true, canWrite: false, canDelete: false }
    },
    site: {
      [UserRole.SUPER_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.PROJECT_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.OPERATOR]: { canRead: true, canWrite: true, canDelete: false },
      [UserRole.CUSTOMER]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.FUNDER]: { canRead: true, canWrite: false, canDelete: false }
    },
    user: {
      [UserRole.SUPER_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.PROJECT_ADMIN]: { canRead: true, canWrite: true, canDelete: false },
      [UserRole.OPERATOR]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.CUSTOMER]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.FUNDER]: { canRead: true, canWrite: false, canDelete: false }
    },
    financial: {
      [UserRole.SUPER_ADMIN]: { canRead: true, canWrite: true, canDelete: true },
      [UserRole.FUNDER]: { canRead: true, canWrite: true, canDelete: false },
      [UserRole.PROJECT_ADMIN]: { canRead: true, canWrite: false, canDelete: false },
      [UserRole.OPERATOR]: { canRead: false, canWrite: false, canDelete: false },
      [UserRole.CUSTOMER]: { canRead: true, canWrite: false, canDelete: false }
    }
  };

  return permissionMatrix[resourceType]?.[userRole] || { canRead: false, canWrite: false, canDelete: false };
}