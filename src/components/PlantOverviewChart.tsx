import { ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip, Legend, BarChart, Bar, LineChart, Line, ComposedChart, LabelList } from "recharts";
import { useEffect, useMemo, useState } from "react";
import { Tooltip as InfoTooltip, TooltipTrigger, TooltipContent, TooltipProvider } from "./ui/tooltip";
import { useCurrency } from "@/contexts/CurrencyContext";

type HistoryPoint = { month: string; totalYield: number | null };

type TimeFilter = {
  period: string;
  startDate: Date;
  endDate: Date;
};

const PlantOverviewChart = ({ timeFilter }: { timeFilter: TimeFilter }) => {
  const { formatAmount } = useCurrency();
  const [history, setHistory] = useState<HistoryPoint[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  
  // Summary cards removed
  const [earningsData, setEarningsData] = useState<{ date: string; dailyYield: number; totalYield: number; dailyEarningsZAR: number; totalEarningsZAR: number }[]>([]);
  const [devices, setDevices] = useState<{ label: string; value: string }[]>([]);
  const [selectedDevice, setSelectedDevice] = useState<string>("all");
  const [monthlyData, setMonthlyData] = useState<{ month: string; totalMonthlyYield: number; monthlyChange: number | null }[]>([]);
  const [monthlyLoading, setMonthlyLoading] = useState<boolean>(false);
  const [monthlyError, setMonthlyError] = useState<string | null>(null);
  const [earningsLoading, setEarningsLoading] = useState<boolean>(false);
  const [earningsError, setEarningsError] = useState<string | null>(null);
  const [monthlyEarnings, setMonthlyEarnings] = useState<{ month: string; totalMonthlyEarnings: number }[]>([]);
  const [monthlyEarningsLoading, setMonthlyEarningsLoading] = useState<boolean>(false);
  const [monthlyEarningsError, setMonthlyEarningsError] = useState<string | null>(null);
  const [avgDailyYield, setAvgDailyYield] = useState<number | null>(null);

  const monthsInRange = useMemo(() => {
    if (!timeFilter?.startDate || !timeFilter?.endDate) return 1;
    const start = timeFilter.startDate;
    const end = timeFilter.endDate;
    const startY = start.getFullYear();
    const startM = start.getMonth();
    const endY = end.getFullYear();
    const endM = end.getMonth();
    const diff = (endY - startY) * 12 + (endM - startM) + 1;
    return Math.max(1, Math.min(60, diff));
  }, [timeFilter?.startDate, timeFilter?.endDate]);

  useEffect(() => {
    const controller = new AbortController();
    const fetchHistory = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(`/api/yield/total/history?months=${monthsInRange}`, { signal: controller.signal });
        const contentType = res.headers.get("content-type") || "";
        const raw = await res.text();
  let data: Record<string, unknown> = {};
        if (contentType.includes("application/json") && raw) {
          try { data = JSON.parse(raw); } catch { /* ignore */ }
        }
        if (!res.ok || data.error) {
          throw new Error(typeof data?.error === 'string' ? data.error : `Failed with status ${res.status}`);
        }
  const mapped: HistoryPoint[] = (Array.isArray(data.history) ? data.history : []).map((p: { month: string; totalYield: number }) => ({ month: p.month, totalYield: p.totalYield }));
        setHistory(mapped);
  } catch (err) {
        if (err.name !== "AbortError") {
          setError(err.message || "Failed to load total yield history");
        }
      } finally {
        setLoading(false);
      }
    };
    fetchHistory();
    return () => controller.abort();
  }, [monthsInRange]);

  

  // Summary cards removed

  // Fetch device list for filter from backend devices endpoint
  useEffect(() => {
    if (!timeFilter?.startDate || !timeFilter?.endDate) return;
    const controller = new AbortController();
    const run = async () => {
      try {
        const start = new Date(timeFilter.startDate.getFullYear(), timeFilter.startDate.getMonth(), 1).toISOString().slice(0,10);
        const end = new Date(timeFilter.endDate.getFullYear(), timeFilter.endDate.getMonth()+1, 0).toISOString().slice(0,10);
        const url = `/api/devices?start=${start}&end=${end}`;
        const res = await fetch(url, { signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
  let data: Record<string, unknown> = {};
  if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (e) { /* ignore */ } }
  if (!res.ok || data.error) throw new Error(typeof data?.error === 'string' ? data.error : `Failed: ${res.status}`);
        const list = Array.isArray(data.devices) ? data.devices : [];
        const opts = list.map((sn: string) => ({ label: sn, value: sn }));
        setDevices([{ label: 'All Devices', value: 'all' }, ...opts]);
      } catch (e) {
        // ignore
      }
    };
    run();
    return () => controller.abort();
  }, [timeFilter?.startDate, timeFilter?.endDate]);

  // Fetch monthly yield with optional device filter
  useEffect(() => {
    if (!timeFilter?.startDate || !timeFilter?.endDate) return;
    const controller = new AbortController();
    const run = async () => {
      try {
        setMonthlyLoading(true);
        setMonthlyError(null);
        const start = new Date(timeFilter.startDate.getFullYear(), timeFilter.startDate.getMonth(), 1).toISOString().slice(0,10);
        const end = new Date(timeFilter.endDate.getFullYear(), timeFilter.endDate.getMonth()+1, 0).toISOString().slice(0,10);
  const body: { start: string; end: string; sn?: string } = { start, end };
        if (selectedDevice && selectedDevice !== 'all') body.sn = selectedDevice;
        const res = await fetch('/api/yield/monthly', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
  let data: Record<string, unknown> = {};
  if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (e) { /* ignore */ } }
  if (!res.ok || data.error) throw new Error(typeof data?.error === 'string' ? data.error : `Failed: ${res.status}`);
        const rows = Array.isArray(data.history) ? data.history : [];
  setMonthlyData(rows.map((r: { month: string; totalMonthlyYield: number; monthlyChange: number | null }) => ({ month: r.month, totalMonthlyYield: Number(r.totalMonthlyYield||0), monthlyChange: r.monthlyChange !== null && r.monthlyChange !== undefined ? Number(r.monthlyChange) : null })));
  } catch (e) {
        if (e.name !== 'AbortError') setMonthlyError(e.message || 'Failed to load monthly');
      } finally {
        setMonthlyLoading(false);
      }
    };
    run();
    return () => controller.abort();
  }, [timeFilter?.startDate, timeFilter?.endDate, selectedDevice]);

  useEffect(() => {
    if (!timeFilter?.startDate || !timeFilter?.endDate) return;
    const controller = new AbortController();
    const fetchEarnings = async () => {
      try {
        setEarningsLoading(true);
        setEarningsError(null);
        const start = timeFilter.startDate.toISOString().slice(0, 10);
        const end = timeFilter.endDate.toISOString().slice(0, 10);
        const res = await fetch('/api/earnings/history', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ start, end, rateZAR: 1.2, sn: selectedDevice !== 'all' ? selectedDevice : undefined }),
          signal: controller.signal,
        });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
  let data: Record<string, unknown> = {};
  if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (e) { /* ignore */ } }
  if (!res.ok || data.error) { throw new Error(typeof data?.error === 'string' ? data.error : `Failed with status ${res.status}`); }
        const rows = Array.isArray(data.history) ? data.history : [];
        // Ensure ascending by date so the last item is the latest
  rows.sort((a: { date: string }, b: { date: string }) => String(a.date).localeCompare(String(b.date)));
  setEarningsData(rows.map((r: { date: string; dailyYield?: number; totalYield?: number; dailyEarningsZAR?: number; totalEarningsZAR?: number }) => ({
    date: r.date,
    dailyYield: typeof r.dailyYield === 'number' ? r.dailyYield : Number(r.dailyYield || 0),
    totalYield: typeof r.totalYield === 'number' ? r.totalYield : Number(r.totalYield || 0),
    dailyEarningsZAR: typeof r.dailyEarningsZAR === 'number' ? r.dailyEarningsZAR : Number(r.dailyEarningsZAR || 0),
    totalEarningsZAR: typeof r.totalEarningsZAR === 'number' ? r.totalEarningsZAR : Number(r.totalEarningsZAR || 0),
  })));
  } catch (e) {
    if (e instanceof Error && e.name !== 'AbortError') {
      setEarningsError(e.message || 'Failed to load earnings');
    }
  } finally {
    setEarningsLoading(false);
  }
    };
    fetchEarnings();
    return () => controller.abort();
  }, [timeFilter?.startDate, timeFilter?.endDate, selectedDevice]);

  // Fetch monthly earnings with change (device optional)
  useEffect(() => {
    if (!timeFilter?.startDate || !timeFilter?.endDate) return;
    const controller = new AbortController();
    const run = async () => {
      try {
        setMonthlyEarningsLoading(true);
        setMonthlyEarningsError(null);
        const start = new Date(timeFilter.startDate.getFullYear(), timeFilter.startDate.getMonth(), 1).toISOString().slice(0,10);
        const end = new Date(timeFilter.endDate.getFullYear(), timeFilter.endDate.getMonth()+1, 0).toISOString().slice(0,10);
  const body: { start: string; end: string; rateZAR: number; sn?: string } = { start, end, rateZAR: 1.2 };
        if (selectedDevice && selectedDevice !== 'all') body.sn = selectedDevice;
        const res = await fetch('/api/earnings/monthly/change', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
  let data: Record<string, unknown> = {};
  if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (e) { /* ignore */ } }
  if (!res.ok || data.error) throw new Error(typeof data?.error === 'string' ? data.error : `Failed: ${res.status}`);
        const rows = Array.isArray(data.history) ? data.history : [];
        // Filter for selected device if present, otherwise if multiple devices exist, sum by month
        const map: Record<string, number> = {};
        for (const r of rows) {
          const key = `${r.year}-${String(r.month).padStart(2,'0')}`;
          const val = Number(r.totalMonthlyEarnings || 0);
          map[key] = (map[key] || 0) + val;
        }
        const sorted = Object.entries(map).sort(([a],[b]) => a.localeCompare(b)).map(([month, totalMonthlyEarnings]) => ({ month, totalMonthlyEarnings }));
        setMonthlyEarnings(sorted);
      } catch (e) {
        if (e instanceof Error && e.name !== 'AbortError') setMonthlyEarningsError(e.message || 'Failed to load monthly earnings');
      } finally {
        setMonthlyEarningsLoading(false);
      }
    };
    run();
    return () => controller.abort();
  }, [timeFilter?.startDate, timeFilter?.endDate, selectedDevice]);

  // Fetch avg daily yield once on mount
  useEffect(() => {
    const controller = new AbortController();
    const fetchAvg = async () => {
      try {
        const res = await fetch('/api/yield/average', { signal: controller.signal });
        const ct = res.headers.get('content-type') || '';
        const raw = await res.text();
  let data: Record<string, unknown> = {};
  if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch (e) { /* ignore */ } }
  if (!res.ok || data.error) throw new Error(typeof data?.error === 'string' ? data.error : `Failed: ${res.status}`);
        setAvgDailyYield(typeof data.avg_daily_yield === 'number' ? data.avg_daily_yield : null);
  } catch (e) { /* ignore */ }
    };
    fetchAvg();
    return () => controller.abort();
  }, []);

  // Compute expected yield per day for the selected month
  const expectedYieldDailyData = useMemo(() => {
    if (!avgDailyYield || earningsData.length === 0) return [];
    return earningsData.map((d) => ({
      date: d.date,
      actual: d.dailyYield,
      expected: avgDailyYield,
    }));
  }, [avgDailyYield, earningsData]);

  return (
    <TooltipProvider>
      {/* Removed Total Yield Trend (kWh) chart per request */}

      {/* Earnings Charts */}
      <div className="space-y-10">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold">Earnings & Yields</h3>
          <div className="flex items-center gap-2 text-sm">
            <label className="text-muted-foreground">Device:</label>
            <select className="bg-background border rounded px-2 py-1" value={selectedDevice} onChange={(e) => setSelectedDevice(e.target.value)}>
              {devices.map((d) => (
                <option key={d.value} value={d.value}>{d.label}</option>
              ))}
            </select>
          </div>
        </div>
      <div className="h-96">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold">Daily Yield vs Earnings</h3>
          <InfoTooltip>
            <TooltipTrigger asChild>
              <button className="ml-2 text-muted-foreground hover:text-foreground" aria-label="Info">
                <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/><text x="12" y="16" textAnchor="middle" fontSize="12" fill="currentColor">i</text></svg>
              </button>
            </TooltipTrigger>
            <TooltipContent side="left" className="max-w-xs">
              Shows daily yield (kWh) and daily earnings for each day in the selected range. Yield is measured from inverter data; earnings are calculated using the configured exchange rate.
            </TooltipContent>
          </InfoTooltip>
        </div>
          {earningsLoading ? (
          <div className="h-full flex items-center justify-center text-sm text-muted-foreground">Loading…</div>
          ) : earningsError ? (
            <div className="h-full flex items-center justify-center text-sm text-destructive">{earningsError}</div>
          ) : earningsData.length === 0 ? (
          <div className="h-full flex items-center justify-center text-sm text-muted-foreground">No data</div>
        ) : (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={earningsData} margin={{ top: 40, right: 20, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis dataKey="date" className="text-muted-foreground text-xs" label={{ value: 'TIME', position: 'insideBottom', offset: -4 }} />
              <YAxis 
                yAxisId="yield"
              className="text-muted-foreground text-xs"
                tickFormatter={(v) => `${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
                label={{ value: 'Yield (kWh)', angle: -90, position: 'insideLeft' }}
            />
            <YAxis 
                yAxisId="earning" 
                orientation="right" 
              className="text-muted-foreground text-xs"
                tickFormatter={(v) => formatAmount(Number(v))}
                label={{ value: 'Earnings', angle: -90, position: 'insideRight' }}
            />
            <Tooltip 
                contentStyle={{ backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))', borderRadius: '8px' }}
                labelStyle={{ color: 'hsl(var(--foreground))' }}
                formatter={(value, name) => {
                  const n = String(name);
                  if (n.includes('Earnings')) return [formatAmount(Number(value)), n];
                  return [`${Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} kWh`, n];
                }}
              />
              <Legend />
              <Bar yAxisId="yield" dataKey="dailyYield" name="dailyYield" fill="#1f77b4" barSize={18} radius={[3,3,0,0]}>
                <LabelList
                  dataKey="dailyYield"
                  position="top"
                  content={({ x, y, width, value, index }) => {
                    if (value == null) return null;
                    // Stagger labels for even/odd bars
                    const yOffset = index % 2 === 0 ? -8 : -24;
                    return (
                      <g>
                        <rect
                          x={typeof x === 'number' && typeof width === 'number' ? x + width / 2 - 22 : 0}
                          y={typeof y === 'number' && typeof yOffset === 'number' ? y + yOffset - 10 : 0}
                          width={44}
                          height={18}
                          rx={4}
                          fill="#fff"
                          stroke="#1f77b4"
                          strokeWidth={0.5}
                          opacity={0.85}
                        />
                        <text
                          x={typeof x === 'number' && typeof width === 'number' ? x + width / 2 : 0}
                          y={typeof y === 'number' && typeof yOffset === 'number' ? y + yOffset + 2 : 0}
                          textAnchor="middle"
                          fontSize={12}
                          fontWeight={600}
                          fill="#1f77b4"
                          style={{ pointerEvents: 'none' }}
                        >
                          {Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </text>
                      </g>
                    );
                  }}
                />
              </Bar>
              <Bar yAxisId="earning" dataKey="dailyEarningsZAR" name="Earnings" fill="#d62728" barSize={18} radius={[3,3,0,0]}>
                <LabelList
                  dataKey="dailyEarningsZAR"
                  position="top"
                  content={({ x, y, width, value, index }) => {
                    if (value == null) return null;
                    // Stagger labels for even/odd bars
                    const yOffset = index % 2 === 0 ? -24 : -8;
                    return (
                      <g>
                        <rect
                          x={typeof x === 'number' && typeof width === 'number' ? x + width / 2 - 28 : 0}
                          y={typeof y === 'number' && typeof yOffset === 'number' ? y + yOffset - 10 : 0}
                          width={56}
                          height={18}
                          rx={4}
                          fill="#fff"
                          stroke="#d62728"
                          strokeWidth={0.5}
                          opacity={0.85}
                        />
                        <text
                          x={typeof x === 'number' && typeof width === 'number' ? x + width / 2 : 0}
                          y={typeof y === 'number' && typeof yOffset === 'number' ? y + yOffset + 2 : 0}
                          textAnchor="middle"
                          fontSize={12}
                          fontWeight={600}
                          fill="#d62728"
                          style={{ pointerEvents: 'none' }}
                        >
                          {formatAmount(Number(value))}
                        </text>
                      </g>
                    );
                  }}
                />
              </Bar>
            </BarChart>
        </ResponsiveContainer>
        )}
      </div>

      {/* Standalone Daily Yield Graph */}
  <div className="h-96 mt-14">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-lg font-semibold">Daily Yield</h3>
          <InfoTooltip>
            <TooltipTrigger asChild>
              <button className="ml-2 text-muted-foreground hover:text-foreground" aria-label="Info">
                <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/><text x="12" y="16" textAnchor="middle" fontSize="12" fill="currentColor">i</text></svg>
              </button>
            </TooltipTrigger>
            <TooltipContent side="left" className="max-w-xs">
              Shows the daily yield (kWh) for each day in the selected range, as measured from inverter data.
            </TooltipContent>
          </InfoTooltip>
        </div>
        {earningsData.length > 0 && (
          <div className="text-xs text-muted-foreground mb-3">Latest daily yield: {Number(earningsData[earningsData.length - 1].dailyYield).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} kWh</div>
        )}
        {earningsLoading ? (
          <div className="h-full flex items-center justify-center text-sm text-muted-foreground">Loading…</div>
        ) : earningsError ? (
          <div className="h-full flex items-center justify-center text-sm text-destructive">{earningsError}</div>
        ) : earningsData.length === 0 ? (
          <div className="h-full flex items-center justify-center text-sm text-muted-foreground">No data</div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={earningsData.map(d => ({ date: d.date, dailyYield: d.dailyYield }))} margin={{ top: 50, right: 20, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="date" className="text-muted-foreground text-xs" label={{ value: 'TIME', position: 'insideBottom', offset: -4 }} />
                <YAxis 
                  className="text-muted-foreground text-xs"
                  tickFormatter={(v) => `${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
                  label={{ value: 'Yield (kWh)', angle: -90, position: 'insideLeft' }}
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))', borderRadius: '8px' }}
                  labelStyle={{ color: 'hsl(var(--foreground))' }}
                  formatter={(value, name) => [`${Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} kWh`, String(name)]}
                />
                <Legend />
                <Bar dataKey="dailyYield" name="Daily Yield" fill="#1f77b4" barSize={28} radius={[3,3,0,0]}>
                  <LabelList
                    dataKey="dailyYield"
                    position="top"
                    content={({ x, y, width, value }) => {
                      if (value == null || typeof x !== 'number' || typeof y !== 'number' || typeof width !== 'number') return null;
                      return (
                        <g>
                          <rect
                            x={x + width / 2 - 28}
                            y={y - 28}
                            width={56}
                            height={24}
                            rx={6}
                            fill="#fff"
                            stroke="#1f77b4"
                            strokeWidth={1}
                            opacity={0.95}
                          />
                          <text
                            x={x + width / 2}
                            y={y - 12}
                            textAnchor="middle"
                            fontSize={16}
                            fontWeight={700}
                            fill="#1f77b4"
                            style={{ pointerEvents: 'none' }}
                          >
                            {Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                          </text>
                        </g>
                      );
                    }}
                  />
                </Bar>
              </BarChart>
          </ResponsiveContainer>
        )}
      </div>

        <div className="h-96 mt-8">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-lg font-semibold">Actual vs Expected Yield (Daily, This Month)</h3>
            <InfoTooltip>
              <TooltipTrigger asChild>
                <button className="ml-2 text-muted-foreground hover:text-foreground" aria-label="Info">
                  <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/><text x="12" y="16" textAnchor="middle" fontSize="12" fill="currentColor">i</text></svg>
                </button>
              </TooltipTrigger>
              <TooltipContent side="left" className="max-w-xs">
                Compares actual daily yield (from inverter data) to expected yield (average daily yield, calculated from historical data) for each day of the selected month.
              </TooltipContent>
            </InfoTooltip>
          </div>
          {earningsLoading || avgDailyYield === null ? (
            <div className="h-full flex items-center justify-center text-muted-foreground">Loading…</div>
          ) : earningsError ? (
            <div className="h-full flex items-center justify-center text-destructive">{earningsError}</div>
          ) : expectedYieldDailyData.length === 0 ? (
            <div className="h-full flex items-center justify-center text-muted-foreground">No data</div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={expectedYieldDailyData} margin={{ top: 20, right: 30, left: 0, bottom: 10 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" fontSize={12} />
                <YAxis fontSize={12} tickFormatter={v => `${Number(v).toLocaleString(undefined, { maximumFractionDigits: 2 })} kWh`} />
                <Tooltip formatter={(v: number) => `${Number(v).toLocaleString(undefined, { maximumFractionDigits: 2 })} kWh`} />
                <Legend />
                <Bar dataKey="actual" name="Actual Yield" fill="#1f77b4" barSize={12} radius={[3,3,0,0]} />
                <Line type="monotone" dataKey="expected" name="Expected Yield" stroke="#fbbf24" strokeWidth={3} dot={false} />
              </ComposedChart>
            </ResponsiveContainer>
          )}
        </div>

      {/* Monthly Yield + Trend and Monthly Earnings graphs hidden as requested */}
      </div>
    </TooltipProvider>
  );
}

export default PlantOverviewChart;