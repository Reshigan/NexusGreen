import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Factory, 
  Download,
  BarChart3,
  Zap,
  TrendingUp,
  Calendar
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import TimeFilter from "@/components/TimeFilter";
import AnalyticsChart from "@/components/AnalyticsChart";

// Mock manufacturer data - will be replaced with API integration
const manufacturers = [
  { id: "solax", name: "Solax Power", plantCount: 8, totalYield: 98450 },
  { id: "huawei", name: "Huawei", plantCount: 3, totalYield: 35280 },
  { id: "sungrow", name: "Sungrow", plantCount: 1, totalYield: 12050 },
];

const Projects = () => {
  const [selectedManufacturer, setSelectedManufacturer] = useState<string>("");
  const [timeFilter, setTimeFilter] = useState({
    period: "month",
    startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    endDate: new Date()
  });

  const handleExportCSV = () => {
    // TODO: Implement CSV export functionality for manufacturer data
    console.log(`Exporting ${selectedManufacturer} data as CSV for period:`, timeFilter);
  };

  const selectedManufacturerData = manufacturers.find(m => m.id === selectedManufacturer);

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-foreground">Projects by Manufacturer</h1>
            <p className="text-muted-foreground">View and analyze data by equipment manufacturer</p>
          </div>
          <div className="flex items-center gap-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleExportCSV}
              disabled={!selectedManufacturer}
            >
              <Download className="h-4 w-4 mr-2" />
              Export Data
            </Button>
          </div>
        </div>

        {/* Time Filter */}
        <TimeFilter 
          value={timeFilter}
          onChange={setTimeFilter}
        />

        {/* Manufacturer Selection */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Factory className="h-5 w-5" />
              Select Manufacturer
            </CardTitle>
            <CardDescription>
              Choose a manufacturer to view their plant data and performance metrics
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Select value={selectedManufacturer} onValueChange={setSelectedManufacturer}>
              <SelectTrigger className="w-full max-w-md">
                <SelectValue placeholder="Select a manufacturer" />
              </SelectTrigger>
              <SelectContent>
                {manufacturers.map((manufacturer) => (
                  <SelectItem key={manufacturer.id} value={manufacturer.id}>
                    <div className="flex items-center justify-between w-full">
                      <span>{manufacturer.name}</span>
                      <Badge variant="secondary" className="ml-2">
                        {manufacturer.plantCount} plants
                      </Badge>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </CardContent>
        </Card>

        {/* Manufacturer Data Display */}
        {selectedManufacturerData && (
          <div className="space-y-6">
            {/* Manufacturer Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Plants</CardTitle>
                  <Factory className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{selectedManufacturerData.plantCount}</div>
                  <Badge variant="secondary" className="mt-1">
                    Active
                  </Badge>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Yield</CardTitle>
                  <Zap className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {selectedManufacturerData.totalYield.toLocaleString()} kWh
                  </div>
                  <div className="flex items-center text-xs text-success mt-1">
                    <TrendingUp className="h-3 w-3 mr-1" />
                    +15% vs last period
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Avg Performance</CardTitle>
                  <BarChart3 className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">92.8%</div>
                  <div className="flex items-center text-xs text-success mt-1">
                    <TrendingUp className="h-3 w-3 mr-1" />
                    Above target
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Charts and Analytics */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <BarChart3 className="h-5 w-5" />
                  {selectedManufacturerData.name} Performance Analytics
                </CardTitle>
                <CardDescription>
                  Detailed performance metrics for {timeFilter.period} period
                </CardDescription>
              </CardHeader>
              <CardContent>
                <AnalyticsChart />
              </CardContent>
            </Card>
          </div>
        )}

        {!selectedManufacturer && (
          <Card className="p-12 text-center">
            <Factory className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">Select a Manufacturer</h3>
            <p className="text-muted-foreground">
              Choose a manufacturer from the dropdown above to view their plant data and analytics
            </p>
          </Card>
        )}
      </div>
    </DashboardLayout>
  );
};

export default Projects;