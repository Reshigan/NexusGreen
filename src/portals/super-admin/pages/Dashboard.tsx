import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
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
  ArrowDownRight
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
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Super Admin Dashboard
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              System overview and management console
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              className="px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-sm"
            >
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="90d">Last 90 days</option>
              <option value="1y">Last year</option>
            </select>
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              New Project
            </Button>
          </div>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Projects</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.totalProjects}</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +12% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <Building2 className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Active Sites</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.totalSites}</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +8% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <MapPin className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">System Users</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.totalUsers}</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +15% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
                <Users className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Capacity</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.totalCapacity}MW</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +5% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center">
                <Zap className="h-6 w-6 text-orange-600 dark:text-orange-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Performance Chart */}
        <Card>
          <CardHeader>
            <CardTitle>System Performance</CardTitle>
            <CardDescription>Energy generation and revenue trends</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={mockPerformanceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Area type="monotone" dataKey="energy" stackId="1" stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.6} />
                <Area type="monotone" dataKey="revenue" stackId="2" stroke="#10b981" fill="#10b981" fillOpacity={0.6} />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Portal Usage */}
        <Card>
          <CardHeader>
            <CardTitle>Portal Usage Distribution</CardTitle>
            <CardDescription>User activity across different portals</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
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
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-4 grid grid-cols-2 gap-4">
              {mockPortalUsage.map((item, index) => (
                <div key={index} className="flex items-center">
                  <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }} />
                  <span className="text-sm text-slate-600 dark:text-slate-400">{item.name}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Status Cards and Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* System Status */}
        <Card>
          <CardHeader>
            <CardTitle>System Status</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <CheckCircle className="h-5 w-5 text-green-500 mr-2" />
                <span className="text-sm">System Uptime</span>
              </div>
              <Badge variant="secondary">{stats.systemUptime}%</Badge>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <AlertTriangle className="h-5 w-5 text-orange-500 mr-2" />
                <span className="text-sm">Active Alerts</span>
              </div>
              <Badge variant="destructive">{stats.activeAlerts}</Badge>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Clock className="h-5 w-5 text-blue-500 mr-2" />
                <span className="text-sm">Pending Maintenance</span>
              </div>
              <Badge variant="outline">{stats.pendingMaintenance}</Badge>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <DollarSign className="h-5 w-5 text-green-500 mr-2" />
                <span className="text-sm">Monthly Revenue</span>
              </div>
              <span className="text-sm font-medium">{formatCurrency(stats.totalRevenue)}</span>
            </div>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest system events and user actions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {mockRecentActivity.map((activity) => (
                <div key={activity.id} className="flex items-start space-x-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${getActivityColor(activity.type)} bg-opacity-10`}>
                    {getActivityIcon(activity.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-slate-900 dark:text-slate-100">{activity.description}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      {activity.timestamp} • by {activity.user}
                    </p>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 pt-4 border-t border-slate-200 dark:border-slate-700">
              <Button variant="outline" className="w-full">
                View All Activity
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SuperAdminDashboard;