import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Sun, 
  Zap, 
  TrendingUp, 
  DollarSign, 
  Leaf, 
  MapPin, 
  AlertTriangle,
  Battery,
  Activity,
  BarChart3,
  Calendar,
  Clock,
  Users,
  Building,
  Target,
  Award,
  Gauge,
  Wind,
  Thermometer,
  Eye,
  Settings,
  Bell,
  Download,
  RefreshCw
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useCurrency } from '@/contexts/CurrencyContext';
import CurrencySelector from '@/components/CurrencySelector';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { nexusTheme, getGlassStyle, getGradient } from '@/styles/nexusTheme';
import { nexusApi, type User, type Organization, type DashboardMetrics, type Site, type Alert } from '@/services/nexusApi';

interface AdvancedDashboardProps {
  user: User;
  organization: Organization;
  onLogout?: () => void;
  onNavigateToSites?: () => void;
  onNavigateToUsers?: () => void;
  onNavigateToAlerts?: () => void;
}

const AdvancedDashboard: React.FC<AdvancedDashboardProps> = ({ user, organization, onLogout, onNavigateToSites, onNavigateToUsers, onNavigateToAlerts }) => {
  const [currentTime, setCurrentTime] = useState(new Date());
  const [selectedTimeRange, setSelectedTimeRange] = useState('today');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [dashboardMetrics, setDashboardMetrics] = useState<DashboardMetrics | null>(null);
  const [sites, setSites] = useState<Site[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const { formatAmount } = useCurrency();

  // Update time every second
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Load initial data
  useEffect(() => {
    loadDashboardData();
  }, [organization.id]);

  // Real-time data updates
  useEffect(() => {
    const interval = setInterval(() => {
      if (!isRefreshing) {
        loadDashboardData();
      }
    }, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, [organization.id, isRefreshing]);

  const loadDashboardData = async () => {
    try {
      const [metricsData, sitesData, alertsData] = await Promise.all([
        nexusApi.getDashboardMetrics(organization.id),
        nexusApi.getSites(organization.id),
        nexusApi.getAlerts(organization.id, 'ACTIVE')
      ]);

      setDashboardMetrics(metricsData);
      setSites(sitesData);
      setAlerts(alertsData);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await loadDashboardData();
    } finally {
      setIsRefreshing(false);
    }
  };

  // Generate sample chart data
  const energyData = Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}:00`,
    generation: Math.max(0, Math.sin((i - 6) / 12 * Math.PI) * 500 + Math.random() * 100),
    consumption: 200 + Math.random() * 150,
    export: Math.max(0, Math.sin((i - 6) / 12 * Math.PI) * 300 + Math.random() * 50)
  }));

  const performanceData = Array.from({ length: 7 }, (_, i) => ({
    day: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
    performance: 85 + Math.random() * 15,
    target: 95,
    weather: ['sunny', 'cloudy', 'sunny', 'rainy', 'sunny', 'sunny', 'cloudy'][i]
  }));

  const siteDistribution = dashboardMetrics ? [
    { name: 'Active', value: dashboardMetrics.activeSites, color: '#22c55e' },
    { name: 'Maintenance', value: sites.filter(s => s.status === 'MAINTENANCE').length, color: '#f59e0b' },
    { name: 'Offline', value: sites.filter(s => s.status === 'OFFLINE').length, color: '#ef4444' },
    { name: 'Fault', value: sites.filter(s => s.status === 'FAULT').length, color: '#ef4444' }
  ] : [];

  const MetricCard = ({ title, value, unit, icon: Icon, trend, color, gradient, description }: any) => (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -5, scale: 1.02 }}
      transition={{ duration: 0.3 }}
    >
      <Card 
        className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 relative overflow-hidden"
        style={{
          ...getGlassStyle('light'),
          background: 'rgba(255, 255, 255, 0.9)',
        }}
      >
        <div 
          className="absolute inset-0 opacity-10"
          style={{ background: gradient }}
        />
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 relative z-10">
          <CardTitle className="text-sm font-medium text-gray-600">{title}</CardTitle>
          <div 
            className="p-2 rounded-lg"
            style={{ 
              background: `${color}20`,
              color: color 
            }}
          >
            <Icon className="h-4 w-4" />
          </div>
        </CardHeader>
        <CardContent className="relative z-10">
          <div className="text-2xl font-bold text-gray-900">
            {typeof value === 'number' ? value.toLocaleString() : value}
            <span className="text-sm font-normal text-gray-500 ml-1">{unit}</span>
          </div>
          {trend && (
            <div className="flex items-center mt-2">
              <TrendingUp className={`h-3 w-3 mr-1 ${trend > 0 ? 'text-green-500' : 'text-red-500'}`} />
              <span className={`text-xs ${trend > 0 ? 'text-green-500' : 'text-red-500'}`}>
                {trend > 0 ? '+' : ''}{trend}% from yesterday
              </span>
            </div>
          )}
          {description && (
            <p className="text-xs text-gray-500 mt-1">{description}</p>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );

  // Loading state
  if (loading || !dashboardMetrics) {
    return (
      <div 
        className="min-h-screen flex items-center justify-center"
        style={{ background: getGradient('lightBg') }}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.5 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center"
          >
            <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
              <div className="w-4 h-4 bg-gradient-to-r from-green-500 to-blue-500 rounded-full" />
            </div>
          </motion.div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
            Loading Dashboard
          </h2>
          <p className="text-gray-600 mt-2">Fetching real-time solar data...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div 
      className="min-h-screen p-6 relative"
      style={{ background: getGradient('lightBg') }}
    >
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-8"
      >
        <Card 
          className="border-0 shadow-lg"
          style={{
            ...getGlassStyle('light'),
            background: 'rgba(255, 255, 255, 0.95)',
          }}
        >
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <div 
                  className="w-12 h-12 rounded-full flex items-center justify-center"
                  style={{
                    background: getGradient('energyFlow'),
                    boxShadow: nexusTheme.shadows.glow.primary
                  }}
                >
                  <Sun className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h1 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                    {organization.name} Dashboard
                  </h1>
                  <p className="text-gray-600">
                    Welcome back, {user.first_name}! • {currentTime.toLocaleString()}
                  </p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3">
                <CurrencySelector />
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleRefresh}
                  disabled={isRefreshing}
                  className="border-green-200 hover:border-green-300"
                >
                  <RefreshCw className={`w-4 h-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
                  Refresh
                </Button>
                <Button variant="outline" size="sm">
                  <Download className="w-4 h-4 mr-2" />
                  Export
                </Button>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={onNavigateToSites}
                >
                  <MapPin className="w-4 h-4 mr-2" />
                  Sites
                </Button>
                {(user.role === 'ADMIN' || user.role === 'MANAGER') && (
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={onNavigateToUsers}
                  >
                    <Users className="w-4 h-4 mr-2" />
                    Users
                  </Button>
                )}
                <Button variant="outline" size="sm">
                  <Settings className="w-4 h-4 mr-2" />
                  Settings
                </Button>
                <div className="relative">
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={onNavigateToAlerts}
                  >
                    <Bell className="w-4 h-4" />
                  </Button>
                  {dashboardMetrics.totalAlerts > 0 && (
                    <Badge 
                      className="absolute -top-2 -right-2 w-5 h-5 p-0 flex items-center justify-center text-xs"
                      style={{ background: nexusTheme.colors.error }}
                    >
                      {dashboardMetrics.totalAlerts}
                    </Badge>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </motion.div>

      {/* Key Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <MetricCard
          title="Total Generation Today"
          value={dashboardMetrics.totalGeneration / 1000}
          unit="MWh"
          icon={Sun}
          trend={8.2}
          color={nexusTheme.colors.accent[500]}
          gradient={getGradient('solarSunrise')}
          description="Peak: 2.4 MW at 12:30 PM"
        />
        <MetricCard
          title="Revenue Today"
          value={formatAmount(dashboardMetrics.totalRevenue, { compact: true })}
          unit=""
          icon={DollarSign}
          trend={12.5}
          color={nexusTheme.colors.primary[500]}
          gradient={getGradient('success')}
          description="Feed-in tariff: 0.12/kWh"
        />
        <MetricCard
          title="System Performance"
          value={dashboardMetrics.avgPerformance.toFixed(1)}
          unit="%"
          icon={Gauge}
          trend={-2.1}
          color={nexusTheme.colors.secondary[500]}
          gradient={getGradient('info')}
          description="Target: 95% efficiency"
        />
        <MetricCard
          title="CO₂ Saved"
          value={(dashboardMetrics.totalCO2Saved / 1000).toFixed(1)}
          unit="tons"
          icon={Leaf}
          trend={15.3}
          color={nexusTheme.colors.success}
          gradient={getGradient('energyFlow')}
          description="Equivalent to 2,450 trees"
        />
      </div>

      {/* Secondary Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        <MetricCard
          title="Active Sites"
          value={dashboardMetrics.activeSites}
          unit={`of ${dashboardMetrics.totalSites}`}
          icon={Building}
          color={nexusTheme.colors.primary[500]}
          gradient={getGradient('energyFlow')}
        />
        <MetricCard
          title="Grid Export"
          value={(dashboardMetrics.gridExport / 1000).toFixed(1)}
          unit="MWh"
          icon={Zap}
          color={nexusTheme.colors.secondary[500]}
          gradient={getGradient('info')}
        />
        <MetricCard
          title="System Efficiency"
          value={dashboardMetrics.systemEfficiency.toFixed(1)}
          unit="%"
          icon={Target}
          color={nexusTheme.colors.accent[500]}
          gradient={getGradient('warning')}
        />
        <MetricCard
          title="Weather"
          value="Sunny"
          unit="25°C"
          icon={Thermometer}
          color={nexusTheme.colors.accent[600]}
          gradient={getGradient('solarSunrise')}
        />
        <MetricCard
          title="Alerts"
          value={dashboardMetrics.totalAlerts}
          unit="active"
          icon={AlertTriangle}
          color={nexusTheme.colors.error}
          gradient={getGradient('error')}
        />
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Energy Generation Chart */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.2 }}
        >
          <Card 
            className="border-0 shadow-lg"
            style={{
              ...getGlassStyle('light'),
              background: 'rgba(255, 255, 255, 0.95)',
            }}
          >
            <CardHeader>
              <CardTitle className="flex items-center">
                <Activity className="w-5 h-5 mr-2 text-green-500" />
                Real-time Energy Flow
              </CardTitle>
              <CardDescription>Generation, consumption, and export over 24 hours</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={energyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="hour" stroke="#6b7280" />
                  <YAxis stroke="#6b7280" />
                  <Tooltip 
                    contentStyle={{
                      backgroundColor: 'rgba(255, 255, 255, 0.95)',
                      border: 'none',
                      borderRadius: '8px',
                      boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                    }}
                  />
                  <Legend />
                  <Area 
                    type="monotone" 
                    dataKey="generation" 
                    stackId="1" 
                    stroke="#f97316" 
                    fill="#f97316" 
                    fillOpacity={0.6}
                    name="Generation (kW)"
                  />
                  <Area 
                    type="monotone" 
                    dataKey="consumption" 
                    stackId="2" 
                    stroke="#3b82f6" 
                    fill="#3b82f6" 
                    fillOpacity={0.6}
                    name="Consumption (kW)"
                  />
                  <Area 
                    type="monotone" 
                    dataKey="export" 
                    stackId="3" 
                    stroke="#22c55e" 
                    fill="#22c55e" 
                    fillOpacity={0.6}
                    name="Grid Export (kW)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </motion.div>

        {/* Performance Chart */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3 }}
        >
          <Card 
            className="border-0 shadow-lg"
            style={{
              ...getGlassStyle('light'),
              background: 'rgba(255, 255, 255, 0.95)',
            }}
          >
            <CardHeader>
              <CardTitle className="flex items-center">
                <BarChart3 className="w-5 h-5 mr-2 text-blue-500" />
                Weekly Performance
              </CardTitle>
              <CardDescription>System performance vs target across the week</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="day" stroke="#6b7280" />
                  <YAxis stroke="#6b7280" />
                  <Tooltip 
                    contentStyle={{
                      backgroundColor: 'rgba(255, 255, 255, 0.95)',
                      border: 'none',
                      borderRadius: '8px',
                      boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                    }}
                  />
                  <Legend />
                  <Bar dataKey="performance" fill="#3b82f6" name="Actual Performance (%)" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="target" fill="#e5e7eb" name="Target (%)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Site Distribution and Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Site Status Distribution */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <Card 
            className="border-0 shadow-lg"
            style={{
              ...getGlassStyle('light'),
              background: 'rgba(255, 255, 255, 0.95)',
            }}
          >
            <CardHeader>
              <CardTitle className="flex items-center">
                <MapPin className="w-5 h-5 mr-2 text-green-500" />
                Site Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={siteDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={40}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {siteDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
              <div className="mt-4 space-y-2">
                {siteDistribution.map((item, index) => (
                  <div key={index} className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div 
                        className="w-3 h-3 rounded-full mr-2"
                        style={{ backgroundColor: item.color }}
                      />
                      <span className="text-sm text-gray-600">{item.name}</span>
                    </div>
                    <span className="text-sm font-medium">{item.value}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Recent Alerts */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="lg:col-span-2"
        >
          <Card 
            className="border-0 shadow-lg"
            style={{
              ...getGlassStyle('light'),
              background: 'rgba(255, 255, 255, 0.95)',
            }}
          >
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <div className="flex items-center">
                  <AlertTriangle className="w-5 h-5 mr-2 text-orange-500" />
                  Recent Alerts
                </div>
                <Button variant="outline" size="sm">
                  <Eye className="w-4 h-4 mr-2" />
                  View All
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[
                  {
                    id: 1,
                    type: 'performance',
                    severity: 'medium',
                    title: 'Performance Below Expected',
                    description: 'Johannesburg site performance is 5% below expected due to cloudy conditions',
                    time: '2 hours ago',
                    site: 'Johannesburg Manufacturing Plant'
                  },
                  {
                    id: 2,
                    type: 'maintenance',
                    severity: 'low',
                    title: 'Scheduled Maintenance Due',
                    description: 'Panel cleaning recommended for optimal performance',
                    time: '1 day ago',
                    site: 'Cape Town Corporate Campus'
                  },
                  {
                    id: 3,
                    type: 'weather',
                    severity: 'low',
                    title: 'Weather Advisory',
                    description: 'Cloudy conditions expected for next 2 days',
                    time: '3 hours ago',
                    site: 'All Sites'
                  }
                ].map((alert) => (
                  <div key={alert.id} className="flex items-start space-x-3 p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors">
                    <div className={`w-2 h-2 rounded-full mt-2 ${
                      alert.severity === 'high' ? 'bg-red-500' :
                      alert.severity === 'medium' ? 'bg-orange-500' : 'bg-yellow-500'
                    }`} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="text-sm font-medium text-gray-900">{alert.title}</h4>
                        <Badge 
                          variant="outline" 
                          className={`text-xs ${
                            alert.severity === 'high' ? 'border-red-200 text-red-700' :
                            alert.severity === 'medium' ? 'border-orange-200 text-orange-700' : 'border-yellow-200 text-yellow-700'
                          }`}
                        >
                          {alert.severity}
                        </Badge>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">{alert.description}</p>
                      <div className="flex items-center justify-between mt-2">
                        <span className="text-xs text-gray-500">{alert.site}</span>
                        <span className="text-xs text-gray-500">{alert.time}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
};

export default AdvancedDashboard;