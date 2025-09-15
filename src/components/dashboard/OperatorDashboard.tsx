import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Activity, 
  Cpu, 
  AlertTriangle, 
  Wrench, 
  MapPin, 
  TrendingUp,
  Calendar,
  LogOut,
  CheckCircle,
  XCircle,
  Clock
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';
import { User, Organization } from '@/services/nexusApi';

interface OperatorDashboardProps {
  user: User;
  organization: Organization;
  onLogout: () => void;
}

interface OperatorDashboardData {
  overview: {
    totalSites: number;
    totalDevices: number;
    onlineDevices: number;
    criticalAlerts: number;
  };
  sites: Array<{
    id: string;
    name: string;
    capacity: number;
    devices: Array<{
      id: string;
      deviceType: string;
      status: string;
    }>;
    siteMetrics: Array<{
      date: Date;
      averageEfficiency: number;
      availability: number;
      capacityFactor: number;
    }>;
    alerts: Array<{
      id: string;
      severity: string;
    }>;
  }>;
  performanceMetrics: Array<{
    kpiName: string;
    kpiValue: number;
    unit: string;
    calculatedAt: Date;
  }>;
  alerts: Array<{
    id: string;
    title: string;
    severity: string;
    alertType: string;
    createdAt: Date;
    site: {
      name: string;
    };
  }>;
  maintenanceSchedule: Array<{
    id: string;
    title: string;
    scheduledDate: Date;
    site: {
      name: string;
    };
  }>;
  deviceStatus: {
    online: number;
    offline: number;
    maintenance: number;
    error: number;
  };
}

const OperatorDashboard: React.FC<OperatorDashboardProps> = ({
  user,
  organization,
  onLogout
}) => {
  const [dashboardData, setDashboardData] = useState<OperatorDashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await fetch('/api/dashboard/operator', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        setDashboardData(data);
      }
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'CRITICAL': return 'bg-red-100 text-red-800';
      case 'HIGH': return 'bg-orange-100 text-orange-800';
      case 'MEDIUM': return 'bg-yellow-100 text-yellow-800';
      case 'LOW': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ONLINE': return 'text-green-600';
      case 'OFFLINE': return 'text-red-600';
      case 'MAINTENANCE': return 'text-yellow-600';
      case 'ERROR': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ONLINE': return <CheckCircle className="h-4 w-4" />;
      case 'OFFLINE': return <XCircle className="h-4 w-4" />;
      case 'MAINTENANCE': return <Wrench className="h-4 w-4" />;
      case 'ERROR': return <AlertTriangle className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  const COLORS = ['#10B981', '#EF4444', '#F59E0B', '#6B7280'];

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-green-500"></div>
          <p className="mt-4 text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Operator Dashboard</h1>
              <p className="text-gray-600">Welcome back, {user.firstName} {user.lastName}</p>
              <p className="text-sm text-gray-500">{organization.name}</p>
            </div>
            <div className="flex items-center space-x-4">
              <Button variant="outline" size="sm" onClick={onLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Overview Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Sites</CardTitle>
              <MapPin className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData?.overview.totalSites || 0}</div>
              <p className="text-xs text-muted-foreground">Under management</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Online Devices</CardTitle>
              <Activity className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {dashboardData?.overview.onlineDevices || 0}
              </div>
              <p className="text-xs text-muted-foreground">
                of {dashboardData?.overview.totalDevices || 0} total
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">System Uptime</CardTitle>
              <TrendingUp className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {dashboardData?.overview.totalDevices ? 
                  ((dashboardData.overview.onlineDevices / dashboardData.overview.totalDevices) * 100).toFixed(1) : 0}%
              </div>
              <p className="text-xs text-muted-foreground">Current availability</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Critical Alerts</CardTitle>
              <AlertTriangle className="h-4 w-4 text-red-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-500">
                {dashboardData?.overview.criticalAlerts || 0}
              </div>
              <p className="text-xs text-muted-foreground">Require immediate attention</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList>
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="performance">Performance</TabsTrigger>
            <TabsTrigger value="devices">Devices</TabsTrigger>
            <TabsTrigger value="maintenance">Maintenance</TabsTrigger>
            <TabsTrigger value="alerts">Alerts</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Device Status Distribution */}
              <Card>
                <CardHeader>
                  <CardTitle>Device Status</CardTitle>
                  <CardDescription>Current status of all devices</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie
                        data={[
                          { name: 'Online', value: dashboardData?.deviceStatus.online || 0, color: '#10B981' },
                          { name: 'Offline', value: dashboardData?.deviceStatus.offline || 0, color: '#EF4444' },
                          { name: 'Maintenance', value: dashboardData?.deviceStatus.maintenance || 0, color: '#F59E0B' },
                          { name: 'Error', value: dashboardData?.deviceStatus.error || 0, color: '#6B7280' }
                        ]}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, value }) => `${name}: ${value}`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {[
                          { name: 'Online', value: dashboardData?.deviceStatus.online || 0, color: '#10B981' },
                          { name: 'Offline', value: dashboardData?.deviceStatus.offline || 0, color: '#EF4444' },
                          { name: 'Maintenance', value: dashboardData?.deviceStatus.maintenance || 0, color: '#F59E0B' },
                          { name: 'Error', value: dashboardData?.deviceStatus.error || 0, color: '#6B7280' }
                        ].map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>

              {/* Performance Metrics */}
              <Card>
                <CardHeader>
                  <CardTitle>Performance Metrics</CardTitle>
                  <CardDescription>Key operational indicators</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {dashboardData?.performanceMetrics.map((metric, index) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div>
                          <p className="font-medium">{metric.kpiName}</p>
                          <p className="text-sm text-gray-500">
                            Updated {new Date(metric.calculatedAt).toLocaleDateString()}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold">{metric.kpiValue.toFixed(1)}</p>
                          <p className="text-sm text-gray-500">{metric.unit}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="performance" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {dashboardData?.sites.map((site) => (
                <Card key={site.id}>
                  <CardHeader>
                    <CardTitle className="text-lg">{site.name}</CardTitle>
                    <CardDescription>{site.capacity.toFixed(1)} kW capacity</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Devices:</span>
                        <span className="font-medium">{site.devices.length}</span>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Online:</span>
                        <span className="font-medium text-green-600">
                          {site.devices.filter(d => d.status === 'ONLINE').length}
                        </span>
                      </div>

                      {site.siteMetrics.length > 0 && (
                        <>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-600">Availability:</span>
                            <span className="font-medium">
                              {site.siteMetrics[0].availability.toFixed(1)}%
                            </span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-600">Efficiency:</span>
                            <span className="font-medium">
                              {site.siteMetrics[0].averageEfficiency.toFixed(1)}%
                            </span>
                          </div>
                        </>
                      )}

                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Alerts:</span>
                        <Badge variant={site.alerts.length > 0 ? "destructive" : "secondary"}>
                          {site.alerts.length}
                        </Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="devices" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Device Management</CardTitle>
                <CardDescription>Monitor and manage all devices across sites</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <Cpu className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">Device management interface coming soon</p>
                  <p className="text-sm text-gray-500 mt-2">
                    This will show detailed device status, diagnostics, and controls
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="maintenance" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Maintenance Schedule</CardTitle>
                <CardDescription>Upcoming maintenance activities</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData?.maintenanceSchedule.map((maintenance) => (
                    <div key={maintenance.id} className="flex items-center space-x-4 p-4 border rounded-lg">
                      <Calendar className="h-5 w-5 text-blue-500" />
                      <div className="flex-1">
                        <p className="font-medium">{maintenance.title}</p>
                        <p className="text-sm text-gray-500">
                          {maintenance.site.name} • {new Date(maintenance.scheduledDate).toLocaleDateString()}
                        </p>
                      </div>
                      <Badge variant="outline">Scheduled</Badge>
                    </div>
                  ))}
                  {(!dashboardData?.maintenanceSchedule || dashboardData.maintenanceSchedule.length === 0) && (
                    <div className="text-center py-8">
                      <Wrench className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">No scheduled maintenance</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="alerts" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Active Alerts</CardTitle>
                <CardDescription>Performance and maintenance alerts</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData?.alerts.map((alert) => (
                    <div key={alert.id} className="flex items-center space-x-4 p-4 border rounded-lg">
                      <AlertTriangle className="h-5 w-5 text-orange-500" />
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <p className="font-medium">{alert.title}</p>
                          <div className="flex items-center space-x-2">
                            <Badge variant="outline">{alert.alertType}</Badge>
                            <Badge className={getSeverityColor(alert.severity)}>
                              {alert.severity}
                            </Badge>
                          </div>
                        </div>
                        <p className="text-sm text-gray-500">
                          {alert.site.name} • {new Date(alert.createdAt).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  ))}
                  {(!dashboardData?.alerts || dashboardData.alerts.length === 0) && (
                    <div className="text-center py-8">
                      <CheckCircle className="h-12 w-12 text-green-400 mx-auto mb-4" />
                      <p className="text-gray-600">No active alerts</p>
                      <p className="text-sm text-gray-500">All systems operating normally</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default OperatorDashboard;