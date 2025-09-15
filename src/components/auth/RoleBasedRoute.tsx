import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

interface RoleBasedRouteProps {
  children: React.ReactNode;
  allowedRoles: string[];
  fallbackPath?: string;
  requiresProject?: boolean;
}

export const RoleBasedRoute: React.FC<RoleBasedRouteProps> = ({
  children,
  allowedRoles,
  fallbackPath = '/unauthorized',
  requiresProject = false
}) => {
  const { user, isAuthenticated } = useAuth();
  const location = useLocation();

  // Redirect to login if not authenticated
  if (!isAuthenticated || !user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Check if user has required role
  if (!allowedRoles.includes(user.role)) {
    return <Navigate to={fallbackPath} replace />;
  }

  // Check project requirement for PROJECT_ADMIN role
  if (requiresProject && user.role === 'PROJECT_ADMIN' && !user.projectId) {
    return <Navigate to="/no-project-assigned" replace />;
  }

  return <>{children}</>;
};

// Higher-order component for role-based access
export function withRoleAccess(allowedRoles: string[], options?: {
  fallbackPath?: string;
  requiresProject?: boolean;
}) {
  return function <P extends object>(Component: React.ComponentType<P>) {
    return function RoleProtectedComponent(props: P) {
      return (
        <RoleBasedRoute 
          allowedRoles={allowedRoles}
          fallbackPath={options?.fallbackPath}
          requiresProject={options?.requiresProject}
        >
          <Component {...props} />
        </RoleBasedRoute>
      );
    };
  };
}

// Role-specific route components
export const SuperAdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['SUPER_ADMIN']}>
    {children}
  </RoleBasedRoute>
);

export const CustomerRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['CUSTOMER']}>
    {children}
  </RoleBasedRoute>
);

export const OperatorRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['OPERATOR']}>
    {children}
  </RoleBasedRoute>
);

export const FunderRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['FUNDER']}>
    {children}
  </RoleBasedRoute>
);

export const ProjectAdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['PROJECT_ADMIN']} requiresProject>
    {children}
  </RoleBasedRoute>
);

// Multi-role routes
export const AdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['SUPER_ADMIN', 'PROJECT_ADMIN']}>
    {children}
  </RoleBasedRoute>
);

export const OperationalRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['SUPER_ADMIN', 'PROJECT_ADMIN', 'OPERATOR']}>
    {children}
  </RoleBasedRoute>
);

export const FinancialRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <RoleBasedRoute allowedRoles={['SUPER_ADMIN', 'FUNDER']}>
    {children}
  </RoleBasedRoute>
);