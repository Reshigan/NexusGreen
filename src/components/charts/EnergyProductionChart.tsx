import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Area, AreaChart } from "recharts";
import { Zap, TrendingUp, Sun, Battery } from "lucide-react";
import { Badge } from "@/components/ui/badge";

// Mock data for energy production over time
const generateEnergyData = () => {
  const now = new Date();
  const data = [];
  
  for (let i = 23; i >= 0; i--) {
    const time = new Date(now.getTime() - i * 60 * 60 * 1000);
    const hour = time.getHours();
    
    // Simulate solar production curve (peak at noon)
    let solarProduction = 0;
    if (hour >= 6 && hour <= 18) {
      const solarCurve = Math.sin(((hour - 6) / 12) * Math.PI);
      solarProduction = Math.max(0, solarCurve * 450 + Math.random() * 50 - 25);
    }
    
    // Battery storage simulation
    const batteryOutput = Math.random() * 100 + 50;
    
    // Grid consumption
    const gridConsumption = 200 + Math.random() * 150;
    
    data.push({
      time: time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
      hour: time.getHours(),
      solarProduction: Math.round(solarProduction),
      batteryOutput: Math.round(batteryOutput),
      gridConsumption: Math.round(gridConsumption),
      netProduction: Math.round(solarProduction + batteryOutput - gridConsumption),
      efficiency: Math.round(85 + Math.random() * 15)
    });
  }
  
  return data;
};

const chartConfig = {
  solarProduction: {
    label: "Solar Production",
    color: "hsl(45, 93%, 47%)", // Golden yellow for solar
  },
  batteryOutput: {
    label: "Battery Output", 
    color: "hsl(142, 76%, 36%)", // Green for battery
  },
  gridConsumption: {
    label: "Grid Consumption",
    color: "hsl(0, 84%, 60%)", // Red for consumption
  },
  netProduction: {
    label: "Net Production",
    color: "hsl(217, 91%, 60%)", // Blue for net
  },
  efficiency: {
    label: "System Efficiency",
    color: "hsl(262, 83%, 58%)", // Purple for efficiency
  }
};

export default function EnergyProductionChart() {
  const [data, setData] = useState(generateEnergyData());
  const [selectedMetric, setSelectedMetric] = useState<'production' | 'consumption' | 'efficiency'>('production');
  
  useEffect(() => {
    // Update data every 30 seconds to simulate real-time updates
    const interval = setInterval(() => {
      setData(generateEnergyData());
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);
  
  const currentData = data[data.length - 1];
  const previousData = data[data.length - 2];
  
  const getMetricChange = (current: number, previous: number) => {
    const change = ((current - previous) / previous) * 100;
    return {
      value: Math.abs(change).toFixed(1),
      isPositive: change > 0
    };
  };
  
  const solarChange = getMetricChange(currentData.solarProduction, previousData.solarProduction);
  const efficiencyChange = getMetricChange(currentData.efficiency, previousData.efficiency);
  
  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-yellow-50 to-orange-50 border-yellow-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-yellow-800">Current Solar Output</CardTitle>
            <Sun className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-900">{currentData.solarProduction} kW</div>
            <div className="flex items-center text-xs text-yellow-700">
              <TrendingUp className={`h-3 w-3 mr-1 ${solarChange.isPositive ? 'text-green-600' : 'text-red-600'}`} />
              <span className={solarChange.isPositive ? 'text-green-600' : 'text-red-600'}>
                {solarChange.value}% from last hour
              </span>
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-green-800">Battery Status</CardTitle>
            <Battery className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-900">{currentData.batteryOutput} kW</div>
            <div className="text-xs text-green-700">
              <Badge variant="outline" className="text-green-700 border-green-300">
                78% Charged
              </Badge>
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-blue-800">Net Production</CardTitle>
            <Zap className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-900">{currentData.netProduction} kW</div>
            <div className="text-xs text-blue-700">
              {currentData.netProduction > 0 ? 'Exporting to Grid' : 'Importing from Grid'}
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-gradient-to-br from-purple-50 to-violet-50 border-purple-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-purple-800">System Efficiency</CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-900">{currentData.efficiency}%</div>
            <div className="flex items-center text-xs text-purple-700">
              <TrendingUp className={`h-3 w-3 mr-1 ${efficiencyChange.isPositive ? 'text-green-600' : 'text-red-600'}`} />
              <span className={efficiencyChange.isPositive ? 'text-green-600' : 'text-red-600'}>
                {efficiencyChange.value}% from last hour
              </span>
            </div>
          </CardContent>
        </Card>
      </div>
      
      {/* Main Chart */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Energy Production & Consumption (24 Hours)</CardTitle>
              <CardDescription>
                Real-time monitoring of solar production, battery output, and grid consumption
              </CardDescription>
            </div>
            <div className="flex gap-2">
              <Badge 
                variant={selectedMetric === 'production' ? 'default' : 'outline'}
                className="cursor-pointer"
                onClick={() => setSelectedMetric('production')}
              >
                Production
              </Badge>
              <Badge 
                variant={selectedMetric === 'consumption' ? 'default' : 'outline'}
                className="cursor-pointer"
                onClick={() => setSelectedMetric('consumption')}
              >
                Consumption
              </Badge>
              <Badge 
                variant={selectedMetric === 'efficiency' ? 'default' : 'outline'}
                className="cursor-pointer"
                onClick={() => setSelectedMetric('efficiency')}
              >
                Efficiency
              </Badge>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <ChartContainer config={chartConfig} className="h-[400px]">
            {selectedMetric === 'efficiency' ? (
              <AreaChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="time" 
                  tick={{ fontSize: 12 }}
                  interval="preserveStartEnd"
                />
                <YAxis 
                  domain={[70, 100]}
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Efficiency (%)', angle: -90, position: 'insideLeft' }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Area
                  type="monotone"
                  dataKey="efficiency"
                  stroke="var(--color-efficiency)"
                  fill="var(--color-efficiency)"
                  fillOpacity={0.3}
                  strokeWidth={2}
                />
              </AreaChart>
            ) : (
              <LineChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="time" 
                  tick={{ fontSize: 12 }}
                  interval="preserveStartEnd"
                />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Power (kW)', angle: -90, position: 'insideLeft' }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                
                {selectedMetric === 'production' && (
                  <>
                    <Line
                      type="monotone"
                      dataKey="solarProduction"
                      stroke="var(--color-solarProduction)"
                      strokeWidth={3}
                      dot={{ r: 4 }}
                      activeDot={{ r: 6 }}
                    />
                    <Line
                      type="monotone"
                      dataKey="batteryOutput"
                      stroke="var(--color-batteryOutput)"
                      strokeWidth={2}
                      dot={{ r: 3 }}
                    />
                    <Line
                      type="monotone"
                      dataKey="netProduction"
                      stroke="var(--color-netProduction)"
                      strokeWidth={2}
                      strokeDasharray="5 5"
                      dot={{ r: 3 }}
                    />
                  </>
                )}
                
                {selectedMetric === 'consumption' && (
                  <Line
                    type="monotone"
                    dataKey="gridConsumption"
                    stroke="var(--color-gridConsumption)"
                    strokeWidth={3}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                )}
              </LineChart>
            )}
          </ChartContainer>
        </CardContent>
      </Card>
    </div>
  );
}