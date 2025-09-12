import { useEffect, useMemo, useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MapContainer, TileLayer, Marker, Popup, Tooltip, useMap } from "react-leaflet";
import L from "leaflet";

// Fix default marker icons path issues in Vite
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

const DefaultIcon = L.icon({
	iconRetinaUrl: markerIcon2x,
	iconUrl: markerIcon,
	shadowUrl: markerShadow,
	iconSize: [25, 41],
	iconAnchor: [12, 41],
	popupAnchor: [1, -34],
	shadowSize: [41, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

type Plant = {
	id?: string | number;
	name?: string;
	city?: string;
	location?: string;
	latitude?: number | null;
	longitude?: number | null;
	sn?: string | number | null;
	lastUpdate?: string | null;
};

const PlantsMap = () => {
	const [plants, setPlants] = useState<Plant[]>([]);
	const [loading, setLoading] = useState<boolean>(false);
	const [error, setError] = useState<string | null>(null);

	// polling for live updates
	const POLL_MS = 30000;

	// simple geocode cache in localStorage to resolve location/city to coords (South Africa only)
	const geocodeCacheRef = useRef<Record<string, { lat: number; lon: number }>>({});
	useEffect(() => {
		try {
			const raw = localStorage.getItem('plant_geocode_cache_v1');
			geocodeCacheRef.current = raw ? JSON.parse(raw) : {};
		} catch {
			geocodeCacheRef.current = {};
		}
	}, []);

	const saveGeocodeCache = () => {
		try { localStorage.setItem('plant_geocode_cache_v1', JSON.stringify(geocodeCacheRef.current)); } catch {}
	};

	const geocodeSA = async (query: string): Promise<{ lat: number; lon: number } | null> => {
		const key = query.trim().toLowerCase();
		if (geocodeCacheRef.current[key]) return geocodeCacheRef.current[key];
		const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=za&q=${encodeURIComponent(query)}`;
		try {
			const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
			if (!res.ok) return null;
			const arr: any[] = await res.json();
			if (!Array.isArray(arr) || arr.length === 0) return null;
			const first = arr[0];
			const lat = Number(first.lat), lon = Number(first.lon);
			if (Number.isFinite(lat) && Number.isFinite(lon)) {
				geocodeCacheRef.current[key] = { lat, lon };
				saveGeocodeCache();
				return { lat, lon };
			}
			return null;
		} catch {
			return null;
		}
	};

	useEffect(() => {
		const controller = new AbortController();
		const fetchPlants = async () => {
			try {
				setLoading(true);
				setError(null);
				const res = await fetch(`/api/plants/summary?limit=500&offset=0`, { signal: controller.signal });
				const ct = res.headers.get('content-type') || '';
				const raw = await res.text();
				let data: any = {};
				if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch {} }
				if (!res.ok || data.error) throw new Error(data?.error || `Failed with status ${res.status}`);
				const rows: Plant[] = (data.plants || []).map((p: any, idx: number) => ({
					id: p.customerId ?? idx,
					name: p.name,
					city: p.city,
					location: p.location,
					latitude: p.latitude ?? p.lat ?? null,
					longitude: p.longitude ?? p.lng ?? p.lon ?? null,
					sn: p.serialNumber ?? p.sn ?? null,
					lastUpdate: p.lastUpdate ?? null,
				}));
				// For plants missing coords, try geocoding using location/city in South Africa
				const needsGeocode = rows.filter(r => (r.latitude == null || r.longitude == null) && (r.location || r.city));
				const limited = needsGeocode.slice(0, 10);
				const geocoded = await Promise.all(limited.map(async (r) => {
					const query = [r.location, r.city, 'South Africa'].filter(Boolean).join(', ');
					const geo = query ? await geocodeSA(query) : null;
					if (geo) return { ...r, latitude: geo.lat, longitude: geo.lon } as Plant;
					return r;
				}));
				const merged = rows.map(r => geocoded.find(g => g.id === r.id) || r);
				setPlants(merged);
			} catch (e: any) {
				if (e.name !== 'AbortError') setError(e.message || 'Failed to load plants');
			} finally {
				setLoading(false);
			}
		};
		fetchPlants();

		const id = setInterval(() => {
			fetchPlants();
		}, POLL_MS);

		return () => {
			controller.abort();
			clearInterval(id);
		};
	}, []);

	const isInSouthAfrica = (lat: number, lon: number) => lat >= -35 && lat <= -22 && lon >= 16 && lon <= 33.9;

	const coords = useMemo(() => {
		const pts = plants.filter(p => typeof p.latitude === 'number' && typeof p.longitude === 'number') as Required<Pick<Plant, 'latitude' | 'longitude'>>[] & Plant[];
		const filtered = (pts as Plant[]).filter(p => isInSouthAfrica(p.latitude as number, p.longitude as number));
		return filtered as Plant[];
	}, [plants]);

	const center = useMemo<[number, number]>(() => {
		if (coords.length > 0) return [coords[0].latitude as number, coords[0].longitude as number];
		return [-28.4793, 24.6727]; // South Africa center-ish fallback
	}, [coords]);

	const FitBounds = () => {
		const map = useMap();
		useEffect(() => {
			if (coords.length === 0) return;
			const bounds = L.latLngBounds(coords.map(p => [p.latitude as number, p.longitude as number] as [number, number]));
			map.fitBounds(bounds.pad(0.2), { animate: true });
		}, [map, coords]);
		return null;
	};

	return (
		<Card>
			<CardHeader>
				<CardTitle>Live Plants Map</CardTitle>
			</CardHeader>
			<CardContent>
				<div className="h-80 w-full rounded-md overflow-hidden border">
					{loading && <div className="h-full flex items-center justify-center text-sm text-muted-foreground">Loading…</div>}
					{error && !loading && <div className="h-full flex items-center justify-center text-sm text-destructive">{error}</div>}
					{!loading && !error && (
						<MapContainer center={center} zoom={6} className="h-full w-full">
							<FitBounds />
							<TileLayer
								attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
								url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
							/>
							{coords.map((p) => (
								<Marker key={String(p.id)} position={[p.latitude as number, p.longitude as number]}>
									<Tooltip direction="top" offset={[0, -10]}>{p.sn ? `SN: ${p.sn}` : (p.name || `Plant ${String(p.id)}`)}</Tooltip>
									<Popup>
										<div className="space-y-1">
											<div className="font-medium">{p.name || 'Plant'}</div>
											<div className="text-xs text-muted-foreground">{p.location || p.city || ''}</div>
											{p.sn && (
												<div className="text-[10px]">Identifier: {String(p.sn)}</div>
											)}
											{p.lastUpdate && (
												<div className="text-[10px] text-muted-foreground">Last update: {p.lastUpdate}</div>
											)}
										</div>
									</Popup>
								</Marker>
							))}
						</MapContainer>
					)}
				</div>
			</CardContent>
		</Card>
	);
};

export default PlantsMap;
