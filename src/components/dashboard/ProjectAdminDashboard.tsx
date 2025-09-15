import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  FolderOpen, 
  MapPin, 
  Users, 
  AlertTriangle, 
  Activity,
  Calendar,
  Settings,
  LogOut,
  CheckCircle,
  Clock,
  TrendingUp
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { User, Organization } from '@/services/nexusApi';

interface ProjectAdminDashboardProps {
  user: User;
  organization: Organization;
  onLogout: () => void;
}

interface ProjectAdminDashboardData {
  project: {
    id: string;
    name: string;
    description: string;
    totalInvestment: number;
    expectedROI: number;
    fundingRate: number;
    organization: {
      name: string;
    };
    financialRecords: Array<{
      id: string;
      amount: number;
      recordType: string;
      createdAt: Date;
    }>;
  };
  overview: {
    totalSites: number;
    totalUsers: number;
    activeUsers: number;
    totalAlerts: number;
  };
  sites: Array<{
    id: string;
    name: string;
    capacity: number;
    municipality: string;
    devices: Array<{
      id: string;
      deviceType: string;
      status: string;
    }>;
    siteMetrics: Array<{
      date: Date;
      totalGeneration: number;
      averageEfficiency: number;
      availability: number;
    }>;
    alerts: Array<{
      id: string;
      severity: string;
    }>;
  }>;
  users: Array<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    role: string;
    isActive: boolean;
    lastLoginAt: Date | null;
  }>;
  projectKPIs: Array<{
    kpiName: string;
    kpiValue: number;
    unit: string;
    calculatedAt: Date;
  }>;
  recentActivity: Array<{
    id: string;
    action: string;
    resource: string;
    createdAt: Date;
    user: {
      firstName: string;
      lastName: string;
    } | null;
  }>;
}

const ProjectAdminDashboard: React.FC<ProjectAdminDashboardProps> = ({
  user,
  organization,
  onLogout
}) => {
  const [dashboardData, setDashboardData] = useState<ProjectAdminDashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await fetch('/api/dashboard/project-admin', {
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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-ZA', {
      style: 'currency',
      currency: 'ZAR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
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

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'CUSTOMER': return 'bg-blue-100 text-blue-800';
      case 'OPERATOR': return 'bg-green-100 text-green-800';
      case 'FUNDER': return 'bg-purple-100 text-purple-800';
      case 'PROJECT_ADMIN': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

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

  if (!dashboardData?.project) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <FolderOpen className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-4">No Project Assigned</h2>
          <p className="text-gray-600 mb-4">You are not currently assigned to any project.</p>
          <Button onClick={onLogout}>
            <LogOut className="h-4 w-4 mr-2" />
            Logout
          </Button>
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
              <h1 className="text-3xl font-bold text-gray-900">Project Admin Dashboard</h1>
              <p className="text-gray-600">Welcome back, {user.firstName} {user.lastName}</p>
              <p className="text-sm text-gray-500">{dashboardData.project.name}</p>
            </div>
            <div className="flex items-center space-x-4">
              <Button variant="outline" size="sm">
                <Settings className="h-4 w-4 mr-2" />
                Settings
              </Button>
              <Button variant="outline" size="sm" onClick={onLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Project Info Card */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center">
              <FolderOpen className="h-5 w-5 mr-2" />
              {dashboardData.project.name}
            </CardTitle>
            <CardDescription>{dashboardData.project.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div>
                <p className="text-sm text-gray-600">Total Investment</p>
                <p className="text-2xl font-bold text-blue-600">
                  {formatCurrency(dashboardData.project.totalInvestment || 0)}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Expected ROI</p>
                <p className="text-2xl font-bold text-green-600">
                  {(dashboardData.project.expectedROI || 0).toFixed(1)}%
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Funding Rate</p>
                <p className="text-2xl font-bold">
                  R{(dashboardData.project.fundingRate || 0).toFixed(2)}/kWh
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Overview Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Sites</CardTitle>
              <MapPin className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData.overview.totalSites}</div>
              <p className="text-xs text-muted-foreground">In this project</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData.overview.totalUsers}</div>
              <p className="text-xs text-muted-foreground">
                {dashboardData.overview.activeUsers} active
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Performance</CardTitle>
              <TrendingUp className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {dashboardData.projectKPIs.find(k => k.kpiName === 'Project Performance')?.kpiValue.toFixed(1) || 'N/A'}
              </div>
              <p className="text-xs text-muted-foreground">Overall score</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Alerts</CardTitle>
              <AlertTriangle className="h-4 w-4 text-orange-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData.overview.totalAlerts}</div>
              <p className="text-xs text-muted-foreground">Require attention</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="sites" className="space-y-6">
          <TabsList>
            <TabsTrigger value="sites">Sites</TabsTrigger>
            <TabsTrigger value="users">Users</TabsTrigger>
            <TabsTrigger value="performance">Performance</TabsTrigger>
            <TabsTrigger value="activity">Activity</TabsTrigger>
          </TabsList>

          <TabsContent value="sites" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {dashboardData.sites.map((site) => (
                <Card key={site.id}>
                  <CardHeader>
                    <CardTitle className="text-lg">{site.name}</CardTitle>
                    <CardDescription>
                      {site.capacity.toFixed(1)} kW • {site.municipality}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Devices:</span>
                        <div className="flex items-center space-x-2">
                          <span className="font-medium">{site.devices.length}</span>
                          <Badge variant="outline">
                            {site.devices.filter(d => d.status === 'ONLINE').length} online
                          </Badge>
                        </div>
                      </div>
                      
                      {site.siteMetrics.length > 0 && (
                        <>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-600">Generation:</span>
                            <span className="font-medium">
                              {site.siteMetrics[0].totalGeneration.toFixed(1)} MWh
                            </span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-600">Efficiency:</span>
                            <span className="font-medium">
                              {site.siteMetrics[0].averageEfficiency.toFixed(1)}%
                            </span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-600">Availability:</span>
                            <span className="font-medium">
                              {site.siteMetrics[0].availability.toFixed(1)}%
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

          <TabsContent value="users" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Project Users</CardTitle>
                <CardDescription>Users assigned to this project</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData.users.map((projectUser) => (
                    <div key={projectUser.id} className="flex items-center space-x-4 p-4 border rounded-lg">
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <p className="font-medium">
                            {projectUser.firstName} {projectUser.lastName}
                          </p>
                          <div className="flex items-center space-x-2">
                            <Badge className={getRoleColor(projectUser.role)}>
                              {projectUser.role}
                            </Badge>
                            <Badge variant={projectUser.isActive ? "default" : "secondary"}>
                              {projectUser.isActive ? "Active" : "Inactive"}
                            </Badge>
                          </div>
                        </div>
                        <p className="text-sm text-gray-500">
                          {projectUser.email}
                        </p>
                        <p className="text-xs text-gray-400">
                          Last login: {projectUser.lastLoginAt ? 
                            new Date(projectUser.lastLoginAt).toLocaleString() : 
                            'Never'
                          }
                        </p>
                      </div>
                    </div>
                  ))}
                  {dashboardData.users.length === 0 && (
                    <div className="text-center py-8">
                      <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">No users assigned to this project</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="performance" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Project KPIs</CardTitle>
                <CardDescription>Key performance indicators for this project</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData.projectKPIs.map((kpi, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div>
                        <p className="font-medium">{kpi.kpiName}</p>
                        <p className="text-sm text-gray-500">
                          Updated {new Date(kpi.calculatedAt).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-2xl font-bold">{kpi.kpiValue.toFixed(1)}</p>
                        <p className="text-sm text-gray-500">{kpi.unit}</p>
                      </div>
                    </div>
                  ))}
                  {dashboardData.projectKPIs.length === 0 && (
                    <div className="text-center py-8">
                      <TrendingUp className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">No performance data available</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="activity" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Recent Activity</CardTitle>
                <CardDescription>Recent actions in this project</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData.recentActivity.map((activity) => (
                    <div key={activity.id} className="flex items-center space-x-4 p-4 border rounded-lg">
                      <Activity className="h-5 w-5 text-blue-500" />
                      <div className="flex-1">
                        <p className="text-sm font-medium">
                          {activity.action} on {activity.resource}
                        </p>
                        <p className="text-xs text-gray-500">
                          {activity.user ? 
                            `${activity.user.firstName} ${activity.user.lastName}` : 
                            'System'
                          } • {new Date(activity.createdAt).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  ))}
                  {dashboardData.recentActivity.length === 0 && (
                    <div className="text-center py-8">
                      <Clock className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">No recent activity</p>
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

export default ProjectAdminDashboard;