import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ScatterChart, Scatter, AreaChart, Area, ComposedChart, Bar } from "recharts";

// Mock analytics data - will be replaced with API integration
const mockAnalyticsData = [
  { 
    month: "Jan", 
    portfolioYield: 125400, 
    predictedYield: 120000,
    efficiency: 92.1,
    roi: 8.2,
    maintenance: 3200,
    revenue: 41800
  },
  { 
    month: "Feb", 
    portfolioYield: 132000, 
    predictedYield: 128000,
    efficiency: 93.5,
    roi: 8.6,
    maintenance: 2800,
    revenue: 44100
  },
  { 
    month: "Mar", 
    portfolioYield: 148000, 
    predictedYield: 142000,
    efficiency: 94.2,
    roi: 9.1,
    maintenance: 4100,
    revenue: 49400
  },
  { 
    month: "Apr", 
    portfolioYield: 161000, 
    predictedYield: 156000,
    efficiency: 95.1,
    roi: 9.5,
    maintenance: 3600,
    revenue: 53800
  },
  { 
    month: "May", 
    portfolioYield: 176000, 
    predictedYield: 170000,
    efficiency: 96.3,
    roi: 10.2,
    maintenance: 2900,
    revenue: 58800
  },
  { 
    month: "Jun", 
    portfolioYield: 182000, 
    predictedYield: 175000,
    efficiency: 94.8,
    roi: 9.8,
    maintenance: 5200,
    revenue: 60900
  }
];

const mockPerformanceData = [
  { plant: "Alpha", efficiency: 96.8, capacity: 500, yield: 25480 },
  { plant: "Beta", efficiency: 94.2, capacity: 450, yield: 22150 },
  { plant: "Gamma", efficiency: 95.7, capacity: 600, yield: 28900 },
  { plant: "Delta", efficiency: 89.4, capacity: 400, yield: 19800 },
  { plant: "Echo", efficiency: 93.8, capacity: 550, yield: 26700 },
];

const mockPredictiveData = [
  { week: "W1", actual: 38500, predicted: 37800, weather: 0.85, maintenance: 0.1 },
  { week: "W2", actual: 41200, predicted: 40500, weather: 0.92, maintenance: 0.05 },
  { week: "W3", actual: 39800, predicted: 41000, weather: 0.78, maintenance: 0.15 },
  { week: "W4", actual: 43100, predicted: 42800, weather: 0.95, maintenance: 0.08 },
];

const AnalyticsChart = () => {
  return (
    <div className="space-y-8">
      {/* Portfolio Performance vs Predictions */}
      <div className="h-80">
        <h3 className="text-lg font-semibold mb-4">Portfolio Performance vs AI Predictions</h3>
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart data={mockAnalyticsData}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
            <XAxis 
              dataKey="month" 
              className="text-muted-foreground text-xs"
            />
            <YAxis 
              yAxisId="yield"
              orientation="left"
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${(value / 1000).toFixed(0)}k kWh`}
            />
            <YAxis 
              yAxisId="efficiency"
              orientation="right"
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${value}%`}
              domain={[90, 100]}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: 'hsl(var(--card))',
                border: '1px solid hsl(var(--border))',
                borderRadius: '8px',
              }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
              formatter={(value, name) => {
                const nameStr = String(name);
                if (nameStr.includes('Yield')) return [`${(value as number).toLocaleString()} kWh`, name];
                if (nameStr.includes('Efficiency')) return [`${value}%`, name];
                if (nameStr.includes('ROI')) return [`${value}%`, name];
                return [value, name];
              }}
            />
            
            {/* Actual yield bars */}
            <Bar
              yAxisId="yield"
              dataKey="portfolioYield"
              fill="hsl(var(--accent))"
              fillOpacity={0.7}
              name="Actual Yield"
            />
            
            {/* Predicted yield line */}
            <Line
              yAxisId="yield"
              type="monotone"
              dataKey="predictedYield"
              stroke="hsl(var(--warning))"
              strokeWidth={2}
              strokeDasharray="5 5"
              dot={false}
              name="AI Predicted Yield"
            />
            
            {/* Efficiency line */}
            <Line
              yAxisId="efficiency"
              type="monotone"
              dataKey="efficiency"
              stroke="hsl(var(--success))"
              strokeWidth={3}
              dot={{ fill: 'hsl(var(--success))', strokeWidth: 2, r: 4 }}
              name="Portfolio Efficiency"
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>

      {/* Plant Performance Analysis */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64">
          <h3 className="text-lg font-semibold mb-4">Plant Efficiency vs Capacity</h3>
          <ResponsiveContainer width="100%" height="100%">
            <ScatterChart data={mockPerformanceData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis 
                dataKey="capacity"
                type="number"
                domain={[350, 650]}
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value} kW`}
              />
              <YAxis 
                dataKey="efficiency"
                type="number"
                domain={[85, 100]}
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value}%`}
              />
              <Tooltip 
                cursor={{ strokeDasharray: '3 3' }}
                contentStyle={{
                  backgroundColor: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                }}
                labelStyle={{ color: 'hsl(var(--foreground))' }}
                formatter={(value, name, props) => [
                  name === 'efficiency' ? `${value}%` : `${value} kW`,
                  props.payload.plant ? `Plant ${props.payload.plant}` : name
                ]}
              />
              <Scatter
                dataKey="efficiency"
                fill="hsl(var(--accent))"
                strokeWidth={2}
                stroke="hsl(var(--accent))"
              />
            </ScatterChart>
          </ResponsiveContainer>
        </div>

        <div className="h-64">
          <h3 className="text-lg font-semibold mb-4">ROI Trend Analysis</h3>
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={mockAnalyticsData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis 
                dataKey="month" 
                className="text-muted-foreground text-xs"
              />
              <YAxis 
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value}%`}
              />
              <Tooltip 
                contentStyle={{
                  backgroundColor: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                }}
                labelStyle={{ color: 'hsl(var(--foreground))' }}
                formatter={(value) => [`${value}%`, 'ROI']}
              />
              <Area
                type="monotone"
                dataKey="roi"
                stroke="hsl(var(--success))"
                fill="hsl(var(--success))"
                fillOpacity={0.3}
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Predictive Analytics */}
      <div className="h-80">
        <h3 className="text-lg font-semibold mb-4">Weekly Predictive Analytics</h3>
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart data={mockPredictiveData}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
            <XAxis 
              dataKey="week" 
              className="text-muted-foreground text-xs"
            />
            <YAxis 
              yAxisId="yield"
              orientation="left"
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${(value / 1000).toFixed(0)}k kWh`}
            />
            <YAxis 
              yAxisId="factor"
              orientation="right"
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${(value * 100).toFixed(0)}%`}
              domain={[0, 1]}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: 'hsl(var(--card))',
                border: '1px solid hsl(var(--border))',
                borderRadius: '8px',
              }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
              formatter={(value, name) => {
                const nameStr = String(name);
                if (nameStr.includes('Yield')) return [`${(value as number).toLocaleString()} kWh`, name];
                if (nameStr.includes('Weather') || nameStr.includes('Maintenance')) return [`${((value as number) * 100).toFixed(1)}%`, name];
                return [value, name];
              }}
            />
            
            {/* Actual vs predicted bars */}
            <Bar
              yAxisId="yield"
              dataKey="actual"
              fill="hsl(var(--accent))"
              name="Actual Yield"
            />
            <Bar
              yAxisId="yield"
              dataKey="predicted"
              fill="hsl(var(--muted))"
              name="Predicted Yield"
            />
            
            {/* Weather impact line */}
            <Line
              yAxisId="factor"
              type="monotone"
              dataKey="weather"
              stroke="hsl(var(--warning))"
              strokeWidth={2}
              name="Weather Impact"
            />
            
            {/* Maintenance impact line */}
            <Line
              yAxisId="factor"
              type="monotone"
              dataKey="maintenance"
              stroke="hsl(var(--destructive))"
              strokeWidth={2}
              name="Maintenance Impact"
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>

      {/* Key Insights Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-4 border-t">
        <div className="text-center p-4 bg-success/10 rounded-lg">
          <div className="text-2xl font-bold text-success">+12%</div>
          <p className="text-sm text-muted-foreground">Performance above prediction</p>
        </div>
        <div className="text-center p-4 bg-warning/10 rounded-lg">
          <div className="text-2xl font-bold text-warning">94.2%</div>
          <p className="text-sm text-muted-foreground">AI prediction accuracy</p>
        </div>
        <div className="text-center p-4 bg-accent/10 rounded-lg">
          <div className="text-2xl font-bold text-accent">6 months</div>
          <p className="text-sm text-muted-foreground">ROI ahead of schedule</p>
        </div>
      </div>
    </div>
  );
};

export default AnalyticsChart;