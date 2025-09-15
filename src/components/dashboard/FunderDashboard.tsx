import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  DollarSign, 
  TrendingUp, 
  PieChart, 
  FolderOpen, 
  Calendar,
  Target,
  BarChart3,
  LogOut,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, AreaChart, Area } from 'recharts';
import { User, Organization } from '@/services/nexusApi';

interface FunderDashboardProps {
  user: User;
  organization: Organization;
  onLogout: () => void;
}

interface FunderDashboardData {
  overview: {
    totalProjects: number;
    totalInvestment: number;
    totalReturns: number;
    averageROI: number;
  };
  projects: Array<{
    id: string;
    name: string;
    totalInvestment: number;
    expectedROI: number;
    fundingRate: number;
    sites: Array<{
      id: string;
      name: string;
      capacity: number;
      siteMetrics: Array<{
        date: Date;
        totalGeneration: number;
        averageEfficiency: number;
      }>;
    }>;
    financialRecords: Array<{
      id: string;
      amount: number;
      recordType: string;
      createdAt: Date;
    }>;
  }>;
  roiMetrics: Array<{
    kpiName: string;
    kpiValue: number;
    unit: string;
    calculatedAt: Date;
  }>;
  monthlyReturns: Array<{
    createdAt: Date;
    _sum: {
      amount: number;
    };
  }>;
  performanceByProject: Array<{
    id: string;
    name: string;
    investment: number;
    expectedROI: number;
    actualROI: number;
    sites: number;
  }>;
}

const FunderDashboard: React.FC<FunderDashboardProps> = ({
  user,
  organization,
  onLogout
}) => {
  const [dashboardData, setDashboardData] = useState<FunderDashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await fetch('/api/dashboard/funder', {
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

  const getROIColor = (roi: number) => {
    if (roi >= 15) return 'text-green-600';
    if (roi >= 10) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getROIIcon = (actual: number, expected: number) => {
    if (actual > expected) return <ArrowUpRight className="h-4 w-4 text-green-600" />;
    if (actual < expected) return <ArrowDownRight className="h-4 w-4 text-red-600" />;
    return <Target className="h-4 w-4 text-blue-600" />;
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
              <h1 className="text-3xl font-bold text-gray-900">Funder Dashboard</h1>
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
              <CardTitle className="text-sm font-medium">Total Investment</CardTitle>
              <DollarSign className="h-4 w-4 text-blue-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">
                {formatCurrency(dashboardData?.overview.totalInvestment || 0)}
              </div>
              <p className="text-xs text-muted-foreground">Across all projects</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Returns</CardTitle>
              <TrendingUp className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {formatCurrency(dashboardData?.overview.totalReturns || 0)}
              </div>
              <p className="text-xs text-muted-foreground">Generated to date</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Average ROI</CardTitle>
              <Target className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className={`text-2xl font-bold ${getROIColor(dashboardData?.overview.averageROI || 0)}`}>
                {(dashboardData?.overview.averageROI || 0).toFixed(1)}%
              </div>
              <p className="text-xs text-muted-foreground">Annual return</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Projects</CardTitle>
              <FolderOpen className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{dashboardData?.overview.totalProjects || 0}</div>
              <p className="text-xs text-muted-foreground">Funded projects</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList>
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="projects">Projects</TabsTrigger>
            <TabsTrigger value="returns">Returns</TabsTrigger>
            <TabsTrigger value="performance">Performance</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* ROI Metrics */}
              <Card>
                <CardHeader>
                  <CardTitle>ROI Metrics</CardTitle>
                  <CardDescription>Return on investment indicators</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {dashboardData?.roiMetrics.map((metric, index) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div>
                          <p className="font-medium">{metric.kpiName}</p>
                          <p className="text-sm text-gray-500">
                            Updated {new Date(metric.calculatedAt).toLocaleDateString()}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className={`text-2xl font-bold ${getROIColor(metric.kpiValue)}`}>
                            {metric.kpiValue.toFixed(1)}
                          </p>
                          <p className="text-sm text-gray-500">{metric.unit}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              {/* Monthly Returns Chart */}
              <Card>
                <CardHeader>
                  <CardTitle>Monthly Returns</CardTitle>
                  <CardDescription>Revenue generated over time</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={dashboardData?.monthlyReturns || []}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis 
                        dataKey="createdAt" 
                        tickFormatter={(value) => new Date(value).toLocaleDateString()}
                      />
                      <YAxis tickFormatter={(value) => formatCurrency(value)} />
                      <Tooltip 
                        labelFormatter={(value) => new Date(value).toLocaleDateString()}
                        formatter={(value: number) => [formatCurrency(value), 'Returns']}
                      />
                      <Area 
                        type="monotone" 
                        dataKey="_sum.amount" 
                        stroke="#10B981" 
                        fill="#10B981"
                        fillOpacity={0.3}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="projects" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {dashboardData?.projects.map((project) => (
                <Card key={project.id}>
                  <CardHeader>
                    <CardTitle className="text-lg">{project.name}</CardTitle>
                    <CardDescription>{project.sites.length} sites</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Investment:</span>
                        <span className="font-medium">
                          {formatCurrency(project.totalInvestment || 0)}
                        </span>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Expected ROI:</span>
                        <span className="font-medium">
                          {(project.expectedROI || 0).toFixed(1)}%
                        </span>
                      </div>

                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Funding Rate:</span>
                        <span className="font-medium">
                          R{(project.fundingRate || 0).toFixed(2)}/kWh
                        </span>
                      </div>

                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">Returns:</span>
                        <span className="font-medium text-green-600">
                          {formatCurrency(
                            project.financialRecords
                              .filter(r => r.recordType === 'FUNDER_RETURN')
                              .reduce((sum, r) => sum + r.amount, 0)
                          )}
                        </span>
                      </div>

                      <div className="pt-2 border-t">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-600">Total Capacity:</span>
                          <span className="font-medium">
                            {project.sites.reduce((sum, site) => sum + site.capacity, 0).toFixed(1)} kW
                          </span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="returns" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Returns Analysis</CardTitle>
                <CardDescription>Detailed return analysis by project</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">Detailed returns analysis coming soon</p>
                  <p className="text-sm text-gray-500 mt-2">
                    This will show cash flow projections, payback periods, and risk analysis
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="performance" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Project Performance</CardTitle>
                <CardDescription>Performance vs expectations by project</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {dashboardData?.performanceByProject.map((project) => (
                    <div key={project.id} className="p-4 border rounded-lg">
                      <div className="flex items-center justify-between mb-3">
                        <h3 className="font-medium">{project.name}</h3>
                        <div className="flex items-center space-x-2">
                          {getROIIcon(project.actualROI, project.expectedROI)}
                          <Badge variant={project.actualROI >= project.expectedROI ? "default" : "secondary"}>
                            {project.actualROI >= project.expectedROI ? "On Track" : "Below Target"}
                          </Badge>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <p className="text-gray-600">Investment</p>
                          <p className="font-medium">{formatCurrency(project.investment || 0)}</p>
                        </div>
                        <div>
                          <p className="text-gray-600">Expected ROI</p>
                          <p className="font-medium">{project.expectedROI.toFixed(1)}%</p>
                        </div>
                        <div>
                          <p className="text-gray-600">Actual ROI</p>
                          <p className={`font-medium ${getROIColor(project.actualROI)}`}>
                            {project.actualROI.toFixed(1)}%
                          </p>
                        </div>
                        <div>
                          <p className="text-gray-600">Sites</p>
                          <p className="font-medium">{project.sites}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                  {(!dashboardData?.performanceByProject || dashboardData.performanceByProject.length === 0) && (
                    <div className="text-center py-8">
                      <PieChart className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">No project performance data available</p>
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

export default FunderDashboard;