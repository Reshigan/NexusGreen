import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { useMultiPortalAuth, UserRole } from '../contexts/MultiPortalAuthContext';
import { 
  Settings, 
  User, 
  DollarSign, 
  Wrench,
  Building2,
  TrendingUp,
  AlertTriangle,
  Users
} from 'lucide-react';

interface PortalSelectorProps {
  availablePortals: UserRole[];
}

const PortalSelector: React.FC<PortalSelectorProps> = ({ availablePortals }) => {
  const { switchPortal, user } = useMultiPortalAuth();

  const portalConfigs = {
    [UserRole.SUPER_ADMIN]: {
      title: 'Super Administrator',
      description: 'Manage projects, sites, users, and system configuration',
      icon: Settings,
      color: 'bg-purple-500',
      features: ['Project Management', 'User Access Control', 'Hardware Tracking', 'Rate Configuration']
    },
    [UserRole.CUSTOMER]: {
      title: 'Customer Portal',
      description: 'Track your savings and monitor site performance',
      icon: User,
      color: 'bg-blue-500',
      features: ['Savings Dashboard', 'Site Performance', 'Energy Reports', 'Bill Comparisons']
    },
    [UserRole.FUNDER]: {
      title: 'Funder Portal',
      description: 'Monitor investment performance and ROI analytics',
      icon: DollarSign,
      color: 'bg-green-500',
      features: ['Investment Tracking', 'ROI Analytics', 'Portfolio Management', 'Financial Reports']
    },
    [UserRole.OM_PROVIDER]: {
      title: 'O&M Provider',
      description: 'Monitor system performance and manage maintenance',
      icon: Wrench,
      color: 'bg-orange-500',
      features: ['Performance Monitoring', 'Alert Management', 'Maintenance Tracking', 'System Health']
    }
  };

  const handlePortalSelect = (portal: UserRole) => {
    try {
      switchPortal(portal);
    } catch (error) {
      console.error('Error switching portal:', error);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex items-center justify-center mb-6">
            <img 
              src="/nexus-green-logo.svg" 
              alt="NexusGreen" 
              className="h-12 w-auto"
            />
          </div>
          <h1 className="text-4xl font-bold text-slate-900 dark:text-slate-100 mb-4">
            Welcome back, {user?.firstName}!
          </h1>
          <p className="text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
            Choose your portal to access the tools and information relevant to your role.
          </p>
        </div>

        {/* Portal Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 max-w-7xl mx-auto">
          {availablePortals.map((portal) => {
            const config = portalConfigs[portal];
            const Icon = config.icon;
            
            return (
              <Card 
                key={portal} 
                className="relative overflow-hidden hover:shadow-lg transition-all duration-300 cursor-pointer group"
                onClick={() => handlePortalSelect(portal)}
              >
                <CardHeader className="pb-4">
                  <div className={`w-12 h-12 rounded-lg ${config.color} flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl font-semibold text-slate-900 dark:text-slate-100">
                    {config.title}
                  </CardTitle>
                  <CardDescription className="text-slate-600 dark:text-slate-400">
                    {config.description}
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  <div className="space-y-2 mb-6">
                    {config.features.map((feature, index) => (
                      <div key={index} className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                        <div className="w-1.5 h-1.5 bg-slate-400 rounded-full mr-2" />
                        {feature}
                      </div>
                    ))}
                  </div>
                  
                  <Button 
                    className="w-full group-hover:bg-slate-900 group-hover:text-white transition-colors duration-300"
                    variant="outline"
                  >
                    Access Portal
                  </Button>
                </CardContent>
                
                {/* Decorative gradient */}
                <div className={`absolute top-0 right-0 w-20 h-20 ${config.color} opacity-10 rounded-full -mr-10 -mt-10`} />
              </Card>
            );
          })}
        </div>

        {/* Quick Stats */}
        <div className="mt-16 grid grid-cols-1 md:grid-cols-4 gap-6 max-w-4xl mx-auto">
          <div className="text-center">
            <div className="flex items-center justify-center w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg mx-auto mb-3">
              <Building2 className="h-6 w-6 text-blue-600 dark:text-blue-400" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">24</div>
            <div className="text-sm text-slate-600 dark:text-slate-400">Active Sites</div>
          </div>
          
          <div className="text-center">
            <div className="flex items-center justify-center w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg mx-auto mb-3">
              <TrendingUp className="h-6 w-6 text-green-600 dark:text-green-400" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">98.2%</div>
            <div className="text-sm text-slate-600 dark:text-slate-400">System Uptime</div>
          </div>
          
          <div className="text-center">
            <div className="flex items-center justify-center w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg mx-auto mb-3">
              <AlertTriangle className="h-6 w-6 text-orange-600 dark:text-orange-400" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">3</div>
            <div className="text-sm text-slate-600 dark:text-slate-400">Active Alerts</div>
          </div>
          
          <div className="text-center">
            <div className="flex items-center justify-center w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg mx-auto mb-3">
              <Users className="h-6 w-6 text-purple-600 dark:text-purple-400" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">156</div>
            <div className="text-sm text-slate-600 dark:text-slate-400">Active Users</div>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-16 pt-8 border-t border-slate-200 dark:border-slate-700">
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Need help? Contact support at{' '}
            <a href="mailto:support@nexusgreen.energy" className="text-blue-600 hover:text-blue-700">
              support@nexusgreen.energy
            </a>
          </p>
        </div>
      </div>
    </div>
  );
};

export default PortalSelector;