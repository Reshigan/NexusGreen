import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useMultiPortalAuth, UserRole } from '../../contexts/MultiPortalAuthContext';
import { Button } from '../../components/ui/button';
import { 
  Home, 
  Activity, 
  AlertTriangle, 
  Wrench, 
  Menu,
  X,
  LogOut,
  User,
  Bell,
  ChevronDown,
  Zap
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../components/ui/dropdown-menu';
import { Badge } from '../../components/ui/badge';

interface OMProviderLayoutProps {
  children: React.ReactNode;
}

const OMProviderLayout: React.FC<OMProviderLayoutProps> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { user, logout, switchPortal, getAccessiblePortals } = useMultiPortalAuth();
  const location = useLocation();

  const navigation = [
    { name: 'Dashboard', href: '/om-provider/dashboard', icon: Home, current: location.pathname === '/om-provider/dashboard' },
    { name: 'Monitoring', href: '/om-provider/monitoring', icon: Activity, current: location.pathname === '/om-provider/monitoring' },
    { name: 'Alerts', href: '/om-provider/alerts', icon: AlertTriangle, current: location.pathname === '/om-provider/alerts' },
    { name: 'Maintenance', href: '/om-provider/maintenance', icon: Wrench, current: location.pathname === '/om-provider/maintenance' },
  ];

  const handleLogout = async () => {
    await logout();
  };

  const handlePortalSwitch = (portal: UserRole) => {
    switchPortal(portal);
  };

  const accessiblePortals = getAccessiblePortals();

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* Mobile sidebar */}
      <div className={`fixed inset-0 z-50 lg:hidden ${sidebarOpen ? 'block' : 'hidden'}`}>
        <div className="fixed inset-0 bg-slate-600 bg-opacity-75" onClick={() => setSidebarOpen(false)} />
        <div className="fixed inset-y-0 left-0 flex w-64 flex-col bg-white dark:bg-slate-800 shadow-xl">
          <div className="flex h-16 items-center justify-between px-4 border-b border-slate-200 dark:border-slate-700">
            <img src="/nexus-green-logo.svg" alt="NexusGreen" className="h-8 w-auto" />
            <Button variant="ghost" size="sm" onClick={() => setSidebarOpen(false)}>
              <X className="h-5 w-5" />
            </Button>
          </div>
          <nav className="flex-1 px-4 py-4 space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                    item.current
                      ? 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
                      : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700'
                  }`}
                  onClick={() => setSidebarOpen(false)}
                >
                  <Icon className="mr-3 h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-white dark:bg-slate-800 border-r border-slate-200 dark:border-slate-700">
          <div className="flex h-16 items-center px-4 border-b border-slate-200 dark:border-slate-700">
            <img src="/nexus-green-logo.svg" alt="NexusGreen" className="h-8 w-auto" />
            <Badge variant="secondary" className="ml-2 text-xs">O&M</Badge>
          </div>
          <nav className="flex-1 px-4 py-4 space-y-1">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                    item.current
                      ? 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
                      : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700'
                  }`}
                >
                  <Icon className="mr-3 h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>
          
          {/* System Status Summary */}
          <div className="p-4 border-t border-slate-200 dark:border-slate-700">
            <div className="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-orange-800 dark:text-orange-300">
                  System Health
                </span>
                <Zap className="h-4 w-4 text-orange-600" />
              </div>
              <p className="text-lg font-bold text-orange-900 dark:text-orange-100">
                98.7%
              </p>
              <p className="text-xs text-orange-600 dark:text-orange-400">
                3 sites monitored
              </p>
            </div>
          </div>

          {/* Portal switcher */}
          {accessiblePortals.length > 1 && (
            <div className="p-4 border-t border-slate-200 dark:border-slate-700">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="w-full justify-between">
                    Switch Portal
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-56">
                  {accessiblePortals.filter(portal => portal !== UserRole.OM_PROVIDER).map((portal) => (
                    <DropdownMenuItem key={portal} onClick={() => handlePortalSwitch(portal)}>
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
      <div className="lg:pl-64">
        {/* Top bar */}
        <div className="sticky top-0 z-40 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
          <div className="flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
            <div className="flex items-center">
              <Button
                variant="ghost"
                size="sm"
                className="lg:hidden"
                onClick={() => setSidebarOpen(true)}
              >
                <Menu className="h-5 w-5" />
              </Button>
              
              {/* Welcome message */}
              <div className="hidden sm:block ml-4">
                <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
                  Operations & Maintenance
                </h2>
                <p className="text-sm text-slate-500 dark:text-slate-400">
                  Monitor and maintain solar installations
                </p>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              {/* Quick stats */}
              <div className="hidden md:flex items-center space-x-6 text-sm">
                <div className="text-center">
                  <p className="font-medium text-slate-900 dark:text-slate-100">3</p>
                  <p className="text-slate-500 dark:text-slate-400">Sites</p>
                </div>
                <div className="text-center">
                  <p className="font-medium text-slate-900 dark:text-slate-100">2.5 MW</p>
                  <p className="text-slate-500 dark:text-slate-400">Capacity</p>
                </div>
                <div className="text-center">
                  <p className="font-medium text-green-600">98.7%</p>
                  <p className="text-slate-500 dark:text-slate-400">Uptime</p>
                </div>
              </div>

              {/* Notifications */}
              <Button variant="ghost" size="sm" className="relative">
                <Bell className="h-5 w-5" />
                <Badge className="absolute -top-1 -right-1 h-5 w-5 rounded-full p-0 flex items-center justify-center text-xs bg-red-500">
                  7
                </Badge>
              </Button>

              {/* User menu */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="flex items-center space-x-2">
                    <div className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
                      <User className="h-4 w-4 text-white" />
                    </div>
                    <span className="hidden sm:block text-sm font-medium">
                      {user?.firstName} {user?.lastName}
                    </span>
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <DropdownMenuItem>
                    <User className="mr-2 h-4 w-4" />
                    Profile Settings
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={handleLogout}>
                    <LogOut className="mr-2 h-4 w-4" />
                    Sign Out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>

        {/* Page content */}
        <main className="flex-1">
          <div className="py-6">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default OMProviderLayout;