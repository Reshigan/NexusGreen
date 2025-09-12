import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, AreaChart, Area, BarChart, Bar } from "recharts";

// Mock detailed plant data - will be replaced with API integration
const mockDetailData = [
  { time: "00:00", power: 0, voltage: 230, current: 0, temperature: 18.5 },
  { time: "06:00", power: 45, voltage: 235, current: 1.2, temperature: 22.1 },
  { time: "08:00", power: 180, voltage: 240, current: 4.8, temperature: 25.8 },
  { time: "10:00", power: 320, voltage: 242, current: 8.6, temperature: 28.9 },
  { time: "12:00", power: 425, voltage: 245, current: 11.2, temperature: 31.2 },
  { time: "14:00", power: 380, voltage: 243, current: 10.1, temperature: 33.5 },
  { time: "16:00", power: 290, voltage: 241, current: 7.8, temperature: 30.8 },
  { time: "18:00", power: 120, voltage: 238, current: 3.2, temperature: 27.4 },
  { time: "20:00", power: 25, voltage: 232, current: 0.7, temperature: 24.1 },
  { time: "22:00", power: 0, voltage: 230, current: 0, temperature: 21.3 },
];

const mockWeeklyData = [
  { day: "Mon", yield: 145, efficiency: 96.8, revenue: 48.5 },
  { day: "Tue", yield: 152, efficiency: 97.2, revenue: 50.8 },
  { day: "Wed", yield: 138, efficiency: 95.4, revenue: 46.2 },
  { day: "Thu", yield: 162, efficiency: 98.1, revenue: 54.2 },
  { day: "Fri", yield: 148, efficiency: 96.5, revenue: 49.6 },
  { day: "Sat", yield: 155, efficiency: 97.8, revenue: 51.9 },
  { day: "Sun", yield: 160, efficiency: 98.5, revenue: 53.6 },
];

interface PlantDetailChartProps {
  plantId: string;
}

const PlantDetailChart = ({ plantId }: PlantDetailChartProps) => {
  return (
    <div className="space-y-8">
      {/* Real-time Power Output */}
      <div className="h-80">
        <h3 className="text-lg font-semibold mb-4">Today's Power Output (kW)</h3>
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={mockDetailData}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
            <XAxis 
              dataKey="time" 
              className="text-muted-foreground text-xs"
            />
            <YAxis 
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${value} kW`}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: 'hsl(var(--card))',
                border: '1px solid hsl(var(--border))',
                borderRadius: '8px',
              }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
              formatter={(value, name) => [
                `${value} ${name === 'power' ? 'kW' : name === 'voltage' ? 'V' : name === 'current' ? 'A' : '°C'}`, 
                name === 'power' ? 'Power Output' : name === 'voltage' ? 'Voltage' : name === 'current' ? 'Current' : 'Temperature'
              ]}
            />
            <Area
              type="monotone"
              dataKey="power"
              stroke="hsl(var(--accent))"
              fill="hsl(var(--accent))"
              fillOpacity={0.4}
              strokeWidth={2}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* System Parameters */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64">
          <h3 className="text-lg font-semibold mb-4">Voltage & Current</h3>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={mockDetailData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis 
                dataKey="time" 
                className="text-muted-foreground text-xs"
              />
              <YAxis 
                yAxisId="voltage"
                orientation="left"
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value}V`}
              />
              <YAxis 
                yAxisId="current"
                orientation="right"
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value}A`}
              />
              <Tooltip 
                contentStyle={{
                  backgroundColor: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                }}
                labelStyle={{ color: 'hsl(var(--foreground))' }}
              />
              <Line
                yAxisId="voltage"
                type="monotone"
                dataKey="voltage"
                stroke="hsl(var(--success))"
                strokeWidth={2}
                dot={false}
                name="Voltage (V)"
              />
              <Line
                yAxisId="current"
                type="monotone"
                dataKey="current"
                stroke="hsl(var(--warning))"
                strokeWidth={2}
                dot={false}
                name="Current (A)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="h-64">
          <h3 className="text-lg font-semibold mb-4">Temperature Monitoring</h3>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={mockDetailData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis 
                dataKey="time" 
                className="text-muted-foreground text-xs"
              />
              <YAxis 
                className="text-muted-foreground text-xs"
                tickFormatter={(value) => `${value}°C`}
              />
              <Tooltip 
                contentStyle={{
                  backgroundColor: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                }}
                labelStyle={{ color: 'hsl(var(--foreground))' }}
                formatter={(value) => [`${value}°C`, 'Temperature']}
              />
              <Line
                type="monotone"
                dataKey="temperature"
                stroke="hsl(var(--destructive))"
                strokeWidth={3}
                dot={{ fill: 'hsl(var(--destructive))', strokeWidth: 2, r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Weekly Performance */}
      <div className="h-80">
        <h3 className="text-lg font-semibold mb-4">Weekly Performance Summary</h3>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={mockWeeklyData}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
            <XAxis 
              dataKey="day" 
              className="text-muted-foreground text-xs"
            />
            <YAxis 
              yAxisId="yield"
              orientation="left"
              className="text-muted-foreground text-xs"
              tickFormatter={(value) => `${value} kWh`}
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
            />
            <Bar
              yAxisId="yield"
              dataKey="yield"
              fill="hsl(var(--accent))"
              name="Daily Yield (kWh)"
              radius={[4, 4, 0, 0]}
            />
            <Line
              yAxisId="efficiency"
              type="monotone"
              dataKey="efficiency"
              stroke="hsl(var(--success))"
              strokeWidth={2}
              name="Efficiency (%)"
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default PlantDetailChart;