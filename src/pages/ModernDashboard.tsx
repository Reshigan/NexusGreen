import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Progress } from "@/components/ui/progress";
import { 
  Sun, 
  Zap,
  TrendingUp,
  AlertTriangle,
  DollarSign,
  Battery,
  Leaf,
  MapPin,
  Calendar,
  Download,
  Activity,
  BarChart3,
  Settings,
  Bell,
  RefreshCw,
  Eye,
  Gauge,
  Lightbulb,
  Shield,
  Wifi,
  WifiOff,
  ChevronRight,
  ArrowUp,
  ArrowDown,
  Clock,
  Users,
  Building,
  Wrench
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import PlantOverviewChart from "@/components/PlantOverviewChart";
import PlantListView from "@/components/PlantListView";
import TimeFilter from "@/components/TimeFilter";
import PlantsMap from "@/components/PlantsMap";
import { smartDataService, type DashboardMetrics, type SiteData } from "@/services/api";

// Animation variants
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2
    }
  }
};

const itemVariants = {
  hidden: { y: 20, opacity: 0 },
  visible: {
    y: 0,
    opacity: 1,
    transition: {
      type: "spring",
      stiffness: 100,
      damping: 10
    }
  }
};

const pulseVariants = {
  pulse: {
    scale: [1, 1.05, 1],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: "easeInOut"
    }
  }
};

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  icon: React.ReactNode;
  color: string;
  isLoading?: boolean;
  trend?: "up" | "down" | "neutral";
}

const MetricCard = ({ title, value, change, changeLabel, icon, color, isLoading, trend }: MetricCardProps) => (
  <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
    <Card className="relative overflow-hidden border-0 shadow-lg bg-gradient-to-br from-white to-gray-50/50 hover:shadow-xl transition-all duration-300">
      <div className={`absolute top-0 left-0 w-full h-1 bg-gradient-to-r ${color}`} />
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-gray-600">{title}</CardTitle>
        <div className={`p-2 rounded-lg bg-gradient-to-br ${color} text-white shadow-sm`}>
          {icon}
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-between">
          <div>
            {isLoading ? (
              <div className="h-8 w-24 bg-gray-200 rounded animate-pulse" />
            ) : (
              <div className="text-2xl font-bold text-gray-900">{value}</div>
            )}
            {change !== undefined && (
              <div className="flex items-center mt-1">
                {trend === "up" && <ArrowUp className="h-3 w-3 text-green-500 mr-1" />}
                {trend === "down" && <ArrowDown className="h-3 w-3 text-red-500 mr-1" />}
                <p className={`text-xs ${
                  trend === "up" ? "text-green-600" : 
                  trend === "down" ? "text-red-600" : 
                  "text-gray-600"
                }`}>
                  {change > 0 ? "+" : ""}{change}% {changeLabel}
                </p>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  </motion.div>
);

interface AlertCardProps {
  alert: {
    id: string;
    type: string;
    severity: "low" | "medium" | "high";
    title: string;
    message: string;
    time: string;
    isResolved: boolean;
  };
}

const AlertCard = ({ alert }: AlertCardProps) => {
  const severityColors = {
    low: "from-blue-500 to-blue-600",
    medium: "from-yellow-500 to-orange-500",
    high: "from-red-500 to-red-600"
  };

  const severityBg = {
    low: "bg-blue-50 border-blue-200",
    medium: "bg-yellow-50 border-yellow-200",
    high: "bg-red-50 border-red-200"
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      className={`p-4 rounded-lg border ${severityBg[alert.severity]} hover:shadow-md transition-all duration-200`}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-start space-x-3">
          <div className={`p-1 rounded-full bg-gradient-to-r ${severityColors[alert.severity]} text-white`}>
            <AlertTriangle className="h-3 w-3" />
          </div>
          <div className="flex-1">
            <h4 className="text-sm font-medium text-gray-900">{alert.title}</h4>
            <p className="text-xs text-gray-600 mt-1">{alert.message}</p>
            <div className="flex items-center mt-2 space-x-2">
              <Clock className="h-3 w-3 text-gray-400" />
              <span className="text-xs text-gray-500">{alert.time}</span>
              {alert.isResolved && (
                <Badge variant="outline" className="text-xs bg-green-50 text-green-700 border-green-200">
                  Resolved
                </Badge>
              )}
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const ModernDashboard = () => {
  const [selectedView, setSelectedView] = useState<"overview" | "sites" | "analytics">("overview");
  const [timeFilter, setTimeFilter] = useState({
    period: "today",
    startDate: new Date(new Date().setHours(0, 0, 0, 0)),
    endDate: new Date()
  });
  const [dashboardMetrics, setDashboardMetrics] = useState<DashboardMetrics | null>(null);
  const [sites, setSites] = useState<SiteData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [apiConnected, setApiConnected] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Mock data for demonstration
  const mockMetrics = {
    totalGeneration: 2847.6,
    activeSites: 10,
    totalCapacity: 28500.0,
    performance: 96.8,
    activeAlerts: 3,
    totalRevenue: 125680.50,
    co2Saved: 1247.8,
    batteryLevel: 85,
    lastUpdated: new Date().toISOString()
  };

  const mockAlerts = [
    {
      id: "1",
      type: "maintenance",
      severity: "medium" as const,
      title: "Scheduled Maintenance Due",
      message: "Bay Area Corporate Campus requires quarterly inspection",
      time: "2 hours ago",
      isResolved: false
    },
    {
      id: "2",
      type: "performance",
      severity: "high" as const,
      title: "Inverter Fault Detected",
      message: "LAX Cargo Terminal - String 3 inverter communication error",
      time: "6 hours ago",
      isResolved: false
    },
    {
      id: "3",
      type: "weather",
      severity: "low" as const,
      title: "Weather Advisory",
      message: "High winds expected in Phoenix area",
      time: "1 day ago",
      isResolved: true
    }
  ];

  const mockSites = [
    {
      id: "1",
      name: "Bay Area Corporate Campus",
      location: "Palo Alto, CA",
      capacity: 2500.0,
      currentGeneration: 2187.5,
      efficiency: 96.8,
      status: "optimal",
      alerts: 1,
      lastUpdate: "2 min ago"
    },
    {
      id: "2",
      name: "LAX Cargo Terminal Solar",
      location: "Los Angeles, CA",
      capacity: 4500.0,
      currentGeneration: 3825.0,
      efficiency: 92.3,
      status: "warning",
      alerts: 1,
      lastUpdate: "5 min ago"
    },
    {
      id: "3",
      name: "Phoenix Sky Harbor Solar Farm",
      location: "Phoenix, AZ",
      capacity: 5200.0,
      currentGeneration: 4888.0,
      efficiency: 98.1,
      status: "optimal",
      alerts: 0,
      lastUpdate: "1 min ago"
    }
  ];

  // Load dashboard data
  useEffect(() => {
    const loadDashboardData = async () => {
      setIsLoading(true);
      try {
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        setDashboardMetrics(mockMetrics);
        setSites(mockSites);
        setApiConnected(true);
        setLastUpdated(new Date());
      } catch (error) {
        console.error('Failed to load dashboard data:', error);
        setApiConnected(false);
      } finally {
        setIsLoading(false);
      }
    };

    loadDashboardData();

    // Set up real-time updates every 60 seconds
    const interval = setInterval(loadDashboardData, 60000);
    return () => clearInterval(interval);
  }, [timeFilter]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await new Promise(resolve => setTimeout(resolve, 1500));
    setLastUpdated(new Date());
    setIsRefreshing(false);
  };

  const formatNumber = (num: number, decimals: number = 1) => {
    return new Intl.NumberFormat('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals
    }).format(num);
  };

  const formatCurrency = (num: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(num);
  };

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50/30">
        {/* Header */}
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/80 backdrop-blur-sm border-b border-gray-200/50 sticky top-0 z-10"
        >
          <div className="px-6 py-4">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                  NexusGreen Dashboard
                </h1>
                <div className="flex items-center mt-1 space-x-4">
                  <div className="flex items-center space-x-2">
                    {apiConnected ? (
                      <Wifi className="h-4 w-4 text-green-500" />
                    ) : (
                      <WifiOff className="h-4 w-4 text-red-500" />
                    )}
                    <span className={`text-sm ${apiConnected ? 'text-green-600' : 'text-red-600'}`}>
                      {apiConnected ? 'Connected' : 'Offline'}
                    </span>
                  </div>
                  <div className="flex items-center space-x-2 text-gray-500">
                    <Clock className="h-4 w-4" />
                    <span className="text-sm">
                      Last updated: {lastUpdated.toLocaleTimeString()}
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <TimeFilter value={timeFilter} onChange={setTimeFilter} />
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleRefresh}
                  disabled={isRefreshing}
                  className="hover:bg-green-50 hover:border-green-300"
                >
                  <RefreshCw className={`h-4 w-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
                  Refresh
                </Button>
                <Button variant="outline" size="sm" className="hover:bg-blue-50 hover:border-blue-300">
                  <Download className="h-4 w-4 mr-2" />
                  Export
                </Button>
              </div>
            </div>
          </div>
        </motion.div>

        <div className="p-6">
          {/* Key Metrics */}
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8"
          >
            <MetricCard
              title="Total Generation Today"
              value={`${formatNumber(dashboardMetrics?.totalGeneration || 0)} kWh`}
              change={12.5}
              changeLabel="vs yesterday"
              trend="up"
              icon={<Sun className="h-5 w-5" />}
              color="from-yellow-500 to-orange-500"
              isLoading={isLoading}
            />
            <MetricCard
              title="Revenue Today"
              value={formatCurrency(dashboardMetrics?.totalRevenue || 0)}
              change={8.3}
              changeLabel="vs yesterday"
              trend="up"
              icon={<DollarSign className="h-5 w-5" />}
              color="from-green-500 to-emerald-500"
              isLoading={isLoading}
            />
            <MetricCard
              title="System Performance"
              value={`${formatNumber(dashboardMetrics?.performance || 0)}%`}
              change={-2.1}
              changeLabel="vs last week"
              trend="down"
              icon={<Gauge className="h-5 w-5" />}
              color="from-blue-500 to-cyan-500"
              isLoading={isLoading}
            />
            <MetricCard
              title="CO₂ Saved"
              value={`${formatNumber(dashboardMetrics?.co2Saved || 0)} kg`}
              change={15.7}
              changeLabel="this month"
              trend="up"
              icon={<Leaf className="h-5 w-5" />}
              color="from-green-600 to-teal-600"
              isLoading={isLoading}
            />
          </motion.div>

          {/* Main Content */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Left Column - Charts and Analytics */}
            <div className="lg:col-span-2 space-y-6">
              {/* Performance Chart */}
              <motion.div variants={itemVariants}>
                <Card className="border-0 shadow-lg bg-white/80 backdrop-blur-sm">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle className="text-lg font-semibold text-gray-900">
                          Energy Generation Overview
                        </CardTitle>
                        <CardDescription>
                          Real-time performance across all installations
                        </CardDescription>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                          Live Data
                        </Badge>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <PlantOverviewChart />
                  </CardContent>
                </Card>
              </motion.div>

              {/* Sites Overview */}
              <motion.div variants={itemVariants}>
                <Card className="border-0 shadow-lg bg-white/80 backdrop-blur-sm">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle className="text-lg font-semibold text-gray-900">
                          Installation Status
                        </CardTitle>
                        <CardDescription>
                          Current status of all solar installations
                        </CardDescription>
                      </div>
                      <Button variant="ghost" size="sm" className="text-blue-600 hover:text-blue-700">
                        View All <ChevronRight className="h-4 w-4 ml-1" />
                      </Button>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {mockSites.map((site, index) => (
                        <motion.div
                          key={site.id}
                          initial={{ opacity: 0, x: -20 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: index * 0.1 }}
                          className="flex items-center justify-between p-4 rounded-lg bg-gray-50/50 hover:bg-gray-100/50 transition-colors duration-200"
                        >
                          <div className="flex items-center space-x-4">
                            <div className={`w-3 h-3 rounded-full ${
                              site.status === 'optimal' ? 'bg-green-500' :
                              site.status === 'warning' ? 'bg-yellow-500' :
                              'bg-red-500'
                            }`} />
                            <div>
                              <h4 className="font-medium text-gray-900">{site.name}</h4>
                              <div className="flex items-center space-x-4 text-sm text-gray-600">
                                <span className="flex items-center">
                                  <MapPin className="h-3 w-3 mr-1" />
                                  {site.location}
                                </span>
                                <span className="flex items-center">
                                  <Zap className="h-3 w-3 mr-1" />
                                  {formatNumber(site.currentGeneration)} / {formatNumber(site.capacity)} kW
                                </span>
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-lg font-semibold text-gray-900">
                              {formatNumber(site.efficiency)}%
                            </div>
                            <div className="text-sm text-gray-500">{site.lastUpdate}</div>
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </div>

            {/* Right Column - Alerts and Quick Stats */}
            <div className="space-y-6">
              {/* Quick Stats */}
              <motion.div variants={itemVariants}>
                <Card className="border-0 shadow-lg bg-white/80 backdrop-blur-sm">
                  <CardHeader>
                    <CardTitle className="text-lg font-semibold text-gray-900">
                      Quick Stats
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <Building className="h-5 w-5 text-blue-500" />
                        <span className="text-sm text-gray-600">Active Sites</span>
                      </div>
                      <span className="text-lg font-semibold text-gray-900">
                        {dashboardMetrics?.activeSites || 0}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <Zap className="h-5 w-5 text-yellow-500" />
                        <span className="text-sm text-gray-600">Total Capacity</span>
                      </div>
                      <span className="text-lg font-semibold text-gray-900">
                        {formatNumber(dashboardMetrics?.totalCapacity || 0)} kW
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <Battery className="h-5 w-5 text-green-500" />
                        <span className="text-sm text-gray-600">Battery Level</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Progress value={dashboardMetrics?.batteryLevel || 0} className="w-16" />
                        <span className="text-lg font-semibold text-gray-900">
                          {dashboardMetrics?.batteryLevel || 0}%
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <AlertTriangle className="h-5 w-5 text-red-500" />
                        <span className="text-sm text-gray-600">Active Alerts</span>
                      </div>
                      <Badge variant={dashboardMetrics?.activeAlerts ? "destructive" : "secondary"}>
                        {dashboardMetrics?.activeAlerts || 0}
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>

              {/* Alerts */}
              <motion.div variants={itemVariants}>
                <Card className="border-0 shadow-lg bg-white/80 backdrop-blur-sm">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-lg font-semibold text-gray-900">
                        System Alerts
                      </CardTitle>
                      <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">
                        {mockAlerts.filter(a => !a.isResolved).length} Active
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <AnimatePresence>
                        {mockAlerts.map((alert) => (
                          <AlertCard key={alert.id} alert={alert} />
                        ))}
                      </AnimatePresence>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>

              {/* Weather & Environmental */}
              <motion.div variants={itemVariants}>
                <Card className="border-0 shadow-lg bg-gradient-to-br from-blue-50 to-cyan-50">
                  <CardHeader>
                    <CardTitle className="text-lg font-semibold text-gray-900">
                      Environmental Conditions
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <Sun className="h-5 w-5 text-yellow-500" />
                          <span className="text-sm text-gray-600">Solar Irradiance</span>
                        </div>
                        <span className="text-lg font-semibold text-gray-900">
                          850 W/m²
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <Activity className="h-5 w-5 text-blue-500" />
                          <span className="text-sm text-gray-600">Temperature</span>
                        </div>
                        <span className="text-lg font-semibold text-gray-900">
                          28°C
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <Shield className="h-5 w-5 text-green-500" />
                          <span className="text-sm text-gray-600">Weather</span>
                        </div>
                        <Badge className="bg-green-100 text-green-800 border-green-200">
                          Sunny
                        </Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default ModernDashboard;