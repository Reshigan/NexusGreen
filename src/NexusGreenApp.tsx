import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Toaster } from 'sonner';
import ModernLogin from '@/components/auth/ModernLogin';
import AdvancedDashboard from '@/components/dashboard/AdvancedDashboard';
import SiteManagement from '@/components/sites/SiteManagement';
import UserManagement from '@/components/users/UserManagement';
import { nexusApi, type User, type Organization } from '@/services/nexusApi';

type AppState = 'login' | 'signup' | 'forgot-password' | 'dashboard' | 'sites' | 'users';

const NexusGreenApp: React.FC = () => {
  const [appState, setAppState] = useState<AppState>('login');
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
        setAppState('dashboard');
      }
      setIsLoading(false);
    };

    // Simulate loading time for better UX
    setTimeout(checkSession, 1000);
  }, []);

  const handleLogin = (user: User, organization: Organization) => {
    setCurrentUser(user);
    setCurrentOrganization(organization);
    setAppState('dashboard');
  };

  const handleLogout = async () => {
    try {
      await nexusApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setCurrentUser(null);
      setCurrentOrganization(null);
      setAppState('login');
    }
  };

  const handleSwitchToSignup = () => {
    setAppState('signup');
  };

  const handleSwitchToLogin = () => {
    setAppState('login');
  };

  const handleForgotPassword = () => {
    setAppState('forgot-password');
  };

  const handleNavigateToSites = () => {
    setAppState('sites');
  };

  const handleNavigateToUsers = () => {
    setAppState('users');
  };

  const handleBackToDashboard = () => {
    setAppState('dashboard');
  };

  // Loading screen
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 via-blue-50 to-orange-50">
        <motion.div
          initial={{ opacity: 0, scale: 0.5 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center"
          >
            <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
              <div className="w-4 h-4 bg-gradient-to-r from-green-500 to-blue-500 rounded-full" />
            </div>
          </motion.div>
          <motion.h2
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent"
          >
            NexusGreen
          </motion.h2>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.7 }}
            className="text-gray-600 mt-2"
          >
            Loading Solar Energy Management Platform...
          </motion.p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <AnimatePresence mode="wait">
        {appState === 'login' && (
          <motion.div
            key="login"
            initial={{ opacity: 0, x: -100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 100 }}
            transition={{ duration: 0.5 }}
          >
            <ModernLogin
              onLogin={handleLogin}
              onSwitchToSignup={handleSwitchToSignup}
              onForgotPassword={handleForgotPassword}
            />
          </motion.div>
        )}

        {appState === 'signup' && (
          <motion.div
            key="signup"
            initial={{ opacity: 0, x: -100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 100 }}
            transition={{ duration: 0.5 }}
          >
            {/* Signup component would go here */}
            <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 via-blue-50 to-orange-50">
              <div className="text-center">
                <h2 className="text-2xl font-bold text-gray-900 mb-4">Sign Up</h2>
                <p className="text-gray-600 mb-4">Sign up functionality coming soon!</p>
                <button
                  onClick={handleSwitchToLogin}
                  className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
                >
                  Back to Login
                </button>
              </div>
            </div>
          </motion.div>
        )}

        {appState === 'forgot-password' && (
          <motion.div
            key="forgot-password"
            initial={{ opacity: 0, x: -100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 100 }}
            transition={{ duration: 0.5 }}
          >
            {/* Forgot password component would go here */}
            <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 via-blue-50 to-orange-50">
              <div className="text-center">
                <h2 className="text-2xl font-bold text-gray-900 mb-4">Forgot Password</h2>
                <p className="text-gray-600 mb-4">Password reset functionality coming soon!</p>
                <button
                  onClick={handleSwitchToLogin}
                  className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
                >
                  Back to Login
                </button>
              </div>
            </div>
          </motion.div>
        )}

        {appState === 'dashboard' && currentUser && currentOrganization && (
          <motion.div
            key="dashboard"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1.05 }}
            transition={{ duration: 0.5 }}
          >
            <AdvancedDashboard
              user={currentUser}
              organization={currentOrganization}
              onLogout={handleLogout}
              onNavigateToSites={handleNavigateToSites}
              onNavigateToUsers={handleNavigateToUsers}
            />
            
            {/* Logout button - floating */}
            <motion.button
              initial={{ opacity: 0, y: 100 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1 }}
              onClick={handleLogout}
              className="fixed bottom-6 right-6 px-4 py-2 bg-red-500 text-white rounded-full shadow-lg hover:bg-red-600 transition-all duration-300 hover:scale-105 z-50"
            >
              Logout
            </motion.button>
          </motion.div>
        )}

        {appState === 'sites' && currentUser && currentOrganization && (
          <motion.div
            key="sites"
            initial={{ opacity: 0, x: 100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -100 }}
            transition={{ duration: 0.5 }}
          >
            <SiteManagement
              user={currentUser}
              organization={currentOrganization}
              onBack={handleBackToDashboard}
            />
          </motion.div>
        )}

        {appState === 'users' && currentUser && currentOrganization && (
          <motion.div
            key="users"
            initial={{ opacity: 0, x: 100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -100 }}
            transition={{ duration: 0.5 }}
          >
            <UserManagement
              user={currentUser}
              organization={currentOrganization}
              onBack={handleBackToDashboard}
            />
          </motion.div>
        )}
      </AnimatePresence>

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
  );
};

export default NexusGreenApp;