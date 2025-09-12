import { useParams, useNavigate } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  ArrowLeft, 
  MapPin, 
  Calendar,
  Zap,
  TrendingUp,
  Download,
  Thermometer,
  Activity
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import PlantDetailChart from "@/components/PlantDetailChart";
 

// Mock plant data - static display
const mockPlantData = {
  id: "1",
  name: "Solar Plant Alpha",
  location: "California, USA",
  city: "San Francisco",
  sn: "SP-001-CA",
  status: "Active",
  totalYield: 25480,
  dailyYield: 145,
  performance: 96.8,
  lastUpdate: "2024-01-15 14:30:00",
  capacity: "500 kW",
  commissioning: "2023-03-15",
  acPower: 425.6,
  temperature: 28.5,
  gridFrequency: 60.1,
  totalActivePower: 425600,
  inverterTemperature: 45.2
};

const PlantDetails = () => {
  const { plantId } = useParams();
  const navigate = useNavigate();

  const handleExportCSV = () => {
    // TODO: Implement CSV export for individual plant
    console.log(`Exporting plant ${plantId} data as CSV`);
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => navigate("/dashboard")}
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Dashboard
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-foreground">Solar Plant Alpha</h1>
              <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
                <div className="flex items-center gap-1">
                  <MapPin className="h-4 w-4" />
                  California, USA
                </div>
                <Badge variant={"default"}>
                  Active
                </Badge>
              </div>
            </div>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={handleExportCSV}
          >
            <Download className="h-4 w-4 mr-2" />
            Export Plant Data
          </Button>
        </div>

        {/* Plant Overview Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Yield</CardTitle>
              <Zap className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{mockPlantData.totalYield.toLocaleString()} kWh</div>
              <p className="text-xs text-muted-foreground">
                Lifetime generation
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Daily Yield</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{mockPlantData.dailyYield} kWh</div>
              <p className="text-xs text-success">
                +5% vs yesterday
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Current Power</CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {mockPlantData.acPower} kW
              </div>
              <p className="text-xs text-muted-foreground">
                Real-time output
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Temperature</CardTitle>
              <Thermometer className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {mockPlantData.temperature}°C
              </div>
              <p className="text-xs text-muted-foreground">
                Ambient temperature
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Detailed Analytics */}
        <Tabs defaultValue="performance" className="space-y-4">
          <TabsList>
            <TabsTrigger value="performance">Performance</TabsTrigger>
            <TabsTrigger value="technical">Technical Data</TabsTrigger>
            <TabsTrigger value="financial">Financial Metrics</TabsTrigger>
          </TabsList>

          <TabsContent value="performance" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Performance Analytics</CardTitle>
                <CardDescription>Detailed performance metrics and trends for {mockPlantData.name}</CardDescription>
              </CardHeader>
              <CardContent>
                <PlantDetailChart plantId={plantId || "1"} />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="technical" className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">System Information</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Serial Number:</span>
                    <span className="font-medium">{mockPlantData.sn}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Capacity:</span>
                    <span className="font-medium">{mockPlantData.capacity}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Commissioned:</span>
                    <span className="font-medium">{mockPlantData.commissioning}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Last Update:</span>
                    <span className="font-medium">{mockPlantData.lastUpdate}</span>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Real-time Metrics</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Grid Frequency:</span>
                    <span className="font-medium">{mockPlantData.gridFrequency} Hz</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Inverter Temp:</span>
                    <span className="font-medium">{mockPlantData.inverterTemperature}°C</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Total Active Power:</span>
                    <span className="font-medium">{mockPlantData.totalActivePower.toLocaleString()} W</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Performance:</span>
                    <span className="font-medium text-success">{mockPlantData.performance}%</span>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="financial" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Financial Performance</CardTitle>
                <CardDescription>
                  Revenue and savings analysis for {mockPlantData.name}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {/* TODO: Add financial charts and metrics */}
                <div className="text-center py-8 text-muted-foreground">
                  Financial analytics will be implemented with API integration
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
};

export default PlantDetails;