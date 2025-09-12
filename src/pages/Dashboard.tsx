import { useEffect, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Sun, 
  Download,
  FileDown,
  Grid3X3,
  Braces
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import PlantOverviewChart from "@/components/PlantOverviewChart";
import PlantListView from "@/components/PlantListView";
import TimeFilter from "@/components/TimeFilter";
import PlantsMap from "@/components/PlantsMap";

// Mock data - will be progressively replaced with API integration
const mockStats = {
  totalSavings: 48560, // USD
  monthlyYield: 12340,
  activeAlerts: 2,
  performance: 94.2
};

const Dashboard = () => {
  const [selectedView, setSelectedView] = useState<"overview" | "list">("overview");
  const [plantsCount, setPlantsCount] = useState<number | null>(null);
  const [plantsCountLoading, setPlantsCountLoading] = useState<boolean>(false);
  const [plantsCountError, setPlantsCountError] = useState<string | null>(null);
  
  const [timeFilter, setTimeFilter] = useState({
    period: "month",
    startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    endDate: new Date()
  });

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
            <h1 className="text-3xl font-bold text-foreground">PPA Dashboard</h1>
            <p className="text-muted-foreground">Monitor your solar investments and performance</p>
          </div>
          <div className="flex items-center gap-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => handleExportCSV("overview")}
            >
              <Download className="h-4 w-4 mr-2" />
              Export Data
            </Button>
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleExportJSON}
            >
              <Braces className="h-4 w-4 mr-2" />
              Export JSON
            </Button>
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleExportPDF}
            >
              <FileDown className="h-4 w-4 mr-2" />
              Export PDF
            </Button>
          </div>
        </div>


        {/* Solar Plants Portfolio Section */}
        <div className="mb-2">
          <h2 className="text-xl font-bold text-foreground mb-2">Solar Plants Portfolio</h2>
          <div className="grid grid-cols-1 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Plants</CardTitle>
                <Grid3X3 className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {plantsCountLoading && ("Loading...")}
                  {!plantsCountLoading && plantsCountError && (<span className="text-destructive">Error</span>)}
                  {!plantsCountLoading && !plantsCountError && plantsCount !== null && (plantsCount)}
                  {!plantsCountLoading && !plantsCountError && plantsCount === null && ("—")}
                </div>
                <Badge variant="secondary" className="mt-1">
                  All Active
                </Badge>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Plant List View (overview) above map */}
        <div className="mb-6">
          <PlantListView />
        </div>
        <PlantsMap />
        <div className="py-2">
          <TimeFilter 
            value={timeFilter}
            onChange={setTimeFilter}
          />
        </div>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Sun className="h-5 w-5" />
              Plant Performance Overview
            </CardTitle>
            <CardDescription>
              Total yield and performance metrics across all your plants
            </CardDescription>
          </CardHeader>
          <CardContent>
            <PlantOverviewChart timeFilter={timeFilter} />
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default Dashboard;