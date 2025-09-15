import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  DollarSign, 
  TrendingDown, 
  Zap, 
  MapPin, 
  AlertTriangle,
  Calendar,
  BarChart3,
  LogOut,
  Leaf
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, AreaChart, Area } from 'recharts';
import { User, Organization } from '@/services/nexusApi';

interface CustomerDashboardProps {
  user: User;
  organization: Organization;
  onLogout: () => void;
}

interface CustomerDashboardData {
  overview: {
    totalSites: number;
    totalProjects: number;
    totalSavings: number;
    activeAlerts: number;
  };
  sites: Array<{
    id: string;
    name: string;
    capacity: number;
    municipality: string;
    siteMetrics: Array<{
      date: Date;
      totalGeneration: number;
      totalConsumption: number;
      averageEfficiency: number;
    }>;
    project: {
      name: string;
    } | null;
  }>;
  efficiencyMetrics: Array<{
    kpiName: string;
    kpiValue: number;
    unit: string;
    calculatedAt: Date;
  }>;
  alerts: Array<{
    id: string;
    title: string;
    severity: string;
    createdAt: Date;
    site: {
      name: string;
    };
  }>;
  savingsBreakdown: {
    monthly: number;
    yearly: number;
  };
}

const CustomerDashboard: React.FC<CustomerDashboardProps> = ({
  user,
  organization,
  onLogout
}) => {
  const [dashboardData, setDashboardData] = useState<CustomerDashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await fetch('/api/dashboard/customer', {
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
      currency: 'ZAR'
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
              <h1 className="text-3xl font-bold text-gray-900">Customer Dashboard</h1>
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
              <CardTitle className="text-sm font-medium">Total Savings</CardTitle>
              <DollarSign className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {formatCurrency(dashboardData?.overview.totalSavings || 0)}
              </div>
              <p className="text-xs text-muted-foreground">vs Municipal rates</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Solar Sites</CardTitle>
              <MapPin className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData?.overview.totalSites || 0}</div>
              <p className="text-xs text-muted-foreground">Active installations</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Monthly Savings</CardTitle>
              <TrendingDown className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {formatCurrency(dashboardData?.savingsBreakdown.monthly || 0)}
              </div>
              <p className="text-xs text-muted-foreground">This month</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Alerts</CardTitle>
              <AlertTriangle className="h-4 w-4 text-orange-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData?.overview.activeAlerts || 0}</div>
              <p className="text-xs text-muted-foreground">Require attention</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList>
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="savings">Savings Analysis</TabsTrigger>
            <TabsTrigger value="sites">Sites</TabsTrigger>
            <TabsTrigger value="alerts">Alerts</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Efficiency Metrics */}
              <Card>
                <CardHeader>
                  <CardTitle>System Efficiency</CardTitle>
                  <CardDescription>Key performance indicators</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {dashboardData?.efficiencyMetrics.map((metric, index) => (
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

              {/* Savings Breakdown */}
              <Card>
                <CardHeader>
                  <CardTitle>Savings Breakdown</CardTitle>
                  <CardDescription>Cost savings vs municipal rates</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-6">
                    <div className="text-center">
                      <div className="text-4xl font-bold text-green-600 mb-2">
                        {formatCurrency(dashboardData?.savingsBreakdown.yearly || 0)}
                      </div>
                      <p className="text-gray-600">Annual Savings</p>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div className="text-center p-4 bg-green-50 rounded-lg">
                        <div className="text-2xl font-bold text-green-600">
                          {formatCurrency(dashboardData?.savingsBreakdown.monthly || 0)}
                        </div>
                        <p className="text-sm text-gray-600">Monthly</p>
                      </div>
                      <div className="text-center p-4 bg-blue-50 rounded-lg">
                        <div className="text-2xl font-bold text-blue-600">
                          {((dashboardData?.savingsBreakdown.yearly || 0) / 12).toFixed(0)}%
                        </div>
                        <p className="text-sm text-gray-600">Avg. Reduction</p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="savings" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Savings Analysis</CardTitle>
                <CardDescription>Detailed cost savings vs municipal electricity rates</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">Detailed savings analysis coming soon</p>
                  <p className="text-sm text-gray-500 mt-2">
                    This will show monthly comparisons, rate structures, and projected savings
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="sites" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {dashboardData?.sites.map((site) => (
                <Card key={site.id}>
                  <CardHeader>
                    <CardTitle className="text-lg">{site.name}</CardTitle>
                    <CardDescription>
                      {site.capacity.toFixed(1)} kW • {site.municipality}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {site.project && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-600">Project:</span>
                          <Badge variant="outline">{site.project.name}</Badge>
                        </div>
                      )}
                      
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
                        </>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="alerts" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Active Alerts</CardTitle>
                <CardDescription>System alerts requiring attention</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData?.alerts.map((alert) => (
                    <div key={alert.id} className="flex items-center space-x-4 p-4 border rounded-lg">
                      <AlertTriangle className="h-5 w-5 text-orange-500" />
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <p className="font-medium">{alert.title}</p>
                          <Badge className={getSeverityColor(alert.severity)}>
                            {alert.severity}
                          </Badge>
                        </div>
                        <p className="text-sm text-gray-500">
                          {alert.site.name} • {new Date(alert.createdAt).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  ))}
                  {(!dashboardData?.alerts || dashboardData.alerts.length === 0) && (
                    <div className="text-center py-8">
                      <Leaf className="h-12 w-12 text-green-400 mx-auto mb-4" />
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

export default CustomerDashboard;