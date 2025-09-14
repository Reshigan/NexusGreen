import { useEffect, useState } from "react";
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
  FileDown,
  Grid3X3,
  Braces,
  Activity,
  BarChart3,
  Settings,
  Bell
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import PlantOverviewChart from "@/components/PlantOverviewChart";
import PlantListView from "@/components/PlantListView";
import TimeFilter from "@/components/TimeFilter";
import PlantsMap from "@/components/PlantsMap";
import NexusGreenLogo from "@/components/NexusGreenLogo";

// Enhanced mock data for solar energy management platform
const mockStats = {
  totalGeneration: 1247.8, // kWh today
  totalSavings: 48560, // USD
  monthlyYield: 12340, // kWh this month
  activeAlerts: 2,
  performance: 94.2, // %
  activeSites: 12,
  totalCapacity: 850.5, // kW
  co2Saved: 892.4, // kg CO2
  systemEfficiency: 87.3, // %
  gridExport: 234.5, // kWh
  batteryLevel: 78, // %
  weatherCondition: "Sunny"
};

const mockSites = [
  {
    id: 1,
    name: "Solar Farm Alpha",
    location: "Sydney, NSW",
    capacity: 250.5,
    currentGeneration: 187.3,
    efficiency: 94.2,
    status: "optimal",
    alerts: 0,
    lastUpdate: "2 min ago"
  },
  {
    id: 2,
    name: "Rooftop Installation Beta",
    location: "Melbourne, VIC",
    capacity: 150.0,
    currentGeneration: 98.7,
    efficiency: 89.1,
    status: "good",
    alerts: 1,
    lastUpdate: "5 min ago"
  },
  {
    id: 3,
    name: "Commercial Complex Gamma",
    location: "Brisbane, QLD",
    capacity: 450.0,
    currentGeneration: 312.8,
    efficiency: 96.7,
    status: "optimal",
    alerts: 0,
    lastUpdate: "1 min ago"
  }
];

const mockAlerts = [
  {
    id: 1,
    type: "warning",
    message: "Inverter efficiency below threshold at Site Beta",
    time: "10 min ago",
    severity: "medium"
  },
  {
    id: 2,
    type: "info",
    message: "Maintenance scheduled for Site Alpha tomorrow",
    time: "1 hour ago",
    severity: "low"
  }
];

const Dashboard = () => {
  const [selectedView, setSelectedView] = useState<"overview" | "sites" | "analytics">("overview");
  const [timeFilter, setTimeFilter] = useState({
    period: "today",
    startDate: new Date(new Date().setHours(0, 0, 0, 0)),
    endDate: new Date()
  });
  const [realTimeData, setRealTimeData] = useState(mockStats);
  const [isLoading, setIsLoading] = useState(false);

  // Simulate real-time data updates
  useEffect(() => {
    const interval = setInterval(() => {
      setRealTimeData(prev => ({
        ...prev,
        totalGeneration: prev.totalGeneration + Math.random() * 5,
        performance: Math.max(85, Math.min(98, prev.performance + (Math.random() - 0.5) * 2)),
        batteryLevel: Math.max(20, Math.min(100, prev.batteryLevel + (Math.random() - 0.5) * 3))
      }));
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "optimal": return "text-green-600 bg-green-50 border-green-200";
      case "good": return "text-blue-600 bg-blue-50 border-blue-200";
      case "warning": return "text-yellow-600 bg-yellow-50 border-yellow-200";
      case "error": return "text-red-600 bg-red-50 border-red-200";
      default: return "text-gray-600 bg-gray-50 border-gray-200";
    }
  };

  const formatNumber = (num: number, decimals: number = 1) => {
    return new Intl.NumberFormat('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals
    }).format(num);
  };

  const handleExportCSV = async (type: "overview" | "detailed") => {
    try {
      const start = timeFilter.startDate.toISOString().slice(0, 10);
      const end = timeFilter.endDate.toISOString().slice(0, 10);

      const download = (filename: string, csv: string) => {
        const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.setAttribute("download", filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
      };

      const parseResponse = async (res: Response) => {
        const contentType = res.headers.get("content-type") || "";
        const raw = await res.text();
        let data: any = {};
        if (contentType.includes("application/json") && raw) {
          try { data = JSON.parse(raw); } catch { /* ignore */ }
        }
        if (!res.ok || data.error) {
          throw new Error(data?.error || `Failed with status ${res.status}`);
        }
        return data;
      };

      if (type === "overview") {
        // Export EVERYTHING shown in the dashboard as a ZIP of CSVs
        const JSZip = (await import("jszip")).default;
        const zip = new JSZip();

        const [yieldRes, savingsRes, perfRes, devicesRes, plantsRes, earningsHistRes, monthlyYieldRes, monthlyEarningsRes] = await Promise.all([
          fetch("/api/yield/total/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
          fetch("/api/savings/total/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
          fetch("/api/performance/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
          fetch(`/api/devices?start=${start}&end=${end}`),
          fetch(`/api/plants?limit=500&offset=0`),
          fetch('/api/earnings/history', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end, rateZAR: 1.2 }) }),
          fetch('/api/yield/monthly', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end }) }),
          fetch('/api/earnings/monthly/change', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end, rateZAR: 1.2 }) }),
        ]);

        const [yieldData, savingsData, perfData, devicesData, plantsData, earningsHistData, monthlyYieldData, monthlyEarningsData] = await Promise.all([
          parseResponse(yieldRes),
          parseResponse(savingsRes),
          parseResponse(perfRes),
          parseResponse(devicesRes),
          parseResponse(plantsRes),
          parseResponse(earningsHistRes),
          parseResponse(monthlyYieldRes),
          parseResponse(monthlyEarningsRes),
        ]);

        const csvEscape = (v: unknown) => `"${String(v ?? '').replace(/"/g, '""')}"`;
        const makeCSV = (headers: string[], rows: any[]) => [headers, ...rows].map(r => r.map(csvEscape).join(',')).join('\n');

        // Overview.csv
        const overviewRows = [
          ["Metric", "Value"],
          ["Start Date", start],
          ["End Date", end],
          ["Total Yield (kWh)", String(yieldData.total_yield ?? "")],
          ["Total Savings (ZAR)", String(savingsData.savings ?? "")],
          ["Performance (%)", String(perfData.performance_percent ?? "")],
        ];
        zip.file(`overview.csv`, overviewRows.map(r => r.map(csvEscape).join(',')).join('\n'));

        // Devices.csv
        const deviceList: string[] = Array.isArray(devicesData.devices) ? devicesData.devices : [];
        zip.file(`devices.csv`, makeCSV(["DeviceSN"], deviceList.map(sn => [sn])));

        // Plants.csv
        const plants = Array.isArray(plantsData.plants) ? plantsData.plants : [];
        zip.file(`plants.csv`, makeCSV(["CustomerID","Name","Location","City","SerialNumber","DateInstalled"],
          plants.map((p: any) => [p.customerId, p.name, p.location, p.city, p.serialNumber, p.dateInstalled])));

        // EarningsHistory.csv
        const earningsHist = Array.isArray(earningsHistData.history) ? earningsHistData.history : [];
        zip.file(`earnings_history.csv`, makeCSV(["Date","DailyYield","TotalYield","DailyEarningsZAR","TotalEarningsZAR"],
          earningsHist.map((r: any) => [r.date, r.dailyYield, r.totalYield, r.dailyEarningsZAR, r.totalEarningsZAR])));

        // MonthlyYield.csv
        const monthlyYield = Array.isArray(monthlyYieldData.history) ? monthlyYieldData.history : [];
        zip.file(`monthly_yield.csv`, makeCSV(["Month","TotalMonthlyYield","MonthlyChange"],
          monthlyYield.map((r: any) => [r.month, r.totalMonthlyYield, r.monthlyChange])));

        // MonthlyEarnings.csv
        const monthlyEarn = Array.isArray(monthlyEarningsData.history) ? monthlyEarningsData.history : [];
        // Aggregate by month across devices
        const byMonth: Record<string, number> = {};
        monthlyEarn.forEach((r: any) => {
          const key = `${r.year}-${String(r.month).padStart(2,'0')}`;
          byMonth[key] = (byMonth[key] || 0) + Number(r.totalMonthlyEarnings || 0);
        });
        const monthlyEarnRows = Object.entries(byMonth).sort(([a],[b]) => a.localeCompare(b)).map(([m, v]) => [m, v]);
        zip.file(`monthly_earnings.csv`, makeCSV(["Month","TotalMonthlyEarningsZAR"], monthlyEarnRows));

        const zipBlob = await zip.generateAsync({ type: 'blob' });
        const url = URL.createObjectURL(zipBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `dashboard_data_${start}_to_${end}.zip`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
      } else {
        const res = await fetch(`/api/plants?limit=500&offset=0`);
        const data = await parseResponse(res);
        const plants = Array.isArray(data.plants) ? data.plants : [];
        const headers = ["CustomerID", "Name", "Location", "City", "SerialNumber", "DateInstalled"];
        const rows = [headers].concat(
          plants.map((p: any) => [
            p.customerId ?? "",
            p.name ?? "",
            p.location ?? "",
            p.city ?? "",
            p.serialNumber ?? "",
            p.dateInstalled ?? "",
          ])
        );
        const csv = rows.map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
        download(`plants_list.csv`, csv);
      }
    } catch (err) {
      console.error("Export failed:", err);
    }
  };

  const handleExportPDF = async () => {
    const { default: jsPDF } = await import('jspdf');
    const html2canvas = (await import('html2canvas')).default;
    const start = timeFilter.startDate.toISOString().slice(0, 10);
    const end = timeFilter.endDate.toISOString().slice(0, 10);

    const container = document.getElementById('dashboard-export-root');
    if (!container) {
      console.error('Export container not found');
      return;
    }
    const canvas = await html2canvas(container, { scale: 2, useCORS: true, allowTaint: true, backgroundColor: '#ffffff' });
    const imgData = canvas.toDataURL('image/png');
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();
    const imgWidth = pageWidth;
    const imgHeight = canvas.height * imgWidth / canvas.width;

    let heightLeft = imgHeight;
    let position = 0;

    pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
    heightLeft -= pageHeight;
    while (heightLeft > 0) {
      position = heightLeft - imgHeight;
      pdf.addPage();
      pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
      heightLeft -= pageHeight;
    }
    pdf.save(`dashboard_${start}_to_${end}.pdf`);
  };

  const handleExportJSON = async () => {
    try {
      const start = timeFilter.startDate.toISOString().slice(0, 10);
      const end = timeFilter.endDate.toISOString().slice(0, 10);
      const parseResponse = async (res: Response) => {
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
        let data: any = {};
        if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch {} }
        if (!res.ok || data.error) throw new Error(data?.error || `Failed: ${res.status}`);
        return data;
      };

      const [yieldRes, savingsRes, perfRes, devicesRes, plantsRes, earningsHistRes, monthlyYieldRes, monthlyEarningsRes] = await Promise.all([
        fetch("/api/yield/total/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
        fetch("/api/savings/total/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
        fetch("/api/performance/range", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ start, end }) }),
        fetch(`/api/devices?start=${start}&end=${end}`),
        fetch(`/api/plants?limit=500&offset=0`),
        fetch('/api/earnings/history', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end, rateZAR: 1.2 }) }),
        fetch('/api/yield/monthly', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end }) }),
        fetch('/api/earnings/monthly/change', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ start, end, rateZAR: 1.2 }) }),
      ]);

      const [yieldData, savingsData, perfData, devicesData, plantsData, earningsHistData, monthlyYieldData, monthlyEarningsData] = await Promise.all([
        parseResponse(yieldRes),
        parseResponse(savingsRes),
        parseResponse(perfRes),
        parseResponse(devicesRes),
        parseResponse(plantsRes),
        parseResponse(earningsHistRes),
        parseResponse(monthlyYieldRes),
        parseResponse(monthlyEarningsRes),
      ]);

      const full = {
        start,
        end,
        overview: {
          totalYield: yieldData.total_yield,
          totalSavingsZAR: savingsData.savings,
          performancePercent: perfData.performance_percent,
        },
        devices: devicesData.devices,
        plants: plantsData.plants,
        earningsHistory: earningsHistData.history,
        monthlyYield: monthlyYieldData.history,
        monthlyEarningsPerDevice: monthlyEarningsData.history,
      };

      const blob = new Blob([JSON.stringify(full, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `dashboard_${start}_to_${end}.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (e) {
      console.error('Export JSON failed:', e);
    }
  };

  

  

  useEffect(() => {
    const controller = new AbortController();
    const fetchPlantsCount = async () => {
      try {
        setPlantsCountLoading(true);
        setPlantsCountError(null);
        const res = await fetch("/api/plants/count", { signal: controller.signal });
        const contentType = res.headers.get("content-type") || "";
        const raw = await res.text();
        let data: any = {};
        if (contentType.includes("application/json") && raw) {
          try { data = JSON.parse(raw); } catch { /* ignore */ }
        }
        if (!res.ok || data.error) {
          throw new Error(data?.error || `Failed with status ${res.status}`);
        }
        setPlantsCount(Number(data.count));
      } catch (err: any) {
        if (err.name !== "AbortError") {
          setPlantsCountError(err.message || "Failed to load plants count");
        }
      } finally {
        setPlantsCountLoading(false);
      }
    };
    fetchPlantsCount();
    return () => controller.abort();
  }, []);

  return (
    <DashboardLayout>
      <div id="dashboard-export-root" className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-4">
              <NexusGreenLogo size="lg" variant="full" />
              <div>
                <h1 className="text-3xl font-bold bg-gradient-to-r from-green-400 via-emerald-500 to-teal-600 bg-clip-text text-transparent">
                  Dashboard
                </h1>
              </div>
            </div>
            <p className="text-muted-foreground font-medium">Next-Generation Solar Energy Intelligence Platform</p>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-green-600 border-green-200">
              <Activity className="h-3 w-3 mr-1" />
              Live Data
            </Badge>
            <Button variant="outline" size="sm" onClick={() => handleExportCSV("overview")}>
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
            <Button variant="outline" size="sm">
              <Settings className="h-4 w-4 mr-2" />
              Settings
            </Button>
          </div>
        </div>

        {/* Key Performance Metrics - Edgy Design */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-green-400/10 via-emerald-500/10 to-teal-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-green-400/20 to-emerald-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Today's Generation</CardTitle>
              <div className="relative">
                <div className="absolute inset-0 bg-green-400 rounded-full blur-sm opacity-50 group-hover:opacity-75 transition-opacity duration-300"></div>
                <Zap className="relative h-5 w-5 text-green-600" />
              </div>
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                {formatNumber(realTimeData.totalGeneration)} kWh
              </div>
              <p className="text-xs text-green-600 font-medium mt-1">
                ↗ +12.5% from yesterday
              </p>
              <div className="mt-3 relative">
                <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                  <div className="bg-gradient-to-r from-green-400 to-emerald-500 h-2 rounded-full transition-all duration-1000 ease-out" style={{width: '75%'}}></div>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-blue-50 via-cyan-50 to-sky-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-400/10 via-cyan-500/10 to-sky-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-blue-400/20 to-cyan-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Active Sites</CardTitle>
              <div className="relative">
                <div className="absolute inset-0 bg-blue-400 rounded-full blur-sm opacity-50 group-hover:opacity-75 transition-opacity duration-300"></div>
                <MapPin className="relative h-5 w-5 text-blue-600" />
              </div>
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">
                {realTimeData.activeSites}
              </div>
              <p className="text-xs text-blue-600 font-medium mt-1">
                {realTimeData.totalCapacity} kW total capacity
              </p>
              <div className="flex items-center mt-3">
                <div className="w-2 h-2 bg-gradient-to-r from-green-400 to-emerald-500 rounded-full mr-2 animate-pulse"></div>
                <span className="text-xs font-medium text-green-600">All systems operational</span>
              </div>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-amber-50 via-yellow-50 to-orange-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-amber-400/10 via-yellow-500/10 to-orange-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-amber-400/20 to-yellow-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">System Performance</CardTitle>
              <div className="relative">
                <div className="absolute inset-0 bg-amber-400 rounded-full blur-sm opacity-50 group-hover:opacity-75 transition-opacity duration-300"></div>
                <TrendingUp className="relative h-5 w-5 text-amber-600" />
              </div>
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-amber-600 to-yellow-600 bg-clip-text text-transparent">
                {formatNumber(realTimeData.performance)}%
              </div>
              <p className="text-xs text-amber-600 font-medium mt-1">
                Efficiency rating
              </p>
              <div className="mt-3 relative">
                <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                  <div className="bg-gradient-to-r from-amber-400 to-yellow-500 h-2 rounded-full transition-all duration-1000 ease-out" style={{width: `${realTimeData.performance}%`}}></div>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-red-50 via-rose-50 to-pink-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-red-400/10 via-rose-500/10 to-pink-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-red-400/20 to-rose-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Active Alerts</CardTitle>
              <div className="relative">
                <div className="absolute inset-0 bg-red-400 rounded-full blur-sm opacity-50 group-hover:opacity-75 transition-opacity duration-300"></div>
                <AlertTriangle className="relative h-5 w-5 text-red-600" />
              </div>
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-red-600 to-rose-600 bg-clip-text text-transparent">
                {realTimeData.activeAlerts}
              </div>
              <p className="text-xs text-red-600 font-medium mt-1">
                Requires attention
              </p>
              <Button className="mt-3 w-full bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600 border-0 shadow-md hover:shadow-lg transition-all duration-300">
                <Bell className="h-3 w-3 mr-1" />
                View Alerts
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Secondary Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Financial Savings</CardTitle>
              <DollarSign className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">${formatNumber(realTimeData.totalSavings)}</div>
              <p className="text-xs text-muted-foreground">Total lifetime savings</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">CO₂ Reduction</CardTitle>
              <Leaf className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{formatNumber(realTimeData.co2Saved)} kg</div>
              <p className="text-xs text-muted-foreground">Carbon footprint reduced</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Battery Storage</CardTitle>
              <Battery className="h-4 w-4 text-blue-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">{formatNumber(realTimeData.batteryLevel)}%</div>
              <p className="text-xs text-muted-foreground">Current charge level</p>
              <Progress value={realTimeData.batteryLevel} className="mt-2" />
            </CardContent>
          </Card>
        </div>

        {/* Main Content Tabs */}
        <Tabs value={selectedView} onValueChange={(value: any) => setSelectedView(value)} className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="sites">Site Management</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            {/* Real-time Energy Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <BarChart3 className="h-5 w-5" />
                  Real-time Energy Production
                </CardTitle>
                <CardDescription>
                  Live energy generation data across all sites
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-80">
                  <PlantOverviewChart timeFilter={timeFilter} />
                </div>
              </CardContent>
            </Card>

            {/* Recent Alerts */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Bell className="h-5 w-5" />
                  Recent Alerts
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {mockAlerts.map((alert) => (
                    <div key={alert.id} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center gap-3">
                        <AlertTriangle className={`h-4 w-4 ${alert.severity === 'medium' ? 'text-yellow-500' : 'text-blue-500'}`} />
                        <div>
                          <p className="text-sm font-medium">{alert.message}</p>
                          <p className="text-xs text-muted-foreground">{alert.time}</p>
                        </div>
                      </div>
                      <Badge variant={alert.severity === 'medium' ? 'destructive' : 'secondary'}>
                        {alert.severity}
                      </Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="sites" className="space-y-6">
            {/* Site Status Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {mockSites.map((site) => (
                <Card key={site.id} className="hover:shadow-lg transition-shadow">
                  <CardHeader className="pb-3">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-lg">{site.name}</CardTitle>
                      <Badge className={getStatusColor(site.status)}>
                        {site.status}
                      </Badge>
                    </div>
                    <CardDescription className="flex items-center gap-1">
                      <MapPin className="h-3 w-3" />
                      {site.location}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p className="text-muted-foreground">Capacity</p>
                        <p className="font-semibold">{formatNumber(site.capacity)} kW</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground">Current Gen.</p>
                        <p className="font-semibold">{formatNumber(site.currentGeneration)} kW</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground">Efficiency</p>
                        <p className="font-semibold">{formatNumber(site.efficiency)}%</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground">Alerts</p>
                        <p className="font-semibold">{site.alerts}</p>
                      </div>
                    </div>
                    <Progress value={(site.currentGeneration / site.capacity) * 100} />
                    <div className="flex items-center justify-between text-xs text-muted-foreground">
                      <span>Last updated: {site.lastUpdate}</span>
                      <Button variant="ghost" size="sm">
                        View Details
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {/* Site Map */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MapPin className="h-5 w-5" />
                  Site Locations
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-96 bg-gray-100 rounded-lg flex items-center justify-center">
                  <p className="text-muted-foreground">Interactive map will be displayed here</p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="analytics" className="space-y-6">
            {/* Time Filter */}
            <div className="flex items-center gap-4">
              <TimeFilter value={timeFilter} onChange={setTimeFilter} />
            </div>

            {/* Analytics Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle>Performance Trends</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
                    <p className="text-muted-foreground">Performance trend chart</p>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Financial Analysis</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
                    <p className="text-muted-foreground">Financial analysis chart</p>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Detailed Analytics */}
            <Card>
              <CardHeader>
                <CardTitle>Detailed Analytics</CardTitle>
              </CardHeader>
              <CardContent>
                <PlantOverviewChart timeFilter={timeFilter} />
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
};

export default Dashboard;