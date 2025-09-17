import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ModernCard, ModernCardContent, ModernCardDescription, ModernCardHeader, ModernCardTitle } from '../../../components/ui/modern-card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { 
  Building2, 
  MapPin, 
  Users, 
  Zap, 
  DollarSign, 
  TrendingUp, 
  AlertTriangle,
  CheckCircle,
  Clock,
  Activity,
  Plus,
  ArrowUpRight,
  ArrowDownRight,
  Sun,
  Battery,
  Gauge,
  Shield
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

// Mock data - replace with actual API calls
const mockSystemStats = {
  totalProjects: 24,
  totalSites: 156,
  totalUsers: 342,
  totalCapacity: 12.5, // MW
  totalRevenue: 2450000, // ZAR
  systemUptime: 98.2,
  activeAlerts: 7,
  pendingMaintenance: 12
};

const mockRecentActivity = [
  { id: 1, type: 'project', action: 'created', description: 'New project "Solar Farm Alpha" created', timestamp: '2 hours ago', user: 'John Smith' },
  { id: 2, type: 'site', action: 'commissioned', description: 'Site "Johannesburg Office" commissioned', timestamp: '4 hours ago', user: 'Sarah Johnson' },
  { id: 3, type: 'user', action: 'added', description: 'New user "mike@example.com" added to system', timestamp: '6 hours ago', user: 'Admin' },
  { id: 4, type: 'alert', action: 'resolved', description: 'Performance alert resolved at Cape Town Site', timestamp: '8 hours ago', user: 'O&M Team' },
  { id: 5, type: 'maintenance', action: 'scheduled', description: 'Quarterly maintenance scheduled for 5 sites', timestamp: '1 day ago', user: 'Maintenance Team' }
];

const mockPerformanceData = [
  { month: 'Jan', energy: 1200, revenue: 180000, efficiency: 92 },
  { month: 'Feb', energy: 1350, revenue: 202500, efficiency: 94 },
  { month: 'Mar', energy: 1450, revenue: 217500, efficiency: 96 },
  { month: 'Apr', energy: 1380, revenue: 207000, efficiency: 95 },
  { month: 'May', energy: 1520, revenue: 228000, efficiency: 97 },
  { month: 'Jun', energy: 1480, revenue: 222000, efficiency: 96 }
];

const mockPortalUsage = [
  { name: 'Customer Portal', value: 45, color: '#3b82f6' },
  { name: 'Funder Portal', value: 25, color: '#10b981' },
  { name: 'O&M Portal', value: 20, color: '#f59e0b' },
  { name: 'Super Admin', value: 10, color: '#8b5cf6' }
];

const SuperAdminDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState('30d');
  const [stats, setStats] = useState(mockSystemStats);

  useEffect(() => {
    // Fetch dashboard data
    // This would be replaced with actual API calls
    setStats(mockSystemStats);
  }, [timeRange]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-ZA', {
      style: 'currency',
      currency: 'ZAR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'project': return <Building2 className="h-4 w-4" />;
      case 'site': return <MapPin className="h-4 w-4" />;
      case 'user': return <Users className="h-4 w-4" />;
      case 'alert': return <AlertTriangle className="h-4 w-4" />;
      case 'maintenance': return <Clock className="h-4 w-4" />;
      default: return <Activity className="h-4 w-4" />;
    }
  };

  const getActivityColor = (type: string) => {
    switch (type) {
      case 'project': return 'text-blue-600';
      case 'site': return 'text-green-600';
      case 'user': return 'text-purple-600';
      case 'alert': return 'text-orange-600';
      case 'maintenance': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  return (
    <div className="space-y-6">
      {/* Modern Header */}
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4"
      >
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-slate-900 to-slate-700 dark:from-slate-100 dark:to-slate-300 bg-clip-text text-transparent">
            Super Admin Dashboard
          </h1>
          <p className="mt-1 text-sm sm:text-base text-slate-600 dark:text-slate-400">
            System overview and management console
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
              className="px-3 py-2 border border-slate-200/50 dark:border-slate-600/50 rounded-xl bg-white/50 dark:bg-slate-700/50 backdrop-blur-sm text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/50"
            >
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="90d">Last 90 days</option>
              <option value="1y">Last year</option>
            </select>
            <Button className="bg-gradient-to-r from-purple-500 to-blue-600 hover:from-purple-600 hover:to-blue-700 shadow-lg shadow-purple-500/25">
              <Plus className="h-4 w-4 mr-2" />
              New Project
            </Button>
          </div>
        </div>
      </motion.div>

      {/* Modern Key Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        {[
          {
            title: 'Total Projects',
            value: stats.totalProjects,
            change: '+12%',
            changeType: 'positive',
            icon: Building2,
            gradient: 'from-blue-500 to-cyan-500',
            bgGradient: 'from-blue-50 to-cyan-50 dark:from-blue-900/20 dark:to-cyan-900/20'
          },
          {
            title: 'Active Sites',
            value: stats.totalSites,
            change: '+8%',
            changeType: 'positive',
            icon: MapPin,
            gradient: 'from-green-500 to-emerald-500',
            bgGradient: 'from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20'
          },
          {
            title: 'System Users',
            value: stats.totalUsers,
            change: '+15%',
            changeType: 'positive',
            icon: Users,
            gradient: 'from-purple-500 to-pink-500',
            bgGradient: 'from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20'
          },
          {
            title: 'Total Capacity',
            value: `${stats.totalCapacity}MW`,
            change: '+5%',
            changeType: 'positive',
            icon: Zap,
            gradient: 'from-orange-500 to-red-500',
            bgGradient: 'from-orange-50 to-red-50 dark:from-orange-900/20 dark:to-red-900/20'
          }
        ].map((metric, index) => {
          const Icon = metric.icon;
          return (
            <motion.div
              key={metric.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <ModernCard glass hover className="group">
                <ModernCardContent className="p-6">
                  <div className="flex items-center justify-between">
                    <div className="space-y-2">
                      <p className="text-sm font-medium text-slate-600 dark:text-slate-400">
                        {metric.title}
                      </p>
                      <p className="text-2xl sm:text-3xl font-bold text-slate-900 dark:text-slate-100">
                        {metric.value}
                      </p>
                      <div className={`flex items-center text-sm ${
                        metric.changeType === 'positive' ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'
                      }`}>
                        {metric.changeType === 'positive' ? (
                          <ArrowUpRight className="h-3 w-3 mr-1" />
                        ) : (
                          <ArrowDownRight className="h-3 w-3 mr-1" />
                        )}
                        {metric.change} from last month
                      </div>
                    </div>
                    <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${metric.bgGradient} flex items-center justify-center group-hover:scale-110 transition-transform duration-200`}>
                      <Icon className={`h-6 w-6 bg-gradient-to-br ${metric.gradient} bg-clip-text text-transparent`} />
                    </div>
                  </div>
                </ModernCardContent>
              </ModernCard>
            </motion.div>
          );
        })}
      </div>

      {/* Modern Charts Section */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Performance Chart */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.5 }}
        >
          <ModernCard glass>
            <ModernCardHeader>
              <ModernCardTitle className="flex items-center">
                <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
                System Performance
              </ModernCardTitle>
              <ModernCardDescription>
                Energy generation and revenue trends over time
              </ModernCardDescription>
            </ModernCardHeader>
            <ModernCardContent>
              <div className="h-80">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={mockPerformanceData}>
                    <defs>
                      <linearGradient id="energyGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.1}/>
                      </linearGradient>
                      <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0.1}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" opacity={0.3} />
                    <XAxis 
                      dataKey="month" 
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#64748b' }}
                    />
                    <YAxis 
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#64748b' }}
                    />
                    <Tooltip 
                      contentStyle={{
                        backgroundColor: 'rgba(255, 255, 255, 0.95)',
                        border: 'none',
                        borderRadius: '12px',
                        boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)',
                        backdropFilter: 'blur(10px)'
                      }}
                    />
                    <Area 
                      type="monotone" 
                      dataKey="energy" 
                      stroke="#3b82f6" 
                      fill="url(#energyGradient)"
                      strokeWidth={2}
                    />
                    <Area 
                      type="monotone" 
                      dataKey="revenue" 
                      stroke="#10b981" 
                      fill="url(#revenueGradient)"
                      strokeWidth={2}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </ModernCardContent>
          </ModernCard>
        </motion.div>

        {/* Portal Usage */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.6 }}
        >
          <ModernCard glass>
            <ModernCardHeader>
              <ModernCardTitle className="flex items-center">
                <Shield className="h-5 w-5 mr-2 text-purple-600" />
                Portal Usage Distribution
              </ModernCardTitle>
              <ModernCardDescription>
                User activity across different portals
              </ModernCardDescription>
            </ModernCardHeader>
            <ModernCardContent>
              <div className="h-80">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={mockPortalUsage}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={120}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {mockPortalUsage.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip 
                      contentStyle={{
                        backgroundColor: 'rgba(255, 255, 255, 0.95)',
                        border: 'none',
                        borderRadius: '12px',
                        boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)',
                        backdropFilter: 'blur(10px)'
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="mt-6 grid grid-cols-2 gap-4">
                {mockPortalUsage.map((item, index) => (
                  <motion.div 
                    key={index} 
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.7 + index * 0.1 }}
                    className="flex items-center p-2 rounded-lg bg-slate-50 dark:bg-slate-800/50"
                  >
                    <div className="w-3 h-3 rounded-full mr-3" style={{ backgroundColor: item.color }} />
                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{item.name}</span>
                    <span className="ml-auto text-xs text-slate-500">{item.value}%</span>
                  </motion.div>
                ))}
              </div>
            </ModernCardContent>
          </ModernCard>
        </motion.div>
      </div>

      {/* Modern Status and Activity Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* System Status */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7 }}
        >
          <ModernCard glass>
            <ModernCardHeader>
              <ModernCardTitle className="flex items-center">
                <Gauge className="h-5 w-5 mr-2 text-green-600" />
                System Status
              </ModernCardTitle>
            </ModernCardHeader>
            <ModernCardContent className="space-y-4">
              {[
                { icon: CheckCircle, label: 'System Uptime', value: `${stats.systemUptime}%`, color: 'text-green-500', bgColor: 'bg-green-100 dark:bg-green-900/20' },
                { icon: AlertTriangle, label: 'Active Alerts', value: stats.activeAlerts, color: 'text-orange-500', bgColor: 'bg-orange-100 dark:bg-orange-900/20' },
                { icon: Clock, label: 'Pending Maintenance', value: stats.pendingMaintenance, color: 'text-blue-500', bgColor: 'bg-blue-100 dark:bg-blue-900/20' },
                { icon: DollarSign, label: 'Monthly Revenue', value: formatCurrency(stats.totalRevenue), color: 'text-green-500', bgColor: 'bg-green-100 dark:bg-green-900/20' }
              ].map((item, index) => {
                const Icon = item.icon;
                return (
                  <motion.div
                    key={item.label}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.8 + index * 0.1 }}
                    className="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-800/50"
                  >
                    <div className="flex items-center">
                      <div className={`w-8 h-8 rounded-lg ${item.bgColor} flex items-center justify-center mr-3`}>
                        <Icon className={`h-4 w-4 ${item.color}`} />
                      </div>
                      <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{item.label}</span>
                    </div>
                    <Badge variant={item.label === 'Active Alerts' ? 'destructive' : 'secondary'} className="font-medium">
                      {item.value}
                    </Badge>
                  </motion.div>
                );
              })}
            </ModernCardContent>
          </ModernCard>
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="lg:col-span-2"
        >
          <ModernCard glass>
            <ModernCardHeader>
              <ModernCardTitle className="flex items-center">
                <Activity className="h-5 w-5 mr-2 text-blue-600" />
                Recent Activity
              </ModernCardTitle>
              <ModernCardDescription>
                Latest system events and user actions
              </ModernCardDescription>
            </ModernCardHeader>
            <ModernCardContent>
              <div className="space-y-4">
                {mockRecentActivity.map((activity, index) => (
                  <motion.div
                    key={activity.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.9 + index * 0.1 }}
                    className="flex items-start space-x-3 p-3 rounded-xl bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:hover:bg-slate-800/70 transition-colors duration-200"
                  >
                    <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${getActivityColor(activity.type)} bg-opacity-10`}>
                      {getActivityIcon(activity.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-slate-900 dark:text-slate-100">{activity.description}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        {activity.timestamp} • by {activity.user}
                      </p>
                    </div>
                  </motion.div>
                ))}
              </div>
              <div className="mt-6 pt-4 border-t border-slate-200/50 dark:border-slate-700/50">
                <Button variant="outline" className="w-full bg-white/50 dark:bg-slate-800/50 backdrop-blur-sm border-slate-200/50 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/50">
                  View All Activity
                </Button>
            </ModernCardContent>
          </ModernCard>
        </motion.div>
      </div>
    </div>
  );
};

export default SuperAdminDashboard;