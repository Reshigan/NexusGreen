import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { 
  Activity, 
  AlertTriangle, 
  CheckCircle,
  Clock,
  Wrench,
  Zap,
  TrendingUp,
  TrendingDown,
  MapPin,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Download,
  Eye,
  Settings,
  XCircle
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

// Mock data - replace with actual API calls
const mockPerformanceData = [
  { 
    date: '2024-09-10', 
    totalOutput: 1850, 
    expectedOutput: 1920, 
    efficiency: 96.4,
    uptime: 99.2,
    alerts: 2
  },
  { 
    date: '2024-09-11', 
    totalOutput: 1920, 
    expectedOutput: 1950, 
    efficiency: 98.5,
    uptime: 100,
    alerts: 0
  },
  { 
    date: '2024-09-12', 
    totalOutput: 1780, 
    expectedOutput: 1900, 
    efficiency: 93.7,
    uptime: 95.5,
    alerts: 5
  },
  { 
    date: '2024-09-13', 
    totalOutput: 1890, 
    expectedOutput: 1930, 
    efficiency: 97.9,
    uptime: 98.8,
    alerts: 1
  },
  { 
    date: '2024-09-14', 
    totalOutput: 1950, 
    expectedOutput: 1960, 
    efficiency: 99.5,
    uptime: 100,
    alerts: 0
  },
  { 
    date: '2024-09-15', 
    totalOutput: 1820, 
    expectedOutput: 1940, 
    efficiency: 93.8,
    uptime: 87.2,
    alerts: 8
  },
  { 
    date: '2024-09-16', 
    totalOutput: 1680, 
    expectedOutput: 1920, 
    efficiency: 87.5,
    uptime: 85.0,
    alerts: 12
  }
];

const mockSiteStatus = [
  { name: 'Operational', value: 67, count: 2, color: '#10b981' },
  { name: 'Maintenance', value: 33, count: 1, color: '#f59e0b' },
  { name: 'Offline', value: 0, count: 0, color: '#ef4444' }
];

const mockSites = [
  {
    id: 1,
    name: 'Johannesburg Office Complex',
    location: 'Sandton, Johannesburg',
    capacity: 850,
    currentOutput: 425.5,
    expectedOutput: 450,
    efficiency: 94.6,
    uptime: 99.1,
    status: 'OPERATIONAL',
    lastMaintenance: '2024-08-15',
    nextMaintenance: '2024-11-15',
    activeAlerts: 0,
    criticalAlerts: 0,
    lastUpdate: '2024-09-16T14:30:00Z'
  },
  {
    id: 2,
    name: 'Cape Town Manufacturing Plant',
    location: 'Bellville, Cape Town',
    capacity: 1200,
    currentOutput: 680.2,
    expectedOutput: 720,
    efficiency: 94.5,
    uptime: 98.7,
    status: 'OPERATIONAL',
    lastMaintenance: '2024-07-20',
    nextMaintenance: '2024-10-20',
    activeAlerts: 2,
    criticalAlerts: 0,
    lastUpdate: '2024-09-16T14:28:00Z'
  },
  {
    id: 3,
    name: 'Durban Warehouse Facility',
    location: 'Pinetown, Durban',
    capacity: 450,
    currentOutput: 0,
    expectedOutput: 280,
    efficiency: 0,
    uptime: 0,
    status: 'MAINTENANCE',
    lastMaintenance: '2024-09-10',
    nextMaintenance: '2024-09-20',
    activeAlerts: 5,
    criticalAlerts: 2,
    lastUpdate: '2024-09-16T08:00:00Z'
  }
];

const mockRecentAlerts = [
  {
    id: 1,
    siteId: 3,
    siteName: 'Durban Warehouse Facility',
    type: 'CRITICAL',
    category: 'INVERTER_FAULT',
    message: 'Inverter #2 has stopped responding',
    timestamp: '2024-09-16T12:45:00Z',
    acknowledged: false,
    assignedTo: 'Mike Wilson'
  },
  {
    id: 2,
    siteId: 3,
    siteName: 'Durban Warehouse Facility',
    type: 'CRITICAL',
    category: 'POWER_LOSS',
    message: 'Complete power loss detected',
    timestamp: '2024-09-16T12:30:00Z',
    acknowledged: true,
    assignedTo: 'Mike Wilson'
  },
  {
    id: 3,
    siteId: 2,
    siteName: 'Cape Town Manufacturing Plant',
    type: 'WARNING',
    category: 'PERFORMANCE',
    message: 'Performance below expected threshold (94.5%)',
    timestamp: '2024-09-16T11:15:00Z',
    acknowledged: false,
    assignedTo: null
  },
  {
    id: 4,
    siteId: 2,
    siteName: 'Cape Town Manufacturing Plant',
    type: 'INFO',
    category: 'MAINTENANCE',
    message: 'Scheduled maintenance due in 30 days',
    timestamp: '2024-09-16T09:00:00Z',
    acknowledged: true,
    assignedTo: 'Sarah Tech'
  }
];

const OMProviderDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState('7d');
  
  const currentData = mockPerformanceData[mockPerformanceData.length - 1];
  const previousData = mockPerformanceData[mockPerformanceData.length - 2];
  
  const efficiencyChange = currentData.efficiency - previousData.efficiency;
  const uptimeChange = currentData.uptime - previousData.uptime;
  const alertsChange = currentData.alerts - previousData.alerts;

  const totalCapacity = mockSites.reduce((sum, site) => sum + site.capacity, 0);
  const totalCurrentOutput = mockSites.reduce((sum, site) => sum + site.currentOutput, 0);
  const totalExpectedOutput = mockSites.reduce((sum, site) => sum + site.expectedOutput, 0);
  const overallEfficiency = (totalCurrentOutput / totalExpectedOutput) * 100;
  const totalActiveAlerts = mockSites.reduce((sum, site) => sum + site.activeAlerts, 0);
  const totalCriticalAlerts = mockSites.reduce((sum, site) => sum + site.criticalAlerts, 0);

  const formatPower = (kw: number) => {
    if (kw >= 1000) {
      return `${(kw / 1000).toFixed(1)} MW`;
    }
    return `${kw} kW`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'OPERATIONAL': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'MAINTENANCE': return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300';
      case 'OFFLINE': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getAlertTypeColor = (type: string) => {
    switch (type) {
      case 'CRITICAL': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      case 'WARNING': return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300';
      case 'INFO': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'CRITICAL': return <XCircle className="h-4 w-4" />;
      case 'WARNING': return <AlertTriangle className="h-4 w-4" />;
      case 'INFO': return <CheckCircle className="h-4 w-4" />;
      default: return <AlertTriangle className="h-4 w-4" />;
    }
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              O&M Dashboard
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Monitor system performance and manage maintenance operations
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <Select value={timeRange} onValueChange={setTimeRange}>
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="24h">Last 24 hours</SelectItem>
                <SelectItem value="7d">Last 7 days</SelectItem>
                <SelectItem value="30d">Last 30 days</SelectItem>
                <SelectItem value="90d">Last 90 days</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="outline">
              <Download className="h-4 w-4 mr-2" />
              Export Report
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">System Efficiency</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {overallEfficiency.toFixed(1)}%
                </p>
                <p className={`text-sm flex items-center mt-1 ${efficiencyChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {efficiencyChange >= 0 ? <ArrowUpRight className="h-3 w-3 mr-1" /> : <ArrowDownRight className="h-3 w-3 mr-1" />}
                  {Math.abs(efficiencyChange).toFixed(1)}% from yesterday
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <Activity className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">System Uptime</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {currentData.uptime.toFixed(1)}%
                </p>
                <p className={`text-sm flex items-center mt-1 ${uptimeChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {uptimeChange >= 0 ? <ArrowUpRight className="h-3 w-3 mr-1" /> : <ArrowDownRight className="h-3 w-3 mr-1" />}
                  {Math.abs(uptimeChange).toFixed(1)}% from yesterday
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <CheckCircle className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Active Alerts</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {totalActiveAlerts}
                </p>
                <p className={`text-sm flex items-center mt-1 ${alertsChange <= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {alertsChange <= 0 ? <ArrowDownRight className="h-3 w-3 mr-1" /> : <ArrowUpRight className="h-3 w-3 mr-1" />}
                  {Math.abs(alertsChange)} from yesterday
                </p>
              </div>
              <div className="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center">
                <AlertTriangle className="h-6 w-6 text-orange-600 dark:text-orange-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Power Output</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatPower(totalCurrentOutput)}
                </p>
                <p className="text-sm text-slate-600 flex items-center mt-1">
                  <Zap className="h-3 w-3 mr-1" />
                  of {formatPower(totalCapacity)} capacity
                </p>
              </div>
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
                <Zap className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Performance Trend */}
        <Card>
          <CardHeader>
            <CardTitle>System Performance Trend</CardTitle>
            <CardDescription>Efficiency and uptime over the last 7 days</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={mockPerformanceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" tickFormatter={(value) => new Date(value).toLocaleDateString()} />
                <YAxis />
                <Tooltip labelFormatter={(value) => new Date(value).toLocaleDateString()} />
                <Line type="monotone" dataKey="efficiency" stroke="#10b981" strokeWidth={2} name="Efficiency %" />
                <Line type="monotone" dataKey="uptime" stroke="#3b82f6" strokeWidth={2} name="Uptime %" />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Site Status Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Site Status Overview</CardTitle>
            <CardDescription>Current operational status of all sites</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={mockSiteStatus}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={120}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {mockSiteStatus.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(value, name) => [`${value}%`, name]} />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-4 space-y-2">
              {mockSiteStatus.map((item, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }} />
                    <span className="text-sm text-slate-600 dark:text-slate-400">{item.name}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-medium">{item.count} sites</span>
                    <span className="text-xs text-slate-500 ml-2">({item.value}%)</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Sites Overview */}
      <Card className="mb-8">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Site Monitoring</CardTitle>
              <CardDescription>Real-time status of all monitored sites</CardDescription>
            </div>
            <Button variant="outline">
              <Eye className="h-4 w-4 mr-2" />
              View All Sites
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {mockSites.map((site) => (
              <Card key={site.id} className="hover:shadow-md transition-shadow">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-lg">{site.name}</CardTitle>
                      <CardDescription className="flex items-center mt-1">
                        <MapPin className="h-3 w-3 mr-1" />
                        {site.location}
                      </CardDescription>
                    </div>
                    <Badge className={getStatusColor(site.status)}>
                      {site.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Performance Metrics */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-slate-500">Current Output</p>
                      <p className="text-sm font-medium">{formatPower(site.currentOutput)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Expected</p>
                      <p className="text-sm font-medium">{formatPower(site.expectedOutput)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Efficiency</p>
                      <p className={`text-sm font-medium ${site.efficiency >= 95 ? 'text-green-600' : site.efficiency >= 90 ? 'text-yellow-600' : 'text-red-600'}`}>
                        {site.efficiency.toFixed(1)}%
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Uptime</p>
                      <p className={`text-sm font-medium ${site.uptime >= 98 ? 'text-green-600' : site.uptime >= 95 ? 'text-yellow-600' : 'text-red-600'}`}>
                        {site.uptime.toFixed(1)}%
                      </p>
                    </div>
                  </div>

                  {/* Alerts */}
                  <div className="pt-3 border-t border-slate-200 dark:border-slate-700">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">
                        Alerts
                      </span>
                      <div className="flex items-center space-x-2">
                        {site.criticalAlerts > 0 && (
                          <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300 text-xs">
                            {site.criticalAlerts} Critical
                          </Badge>
                        )}
                        {site.activeAlerts > 0 && (
                          <Badge variant="outline" className="text-xs">
                            {site.activeAlerts} Total
                          </Badge>
                        )}
                        {site.activeAlerts === 0 && (
                          <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300 text-xs">
                            No Alerts
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Maintenance */}
                  <div className="pt-2 border-t border-slate-200 dark:border-slate-700">
                    <div className="flex items-center justify-between text-xs">
                      <div>
                        <p className="text-slate-500">Next Maintenance</p>
                        <p className="font-medium">{new Date(site.nextMaintenance).toLocaleDateString()}</p>
                      </div>
                      <Button variant="outline" size="sm">
                        <Settings className="h-3 w-3 mr-1" />
                        Manage
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Recent Alerts */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Recent Alerts</CardTitle>
              <CardDescription>Latest system alerts and notifications</CardDescription>
            </div>
            <Button variant="outline">
              <AlertTriangle className="h-4 w-4 mr-2" />
              View All Alerts
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {mockRecentAlerts.map((alert) => (
              <div key={alert.id} className="flex items-start space-x-4 p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex-shrink-0">
                  <div className={`p-2 rounded-lg ${getAlertTypeColor(alert.type)}`}>
                    {getAlertIcon(alert.type)}
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-slate-900 dark:text-slate-100">
                        {alert.siteName}
                      </p>
                      <p className="text-sm text-slate-600 dark:text-slate-400">
                        {alert.message}
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge className={getAlertTypeColor(alert.type)}>
                        {alert.type}
                      </Badge>
                      {alert.acknowledged && (
                        <Badge variant="outline" className="text-xs">
                          Acknowledged
                        </Badge>
                      )}
                    </div>
                  </div>
                  <div className="mt-2 flex items-center justify-between text-xs text-slate-500">
                    <div className="flex items-center">
                      <Calendar className="h-3 w-3 mr-1" />
                      {new Date(alert.timestamp).toLocaleString()}
                    </div>
                    {alert.assignedTo && (
                      <div>
                        Assigned to: {alert.assignedTo}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default OMProviderDashboard;