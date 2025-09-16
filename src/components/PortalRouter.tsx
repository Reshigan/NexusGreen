import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useMultiPortalAuth, UserRole } from '../contexts/MultiPortalAuthContext';
import { ProtectedRoute } from './ProtectedRoute';

// Portal layouts
import SuperAdminLayout from '../portals/super-admin/SuperAdminLayout';
import CustomerLayout from '../portals/customer/CustomerLayout';
import FunderLayout from '../portals/funder/FunderLayout';
import OMProviderLayout from '../portals/om-provider/OMProviderLayout';

// Portal pages - Super Admin
import SuperAdminDashboard from '../portals/super-admin/pages/Dashboard';
import ProjectManagement from '../portals/super-admin/pages/ProjectManagement';
import SiteManagement from '../portals/super-admin/pages/SiteManagement';
import UserManagement from '../portals/super-admin/pages/UserManagement';
import HardwareManagement from '../portals/super-admin/pages/HardwareManagement';
import RateManagement from '../portals/super-admin/pages/RateManagement';
import APIManagement from '../portals/super-admin/pages/APIManagement';

// Portal pages - Customer
import CustomerDashboard from '../portals/customer/pages/Dashboard';
import CustomerSavings from '../portals/customer/pages/Savings';
import CustomerSites from '../portals/customer/pages/Sites';
import CustomerReports from '../portals/customer/pages/Reports';

// Portal pages - Funder
import FunderDashboard from '../portals/funder/pages/Dashboard';
import FunderPortfolio from '../portals/funder/pages/Portfolio';
import FunderROI from '../portals/funder/pages/ROI';
import FunderAnalytics from '../portals/funder/pages/Analytics';

// Portal pages - O&M Provider
import OMDashboard from '../portals/om-provider/pages/Dashboard';
import OMMonitoring from '../portals/om-provider/pages/Monitoring';
import OMAlerts from '../portals/om-provider/pages/Alerts';
import OMMaintenance from '../portals/om-provider/pages/Maintenance';

// Shared components
import Login from '../pages/Login';
import PortalSelector from './PortalSelector';
import Unauthorized from '../pages/Unauthorized';

const PortalRouter: React.FC = () => {
  const { isAuthenticated, currentPortal, getAccessiblePortals } = useMultiPortalAuth();

  if (!isAuthenticated) {
    return (
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  if (!currentPortal) {
    const accessiblePortals = getAccessiblePortals();
    if (accessiblePortals.length === 0) {
      return <Unauthorized message="No portal access granted. Please contact your administrator." />;
    }
    return <PortalSelector availablePortals={accessiblePortals} />;
  }

  return (
    <Routes>
      {/* Portal Selection */}
      <Route path="/portal-selector" element={<PortalSelector availablePortals={getAccessiblePortals()} />} />
      
      {/* Super Admin Portal */}
      <Route path="/super-admin/*" element={
        <ProtectedRoute requiredRole={UserRole.SUPER_ADMIN}>
          <SuperAdminLayout>
            <Routes>
              <Route index element={<SuperAdminDashboard />} />
              <Route path="dashboard" element={<SuperAdminDashboard />} />
              <Route path="projects" element={<ProjectManagement />} />
              <Route path="sites" element={<SiteManagement />} />
              <Route path="users" element={<UserManagement />} />
              <Route path="hardware" element={<HardwareManagement />} />
              <Route path="rates" element={<RateManagement />} />
              <Route path="api" element={<APIManagement />} />
            </Routes>
          </SuperAdminLayout>
        </ProtectedRoute>
      } />

      {/* Customer Portal */}
      <Route path="/customer/*" element={
        <ProtectedRoute requiredRole={UserRole.CUSTOMER}>
          <CustomerLayout>
            <Routes>
              <Route index element={<CustomerDashboard />} />
              <Route path="dashboard" element={<CustomerDashboard />} />
              <Route path="savings" element={<CustomerSavings />} />
              <Route path="sites" element={<CustomerSites />} />
              <Route path="sites/:siteId" element={<CustomerSites />} />
              <Route path="reports" element={<CustomerReports />} />
            </Routes>
          </CustomerLayout>
        </ProtectedRoute>
      } />

      {/* Funder Portal */}
      <Route path="/funder/*" element={
        <ProtectedRoute requiredRole={UserRole.FUNDER}>
          <FunderLayout>
            <Routes>
              <Route index element={<FunderDashboard />} />
              <Route path="dashboard" element={<FunderDashboard />} />
              <Route path="portfolio" element={<FunderPortfolio />} />
              <Route path="roi" element={<FunderROI />} />
              <Route path="analytics" element={<FunderAnalytics />} />
            </Routes>
          </FunderLayout>
        </ProtectedRoute>
      } />

      {/* O&M Provider Portal */}
      <Route path="/om-provider/*" element={
        <ProtectedRoute requiredRole={UserRole.OM_PROVIDER}>
          <OMProviderLayout>
            <Routes>
              <Route index element={<OMDashboard />} />
              <Route path="dashboard" element={<OMDashboard />} />
              <Route path="monitoring" element={<OMMonitoring />} />
              <Route path="alerts" element={<OMAlerts />} />
              <Route path="maintenance" element={<OMMaintenance />} />
            </Routes>
          </OMProviderLayout>
        </ProtectedRoute>
      } />

      {/* Default redirects based on current portal */}
      <Route path="/" element={<Navigate to={getDefaultPortalPath(currentPortal)} replace />} />
      <Route path="/dashboard" element={<Navigate to={getDefaultPortalPath(currentPortal)} replace />} />
      
      {/* Unauthorized access */}
      <Route path="/unauthorized" element={<Unauthorized />} />
      
      {/* Catch all - redirect to appropriate portal */}
      <Route path="*" element={<Navigate to={getDefaultPortalPath(currentPortal)} replace />} />
    </Routes>
  );
};

// Helper function to get default path for each portal
const getDefaultPortalPath = (portal: UserRole): string => {
  switch (portal) {
    case UserRole.SUPER_ADMIN:
      return '/super-admin/dashboard';
    case UserRole.CUSTOMER:
      return '/customer/dashboard';
    case UserRole.FUNDER:
      return '/funder/dashboard';
    case UserRole.OM_PROVIDER:
      return '/om-provider/dashboard';
    default:
      return '/portal-selector';
  }
};

export default PortalRouter;