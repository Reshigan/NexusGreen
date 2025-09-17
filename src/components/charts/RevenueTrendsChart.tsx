import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, LineChart, Line, ComposedChart } from "recharts";
import { DollarSign, TrendingUp, TrendingDown, Calendar, PieChart } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

// Generate revenue data for the last 12 months
const generateRevenueData = () => {
  const data = [];
  const now = new Date();
  
  for (let i = 11; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const month = date.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });
    
    // Simulate seasonal variations in solar revenue
    const seasonalMultiplier = 0.7 + 0.3 * Math.sin(((date.getMonth() + 3) / 12) * 2 * Math.PI);
    
    const energySales = Math.round((15000 + Math.random() * 5000) * seasonalMultiplier);
    const gridExport = Math.round((8000 + Math.random() * 3000) * seasonalMultiplier);
    const carbonCredits = Math.round(2000 + Math.random() * 1000);
    const maintenanceCosts = Math.round(3000 + Math.random() * 1000);
    const operationalCosts = Math.round(2000 + Math.random() * 500);
    
    const totalRevenue = energySales + gridExport + carbonCredits;
    const totalCosts = maintenanceCosts + operationalCosts;
    const netProfit = totalRevenue - totalCosts;
    
    data.push({
      month,
      energySales,
      gridExport,
      carbonCredits,
      totalRevenue,
      maintenanceCosts,
      operationalCosts,
      totalCosts,
      netProfit,
      profitMargin: Math.round((netProfit / totalRevenue) * 100)
    });
  }
  
  return data;
};

const chartConfig = {
  energySales: {
    label: "Energy Sales",
    color: "hsl(142, 76%, 36%)", // Green
  },
  gridExport: {
    label: "Grid Export",
    color: "hsl(217, 91%, 60%)", // Blue
  },
  carbonCredits: {
    label: "Carbon Credits",
    color: "hsl(45, 93%, 47%)", // Yellow
  },
  totalRevenue: {
    label: "Total Revenue",
    color: "hsl(142, 76%, 36%)", // Green
  },
  totalCosts: {
    label: "Total Costs",
    color: "hsl(0, 84%, 60%)", // Red
  },
  netProfit: {
    label: "Net Profit",
    color: "hsl(262, 83%, 58%)", // Purple
  },
  profitMargin: {
    label: "Profit Margin (%)",
    color: "hsl(39, 77%, 58%)", // Orange
  }
};

export default function RevenueTrendsChart() {
  const [data, setData] = useState(generateRevenueData());
  const [viewType, setViewType] = useState<'revenue' | 'profit' | 'breakdown'>('revenue');
  const [timeRange, setTimeRange] = useState<'6m' | '12m' | '24m'>('12m');
  
  useEffect(() => {
    // Regenerate data when time range changes
    setData(generateRevenueData());
  }, [timeRange]);
  
  const currentMonth = data[data.length - 1];
  const previousMonth = data[data.length - 2];
  
  const getChange = (current: number, previous: number) => {
    const change = ((current - previous) / previous) * 100;
    return {
      value: Math.abs(change).toFixed(1),
      isPositive: change > 0
    };
  };
  
  const revenueChange = getChange(currentMonth.totalRevenue, previousMonth.totalRevenue);
  const profitChange = getChange(currentMonth.netProfit, previousMonth.netProfit);
  const marginChange = getChange(currentMonth.profitMargin, previousMonth.profitMargin);
  
  // Calculate totals for the period
  const totalRevenue = data.reduce((sum, item) => sum + item.totalRevenue, 0);
  const totalProfit = data.reduce((sum, item) => sum + item.netProfit, 0);
  const avgMargin = Math.round(data.reduce((sum, item) => sum + item.profitMargin, 0) / data.length);
  
  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-green-800">Monthly Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-900">
              ${currentMonth.totalRevenue.toLocaleString()}
            </div>
            <div className="flex items-center text-xs text-green-700">
              {revenueChange.isPositive ? (
                <TrendingUp className="h-3 w-3 mr-1 text-green-600" />
              ) : (
                <TrendingDown className="h-3 w-3 mr-1 text-red-600" />
              )}
              <span className={revenueChange.isPositive ? 'text-green-600' : 'text-red-600'}>
                {revenueChange.value}% from last month
              </span>
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-purple-50 to-violet-50 border-purple-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-purple-800">Net Profit</CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-900">
              ${currentMonth.netProfit.toLocaleString()}
            </div>
            <div className="flex items-center text-xs text-purple-700">
              {profitChange.isPositive ? (
                <TrendingUp className="h-3 w-3 mr-1 text-green-600" />
              ) : (
                <TrendingDown className="h-3 w-3 mr-1 text-red-600" />
              )}
              <span className={profitChange.isPositive ? 'text-green-600' : 'text-red-600'}>
                {profitChange.value}% from last month
              </span>
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-orange-50 to-amber-50 border-orange-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-orange-800">Profit Margin</CardTitle>
            <PieChart className="h-4 w-4 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-900">{currentMonth.profitMargin}%</div>
            <div className="flex items-center text-xs text-orange-700">
              {marginChange.isPositive ? (
                <TrendingUp className="h-3 w-3 mr-1 text-green-600" />
              ) : (
                <TrendingDown className="h-3 w-3 mr-1 text-red-600" />
              )}
              <span className={marginChange.isPositive ? 'text-green-600' : 'text-red-600'}>
                {marginChange.value}% from last month
              </span>
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-blue-800">YTD Total</CardTitle>
            <Calendar className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-900">
              ${totalRevenue.toLocaleString()}
            </div>
            <div className="text-xs text-blue-700">
              Avg. Margin: {avgMargin}%
            </div>
          </CardContent>
        </Card>
      </div>
      
      {/* Controls */}
      <div className="flex items-center justify-between">
        <div className="flex gap-2">
          <Badge 
            variant={viewType === 'revenue' ? 'default' : 'outline'}
            className="cursor-pointer"
            onClick={() => setViewType('revenue')}
          >
            Revenue Streams
          </Badge>
          <Badge 
            variant={viewType === 'profit' ? 'default' : 'outline'}
            className="cursor-pointer"
            onClick={() => setViewType('profit')}
          >
            Profit Analysis
          </Badge>
          <Badge 
            variant={viewType === 'breakdown' ? 'default' : 'outline'}
            className="cursor-pointer"
            onClick={() => setViewType('breakdown')}
          >
            Cost Breakdown
          </Badge>
        </div>
        
        <div className="flex gap-2">
          <Button 
            variant={timeRange === '6m' ? 'default' : 'outline'} 
            size="sm"
            onClick={() => setTimeRange('6m')}
          >
            6M
          </Button>
          <Button 
            variant={timeRange === '12m' ? 'default' : 'outline'} 
            size="sm"
            onClick={() => setTimeRange('12m')}
          >
            12M
          </Button>
          <Button 
            variant={timeRange === '24m' ? 'default' : 'outline'} 
            size="sm"
            onClick={() => setTimeRange('24m')}
          >
            24M
          </Button>
        </div>
      </div>
      
      {/* Main Chart */}
      <Card>
        <CardHeader>
          <CardTitle>
            {viewType === 'revenue' && 'Revenue Streams Analysis'}
            {viewType === 'profit' && 'Profit & Margin Trends'}
            {viewType === 'breakdown' && 'Revenue vs Costs Breakdown'}
          </CardTitle>
          <CardDescription>
            {viewType === 'revenue' && 'Monthly breakdown of energy sales, grid export, and carbon credits'}
            {viewType === 'profit' && 'Net profit trends and profit margin analysis over time'}
            {viewType === 'breakdown' && 'Comprehensive view of revenue streams and operational costs'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ChartContainer config={chartConfig} className="h-[400px]">
            {viewType === 'revenue' && (
              <BarChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Revenue ($)', angle: -90, position: 'insideLeft' }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="energySales" stackId="revenue" fill="var(--color-energySales)" />
                <Bar dataKey="gridExport" stackId="revenue" fill="var(--color-gridExport)" />
                <Bar dataKey="carbonCredits" stackId="revenue" fill="var(--color-carbonCredits)" />
              </BarChart>
            )}
            
            {viewType === 'profit' && (
              <ComposedChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis 
                  yAxisId="profit"
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Profit ($)', angle: -90, position: 'insideLeft' }}
                />
                <YAxis 
                  yAxisId="margin"
                  orientation="right"
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Margin (%)', angle: 90, position: 'insideRight' }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar 
                  yAxisId="profit"
                  dataKey="netProfit" 
                  fill="var(--color-netProfit)" 
                />
                <Line 
                  yAxisId="margin"
                  type="monotone" 
                  dataKey="profitMargin" 
                  stroke="var(--color-profitMargin)"
                  strokeWidth={3}
                  dot={{ r: 4 }}
                />
              </ComposedChart>
            )}
            
            {viewType === 'breakdown' && (
              <BarChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Amount ($)', angle: -90, position: 'insideLeft' }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="totalRevenue" fill="var(--color-totalRevenue)" />
                <Bar dataKey="totalCosts" fill="var(--color-totalCosts)" />
              </BarChart>
            )}
          </ChartContainer>
        </CardContent>
      </Card>
    </div>
  );
}