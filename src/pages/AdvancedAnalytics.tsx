import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  BarChart3, 
  TrendingUp, 
  Activity, 
  Download, 
  RefreshCw,
  Zap,
  DollarSign,
  Gauge
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import EnergyProductionChart from "@/components/charts/EnergyProductionChart";
import RevenueTrendsChart from "@/components/charts/RevenueTrendsChart";
import PerformanceAnalyticsChart from "@/components/charts/PerformanceAnalyticsChart";

export default function AdvancedAnalytics() {
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedTimeRange, setSelectedTimeRange] = useState<'24h' | '7d' | '30d' | '1y'>('24h');
  
  const handleRefresh = async () => {
    setIsRefreshing(true);
    // Simulate data refresh
    await new Promise(resolve => setTimeout(resolve, 1000));
    setIsRefreshing(false);
  };
  
  const handleExport = (format: 'pdf' | 'csv' | 'json') => {
    // Export functionality would be implemented here
    console.log(`Exporting analytics data as ${format}`);
  };
  
  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Advanced Analytics</h1>
            <p className="text-muted-foreground">
              Comprehensive data visualizations and performance insights
            </p>
          </div>
          
          <div className="flex items-center space-x-2">
            {/* Time Range Selector */}
            <div className="flex items-center space-x-1 border rounded-lg p-1">
              <Button
                variant={selectedTimeRange === '24h' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setSelectedTimeRange('24h')}
              >
                24H
              </Button>
              <Button
                variant={selectedTimeRange === '7d' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setSelectedTimeRange('7d')}
              >
                7D
              </Button>
              <Button
                variant={selectedTimeRange === '30d' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setSelectedTimeRange('30d')}
              >
                30D
              </Button>
              <Button
                variant={selectedTimeRange === '1y' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setSelectedTimeRange('1y')}
              >
                1Y
              </Button>
            </div>
            
            {/* Action Buttons */}
            <Button
              variant="outline"
              size="sm"
              onClick={handleRefresh}
              disabled={isRefreshing}
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
            
            <div className="flex items-center space-x-1">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('pdf')}
              >
                <Download className="h-4 w-4 mr-2" />
                PDF
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('csv')}
              >
                CSV
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('json')}
              >
                JSON
              </Button>
            </div>
          </div>
        </div>
        
        {/* Phase 2 Feature Badge */}
        <div className="flex items-center space-x-2">
          <Badge variant="secondary" className="bg-blue-100 text-blue-800 border-blue-300">
            <BarChart3 className="h-3 w-3 mr-1" />
            Phase 2: Advanced Data Visualizations
          </Badge>
          <Badge variant="outline" className="text-green-700 border-green-300">
            ✅ Interactive Charts
          </Badge>
          <Badge variant="outline" className="text-green-700 border-green-300">
            ✅ Real-time Updates
          </Badge>
          <Badge variant="outline" className="text-green-700 border-green-300">
            ✅ Multi-view Analytics
          </Badge>
        </div>
        
        {/* Analytics Tabs */}
        <Tabs defaultValue="energy" className="space-y-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="energy" className="flex items-center space-x-2">
              <Zap className="h-4 w-4" />
              <span>Energy Production</span>
            </TabsTrigger>
            <TabsTrigger value="revenue" className="flex items-center space-x-2">
              <DollarSign className="h-4 w-4" />
              <span>Revenue Trends</span>
            </TabsTrigger>
            <TabsTrigger value="performance" className="flex items-center space-x-2">
              <Gauge className="h-4 w-4" />
              <span>Performance Analytics</span>
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value="energy" className="space-y-6">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center space-x-2">
                      <Zap className="h-5 w-5 text-yellow-600" />
                      <span>Energy Production Analytics</span>
                    </CardTitle>
                    <CardDescription>
                      Real-time monitoring of solar production, battery output, and grid consumption with interactive visualizations
                    </CardDescription>
                  </div>
                  <Badge variant="outline" className="text-green-700 border-green-300">
                    Live Data
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <EnergyProductionChart />
              </CardContent>
            </Card>
          </TabsContent>
          
          <TabsContent value="revenue" className="space-y-6">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center space-x-2">
                      <TrendingUp className="h-5 w-5 text-green-600" />
                      <span>Revenue Trends & Financial Analytics</span>
                    </CardTitle>
                    <CardDescription>
                      Comprehensive analysis of revenue streams, profit margins, and financial performance over time
                    </CardDescription>
                  </div>
                  <Badge variant="outline" className="text-blue-700 border-blue-300">
                    Monthly Updates
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <RevenueTrendsChart />
              </CardContent>
            </Card>
          </TabsContent>
          
          <TabsContent value="performance" className="space-y-6">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center space-x-2">
                      <Activity className="h-5 w-5 text-purple-600" />
                      <span>Performance Analytics & System Health</span>
                    </CardTitle>
                    <CardDescription>
                      Multi-dimensional performance analysis with fleet overview, site-specific metrics, and system health monitoring
                    </CardDescription>
                  </div>
                  <Badge variant="outline" className="text-purple-700 border-purple-300">
                    Real-time Monitoring
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <PerformanceAnalyticsChart />
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
        
        {/* Feature Summary */}
        <Card className="bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200">
          <CardHeader>
            <CardTitle className="text-blue-900">Phase 2 Features Implemented</CardTitle>
            <CardDescription className="text-blue-700">
              Advanced data visualizations now available across the platform
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
                  <Zap className="h-4 w-4 text-yellow-600" />
                </div>
                <div>
                  <h4 className="font-semibold text-blue-900">Energy Production Charts</h4>
                  <p className="text-sm text-blue-700">Interactive line charts, area charts, and real-time monitoring</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                  <TrendingUp className="h-4 w-4 text-green-600" />
                </div>
                <div>
                  <h4 className="font-semibold text-blue-900">Revenue Analytics</h4>
                  <p className="text-sm text-blue-700">Bar charts, composed charts, and financial trend analysis</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                  <Activity className="h-4 w-4 text-purple-600" />
                </div>
                <div>
                  <h4 className="font-semibold text-blue-900">Performance Monitoring</h4>
                  <p className="text-sm text-blue-700">Radar charts, scatter plots, and system health dashboards</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}