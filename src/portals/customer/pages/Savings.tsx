import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { 
  DollarSign, 
  TrendingUp, 
  TrendingDown,
  Zap, 
  Home,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Download,
  Calculator,
  PieChart,
  BarChart3,
  Lightbulb,
  Leaf
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart as RechartsPieChart, Pie, Cell, ComposedChart } from 'recharts';
import { useCurrency } from '../../../contexts/CurrencyContext';

// Mock data - replace with actual API calls
const mockSavingsData = [
  { 
    month: 'Jan', 
    ppaRate: 0.85, 
    municipalRate: 1.85, 
    energyUsed: 12400, 
    ppaCost: 10540, 
    municipalCost: 22940, 
    savings: 12400,
    selfConsumption: 8500,
    gridExport: 3900,
    gridImport: 2800
  },
  { 
    month: 'Feb', 
    ppaRate: 0.86, 
    municipalRate: 1.87, 
    energyUsed: 13100, 
    ppaCost: 11266, 
    municipalCost: 24497, 
    savings: 13231,
    selfConsumption: 9200,
    gridExport: 3900,
    gridImport: 2600
  },
  { 
    month: 'Mar', 
    ppaRate: 0.87, 
    municipalRate: 1.89, 
    energyUsed: 15600, 
    ppaCost: 13572, 
    municipalCost: 29484, 
    savings: 15912,
    selfConsumption: 11800,
    gridExport: 3800,
    gridImport: 2400
  },
  { 
    month: 'Apr', 
    ppaRate: 0.88, 
    municipalRate: 1.91, 
    energyUsed: 14200, 
    ppaCost: 12496, 
    municipalCost: 27122, 
    savings: 14626,
    selfConsumption: 10500,
    gridExport: 3700,
    gridImport: 2500
  },
  { 
    month: 'May', 
    ppaRate: 0.89, 
    municipalRate: 1.93, 
    energyUsed: 16200, 
    ppaCost: 14418, 
    municipalCost: 31266, 
    savings: 16848,
    selfConsumption: 12450,
    gridExport: 3750,
    gridImport: 2300
  },
  { 
    month: 'Jun', 
    ppaRate: 0.90, 
    municipalRate: 1.95, 
    energyUsed: 15800, 
    ppaCost: 14220, 
    municipalCost: 30810, 
    savings: 16590,
    selfConsumption: 11900,
    gridExport: 3900,
    gridImport: 2400
  }
];

const mockBillComparison = [
  { 
    month: 'Jan', 
    withoutSolar: 28500, 
    withSolar: 16100, 
    savings: 12400,
    savingsPercent: 43.5
  },
  { 
    month: 'Feb', 
    withoutSolar: 30200, 
    withSolar: 16969, 
    savings: 13231,
    savingsPercent: 43.8
  },
  { 
    month: 'Mar', 
    withoutSolar: 35800, 
    withSolar: 19888, 
    savings: 15912,
    savingsPercent: 44.5
  },
  { 
    month: 'Apr', 
    withoutSolar: 32400, 
    withSolar: 17774, 
    savings: 14626,
    savingsPercent: 45.1
  },
  { 
    month: 'May', 
    withoutSolar: 38200, 
    withSolar: 21352, 
    savings: 16848,
    savingsPercent: 44.1
  },
  { 
    month: 'Jun', 
    withoutSolar: 37100, 
    withSolar: 20510, 
    savings: 16590,
    savingsPercent: 44.7
  }
];

const mockEnergyBreakdown = [
  { name: 'Self Consumption', value: 65, amount: 11900, color: '#10b981' },
  { name: 'Grid Export', value: 25, amount: 3900, color: '#3b82f6' },
  { name: 'Grid Import', value: 10, amount: 2400, color: '#f59e0b' }
];

const mockSiteBreakdown = [
  { 
    siteName: 'Main Office Building',
    capacity: 850,
    monthlySavings: 4200,
    monthlyGeneration: 5800,
    efficiency: 94.2,
    savingsPercent: 42.1
  },
  { 
    siteName: 'Manufacturing Plant',
    capacity: 1200,
    monthlySavings: 6800,
    monthlyGeneration: 8900,
    efficiency: 96.8,
    savingsPercent: 45.8
  },
  { 
    siteName: 'Warehouse Facility',
    capacity: 450,
    monthlySavings: 1450,
    monthlyGeneration: 2100,
    efficiency: 88.5,
    savingsPercent: 38.2
  }
];

const CustomerSavings: React.FC = () => {
  const [timeRange, setTimeRange] = useState('6m');
  const [viewType, setViewType] = useState('savings');
  const { formatAmount } = useCurrency();

  const totalSavings = mockSavingsData.reduce((sum, month) => sum + month.savings, 0);
  const averageSavingsPercent = mockBillComparison.reduce((sum, month) => sum + month.savingsPercent, 0) / mockBillComparison.length;
  const totalEnergyGenerated = mockSavingsData.reduce((sum, month) => sum + month.energyUsed, 0);
  const totalCO2Avoided = (totalEnergyGenerated * 0.8) / 1000; // Rough calculation

  const formatEnergy = (kwh: number) => {
    if (kwh >= 1000) {
      return `${(kwh / 1000).toFixed(1)} MWh`;
    }
    return `${kwh} kWh`;
  };

  const formatRate = (rate: number) => {
    return `${formatAmount(rate)}/kWh`;
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Savings Analysis
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Detailed breakdown of your solar energy savings and benefits
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
            <Select value={viewType} onValueChange={setViewType}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="savings">Savings View</SelectItem>
                <SelectItem value="energy">Energy View</SelectItem>
                <SelectItem value="rates">Rate Comparison</SelectItem>
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Savings</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatAmount(totalSavings)}
                </p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  {averageSavingsPercent.toFixed(1)}% average
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Energy Generated</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {formatEnergy(totalEnergyGenerated)}
                </p>
                <p className="text-sm text-blue-600 flex items-center mt-1">
                  <Zap className="h-3 w-3 mr-1" />
                  Clean energy
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <Zap className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">CO₂ Avoided</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {totalCO2Avoided.toFixed(1)}t
                </p>
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

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Avg. Savings Rate</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {averageSavingsPercent.toFixed(1)}%
                </p>
                <p className="text-sm text-green-600 flex items-center mt-1">
                  <Calculator className="h-3 w-3 mr-1" />
                  vs municipal rate
                </p>
              </div>
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
                <Calculator className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Savings Trend */}
        <Card>
          <CardHeader>
            <CardTitle>Monthly Savings Trend</CardTitle>
            <CardDescription>PPA vs Municipal rate savings over time</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <ComposedChart data={mockSavingsData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis yAxisId="left" />
                <YAxis yAxisId="right" orientation="right" />
                <Tooltip formatter={(value, name) => {
                  if (name === 'savings' || name === 'ppaCost' || name === 'municipalCost') {
                    return [formatAmount(value as number), name];
                  }
                  return [value, name];
                }} />
                <Bar yAxisId="left" dataKey="municipalCost" fill="#ef4444" fillOpacity={0.6} name="Municipal Cost" />
                <Bar yAxisId="left" dataKey="ppaCost" fill="#3b82f6" fillOpacity={0.8} name="PPA Cost" />
                <Line yAxisId="right" type="monotone" dataKey="savings" stroke="#10b981" strokeWidth={3} name="Savings" />
              </ComposedChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Energy Usage Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Energy Usage Pattern</CardTitle>
            <CardDescription>How your solar energy is utilized</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <RechartsPieChart>
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
                <Tooltip formatter={(value, name) => [`${value}%`, name]} />
              </RechartsPieChart>
            </ResponsiveContainer>
            <div className="mt-4 space-y-2">
              {mockEnergyBreakdown.map((item, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }} />
                    <span className="text-sm text-slate-600 dark:text-slate-400">{item.name}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-medium">{item.value}%</span>
                    <span className="text-xs text-slate-500 ml-2">({formatEnergy(item.amount)})</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Rate Comparison */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Rate Comparison Analysis</CardTitle>
          <CardDescription>PPA rates vs municipal electricity rates over time</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={mockSavingsData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value, name) => {
                if (name === 'ppaRate' || name === 'municipalRate') {
                  return [formatRate(value as number), name];
                }
                return [value, name];
              }} />
              <Line type="monotone" dataKey="municipalRate" stroke="#ef4444" strokeWidth={2} name="Municipal Rate" />
              <Line type="monotone" dataKey="ppaRate" stroke="#10b981" strokeWidth={2} name="PPA Rate" />
            </LineChart>
          </ResponsiveContainer>
          <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <p className="text-sm text-green-600 dark:text-green-400">Current PPA Rate</p>
              <p className="text-2xl font-bold text-green-700 dark:text-green-300">
                {formatRate(mockSavingsData[mockSavingsData.length - 1].ppaRate)}
              </p>
            </div>
            <div className="text-center p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
              <p className="text-sm text-red-600 dark:text-red-400">Current Municipal Rate</p>
              <p className="text-2xl font-bold text-red-700 dark:text-red-300">
                {formatRate(mockSavingsData[mockSavingsData.length - 1].municipalRate)}
              </p>
            </div>
            <div className="text-center p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <p className="text-sm text-blue-600 dark:text-blue-400">Rate Difference</p>
              <p className="text-2xl font-bold text-blue-700 dark:text-blue-300">
                {formatRate(mockSavingsData[mockSavingsData.length - 1].municipalRate - mockSavingsData[mockSavingsData.length - 1].ppaRate)}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Site Breakdown */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Savings by Site</CardTitle>
          <CardDescription>Individual site performance and savings contribution</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {mockSiteBreakdown.map((site, index) => (
              <Card key={index} className="border-l-4 border-l-blue-500">
                <CardHeader className="pb-3">
                  <CardTitle className="text-lg">{site.siteName}</CardTitle>
                  <CardDescription>{site.capacity} kW capacity</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-slate-500">Monthly Savings</p>
                      <p className="text-lg font-bold text-green-600">
                        {formatAmount(site.monthlySavings)}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Generation</p>
                      <p className="text-lg font-bold text-blue-600">
                        {formatEnergy(site.monthlyGeneration)}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Efficiency</p>
                      <p className="text-sm font-medium">{site.efficiency}%</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Savings Rate</p>
                      <p className="text-sm font-medium text-green-600">{site.savingsPercent}%</p>
                    </div>
                  </div>
                  <div className="pt-2 border-t border-slate-200 dark:border-slate-700">
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-slate-500">Contribution to total savings</span>
                      <span className="text-sm font-medium">
                        {((site.monthlySavings / mockSiteBreakdown.reduce((sum, s) => sum + s.monthlySavings, 0)) * 100).toFixed(1)}%
                      </span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Insights and Recommendations */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Lightbulb className="h-5 w-5 mr-2 text-yellow-500" />
            Insights & Recommendations
          </CardTitle>
          <CardDescription>AI-powered analysis of your solar performance</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <div className="flex items-start space-x-3">
                  <TrendingUp className="h-5 w-5 text-green-600 mt-0.5" />
                  <div>
                    <h4 className="font-medium text-green-800 dark:text-green-300">Excellent Performance</h4>
                    <p className="text-sm text-green-700 dark:text-green-400 mt-1">
                      Your solar system is performing 8% above expected efficiency. The Manufacturing Plant site is your top performer with 96.8% efficiency.
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                <div className="flex items-start space-x-3">
                  <Calculator className="h-5 w-5 text-blue-600 mt-0.5" />
                  <div>
                    <h4 className="font-medium text-blue-800 dark:text-blue-300">Savings Optimization</h4>
                    <p className="text-sm text-blue-700 dark:text-blue-400 mt-1">
                      You're saving an average of 44.4% on electricity costs. Consider increasing self-consumption during peak hours to maximize savings.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div className="p-4 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800">
                <div className="flex items-start space-x-3">
                  <Home className="h-5 w-5 text-orange-600 mt-0.5" />
                  <div>
                    <h4 className="font-medium text-orange-800 dark:text-orange-300">Site Attention Needed</h4>
                    <p className="text-sm text-orange-700 dark:text-orange-400 mt-1">
                      The Warehouse Facility is underperforming at 88.5% efficiency. Schedule maintenance to optimize performance.
                    </p>
                  </div>
                </div>
              </div>

              <div className="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
                <div className="flex items-start space-x-3">
                  <Leaf className="h-5 w-5 text-purple-600 mt-0.5" />
                  <div>
                    <h4 className="font-medium text-purple-800 dark:text-purple-300">Environmental Impact</h4>
                    <p className="text-sm text-purple-700 dark:text-purple-400 mt-1">
                      You've avoided {totalCO2Avoided.toFixed(1)} tons of CO₂ emissions this period. That's equivalent to planting {Math.round(totalCO2Avoided * 16)} trees!
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default CustomerSavings;