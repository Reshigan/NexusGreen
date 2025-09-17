import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar, PieChart, Pie, Cell, ScatterChart, Scatter, XAxis, YAxis, CartesianGrid } from "recharts";
import { Activity, Gauge, AlertTriangle, CheckCircle, Target, Zap } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";

// Generate performance data for different sites
const generatePerformanceData = () => {
  const sites = [
    { name: "Solar Farm Alpha", capacity: 250, location: "Sydney" },
    { name: "Rooftop Beta", capacity: 150, location: "Melbourne" },
    { name: "Commercial Gamma", capacity: 450, location: "Brisbane" },
    { name: "Industrial Delta", capacity: 320, location: "Perth" },
    { name: "Residential Epsilon", capacity: 80, location: "Adelaide" },
  ];
  
  return sites.map(site => {
    const efficiency = 85 + Math.random() * 15;
    const availability = 95 + Math.random() * 5;
    const weatherImpact = 70 + Math.random() * 30;
    const maintenanceScore = 80 + Math.random() * 20;
    const gridStability = 90 + Math.random() * 10;
    const energyYield = 75 + Math.random() * 25;
    
    const overallScore = (efficiency + availability + weatherImpact + maintenanceScore + gridStability + energyYield) / 6;
    
    return {
      ...site,
      efficiency: Math.round(efficiency),
      availability: Math.round(availability),
      weatherImpact: Math.round(weatherImpact),
      maintenanceScore: Math.round(maintenanceScore),
      gridStability: Math.round(gridStability),
      energyYield: Math.round(energyYield),
      overallScore: Math.round(overallScore),
      currentOutput: Math.round(site.capacity * (efficiency / 100) * (availability / 100)),
      alerts: Math.floor(Math.random() * 3),
      status: overallScore > 90 ? 'excellent' : overallScore > 80 ? 'good' : overallScore > 70 ? 'fair' : 'poor'
    };
  });
};

// Generate system health data
const generateSystemHealthData = () => {
  return [
    { name: 'Inverters', value: 95, status: 'healthy', total: 24, healthy: 23, warning: 1, critical: 0 },
    { name: 'Panels', value: 98, status: 'healthy', total: 1200, healthy: 1176, warning: 20, critical: 4 },
    { name: 'Batteries', value: 87, status: 'warning', total: 8, healthy: 7, warning: 1, critical: 0 },
    { name: 'Monitoring', value: 100, status: 'healthy', total: 12, healthy: 12, warning: 0, critical: 0 },
    { name: 'Grid Connection', value: 92, status: 'good', total: 5, healthy: 5, warning: 0, critical: 0 },
  ];
};

const chartConfig = {
  efficiency: { label: "Efficiency", color: "hsl(142, 76%, 36%)" },
  availability: { label: "Availability", color: "hsl(217, 91%, 60%)" },
  weatherImpact: { label: "Weather Resilience", color: "hsl(45, 93%, 47%)" },
  maintenanceScore: { label: "Maintenance", color: "hsl(262, 83%, 58%)" },
  gridStability: { label: "Grid Stability", color: "hsl(0, 84%, 60%)" },
  energyYield: { label: "Energy Yield", color: "hsl(39, 77%, 58%)" },
};

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6', '#ef4444'];

export default function PerformanceAnalyticsChart() {
  const [performanceData, setPerformanceData] = useState(generatePerformanceData());
  const [systemHealthData, setSystemHealthData] = useState(generateSystemHealthData());
  const [selectedSite, setSelectedSite] = useState(performanceData[0]);
  const [viewMode, setViewMode] = useState<'overview' | 'detailed' | 'health'>('overview');
  
  useEffect(() => {
    // Update data every 60 seconds
    const interval = setInterval(() => {
      setPerformanceData(generatePerformanceData());
      setSystemHealthData(generateSystemHealthData());
    }, 60000);
    
    return () => clearInterval(interval);
  }, []);
  
  // Calculate fleet-wide metrics
  const fleetMetrics = {
    totalCapacity: performanceData.reduce((sum, site) => sum + site.capacity, 0),
    totalOutput: performanceData.reduce((sum, site) => sum + site.currentOutput, 0),
    avgEfficiency: Math.round(performanceData.reduce((sum, site) => sum + site.efficiency, 0) / performanceData.length),
    avgAvailability: Math.round(performanceData.reduce((sum, site) => sum + site.availability, 0) / performanceData.length),
    totalAlerts: performanceData.reduce((sum, site) => sum + site.alerts, 0),
    healthySites: performanceData.filter(site => site.status === 'excellent' || site.status === 'good').length
  };
  
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return 'text-green-700 bg-green-100 border-green-300';
      case 'good': return 'text-blue-700 bg-blue-100 border-blue-300';
      case 'fair': return 'text-yellow-700 bg-yellow-100 border-yellow-300';
      case 'poor': return 'text-red-700 bg-red-100 border-red-300';
      default: return 'text-gray-700 bg-gray-100 border-gray-300';
    }
  };
  
  const getHealthColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-green-600';
      case 'warning': return 'text-yellow-600';
      case 'critical': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };
  
  return (
    <div className="space-y-6">
      {/* Fleet Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-blue-800">Fleet Capacity</CardTitle>
            <Zap className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-900">{fleetMetrics.totalCapacity} kW</div>
            <div className="text-xs text-blue-700">
              Current: {fleetMetrics.totalOutput} kW ({Math.round((fleetMetrics.totalOutput / fleetMetrics.totalCapacity) * 100)}%)
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-green-800">Avg Efficiency</CardTitle>
            <Gauge className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-900">{fleetMetrics.avgEfficiency}%</div>
            <Progress value={fleetMetrics.avgEfficiency} className="h-2 mt-2" />
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-purple-50 to-violet-50 border-purple-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-purple-800">System Health</CardTitle>
            <CheckCircle className="h-4 w-4 text-purple-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-900">{fleetMetrics.healthySites}/{performanceData.length}</div>
            <div className="text-xs text-purple-700">Sites Operating Well</div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-orange-50 to-amber-50 border-orange-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-orange-800">Active Alerts</CardTitle>
            <AlertTriangle className="h-4 w-4 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-900">{fleetMetrics.totalAlerts}</div>
            <div className="text-xs text-orange-700">Require Attention</div>
          </CardContent>
        </Card>
      </div>
      
      {/* View Mode Controls */}
      <div className="flex gap-2">
        <Badge 
          variant={viewMode === 'overview' ? 'default' : 'outline'}
          className="cursor-pointer"
          onClick={() => setViewMode('overview')}
        >
          Fleet Overview
        </Badge>
        <Badge 
          variant={viewMode === 'detailed' ? 'default' : 'outline'}
          className="cursor-pointer"
          onClick={() => setViewMode('detailed')}
        >
          Site Analysis
        </Badge>
        <Badge 
          variant={viewMode === 'health' ? 'default' : 'outline'}
          className="cursor-pointer"
          onClick={() => setViewMode('health')}
        >
          System Health
        </Badge>
      </div>
      
      {/* Main Content */}
      {viewMode === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Performance Scatter Plot */}
          <Card>
            <CardHeader>
              <CardTitle>Site Performance Matrix</CardTitle>
              <CardDescription>Efficiency vs Availability across all sites</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer config={chartConfig} className="h-[300px]">
                <ScatterChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="efficiency" 
                    domain={[80, 100]}
                    tick={{ fontSize: 12 }}
                    label={{ value: 'Efficiency (%)', position: 'insideBottom', offset: -5 }}
                  />
                  <YAxis 
                    dataKey="availability" 
                    domain={[90, 100]}
                    tick={{ fontSize: 12 }}
                    label={{ value: 'Availability (%)', angle: -90, position: 'insideLeft' }}
                  />
                  <ChartTooltip 
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        const data = payload[0].payload;
                        return (
                          <div className="bg-white p-3 border rounded-lg shadow-lg">
                            <p className="font-semibold">{data.name}</p>
                            <p>Efficiency: {data.efficiency}%</p>
                            <p>Availability: {data.availability}%</p>
                            <p>Capacity: {data.capacity} kW</p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Scatter dataKey="availability" fill="hsl(217, 91%, 60%)" />
                </ScatterChart>
              </ChartContainer>
            </CardContent>
          </Card>
          
          {/* Site Status Overview */}
          <Card>
            <CardHeader>
              <CardTitle>Site Status Distribution</CardTitle>
              <CardDescription>Current operational status of all sites</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {performanceData.map((site, index) => (
                  <div key={site.name} className="flex items-center justify-between p-3 rounded-lg border">
                    <div className="flex items-center space-x-3">
                      <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[index % COLORS.length] }} />
                      <div>
                        <p className="font-medium">{site.name}</p>
                        <p className="text-sm text-gray-600">{site.location} • {site.capacity} kW</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge className={getStatusColor(site.status)}>
                        {site.status}
                      </Badge>
                      <span className="text-sm font-medium">{site.overallScore}%</span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
      
      {viewMode === 'detailed' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Site Selector */}
          <Card>
            <CardHeader>
              <CardTitle>Select Site</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {performanceData.map((site) => (
                  <div
                    key={site.name}
                    className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                      selectedSite.name === site.name 
                        ? 'bg-blue-50 border-blue-300' 
                        : 'hover:bg-gray-50'
                    }`}
                    onClick={() => setSelectedSite(site)}
                  >
                    <div className="flex justify-between items-center">
                      <div>
                        <p className="font-medium">{site.name}</p>
                        <p className="text-sm text-gray-600">{site.location}</p>
                      </div>
                      <Badge className={getStatusColor(site.status)}>
                        {site.overallScore}%
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
          
          {/* Radar Chart */}
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle>{selectedSite.name} - Performance Analysis</CardTitle>
              <CardDescription>Comprehensive performance metrics breakdown</CardDescription>
            </CardHeader>
            <CardContent>
              <ChartContainer config={chartConfig} className="h-[400px]">
                <RadarChart data={[selectedSite]}>
                  <PolarGrid />
                  <PolarAngleAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <PolarRadiusAxis 
                    angle={90} 
                    domain={[0, 100]} 
                    tick={{ fontSize: 10 }}
                  />
                  <Radar
                    name="Efficiency"
                    dataKey="efficiency"
                    stroke="var(--color-efficiency)"
                    fill="var(--color-efficiency)"
                    fillOpacity={0.3}
                    strokeWidth={2}
                  />
                  <Radar
                    name="Availability"
                    dataKey="availability"
                    stroke="var(--color-availability)"
                    fill="var(--color-availability)"
                    fillOpacity={0.2}
                    strokeWidth={2}
                  />
                  <Radar
                    name="Weather Impact"
                    dataKey="weatherImpact"
                    stroke="var(--color-weatherImpact)"
                    fill="var(--color-weatherImpact)"
                    fillOpacity={0.2}
                    strokeWidth={2}
                  />
                  <ChartTooltip content={<ChartTooltipContent />} />
                </RadarChart>
              </ChartContainer>
            </CardContent>
          </Card>
        </div>
      )}
      
      {viewMode === 'health' && (
        <Card>
          <CardHeader>
            <CardTitle>System Health Dashboard</CardTitle>
            <CardDescription>Component-level health monitoring across the fleet</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {systemHealthData.map((component) => (
                <div key={component.name} className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold">{component.name}</h3>
                    <Badge className={getHealthColor(component.status)}>
                      {component.value}%
                    </Badge>
                  </div>
                  
                  <Progress value={component.value} className="h-3" />
                  
                  <div className="grid grid-cols-3 gap-2 text-sm">
                    <div className="text-center">
                      <div className="text-green-600 font-semibold">{component.healthy}</div>
                      <div className="text-gray-600">Healthy</div>
                    </div>
                    <div className="text-center">
                      <div className="text-yellow-600 font-semibold">{component.warning}</div>
                      <div className="text-gray-600">Warning</div>
                    </div>
                    <div className="text-center">
                      <div className="text-red-600 font-semibold">{component.critical}</div>
                      <div className="text-gray-600">Critical</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}