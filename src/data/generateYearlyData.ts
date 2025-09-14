import { demoSites, monthlyIrradianceData } from './demoCompany';

// Generate realistic solar generation data for a full year
export interface DailyGenerationData {
  date: string;
  siteId: string;
  siteName: string;
  generation: number; // kWh
  irradiance: number; // kWh/m²/day
  temperature: number; // °C
  performanceRatio: number;
  revenue: number; // ZAR
  co2Saved: number; // kg
  efficiency: number; // %
}

export interface MonthlyAggregateData {
  month: number;
  year: number;
  siteId: string;
  siteName: string;
  totalGeneration: number; // kWh
  avgDailyGeneration: number; // kWh
  totalRevenue: number; // ZAR
  totalCo2Saved: number; // kg
  avgEfficiency: number; // %
  avgPerformanceRatio: number;
}

// Generate random variation within realistic bounds
const addVariation = (baseValue: number, variationPercent: number): number => {
  const variation = (Math.random() - 0.5) * 2 * variationPercent;
  return baseValue * (1 + variation);
};

// Calculate CO2 savings (0.95 kg CO2 per kWh in South Africa)
const calculateCO2Savings = (generation: number): number => {
  return generation * 0.95;
};

// Generate weather-based daily irradiance
const generateDailyIrradiance = (month: number, day: number): { irradiance: number; temperature: number } => {
  const monthData = monthlyIrradianceData[month - 1];
  
  // Add seasonal and daily variations
  const seasonalVariation = Math.sin((month - 1) * Math.PI / 6) * 0.1;
  const dailyVariation = addVariation(1, 0.3); // ±30% daily variation
  const cloudVariation = Math.random() < 0.2 ? addVariation(1, 0.5) : 1; // 20% chance of cloudy day
  
  const irradiance = monthData.avgIrradiance * dailyVariation * cloudVariation * (1 + seasonalVariation);
  const temperature = addVariation(monthData.avgTemp, 0.15); // ±15% temperature variation
  
  return {
    irradiance: Math.max(0.5, irradiance), // Minimum 0.5 kWh/m²/day
    temperature: Math.max(5, temperature) // Minimum 5°C
  };
};

// Generate daily generation data for a site
const generateSiteDailyData = (site: any, date: Date): DailyGenerationData => {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  
  const weather = generateDailyIrradiance(month, day);
  
  // Calculate expected generation based on irradiance and system capacity
  const baseGeneration = (site.system.capacity * weather.irradiance * site.performance.performanceRatio);
  
  // Add system-specific variations
  const temperatureEffect = weather.temperature > 25 ? (25 - weather.temperature) * 0.004 : 0; // -0.4% per °C above 25°C
  const systemVariation = addVariation(1, 0.05); // ±5% system variation
  const maintenanceEffect = Math.random() < 0.02 ? 0.7 : 1; // 2% chance of maintenance/issues
  
  const actualGeneration = baseGeneration * (1 + temperatureEffect) * systemVariation * maintenanceEffect;
  const performanceRatio = actualGeneration / (site.system.capacity * weather.irradiance);
  const efficiency = (performanceRatio / site.performance.performanceRatio) * 100;
  
  return {
    date: date.toISOString().split('T')[0],
    siteId: site.id,
    siteName: site.name,
    generation: Math.max(0, actualGeneration),
    irradiance: weather.irradiance,
    temperature: weather.temperature,
    performanceRatio: Math.min(1, Math.max(0, performanceRatio)),
    revenue: actualGeneration * site.financial.ppaRate,
    co2Saved: calculateCO2Savings(actualGeneration),
    efficiency: Math.min(100, Math.max(0, efficiency))
  };
};

// Generate full year data for all sites
export const generateYearlyData = (year: number = 2024): DailyGenerationData[] => {
  const data: DailyGenerationData[] = [];
  const startDate = new Date(year, 0, 1); // January 1st
  const endDate = new Date(year, 11, 31); // December 31st
  
  for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + 1)) {
    for (const site of demoSites) {
      const dailyData = generateSiteDailyData(site, new Date(date));
      data.push(dailyData);
    }
  }
  
  return data;
};

// Generate monthly aggregates
export const generateMonthlyAggregates = (dailyData: DailyGenerationData[]): MonthlyAggregateData[] => {
  const monthlyMap = new Map<string, DailyGenerationData[]>();
  
  // Group by site and month
  dailyData.forEach(day => {
    const date = new Date(day.date);
    const key = `${day.siteId}-${date.getFullYear()}-${date.getMonth() + 1}`;
    
    if (!monthlyMap.has(key)) {
      monthlyMap.set(key, []);
    }
    monthlyMap.get(key)!.push(day);
  });
  
  // Calculate monthly aggregates
  const monthlyData: MonthlyAggregateData[] = [];
  
  monthlyMap.forEach((days, key) => {
    const [siteId, year, month] = key.split('-');
    const site = demoSites.find(s => s.id === siteId);
    
    const totalGeneration = days.reduce((sum, day) => sum + day.generation, 0);
    const totalRevenue = days.reduce((sum, day) => sum + day.revenue, 0);
    const totalCo2Saved = days.reduce((sum, day) => sum + day.co2Saved, 0);
    const avgEfficiency = days.reduce((sum, day) => sum + day.efficiency, 0) / days.length;
    const avgPerformanceRatio = days.reduce((sum, day) => sum + day.performanceRatio, 0) / days.length;
    
    monthlyData.push({
      month: parseInt(month),
      year: parseInt(year),
      siteId,
      siteName: site?.name || 'Unknown Site',
      totalGeneration,
      avgDailyGeneration: totalGeneration / days.length,
      totalRevenue,
      totalCo2Saved,
      avgEfficiency,
      avgPerformanceRatio
    });
  });
  
  return monthlyData.sort((a, b) => {
    if (a.year !== b.year) return a.year - b.year;
    if (a.month !== b.month) return a.month - b.month;
    return a.siteId.localeCompare(b.siteId);
  });
};

// Generate current year data
export const currentYearData = generateYearlyData(2024);
export const monthlyAggregates = generateMonthlyAggregates(currentYearData);

// Calculate summary statistics
export const yearSummary = {
  totalGeneration: currentYearData.reduce((sum, day) => sum + day.generation, 0),
  totalRevenue: currentYearData.reduce((sum, day) => sum + day.revenue, 0),
  totalCo2Saved: currentYearData.reduce((sum, day) => sum + day.co2Saved, 0),
  avgEfficiency: currentYearData.reduce((sum, day) => sum + day.efficiency, 0) / currentYearData.length,
  avgPerformanceRatio: currentYearData.reduce((sum, day) => sum + day.performanceRatio, 0) / currentYearData.length,
  totalSites: demoSites.length,
  totalCapacity: demoSites.reduce((sum, site) => sum + site.system.capacity, 0)
};

export default {
  generateYearlyData,
  generateMonthlyAggregates,
  currentYearData,
  monthlyAggregates,
  yearSummary
};