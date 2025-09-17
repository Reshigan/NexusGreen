import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// User roles enum
export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  CUSTOMER = 'CUSTOMER',
  FUNDER = 'FUNDER',
  OM_PROVIDER = 'OM_PROVIDER'
}

// Permission structure
export interface Permission {
  resource: string;
  action: string;
  scope?: 'own' | 'funded' | 'contracted' | 'all';
  projectId?: number;
  siteId?: number;
}

// User interface
export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  phone?: string;
  company?: string;
  title?: string;
  avatarUrl?: string;
  isActive: boolean;
  emailVerified: boolean;
  lastLogin?: string;
  createdAt: string;
  updatedAt: string;
}

// User role assignment
export interface UserRoleAssignment {
  id: number;
  userId: number;
  roleId: number;
  roleName: UserRole;
  roleDisplayName: string;
  projectId?: number;
  siteId?: number;
  permissions: Permission[];
  grantedBy: number;
  grantedAt: string;
  expiresAt?: string;
  isActive: boolean;
}

// Organization/Company info
export interface Organization {
  id: number;
  name: string;
  type: 'INSTALLER' | 'CUSTOMER' | 'FUNDER' | 'OM_PROVIDER';
  logo?: string;
  address?: string;
  country: string;
  timezone: string;
  settings: {
    theme: 'light' | 'dark';
    currency: string;
    timezone: string;
  };
}

// Auth context interface
export interface MultiPortalAuthContextType {
  user: User | null;
  roles: UserRoleAssignment[];
  organization: Organization | null;
  currentPortal: UserRole | null;
  accessibleProjects: number[];
  accessibleSites: number[];
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  switchPortal: (portal: UserRole) => void;
  hasPermission: (resource: string, action: string, projectId?: number, siteId?: number) => boolean;
  hasRole: (role: UserRole, projectId?: number, siteId?: number) => boolean;
  getAccessiblePortals: () => UserRole[];
  refreshPermissions: () => Promise<void>;
}

const MultiPortalAuthContext = createContext<MultiPortalAuthContextType | undefined>(undefined);

interface MultiPortalAuthProviderProps {
  children: ReactNode;
}

export const MultiPortalAuthProvider: React.FC<MultiPortalAuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [roles, setRoles] = useState<UserRoleAssignment[]>([]);
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [currentPortal, setCurrentPortal] = useState<UserRole | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Initialize auth state from localStorage
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const token = localStorage.getItem('accessToken');
        const savedPortal = localStorage.getItem('currentPortal') as UserRole;
        
        if (token) {
          // Validate token and get user info
          const response = await fetch('/api/v1/auth/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });
          
          if (response.ok) {
            const userData = await response.json();
            setUser(userData.user);
            setRoles(userData.roles);
            setOrganization(userData.organization);
            
            // Set current portal based on saved preference or first available role
            const availablePortals = getAvailablePortals(userData.roles);
            if (savedPortal && availablePortals.includes(savedPortal)) {
              setCurrentPortal(savedPortal);
            } else if (availablePortals.length > 0) {
              setCurrentPortal(availablePortals[0]);
            }
          } else {
            // Token invalid, clear auth state
            localStorage.removeItem('accessToken');
            localStorage.removeItem('refreshToken');
            localStorage.removeItem('currentPortal');
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();
  }, []);

  // Get available portals based on user roles
  const getAvailablePortals = (userRoles: UserRoleAssignment[]): UserRole[] => {
    return Array.from(new Set(userRoles.map(role => role.roleName)));
  };

  // Calculate accessible projects and sites
  const accessibleProjects = React.useMemo(() => {
    const projectIds = new Set<number>();
    roles.forEach(role => {
      if (role.projectId) {
        projectIds.add(role.projectId);
      }
    });
    return Array.from(projectIds);
  }, [roles]);

  const accessibleSites = React.useMemo(() => {
    const siteIds = new Set<number>();
    roles.forEach(role => {
      if (role.siteId) {
        siteIds.add(role.siteId);
      }
    });
    return Array.from(siteIds);
  }, [roles]);

  // Login function
  const login = async (email: string, password: string): Promise<void> => {
    try {
      setIsLoading(true);
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Login failed');
      }

      const data = await response.json();
      
      // Store tokens
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('refreshToken', data.refreshToken);
      
      // Set user data
      setUser(data.user);
      setRoles(data.roles);
      setOrganization(data.organization);
      
      // Set default portal
      const availablePortals = getAvailablePortals(data.roles);
      if (availablePortals.length > 0) {
        const defaultPortal = availablePortals[0];
        setCurrentPortal(defaultPortal);
        localStorage.setItem('currentPortal', defaultPortal);
      }
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  // Logout function
  const logout = async (): Promise<void> => {
    try {
      const token = localStorage.getItem('accessToken');
      if (token) {
        await fetch('/api/v1/auth/logout', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
      }
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      // Clear all auth state
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('currentPortal');
      setUser(null);
      setRoles([]);
      setOrganization(null);
      setCurrentPortal(null);
    }
  };

  // Switch portal
  const switchPortal = (portal: UserRole): void => {
    const availablePortals = getAccessiblePortals();
    if (availablePortals.includes(portal)) {
      setCurrentPortal(portal);
      localStorage.setItem('currentPortal', portal);
    } else {
      throw new Error(`Access denied to ${portal} portal`);
    }
  };

  // Check if user has specific permission
  const hasPermission = (
    resource: string, 
    action: string, 
    projectId?: number, 
    siteId?: number
  ): boolean => {
    if (!user || !currentPortal) return false;

    // Super admin has all permissions
    if (roles.some(role => role.roleName === UserRole.SUPER_ADMIN)) {
      return true;
    }

    // Check specific permissions for current portal
    const currentRoles = roles.filter(role => 
      role.roleName === currentPortal && role.isActive
    );

    return currentRoles.some(role => {
      return role.permissions.some(permission => {
        // Check resource and action match
        if (permission.resource !== resource && permission.resource !== '*') {
          return false;
        }
        if (permission.action !== action && permission.action !== '*') {
          return false;
        }

        // Check scope restrictions
        if (permission.scope) {
          switch (permission.scope) {
            case 'own':
              // User can only access their own resources
              return true; // Additional logic needed based on user ownership
            case 'funded':
              // Funder can only access funded projects
              return role.projectId ? accessibleProjects.includes(role.projectId) : false;
            case 'contracted':
              // O&M provider can only access contracted sites
              return role.siteId ? accessibleSites.includes(role.siteId) : false;
            case 'all':
              return true;
          }
        }

        // Check project/site specific permissions
        if (projectId && permission.projectId && permission.projectId !== projectId) {
          return false;
        }
        if (siteId && permission.siteId && permission.siteId !== siteId) {
          return false;
        }

        return true;
      });
    });
  };

  // Check if user has specific role
  const hasRole = (role: UserRole, projectId?: number, siteId?: number): boolean => {
    return roles.some(userRole => 
      userRole.roleName === role && 
      userRole.isActive &&
      (!projectId || userRole.projectId === projectId) &&
      (!siteId || userRole.siteId === siteId)
    );
  };

  // Get accessible portals
  const getAccessiblePortals = (): UserRole[] => {
    return getAvailablePortals(roles);
  };

  // Refresh permissions
  const refreshPermissions = async (): Promise<void> => {
    try {
      const token = localStorage.getItem('accessToken');
      if (!token) return;

      const response = await fetch('/api/v1/auth/permissions', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setRoles(data.roles);
      }
    } catch (error) {
      console.error('Error refreshing permissions:', error);
    }
  };

  const contextValue: MultiPortalAuthContextType = {
    user,
    roles,
    organization,
    currentPortal,
    accessibleProjects,
    accessibleSites,
    isAuthenticated: !!user,
    isLoading,
    login,
    logout,
    switchPortal,
    hasPermission,
    hasRole,
    getAccessiblePortals,
    refreshPermissions
  };

  return (
    <MultiPortalAuthContext.Provider value={contextValue}>
      {children}
    </MultiPortalAuthContext.Provider>
  );
};

// Hook to use auth context
export const useMultiPortalAuth = (): MultiPortalAuthContextType => {
  const context = useContext(MultiPortalAuthContext);
  if (context === undefined) {
    throw new Error('useMultiPortalAuth must be used within a MultiPortalAuthProvider');
  }
  return context;
};

// Permission checking hook
export const usePermissions = () => {
  const { hasPermission, hasRole, currentPortal } = useMultiPortalAuth();
  
  return {
    hasPermission,
    hasRole,
    currentPortal,
    canAccessSuperAdmin: () => hasRole(UserRole.SUPER_ADMIN),
    canAccessCustomer: () => hasRole(UserRole.CUSTOMER),
    canAccessFunder: () => hasRole(UserRole.FUNDER),
    canAccessOMProvider: () => hasRole(UserRole.OM_PROVIDER),
    canManageProjects: () => hasPermission('projects', 'write'),
    canManageSites: () => hasPermission('sites', 'write'),
    canManageUsers: () => hasPermission('users', 'write'),
    canViewFinancials: () => hasPermission('financial', 'read'),
    canManageMaintenance: () => hasPermission('maintenance', 'write'),
  };
};