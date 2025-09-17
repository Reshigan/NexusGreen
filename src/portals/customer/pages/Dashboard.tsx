import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { 
  DollarSign, 
  TrendingUp, 
  TrendingDown,
  Zap, 
  Leaf, 
  MapPin,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Eye,
  Download,
  AlertCircle,
  CheckCircle
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useCurrency } from '../../../contexts/CurrencyContext';

// Mock data - replace with actual API calls
const mockSavingsData = [
  { month: 'Jan', savings: 8500, production: 12400, consumption: 15200, gridExport: 2800 },
  { month: 'Feb', savings: 9200, production: 13100, consumption: 14900, gridExport: 3200 },
  { month: 'Mar', savings: 11800, production: 15600, consumption: 16800, gridExport: 4200 },
  { month: 'Apr', savings: 10500, production: 14200, consumption: 15800, gridExport: 3600 },
  { month: 'May', savings: 12450, production: 16200, consumption: 17100, gridExport: 4800 },
  { month: 'Jun', savings: 11900, production: 15800, consumption: 16500, gridExport: 4300 }
];

const mockEnergyBreakdown = [
  { name: 'Self Consumption', value: 65, color: '#10b981' },
  { name: 'Grid Export', value: 25, color: '#3b82f6' },
  { name: 'Grid Import', value: 10, color: '#f59e0b' }
];

const mockSites = [
  {
    id: 1,
    name: 'Main Office Building',
    location: 'Johannesburg',
    capacity: 850,
    currentOutput: 425.5,
    todayYield: 3420,
    monthlyYield: 89500,
    savings: 4200,
    efficiency: 94.2,
    status: 'ACTIVE',
    lastUpdate: '2024-09-16T14:30:00Z'
  },
  {
    id: 2,
    name: 'Manufacturing Plant',
    location: 'Cape Town',
    capacity: 1200,
    currentOutput: 680.2,
    todayYield: 5240,
    monthlyYield: 142800,
    savings: 6800,
    efficiency: 96.8,
    status: 'ACTIVE',
    lastUpdate: '2024-09-16T14:28:00Z'
  },
  {
    id: 3,
    name: 'Warehouse Facility',
    location: 'Durban',
    capacity: 450,
    currentOutput: 0,
    todayYield: 0,
    monthlyYield: 45200,
    savings: 1450,
    efficiency: 0,
    status: 'MAINTENANCE',
    lastUpdate: '2024-09-16T08:00:00Z'
  }
];

const CustomerDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState('30d');
  const [totalSavings, setTotalSavings] = useState(12450);
  const [monthlySavings, setMonthlySavings] = useState(12450);
  const [yearlyProjection, setYearlyProjection] = useState(149400);
  const { formatAmount } = useCurrency();

  useEffect(() => {
    // Fetch customer dashboard data
    // This would be replaced with actual API calls
  }, [timeRange]);

  const formatPower = (kw: number) => {
    if (kw >= 1000) {
      return `${(kw / 1000).toFixed(1)} MW`;
    }
    return `${kw} kW`;
  };

  const formatEnergy = (kwh: number) => {
    if (kwh >= 1000) {
      return `${(kwh / 1000).toFixed(1)} MWh`;
    }
    return `${kwh} kWh`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'text-green-600';
      case 'MAINTENANCE': return 'text-orange-600';
      case 'OFFLINE': return 'text-red-600';
      default: return 'text-slate-600';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ACTIVE': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'MAINTENANCE': return <AlertCircle className="h-4 w-4 text-orange-500" />;
      case 'OFFLINE': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <AlertCircle className="h-4 w-4 text-slate-500" />;
    }
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Your Solar Dashboard
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Track your energy savings and system performance
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Monthly Savings</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatAmount(monthlySavings)}
                </p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +8.2% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <DollarSign className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Yearly Projection</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatAmount(yearlyProjection)}
                </p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  On track for target
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <TrendingUp className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Energy Generated</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">16.2 MWh</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <ArrowUpRight className="h-3 w-3 mr-1" />
                  +12% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center">
                <Zap className="h-6 w-6 text-orange-600 dark:text-orange-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">CO₂ Avoided</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">12.8t</p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <Leaf className="h-3 w-3 mr-1" />
                  Environmental impact
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <Leaf className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Savings Trend */}
        <Card>
          <CardHeader>
            <CardTitle>Savings Trend</CardTitle>
            <CardDescription>Monthly savings and energy production</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={mockSavingsData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip formatter={(value, name) => {
                  if (name === 'savings') return [formatAmount(value as number), 'Savings'];
                  return [formatEnergy(value as number), name];
                }} />
                <Area type="monotone" dataKey="savings" stackId="1" stroke="#10b981" fill="#10b981" fillOpacity={0.6} />
                <Area type="monotone" dataKey="production" stackId="2" stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.4} />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Energy Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Energy Usage Breakdown</CardTitle>
            <CardDescription>How your solar energy is utilized</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={mockEnergyBreakdown}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={120}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {mockEnergyBreakdown.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => [`${value}%`, 'Percentage']} />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-4 grid grid-cols-1 gap-2">
              {mockEnergyBreakdown.map((item, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }} />
                    <span className="text-sm text-slate-600 dark:text-slate-400">{item.name}</span>
                  </div>
                  <span className="text-sm font-medium">{item.value}%</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Sites Overview */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Your Solar Sites</CardTitle>
              <CardDescription>Real-time performance of your installations</CardDescription>
            </div>
            <Button variant="outline">
              <Eye className="h-4 w-4 mr-2" />
              View All Sites
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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
                    <div className="flex items-center space-x-1">
                      {getStatusIcon(site.status)}
                      <span className={`text-xs font-medium ${getStatusColor(site.status)}`}>
                        {site.status}
                      </span>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Current Performance */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-slate-500">Current Output</p>
                      <p className="text-sm font-medium">{formatPower(site.currentOutput)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Capacity</p>
                      <p className="text-sm font-medium">{formatPower(site.capacity)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Today's Yield</p>
                      <p className="text-sm font-medium">{formatEnergy(site.todayYield)}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Efficiency</p>
                      <p className="text-sm font-medium">{site.efficiency}%</p>
                    </div>
                  </div>

                  {/* Monthly Performance */}
                  <div className="pt-3 border-t border-slate-200 dark:border-slate-700">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xs text-slate-500">Monthly Savings</p>
                        <p className="text-lg font-bold text-green-600">
                          {formatAmount(site.savings)}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-slate-500">Monthly Yield</p>
                        <p className="text-sm font-medium">{formatEnergy(site.monthlyYield)}</p>
                      </div>
                    </div>
                  </div>

                  {/* Last Update */}
                  <div className="text-xs text-slate-500 flex items-center">
                    <Calendar className="h-3 w-3 mr-1" />
                    Last updated: {new Date(site.lastUpdate).toLocaleString()}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default CustomerDashboard;