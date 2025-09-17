import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { 
  DollarSign, 
  TrendingUp, 
  TrendingDown,
  PieChart, 
  Building2,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Download,
  Eye,
  AlertTriangle,
  CheckCircle,
  Clock,
  Target
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart as RechartsPieChart, Pie, Cell, ComposedChart } from 'recharts';
import { useCurrency } from '../../../contexts/CurrencyContext';

// Mock data - replace with actual API calls
const mockPortfolioData = [
  { 
    month: 'Jan', 
    totalInvestment: 42000000,
    totalRevenue: 3850000,
    roi: 11.2,
    activeProjects: 6,
    newInvestments: 2500000
  },
  { 
    month: 'Feb', 
    totalInvestment: 43200000,
    totalRevenue: 4120000,
    roi: 11.8,
    activeProjects: 7,
    newInvestments: 1200000
  },
  { 
    month: 'Mar', 
    totalInvestment: 45200000,
    totalRevenue: 4580000,
    roi: 12.4,
    activeProjects: 8,
    newInvestments: 2000000
  },
  { 
    month: 'Apr', 
    totalInvestment: 45200000,
    totalRevenue: 4720000,
    roi: 12.6,
    activeProjects: 8,
    newInvestments: 0
  },
  { 
    month: 'May', 
    totalInvestment: 45200000,
    totalRevenue: 4890000,
    roi: 12.8,
    activeProjects: 8,
    newInvestments: 0
  },
  { 
    month: 'Jun', 
    totalInvestment: 45200000,
    totalRevenue: 4950000,
    roi: 12.9,
    activeProjects: 8,
    newInvestments: 0
  }
];

const mockProjectBreakdown = [
  { name: 'Solar Farm Alpha', value: 35, investment: 15800000, roi: 13.2, color: '#10b981' },
  { name: 'Corporate Rooftop Initiative', value: 25, investment: 11300000, roi: 12.8, color: '#3b82f6' },
  { name: 'Community Solar Garden', value: 15, investment: 6800000, roi: 11.5, color: '#f59e0b' },
  { name: 'Industrial Complex Array', value: 15, investment: 6800000, roi: 13.8, color: '#8b5cf6' },
  { name: 'Other Projects', value: 10, investment: 4500000, roi: 10.2, color: '#6b7280' }
];

const mockInvestmentProjects = [
  {
    id: 1,
    name: 'Solar Farm Alpha',
    customer: 'ABC Manufacturing',
    investment: 15800000,
    capacity: 2500,
    roi: 13.2,
    monthlyRevenue: 1680000,
    status: 'ACTIVE',
    startDate: '2024-01-15',
    expectedPayback: 7.2,
    riskLevel: 'LOW',
    performance: 104.2
  },
  {
    id: 2,
    name: 'Corporate Rooftop Initiative',
    customer: 'XYZ Corporation',
    investment: 11300000,
    capacity: 1800,
    roi: 12.8,
    monthlyRevenue: 1205000,
    status: 'ACTIVE',
    startDate: '2024-03-01',
    expectedPayback: 7.8,
    riskLevel: 'LOW',
    performance: 98.7
  },
  {
    id: 3,
    name: 'Community Solar Garden',
    customer: 'Greenville Community',
    investment: 6800000,
    capacity: 800,
    roi: 11.5,
    monthlyRevenue: 650000,
    status: 'COMPLETED',
    startDate: '2023-09-01',
    expectedPayback: 8.7,
    riskLevel: 'MEDIUM',
    performance: 102.1
  },
  {
    id: 4,
    name: 'Industrial Complex Array',
    customer: 'Heavy Industries Ltd',
    investment: 6800000,
    capacity: 1200,
    roi: 13.8,
    monthlyRevenue: 780000,
    status: 'PLANNING',
    startDate: '2024-10-01',
    expectedPayback: 6.9,
    riskLevel: 'MEDIUM',
    performance: null
  }
];

const FunderDashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState('6m');
  const { formatAmount } = useCurrency();

  const currentData = mockPortfolioData[mockPortfolioData.length - 1];
  const previousData = mockPortfolioData[mockPortfolioData.length - 2];
  
  const roiChange = currentData.roi - previousData.roi;
  const revenueChange = ((currentData.totalRevenue - previousData.totalRevenue) / previousData.totalRevenue) * 100;

  const formatPower = (kw: number) => {
    if (kw >= 1000) {
      return `${(kw / 1000).toFixed(1)} MW`;
    }
    return `${kw} kW`;
  };

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'LOW': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'MEDIUM': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300';
      case 'HIGH': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'PLANNING': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
      case 'COMPLETED': return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getPerformanceColor = (performance: number | null) => {
    if (!performance) return 'text-slate-500';
    if (performance >= 100) return 'text-green-600';
    if (performance >= 95) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Investment Dashboard
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Monitor your solar energy investment portfolio performance
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <Select value={timeRange} onValueChange={setTimeRange}>
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="3m">Last 3 months</SelectItem>
                <SelectItem value="6m">Last 6 months</SelectItem>
                <SelectItem value="12m">Last 12 months</SelectItem>
                <SelectItem value="24m">Last 24 months</SelectItem>
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Investment</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatAmount(currentData.totalInvestment)}
                </p>
                <p className="text-sm text-blue-600 flex items-center mt-1">
                  <DollarSign className="h-3 w-3 mr-1" />
                  Across {currentData.activeProjects} projects
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <DollarSign className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Portfolio ROI</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {currentData.roi.toFixed(1)}%
                </p>
                <p className={`text-sm flex items-center mt-1 ${roiChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {roiChange >= 0 ? <ArrowUpRight className="h-3 w-3 mr-1" /> : <ArrowDownRight className="h-3 w-3 mr-1" />}
                  {Math.abs(roiChange).toFixed(1)}% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <TrendingUp className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Monthly Revenue</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatAmount(currentData.totalRevenue)}
                </p>
                <p className={`text-sm flex items-center mt-1 ${revenueChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {revenueChange >= 0 ? <ArrowUpRight className="h-3 w-3 mr-1" /> : <ArrowDownRight className="h-3 w-3 mr-1" />}
                  {Math.abs(revenueChange).toFixed(1)}% from last month
                </p>
              </div>
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
                <PieChart className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Active Projects</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {currentData.activeProjects}
                </p>
                <p className="text-sm text-blue-600 flex items-center mt-1">
                  <Building2 className="h-3 w-3 mr-1" />
                  6.3 MW total capacity
                </p>
              </div>
              <div className="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center">
                <Building2 className="h-6 w-6 text-orange-600 dark:text-orange-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* ROI Trend */}
        <Card>
          <CardHeader>
            <CardTitle>Portfolio Performance</CardTitle>
            <CardDescription>ROI and revenue trends over time</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <ComposedChart data={mockPortfolioData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis yAxisId="left" />
                <YAxis yAxisId="right" orientation="right" />
                <Tooltip formatter={(value, name) => {
                  if (name === 'totalRevenue') {
                    return [formatAmount(value as number), 'Revenue'];
                  }
                  if (name === 'roi') {
                    return [`${value}%`, 'ROI'];
                  }
                  return [value, name];
                }} />
                <Bar yAxisId="left" dataKey="totalRevenue" fill="#3b82f6" fillOpacity={0.6} name="Revenue" />
                <Line yAxisId="right" type="monotone" dataKey="roi" stroke="#10b981" strokeWidth={3} name="ROI %" />
              </ComposedChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Investment Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Investment Distribution</CardTitle>
            <CardDescription>Portfolio allocation by project</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <RechartsPieChart>
                <Pie
                  data={mockProjectBreakdown}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={120}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {mockProjectBreakdown.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(value, name) => [`${value}%`, name]} />
              </RechartsPieChart>
            </ResponsiveContainer>
            <div className="mt-4 space-y-2">
              {mockProjectBreakdown.map((item, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }} />
                    <span className="text-sm text-slate-600 dark:text-slate-400">{item.name}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-medium">{item.value}%</span>
                    <span className="text-xs text-slate-500 ml-2">({item.roi}% ROI)</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Investment Projects */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Investment Projects</CardTitle>
              <CardDescription>Detailed view of your funded projects</CardDescription>
            </div>
            <Button variant="outline">
              <Eye className="h-4 w-4 mr-2" />
              View All Projects
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700">
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Project</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Investment</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">ROI</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Revenue</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Performance</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Risk</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Status</th>
                </tr>
              </thead>
              <tbody>
                {mockInvestmentProjects.map((project) => (
                  <tr key={project.id} className="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td className="py-4 px-4">
                      <div>
                        <p className="font-medium text-slate-900 dark:text-slate-100">{project.name}</p>
                        <p className="text-sm text-slate-500">{project.customer}</p>
                        <p className="text-xs text-slate-500">{formatPower(project.capacity)} capacity</p>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div>
                        <p className="font-medium text-slate-900 dark:text-slate-100">
                          {formatAmount(project.investment)}
                        </p>
                        <p className="text-xs text-slate-500">
                          Payback: {project.expectedPayback} years
                        </p>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center">
                        <span className={`font-medium ${project.roi >= 12 ? 'text-green-600' : project.roi >= 10 ? 'text-yellow-600' : 'text-red-600'}`}>
                          {project.roi.toFixed(1)}%
                        </span>
                        {project.roi >= 12 && <TrendingUp className="h-3 w-3 ml-1 text-green-600" />}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <p className="font-medium text-slate-900 dark:text-slate-100">
                        {formatAmount(project.monthlyRevenue)}
                      </p>
                      <p className="text-xs text-slate-500">per month</p>
                    </td>
                    <td className="py-4 px-4">
                      {project.performance ? (
                        <div>
                          <p className={`font-medium ${getPerformanceColor(project.performance)}`}>
                            {project.performance.toFixed(1)}%
                          </p>
                          <p className="text-xs text-slate-500">vs expected</p>
                        </div>
                      ) : (
                        <span className="text-sm text-slate-500">Not started</span>
                      )}
                    </td>
                    <td className="py-4 px-4">
                      <Badge className={getRiskColor(project.riskLevel)}>
                        {project.riskLevel}
                      </Badge>
                    </td>
                    <td className="py-4 px-4">
                      <Badge className={getStatusColor(project.status)}>
                        {project.status}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Performance Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-8">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Target className="h-5 w-5 mr-2 text-green-500" />
              Performance Highlights
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
              <div className="flex items-start space-x-3">
                <CheckCircle className="h-5 w-5 text-green-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-green-800 dark:text-green-300">Exceeding ROI Target</h4>
                  <p className="text-sm text-green-700 dark:text-green-400 mt-1">
                    Portfolio ROI of 12.9% is above your target of 12.0%. Solar Farm Alpha is your top performer at 13.2% ROI.
                  </p>
                </div>
              </div>
            </div>
            
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
              <div className="flex items-start space-x-3">
                <TrendingUp className="h-5 w-5 text-blue-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-blue-800 dark:text-blue-300">Strong Revenue Growth</h4>
                  <p className="text-sm text-blue-700 dark:text-blue-400 mt-1">
                    Monthly revenue increased by {revenueChange.toFixed(1)}% to {formatAmount(currentData.totalRevenue)}. All active projects are generating positive returns.
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <AlertTriangle className="h-5 w-5 mr-2 text-orange-500" />
              Attention Required
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="p-4 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800">
              <div className="flex items-start space-x-3">
                <Clock className="h-5 w-5 text-orange-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-orange-800 dark:text-orange-300">Project Delays</h4>
                  <p className="text-sm text-orange-700 dark:text-orange-400 mt-1">
                    Industrial Complex Array project start date has been pushed to October 2024. Monitor for potential impact on projected returns.
                  </p>
                </div>
              </div>
            </div>
            
            <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
              <div className="flex items-start space-x-3">
                <TrendingDown className="h-5 w-5 text-yellow-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-yellow-800 dark:text-yellow-300">Performance Monitoring</h4>
                  <p className="text-sm text-yellow-700 dark:text-yellow-400 mt-1">
                    Corporate Rooftop Initiative is performing at 98.7% of expected output. Consider maintenance optimization.
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default FunderDashboard;