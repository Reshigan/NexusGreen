import { useEffect, useMemo, useState } from "react";
import { ResponsiveContainer, BarChart, Bar, CartesianGrid, XAxis, YAxis, Tooltip } from "recharts";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { MapPin, TrendingUp, Eye, Search, Download } from "lucide-react";

type PlantRow = {
  id?: string | number;
  name: string;
  location: string;
  city: string;
  sn: string;
  status: string;
  totalYield: number | null;
  dailyYield: number | null;
  performance: number | null;
  manufacturer: string;
  capacity?: string;
  lastUpdate?: string | null;
};

type EarningsHistoryRow = { date: string; dailyYield: number; totalYield: number; dailyEarningsZAR: number; totalEarningsZAR: number; deviceSn?: string };

const PlantListView = () => {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState("");
  const [plants, setPlants] = useState<PlantRow[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [combinedYield, setCombinedYield] = useState<number | null>(null);
  const [earningsHistory, setEarningsHistory] = useState<EarningsHistoryRow[]>([]);
  const [earningsLoading, setEarningsLoading] = useState<boolean>(false);
  const [earningsError, setEarningsError] = useState<string | null>(null);
  // Manufacturer filter state (must be at top level)
  const [manufacturerFilter, setManufacturerFilter] = useState<string>("");

  // Fetch plants
  useEffect(() => {
    const controller = new AbortController();
    const fetchPlants = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(`/api/plants/summary?limit=500&offset=0`, { signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
        let data: unknown = {};
        if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (err) { /* ignore */ } }
        if (typeof data === 'object' && data !== null && 'error' in data) throw new Error((data as { error?: string })?.error || `Failed with status ${res.status}`);
        const rows: PlantRow[] = Array.isArray((data as { plants?: unknown[] }).plants)
          ? ((data as { plants: any[] }).plants).map((p, idx: number) => ({
              id: p.customerId ?? idx,
              name: p.name,
              location: p.location,
              city: p.city,
              sn: p.serialNumber,
              status: p.status || 'Unknown',
              totalYield: p.totalYield ?? null,
              dailyYield: p.dailyYield ?? null,
              performance: p.performance ?? null,
              manufacturer: p.manufacturer || 'Unknown',
              lastUpdate: p.lastUpdate ?? null
            }))
          : [];
        setPlants(rows);
        setLoading(false);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to fetch plants');
        setLoading(false);
      }
    };
    fetchPlants();
    return () => controller.abort();
  }, []);

  // Calculate total earnings per site (by device) and combined
  const earningsByDevice: Record<string, number> = useMemo(() => {
    const byDevice: Record<string, number> = {};
    for (const row of earningsHistory) {
      if (row.deviceSn) {
        byDevice[row.deviceSn] = (byDevice[row.deviceSn] || 0) + (row.dailyEarningsZAR || 0);
      }
    }
    return byDevice;
  }, [earningsHistory]);

  const combinedEarnings = useMemo(() => {
    return earningsHistory.reduce((sum, row) => sum + (row.dailyEarningsZAR || 0), 0);
  }, [earningsHistory]);

  // Fetch latest combined totalYield from backend
  useEffect(() => {
    const controller = new AbortController();
    const fetchCombinedYield = async () => {
      try {
        const res = await fetch('/api/yield/total', { signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
        let data: unknown = {};
        if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (err) { /* ignore */ } }
        if (typeof data === 'object' && data !== null && 'error' in data) throw new Error((data as { error?: string })?.error || `Failed with status ${res.status}`);
        setCombinedYield(typeof (data as { total_yield?: number }).total_yield === 'number' ? (data as { total_yield: number }).total_yield : null);
      } catch (e) {
        setCombinedYield(null);
      }
    };
    fetchCombinedYield();
    return () => controller.abort();
  }, []);

  const filteredPlants = useMemo(() => {
    const term = searchTerm.toLowerCase();
    return plants.filter(plant =>
      (manufacturerFilter === "" || plant.manufacturer === manufacturerFilter) &&
      (
        plant.name?.toLowerCase().includes(term) ||
        plant.location?.toLowerCase().includes(term) ||
        plant.city?.toLowerCase().includes(term) ||
        plant.sn?.toLowerCase().includes(term)
      )
    );
  }, [plants, searchTerm, manufacturerFilter]);
  const uniqueManufacturers = useMemo(() => {
    const set = new Set<string>();
    plants.forEach(p => set.add(p.manufacturer));
    return Array.from(set);
  }, [plants]);

  const handleSearch = (term: string) => {
    setSearchTerm(term);
  };

  const handleViewPlant = (plantId: string | number | undefined) => {
    if (!plantId) return;
    navigate(`/plant/${plantId}`);
  };

  const handleExportCSV = () => {
    const headers = ["Name","Location","City","Serial Number","Status","Total Yield (kWh)","Daily Yield (kWh)","Performance (%)","Last Update"];
    const rows = filteredPlants.map(p => [
      p.name ?? '',
      p.location ?? '',
      p.city ?? '',
      p.sn ?? '',
      p.status ?? '',
      p.totalYield ?? '',
      p.dailyYield ?? '',
      p.performance ?? '',
      p.lastUpdate ?? '',
    ]);
    const csv = [headers, ...rows]
      .map(r => r.map(c => `"${String(c).replace(/"/g,'""')}"`).join(","))
      .join("\n");
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url; link.setAttribute('download', 'plants_summary.csv');
    document.body.appendChild(link); link.click(); document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <CardTitle>Solar Plants Portfolio</CardTitle>
            <div className="flex items-center gap-2">
              <select
                className="border rounded px-2 py-1 text-sm"
                value={manufacturerFilter}
                onChange={e => setManufacturerFilter(e.target.value)}
              >
                <option value="">All Manufacturers</option>
                {uniqueManufacturers.map(m => (
                  <option key={m} value={m}>{m}</option>
                ))}
              </select>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search plants..."
                  value={searchTerm}
                  onChange={(e) => handleSearch(e.target.value)}
                  className="pl-9 w-64"
                />
              </div>
              <Button 
                variant="outline" 
                size="sm"
                onClick={handleExportCSV}
              >
                <Download className="h-4 w-4 mr-2" />
                Export CSV
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Plant Name</TableHead>
                  <TableHead>Manufacturer</TableHead>
                  <TableHead>Location</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Total Yield</TableHead>
                  <TableHead>Daily Yield</TableHead>
                  <TableHead>Performance</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading && (
                  <TableRow><TableCell colSpan={7}>Loading...</TableCell></TableRow>
                )}
                {error && !loading && (
                  <TableRow><TableCell colSpan={7} className="text-destructive">{error}</TableCell></TableRow>
                )}
                {!loading && !error && filteredPlants.map((plant) => (
                  <TableRow key={plant.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium">{plant.name}</div>
                        <div className="text-sm text-muted-foreground">{plant.sn}</div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">{plant.manufacturer}</div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <MapPin className="h-3 w-3 text-muted-foreground" />
                        <div className="text-sm">
                          <div>{plant.city}</div>
                          <div className="text-muted-foreground">{plant.location}</div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge 
                        variant={plant.status === "Active" ? "default" : "secondary"}
                      >
                        {plant.status}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="font-medium">
                        {plant.totalYield !== null ? `${Number(plant.totalYield).toLocaleString()} kWh` : '—'}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="font-medium">
                        {plant.dailyYield !== null ? `${plant.dailyYield} kWh` : '—'}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <span 
                          className={`font-medium ${
                            plant.performance && plant.performance >= 95 
                              ? "text-success" 
                              : plant.performance && plant.performance >= 90 
                              ? "text-warning" 
                              : "text-destructive"
                          }`}
                        >
                          {plant.performance !== null ? `${plant.performance.toFixed(1)}%` : '—'}
                        </span>
                        {plant.performance && plant.performance >= 95 && (
                          <TrendingUp className="h-4 w-4 text-success" />
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => handleViewPlant(plant.id)}
                      >
                        <Eye className="h-4 w-4 mr-2" />
                        View Details
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          
          {filteredPlants.length === 0 && (
            <div className="text-center py-8 text-muted-foreground">
              No plants found matching your search criteria.
            </div>
          )}
        </CardContent>
      </Card>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {filteredPlants.length}
            </div>
            <p className="text-xs text-muted-foreground">Total Plants</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-success">
              {filteredPlants.filter(p => p.status === "Active").length}
            </div>
            <p className="text-xs text-muted-foreground">Active Plants</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-accent">
              {combinedYield !== null ? combinedYield.toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 }) : '—'} kWh
            </div>
            <p className="text-xs text-muted-foreground">Combined Yield</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-warning">
              {(filteredPlants.reduce((sum, plant) => sum + (plant.performance ?? 0), 0) / (filteredPlants.length || 1)).toFixed(1)}%
            </div>
            <p className="text-xs text-muted-foreground">Avg Performance</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold text-primary">
              {earningsLoading ? '…' : `R${combinedEarnings.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
            </div>
            <p className="text-xs text-muted-foreground">Combined Earnings (30d)</p>
          </CardContent>
        </Card>
      </div>

      {/* Earnings per day graph */}
      <div className="mt-8">
        <Card>
          <CardHeader>
            <CardTitle>Daily Earnings (Last 30 Days)</CardTitle>
          </CardHeader>
          <CardContent>
            {earningsLoading ? (
              <div className="h-48 flex items-center justify-center text-muted-foreground">Loading…</div>
            ) : earningsError ? (
              <div className="h-48 flex items-center justify-center text-destructive">{earningsError}</div>
            ) : earningsHistory.length === 0 ? (
              <div className="h-48 flex items-center justify-center text-muted-foreground">No data</div>
            ) : (
              <div style={{ width: '100%', height: 320 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={earningsHistory.map(d => ({ date: d.date, dailyEarningsZAR: d.dailyEarningsZAR }))}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" fontSize={12} angle={-45} textAnchor="end" height={60} />
                    <YAxis fontSize={12} tickFormatter={v => `R${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
                    <Tooltip formatter={(v: number) => `R${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} />
                    <Bar dataKey="dailyEarningsZAR" name="Daily Earnings" fill="#fbbf24" barSize={18} radius={[3,3,0,0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default PlantListView;