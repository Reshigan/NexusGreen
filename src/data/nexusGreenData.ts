// NexusGreen Comprehensive Data Service
// Realistic seeded data for solar energy management platform

export interface Organization {
  id: string;
  name: string;
  type: 'installer' | 'oem' | 'asset_owner' | 'end_customer';
  logo?: string;
  address: string;
  country: string;
  timezone: string;
  created_at: string;
  subscription_tier: 'basic' | 'professional' | 'enterprise';
  total_capacity: number; // kW
  total_sites: number;
  monthly_revenue: number; // USD
}

export interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: 'super_admin' | 'admin' | 'manager' | 'operator' | 'viewer';
  organization_id: string;
  avatar?: string;
  last_login: string;
  is_active: boolean;
  permissions: string[];
}

export interface Site {
  id: string;
  name: string;
  organization_id: string;
  location: {
    lat: number;
    lng: number;
    address: string;
    city: string;
    country: string;
  };
  capacity: number; // kW
  installation_date: string;
  system_type: 'grid_tied' | 'off_grid' | 'hybrid';
  panel_count: number;
  inverter_type: string;
  status: 'active' | 'maintenance' | 'offline' | 'fault';
  performance_ratio: number; // %
  monthly_generation: number; // kWh
  total_generation: number; // kWh lifetime
  co2_saved: number; // kg
  revenue_today: number; // USD
  revenue_monthly: number; // USD
  revenue_total: number; // USD
  weather_condition: 'sunny' | 'cloudy' | 'rainy' | 'snowy';
  temperature: number; // °C
  irradiance: number; // W/m²
  alerts: Alert[];
}

export interface Alert {
  id: string;
  site_id: string;
  type: 'performance' | 'maintenance' | 'fault' | 'weather' | 'security';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  created_at: string;
  resolved_at?: string;
  is_resolved: boolean;
}

export interface EnergyData {
  timestamp: string;
  site_id: string;
  generation: number; // kW
  consumption?: number; // kW
  grid_export?: number; // kW
  grid_import?: number; // kW
  battery_level?: number; // %
  battery_charge?: number; // kW
  battery_discharge?: number; // kW
  irradiance: number; // W/m²
  temperature: number; // °C
  wind_speed?: number; // m/s
}

export interface FinancialData {
  site_id: string;
  date: string;
  revenue: number; // USD
  savings: number; // USD
  tariff_rate: number; // USD/kWh
  feed_in_tariff: number; // USD/kWh
  grid_cost_avoided: number; // USD
  maintenance_cost: number; // USD
  roi_percentage: number; // %
}

export interface PredictiveAnalytics {
  site_id: string;
  forecast_date: string;
  predicted_generation: number; // kWh
  confidence_level: number; // %
  weather_forecast: string;
  maintenance_recommendation: string;
  performance_trend: 'improving' | 'stable' | 'declining';
  expected_revenue: number; // USD
}

// Seeded Organizations
export const organizations: Organization[] = [
  {
    id: 'org-1',
    name: 'GonXT Solar Solutions',
    type: 'installer',
    logo: '/gonxt-logo.jpeg',
    address: '123 Solar Street, Cape Town, South Africa',
    country: 'South Africa',
    timezone: 'Africa/Johannesburg',
    created_at: '2023-01-15T08:00:00Z',
    subscription_tier: 'enterprise',
    total_capacity: 2850.5,
    total_sites: 12,
    monthly_revenue: 125680
  },
  {
    id: 'org-2',
    name: 'SunPower Africa',
    type: 'installer',
    address: '456 Energy Avenue, Johannesburg, South Africa',
    country: 'South Africa',
    timezone: 'Africa/Johannesburg',
    created_at: '2023-03-20T10:30:00Z',
    subscription_tier: 'professional',
    total_capacity: 1650.2,
    total_sites: 8,
    monthly_revenue: 78450
  },
  {
    id: 'org-3',
    name: 'Green Energy Investments',
    type: 'asset_owner',
    address: '789 Investment Plaza, Durban, South Africa',
    country: 'South Africa',
    timezone: 'Africa/Johannesburg',
    created_at: '2023-02-10T14:15:00Z',
    subscription_tier: 'enterprise',
    total_capacity: 5200.8,
    total_sites: 25,
    monthly_revenue: 285600
  },
  {
    id: 'org-4',
    name: 'Residential Solar Co-op',
    type: 'end_customer',
    address: '321 Community Center, Pretoria, South Africa',
    country: 'South Africa',
    timezone: 'Africa/Johannesburg',
    created_at: '2023-04-05T09:45:00Z',
    subscription_tier: 'basic',
    total_capacity: 450.3,
    total_sites: 15,
    monthly_revenue: 18750
  }
];

// Seeded Users
export const users: User[] = [
  {
    id: 'user-1',
    email: 'admin@gonxt.tech',
    first_name: 'John',
    last_name: 'Administrator',
    role: 'super_admin',
    organization_id: 'org-1',
    avatar: '/avatars/admin.jpg',
    last_login: '2024-12-14T08:30:00Z',
    is_active: true,
    permissions: ['all']
  },
  {
    id: 'user-2',
    email: 'manager@gonxt.tech',
    first_name: 'Sarah',
    last_name: 'Manager',
    role: 'manager',
    organization_id: 'org-1',
    avatar: '/avatars/manager.jpg',
    last_login: '2024-12-14T07:45:00Z',
    is_active: true,
    permissions: ['view_sites', 'manage_sites', 'view_analytics', 'generate_reports']
  },
  {
    id: 'user-3',
    email: 'operator@gonxt.tech',
    first_name: 'Mike',
    last_name: 'Operator',
    role: 'operator',
    organization_id: 'org-1',
    avatar: '/avatars/operator.jpg',
    last_login: '2024-12-14T06:20:00Z',
    is_active: true,
    permissions: ['view_sites', 'view_analytics', 'manage_alerts']
  },
  {
    id: 'user-4',
    email: 'demo@nexusgreen.com',
    first_name: 'Demo',
    last_name: 'User',
    role: 'viewer',
    organization_id: 'org-1',
    avatar: '/avatars/demo.jpg',
    last_login: '2024-12-14T09:15:00Z',
    is_active: true,
    permissions: ['view_sites', 'view_analytics']
  }
];

// Seeded Sites with realistic South African locations
export const sites: Site[] = [
  {
    id: 'site-1',
    name: 'Cape Town Corporate Campus',
    organization_id: 'org-1',
    location: {
      lat: -33.9249,
      lng: 18.4241,
      address: '123 Business Park Drive',
      city: 'Cape Town',
      country: 'South Africa'
    },
    capacity: 500.0,
    installation_date: '2023-06-15',
    system_type: 'grid_tied',
    panel_count: 1250,
    inverter_type: 'SMA Sunny Tripower',
    status: 'active',
    performance_ratio: 94.2,
    monthly_generation: 65000,
    total_generation: 485000,
    co2_saved: 342500,
    revenue_today: 2850,
    revenue_monthly: 78500,
    revenue_total: 485000,
    weather_condition: 'sunny',
    temperature: 24,
    irradiance: 850,
    alerts: []
  },
  {
    id: 'site-2',
    name: 'Johannesburg Manufacturing Plant',
    organization_id: 'org-1',
    location: {
      lat: -26.2041,
      lng: 28.0473,
      address: '456 Industrial Avenue',
      city: 'Johannesburg',
      country: 'South Africa'
    },
    capacity: 750.5,
    installation_date: '2023-04-20',
    system_type: 'hybrid',
    panel_count: 1876,
    inverter_type: 'Fronius Symo Hybrid',
    status: 'active',
    performance_ratio: 91.8,
    monthly_generation: 89500,
    total_generation: 625000,
    co2_saved: 437500,
    revenue_today: 3950,
    revenue_monthly: 98750,
    revenue_total: 625000,
    weather_condition: 'cloudy',
    temperature: 22,
    irradiance: 650,
    alerts: [
      {
        id: 'alert-1',
        site_id: 'site-2',
        type: 'performance',
        severity: 'medium',
        title: 'Performance Below Expected',
        description: 'Site performance is 5% below expected due to cloudy conditions',
        created_at: '2024-12-14T08:15:00Z',
        is_resolved: false
      }
    ]
  },
  {
    id: 'site-3',
    name: 'Durban Logistics Center',
    organization_id: 'org-1',
    location: {
      lat: -29.8587,
      lng: 31.0218,
      address: '789 Port Road',
      city: 'Durban',
      country: 'South Africa'
    },
    capacity: 425.8,
    installation_date: '2023-08-10',
    system_type: 'grid_tied',
    panel_count: 1064,
    inverter_type: 'Huawei SUN2000',
    status: 'active',
    performance_ratio: 96.5,
    monthly_generation: 58500,
    total_generation: 285000,
    co2_saved: 199500,
    revenue_today: 2650,
    revenue_monthly: 68500,
    revenue_total: 285000,
    weather_condition: 'sunny',
    temperature: 26,
    irradiance: 920,
    alerts: []
  },
  {
    id: 'site-4',
    name: 'Pretoria Government Building',
    organization_id: 'org-3',
    location: {
      lat: -25.7479,
      lng: 28.2293,
      address: '321 Government Avenue',
      city: 'Pretoria',
      country: 'South Africa'
    },
    capacity: 1200.0,
    installation_date: '2023-02-28',
    system_type: 'grid_tied',
    panel_count: 3000,
    inverter_type: 'ABB PVS980',
    status: 'active',
    performance_ratio: 93.7,
    monthly_generation: 145000,
    total_generation: 1250000,
    co2_saved: 875000,
    revenue_today: 6250,
    revenue_monthly: 165000,
    revenue_total: 1250000,
    weather_condition: 'sunny',
    temperature: 23,
    irradiance: 880,
    alerts: []
  },
  {
    id: 'site-5',
    name: 'Port Elizabeth Wind & Solar Farm',
    organization_id: 'org-3',
    location: {
      lat: -33.9608,
      lng: 25.6022,
      address: '654 Renewable Energy Park',
      city: 'Port Elizabeth',
      country: 'South Africa'
    },
    capacity: 2500.0,
    installation_date: '2022-11-15',
    system_type: 'grid_tied',
    panel_count: 6250,
    inverter_type: 'SMA Central Inverter',
    status: 'active',
    performance_ratio: 95.1,
    monthly_generation: 385000,
    total_generation: 3850000,
    co2_saved: 2695000,
    revenue_today: 18500,
    revenue_monthly: 425000,
    revenue_total: 3850000,
    weather_condition: 'sunny',
    temperature: 25,
    irradiance: 950,
    alerts: []
  }
];

// Generate realistic energy data for the last 30 days
export const generateEnergyData = (siteId: string, days: number = 30): EnergyData[] => {
  const data: EnergyData[] = [];
  const site = sites.find(s => s.id === siteId);
  if (!site) return data;

  const now = new Date();
  
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    
    // Generate 24 hours of data for each day
    for (let hour = 0; hour < 24; hour++) {
      const timestamp = new Date(date);
      timestamp.setHours(hour, 0, 0, 0);
      
      // Solar generation curve (0 at night, peak at midday)
      let generationFactor = 0;
      if (hour >= 6 && hour <= 18) {
        const solarHour = hour - 6;
        generationFactor = Math.sin((solarHour / 12) * Math.PI);
      }
      
      // Add some randomness and weather effects
      const weatherMultiplier = site.weather_condition === 'sunny' ? 1.0 : 
                               site.weather_condition === 'cloudy' ? 0.7 : 0.3;
      const randomFactor = 0.8 + Math.random() * 0.4; // 80-120% variation
      
      const generation = site.capacity * generationFactor * weatherMultiplier * randomFactor;
      const irradiance = generationFactor * 1000 * weatherMultiplier * randomFactor;
      const temperature = 15 + Math.random() * 20 + (generationFactor * 10); // 15-45°C
      
      data.push({
        timestamp: timestamp.toISOString(),
        site_id: siteId,
        generation: Math.max(0, generation),
        irradiance: Math.max(0, irradiance),
        temperature: temperature,
        consumption: generation * 0.3 + Math.random() * 50, // Some base consumption
        grid_export: Math.max(0, generation * 0.7 - 20),
        battery_level: site.system_type === 'hybrid' ? 50 + Math.random() * 50 : undefined,
        wind_speed: 2 + Math.random() * 8
      });
    }
  }
  
  return data;
};

// Generate financial data
export const generateFinancialData = (siteId: string, months: number = 12): FinancialData[] => {
  const data: FinancialData[] = [];
  const site = sites.find(s => s.id === siteId);
  if (!site) return data;

  const now = new Date();
  
  for (let i = months - 1; i >= 0; i--) {
    const date = new Date(now);
    date.setMonth(date.getMonth() - i);
    date.setDate(1);
    
    const monthlyGeneration = site.monthly_generation * (0.8 + Math.random() * 0.4);
    const tariffRate = 0.15 + Math.random() * 0.05; // R0.15-0.20 per kWh
    const feedInTariff = 0.08 + Math.random() * 0.02; // R0.08-0.10 per kWh
    
    const revenue = monthlyGeneration * feedInTariff;
    const savings = monthlyGeneration * tariffRate;
    const maintenanceCost = site.capacity * 0.5 + Math.random() * 100; // Basic maintenance
    
    data.push({
      site_id: siteId,
      date: date.toISOString().split('T')[0],
      revenue: revenue,
      savings: savings,
      tariff_rate: tariffRate,
      feed_in_tariff: feedInTariff,
      grid_cost_avoided: savings,
      maintenance_cost: maintenanceCost,
      roi_percentage: ((revenue + savings - maintenanceCost) / (site.capacity * 1000)) * 100
    });
  }
  
  return data;
};

// Generate predictive analytics
export const generatePredictiveAnalytics = (siteId: string): PredictiveAnalytics[] => {
  const data: PredictiveAnalytics[] = [];
  const site = sites.find(s => s.id === siteId);
  if (!site) return data;

  const now = new Date();
  
  for (let i = 0; i < 7; i++) { // 7 days forecast
    const date = new Date(now);
    date.setDate(date.getDate() + i);
    
    const weatherConditions = ['sunny', 'cloudy', 'partly_cloudy', 'rainy'];
    const weather = weatherConditions[Math.floor(Math.random() * weatherConditions.length)];
    
    const weatherMultiplier = weather === 'sunny' ? 1.0 : 
                             weather === 'partly_cloudy' ? 0.8 : 
                             weather === 'cloudy' ? 0.6 : 0.3;
    
    const predictedGeneration = site.monthly_generation / 30 * weatherMultiplier * (0.9 + Math.random() * 0.2);
    const confidence = weather === 'sunny' ? 90 + Math.random() * 10 : 70 + Math.random() * 20;
    
    data.push({
      site_id: siteId,
      forecast_date: date.toISOString().split('T')[0],
      predicted_generation: predictedGeneration,
      confidence_level: confidence,
      weather_forecast: weather,
      maintenance_recommendation: i === 3 ? 'Panel cleaning recommended' : 'No maintenance required',
      performance_trend: site.performance_ratio > 95 ? 'stable' : 
                        site.performance_ratio > 90 ? 'stable' : 'declining',
      expected_revenue: predictedGeneration * 0.12 // Estimated revenue
    });
  }
  
  return data;
};

// Dashboard aggregated metrics
export const getDashboardMetrics = (organizationId: string) => {
  const orgSites = sites.filter(s => s.organization_id === organizationId);
  
  const totalCapacity = orgSites.reduce((sum, site) => sum + site.capacity, 0);
  const totalGeneration = orgSites.reduce((sum, site) => sum + site.monthly_generation, 0);
  const totalRevenue = orgSites.reduce((sum, site) => sum + site.revenue_monthly, 0);
  const totalCO2Saved = orgSites.reduce((sum, site) => sum + site.co2_saved, 0);
  const avgPerformance = orgSites.reduce((sum, site) => sum + site.performance_ratio, 0) / orgSites.length;
  const activeSites = orgSites.filter(s => s.status === 'active').length;
  const totalAlerts = orgSites.reduce((sum, site) => sum + site.alerts.length, 0);
  
  return {
    totalCapacity,
    totalGeneration,
    totalRevenue,
    totalCO2Saved,
    avgPerformance,
    activeSites,
    totalSites: orgSites.length,
    totalAlerts,
    systemEfficiency: avgPerformance * 0.9, // Slightly lower than performance ratio
    gridExport: totalGeneration * 0.7, // Assume 70% is exported
    weatherCondition: 'sunny', // Overall condition
    lastUpdated: new Date().toISOString()
  };
};

// Export all data
export const nexusGreenData = {
  organizations,
  users,
  sites,
  generateEnergyData,
  generateFinancialData,
  generatePredictiveAnalytics,
  getDashboardMetrics
};

export default nexusGreenData;