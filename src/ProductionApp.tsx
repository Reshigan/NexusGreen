import React, { useState, useEffect } from 'react';
import { Toaster } from 'sonner';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from '@/pages/Login';
import { Unauthorized, NoProjectAssigned } from '@/pages/Unauthorized';
import SuperAdminDashboard from '@/components/dashboard/SuperAdminDashboard';
import CustomerDashboard from '@/components/dashboard/CustomerDashboard';
import OperatorDashboard from '@/components/dashboard/OperatorDashboard';
import FunderDashboard from '@/components/dashboard/FunderDashboard';
import ProjectAdminDashboard from '@/components/dashboard/ProjectAdminDashboard';
import { nexusApi, type User, type Organization } from '@/services/nexusApi';

const ProductionApp: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [currentOrganization, setCurrentOrganization] = useState<Organization | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Check for existing session on app load
  useEffect(() => {
    const checkSession = () => {
      const user = nexusApi.getCurrentUser();
      const organization = nexusApi.getCurrentOrganization();
      
      if (user && organization && nexusApi.isAuthenticated()) {
        setCurrentUser(user);
        setCurrentOrganization(organization);
      }
      setIsLoading(false);
    };

    checkSession();
  }, []);

  const handleLogin = (user: User, organization: Organization) => {
    setCurrentUser(user);
    setCurrentOrganization(organization);
  };

  const handleLogout = async () => {
    try {
      await nexusApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setCurrentUser(null);
      setCurrentOrganization(null);
    }
  };

  // Loading screen
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 via-blue-50 to-orange-50">
        <div className="text-center">
          <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center">
            <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
              <div className="w-4 h-4 bg-gradient-to-r from-green-500 to-blue-500 rounded-full" />
            </div>
          </div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
            NexusGreen
          </h2>
          <p className="text-gray-600 mt-2">
            Loading Solar Energy Management Platform...
          </p>
        </div>
      </div>
    );
  }

  // If not authenticated, show login
  if (!currentUser || !currentOrganization) {
    return <Login onLogin={handleLogin} />;
  }

  // Route based on user role
  const getDashboardComponent = () => {
    switch (currentUser.role) {
      case 'SUPER_ADMIN':
        return (
          <SuperAdminDashboard
            user={currentUser}
            organization={currentOrganization}
            onLogout={handleLogout}
          />
        );
      case 'CUSTOMER':
        return (
          <CustomerDashboard
            user={currentUser}
            organization={currentOrganization}
            onLogout={handleLogout}
          />
        );
      case 'OPERATOR':
        return (
          <OperatorDashboard
            user={currentUser}
            organization={currentOrganization}
            onLogout={handleLogout}
          />
        );
      case 'FUNDER':
        return (
          <FunderDashboard
            user={currentUser}
            organization={currentOrganization}
            onLogout={handleLogout}
          />
        );
      case 'PROJECT_ADMIN':
        return (
          <ProjectAdminDashboard
            user={currentUser}
            organization={currentOrganization}
            onLogout={handleLogout}
          />
        );
      default:
        return (
          <div className="min-h-screen flex items-center justify-center">
            <div className="text-center">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Access Denied</h2>
              <p className="text-gray-600 mb-4">Your role is not recognized.</p>
              <button
                onClick={handleLogout}
                className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
              >
                Logout
              </button>
            </div>
          </div>
        );
    }
  };

  return (
    <Router>
      <div className="min-h-screen">
        <Routes>
          {/* Main dashboard routes */}
          <Route path="/" element={getDashboardComponent()} />
          <Route path="/dashboard" element={getDashboardComponent()} />
          
          {/* Role-specific dashboard routes */}
          <Route path="/dashboard/super-admin" element={
            currentUser?.role === 'SUPER_ADMIN' ? getDashboardComponent() : <Unauthorized />
          } />
          <Route path="/dashboard/customer" element={
            currentUser?.role === 'CUSTOMER' ? getDashboardComponent() : <Unauthorized />
          } />
          <Route path="/dashboard/operator" element={
            currentUser?.role === 'OPERATOR' ? getDashboardComponent() : <Unauthorized />
          } />
          <Route path="/dashboard/funder" element={
            currentUser?.role === 'FUNDER' ? getDashboardComponent() : <Unauthorized />
          } />
          <Route path="/dashboard/project-admin" element={
            currentUser?.role === 'PROJECT_ADMIN' ? getDashboardComponent() : <Unauthorized />
          } />
          
          {/* Error pages */}
          <Route path="/unauthorized" element={<Unauthorized />} />
          <Route path="/no-project-assigned" element={<NoProjectAssigned />} />
          
          {/* Catch all route */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>

        {/* Toast notifications */}
        <Toaster 
          position="top-right"
          toastOptions={{
            style: {
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(16px)',
              border: '1px solid rgba(255, 255, 255, 0.18)',
              boxShadow: '0 8px 32px 0 rgba(31, 38, 135, 0.37)'
            }
          }}
        />
      </div>
    </Router>
  );
};

export default ProductionApp;