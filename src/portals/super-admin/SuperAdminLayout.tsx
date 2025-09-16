import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useMultiPortalAuth, UserRole } from '../../contexts/MultiPortalAuthContext';
import { Button } from '../../components/ui/button';
import { 
  Settings, 
  Building2, 
  MapPin, 
  Users, 
  HardDrive, 
  DollarSign, 
  Plug, 
  Menu,
  X,
  LogOut,
  User,
  Bell,
  Search,
  ChevronDown,
  Sun,
  Moon,
  Shield,
  Zap
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuSeparator } from '../../components/ui/dropdown-menu';
import { Badge } from '../../components/ui/badge';
import { motion, AnimatePresence } from 'framer-motion';

interface SuperAdminLayoutProps {
  children: React.ReactNode;
}

const SuperAdminLayout: React.FC<SuperAdminLayoutProps> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const { user, logout, switchPortal, getAccessiblePortals } = useMultiPortalAuth();
  const location = useLocation();

  // Check for mobile screen size
  useEffect(() => {
    const checkScreenSize = () => {
      setIsMobile(window.innerWidth < 1024);
    };
    
    checkScreenSize();
    window.addEventListener('resize', checkScreenSize);
    
    return () => window.removeEventListener('resize', checkScreenSize);
  }, []);

  // Handle dark mode
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      setDarkMode(true);
      document.documentElement.classList.add('dark');
    }
  }, []);

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
    if (!darkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  };

  // Close sidebar when clicking outside on mobile
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (isMobile && sidebarOpen) {
        const sidebar = document.getElementById('mobile-sidebar');
        if (sidebar && !sidebar.contains(event.target as Node)) {
          setSidebarOpen(false);
        }
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isMobile, sidebarOpen]);

  const navigation = [
    { name: 'Dashboard', href: '/super-admin/dashboard', icon: Settings, current: location.pathname === '/super-admin/dashboard' },
    { name: 'Projects', href: '/super-admin/projects', icon: Building2, current: location.pathname === '/super-admin/projects' },
    { name: 'Sites', href: '/super-admin/sites', icon: MapPin, current: location.pathname === '/super-admin/sites' },
    { name: 'Users', href: '/super-admin/users', icon: Users, current: location.pathname === '/super-admin/users' },
    { name: 'Hardware', href: '/super-admin/hardware', icon: HardDrive, current: location.pathname === '/super-admin/hardware' },
    { name: 'Rates', href: '/super-admin/rates', icon: DollarSign, current: location.pathname === '/super-admin/rates' },
    { name: 'API Management', href: '/super-admin/api', icon: Plug, current: location.pathname === '/super-admin/api' },
  ];

  const handleLogout = async () => {
    await logout();
  };

  const handlePortalSwitch = (portal: UserRole) => {
    switchPortal(portal);
  };

  const accessiblePortals = getAccessiblePortals();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 transition-colors duration-300">
      {/* Mobile sidebar overlay */}
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 lg:hidden"
          >
            <div className="fixed inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setSidebarOpen(false)} />
            <motion.div
              id="mobile-sidebar"
              initial={{ x: -300 }}
              animate={{ x: 0 }}
              exit={{ x: -300 }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 left-0 flex w-72 flex-col bg-white/95 dark:bg-slate-800/95 backdrop-blur-xl shadow-2xl border-r border-slate-200/50 dark:border-slate-700/50"
            >
              {/* Mobile sidebar header */}
              <div className="flex h-16 items-center justify-between px-6 border-b border-slate-200/50 dark:border-slate-700/50">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-600 rounded-lg flex items-center justify-center">
                    <Zap className="h-4 w-4 text-white" />
                  </div>
                  <span className="text-lg font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
                    NexusGreen
                  </span>
                </div>
                <Button variant="ghost" size="sm" onClick={() => setSidebarOpen(false)} className="hover:bg-slate-100 dark:hover:bg-slate-700">
                  <X className="h-5 w-5" />
                </Button>
              </div>

              {/* Mobile navigation */}
              <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
                {navigation.map((item, index) => {
                  const Icon = item.icon;
                  return (
                    <motion.div
                      key={item.name}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.1 }}
                    >
                      <Link
                        to={item.href}
                        className={`flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 ${
                          item.current
                            ? 'bg-gradient-to-r from-purple-500 to-blue-600 text-white shadow-lg shadow-purple-500/25'
                            : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700/50 hover:scale-105'
                        }`}
                        onClick={() => setSidebarOpen(false)}
                      >
                        <Icon className="mr-3 h-5 w-5" />
                        {item.name}
                      </Link>
                    </motion.div>
                  );
                })}
              </nav>

              {/* Mobile portal switcher */}
              {accessiblePortals.length > 1 && (
                <div className="p-4 border-t border-slate-200/50 dark:border-slate-700/50">
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="outline" className="w-full justify-between bg-white/50 dark:bg-slate-800/50 backdrop-blur-sm border-slate-200/50 dark:border-slate-700/50">
                        <Shield className="h-4 w-4 mr-2" />
                        Switch Portal
                        <ChevronDown className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent className="w-64 bg-white/95 dark:bg-slate-800/95 backdrop-blur-xl border-slate-200/50 dark:border-slate-700/50">
                      {accessiblePortals.filter(portal => portal !== UserRole.SUPER_ADMIN).map((portal) => (
                        <DropdownMenuItem key={portal} onClick={() => handlePortalSwitch(portal)} className="hover:bg-slate-100/50 dark:hover:bg-slate-700/50">
                          {portal.replace('_', ' ')}
                        </DropdownMenuItem>
                      ))}
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-72 lg:flex-col">
        <div className="flex flex-col flex-grow bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl border-r border-slate-200/50 dark:border-slate-700/50 shadow-xl">
          {/* Desktop sidebar header */}
          <div className="flex h-16 items-center px-6 border-b border-slate-200/50 dark:border-slate-700/50">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-600 rounded-lg flex items-center justify-center">
                <Zap className="h-4 w-4 text-white" />
              </div>
              <span className="text-lg font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
                NexusGreen
              </span>
            </div>
            <Badge variant="secondary" className="ml-auto bg-gradient-to-r from-purple-100 to-blue-100 text-purple-700 dark:from-purple-900 dark:to-blue-900 dark:text-purple-300 border-0">
              Super Admin
            </Badge>
          </div>

          {/* Desktop navigation */}
          <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
            {navigation.map((item, index) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`group flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 ${
                    item.current
                      ? 'bg-gradient-to-r from-purple-500 to-blue-600 text-white shadow-lg shadow-purple-500/25'
                      : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700/50 hover:scale-105'
                  }`}
                >
                  <Icon className={`mr-3 h-5 w-5 transition-transform duration-200 ${item.current ? '' : 'group-hover:scale-110'}`} />
                  {item.name}
                </Link>
              );
            })}
          </nav>
          
          {/* Desktop portal switcher */}
          {accessiblePortals.length > 1 && (
            <div className="p-4 border-t border-slate-200/50 dark:border-slate-700/50">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="w-full justify-between bg-white/50 dark:bg-slate-800/50 backdrop-blur-sm border-slate-200/50 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/50">
                    <div className="flex items-center">
                      <Shield className="h-4 w-4 mr-2" />
                      Switch Portal
                    </div>
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-64 bg-white/95 dark:bg-slate-800/95 backdrop-blur-xl border-slate-200/50 dark:border-slate-700/50">
                  {accessiblePortals.filter(portal => portal !== UserRole.SUPER_ADMIN).map((portal) => (
                    <DropdownMenuItem key={portal} onClick={() => handlePortalSwitch(portal)} className="hover:bg-slate-100/50 dark:hover:bg-slate-700/50">
                      {portal.replace('_', ' ')}
                    </DropdownMenuItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          )}
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-72 transition-all duration-300">
        {/* Modern top bar */}
        <motion.div 
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="sticky top-0 z-40 bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl border-b border-slate-200/50 dark:border-slate-700/50 shadow-sm"
        >
          <div className="flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
            <div className="flex items-center space-x-4">
              {/* Mobile menu button */}
              <Button
                variant="ghost"
                size="sm"
                className="lg:hidden hover:bg-slate-100 dark:hover:bg-slate-700 rounded-xl"
                onClick={() => setSidebarOpen(true)}
              >
                <Menu className="h-5 w-5" />
              </Button>
              
              {/* Modern search */}
              <div className="hidden sm:block">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                  <input
                    type="text"
                    placeholder="Search projects, sites, users..."
                    className="pl-10 pr-4 py-2.5 w-80 border border-slate-200/50 dark:border-slate-600/50 rounded-xl bg-white/50 dark:bg-slate-700/50 backdrop-blur-sm text-sm placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500/50 focus:border-purple-500/50 transition-all duration-200"
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              {/* Dark mode toggle */}
              <Button
                variant="ghost"
                size="sm"
                onClick={toggleDarkMode}
                className="hover:bg-slate-100 dark:hover:bg-slate-700 rounded-xl"
              >
                {darkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
              </Button>

              {/* Notifications */}
              <Button variant="ghost" size="sm" className="relative hover:bg-slate-100 dark:hover:bg-slate-700 rounded-xl">
                <Bell className="h-5 w-5" />
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  className="absolute -top-1 -right-1 h-5 w-5 bg-gradient-to-r from-red-500 to-pink-500 rounded-full flex items-center justify-center"
                >
                  <span className="text-xs text-white font-medium">3</span>
                </motion.div>
              </Button>

              {/* User menu */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="flex items-center space-x-3 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-xl px-3 py-2">
                    <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-600 rounded-full flex items-center justify-center shadow-lg">
                      <User className="h-4 w-4 text-white" />
                    </div>
                    <div className="hidden sm:block text-left">
                      <div className="text-sm font-medium text-slate-900 dark:text-slate-100">
                        {user?.firstName} {user?.lastName}
                      </div>
                      <div className="text-xs text-slate-500 dark:text-slate-400">
                        Super Administrator
                      </div>
                    </div>
                    <ChevronDown className="h-4 w-4 text-slate-400" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-64 bg-white/95 dark:bg-slate-800/95 backdrop-blur-xl border-slate-200/50 dark:border-slate-700/50 shadow-xl">
                  <div className="px-3 py-2 border-b border-slate-200/50 dark:border-slate-700/50">
                    <div className="text-sm font-medium text-slate-900 dark:text-slate-100">
                      {user?.firstName} {user?.lastName}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">
                      {user?.email}
                    </div>
                  </div>
                  <DropdownMenuItem className="hover:bg-slate-100/50 dark:hover:bg-slate-700/50">
                    <User className="mr-2 h-4 w-4" />
                    Profile Settings
                  </DropdownMenuItem>
                  <DropdownMenuSeparator className="bg-slate-200/50 dark:bg-slate-700/50" />
                  <DropdownMenuItem onClick={handleLogout} className="hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 dark:text-red-400">
                    <LogOut className="mr-2 h-4 w-4" />
                    Sign Out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>

        {/* Modern page content */}
        <main className="flex-1 min-h-screen">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="p-4 sm:p-6 lg:p-8"
          >
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </motion.div>
        </main>
      </div>
    </div>
  );
};

export default SuperAdminLayout;