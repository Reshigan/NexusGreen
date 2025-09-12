export interface SolaxTokenData {
  token: string;
  expiresAt: number;
}

export interface SolaxPlantInfo {
  plantId: string;
  plantName: string;
  capacity: number;
  location: string;
  installDate: string;
  status: string;
}

export interface SolaxRealtimeData {
  yieldtoday: number;
  yieldtotal: number;
  consumeEnergyToday: number;
  feedinEnergyToday: number;
  power: number;
  gridPower: number;
  batteryPower: number;
  timestamp: string;
}

export interface SolaxHistoricalData {
  yieldEnergy: number;
  consumeEnergy: number;
  feedinEnergy: number;
  useEnergy: number;
  peakUsage: number;
  offPeakUsage: number;
  date: string;
}

export interface SolaxAlarmInfo {
  alarmId: string;
  alarmType: string;
  alarmLevel: string;
  description: string;
  timestamp: string;
  status: string;
}

export interface UsageAnalysis {
  solarGeneration: number;
  solarUsage: number;
  gridUsage: number;
  gridFeedIn: number;
  totalConsumption: number;
  solarPercentage: number;
  gridPercentage: number;
}

export interface TariffRates {
  peak: number;
  standard: number;
  offPeak: number;
  feedIn: number;
}

export interface TimePeriod {
  start: string;
  end: string;
}

export interface TimePeriods {
  peak: TimePeriod[];
  standard: TimePeriod[];
  offPeak: TimePeriod[];
}

export interface SeasonalAdjustments {
  summer: {
    peak: number;
    standard: number;
    offPeak: number;
  };
  winter: {
    peak: number;
    standard: number;
    offPeak: number;
  };
}

export interface SavingsCalculation {
  totalGridCost: number;
  totalSolarSavings: number;
  totalFeedInEarnings: number;
  netSavings: number;
  totalBenefit: number;
  savingsPercentage: number;
  season: string;
  currency: string;
  period?: string;
}

export interface EnvironmentalImpact {
  totalSolarGeneration: number;
  co2Reduction: number;
  treesEquivalent: number;
  homesEquivalent: number;
  sdgGoals: {
    goal7: SDGGoal;
    goal13: SDGGoal;
    goal11: SDGGoal;
  };
}

export interface SDGGoal {
  description: string;
  value: number;
  unit: string;
}

export interface UsageRecommendation {
  type: string;
  title: string;
  description: string;
  potentialSaving: number;
  priority: 'high' | 'medium' | 'low';
}

export interface EnergyData {
  gridConsumption?: number;
  solarUsage?: number;
  feedIn?: number;
  solarGeneration?: number;
  peakUsage?: number;
  offPeakUsage?: number;
  standardUsage?: number;
  hourlyData?: HourlyEnergyData[];
}

export interface HourlyEnergyData {
  time: string;
  gridConsumption: number;
  solarUsage: number;
  feedIn: number;
}

export interface DashboardSummary {
  totalSites: number;
  activeSites: number;
  totalSolarGeneration: number;
  totalGridUsage: number;
  totalSavings: number;
  totalCO2Reduction: number;
  alarmsCount: number;
  currency: string;
}

export interface SiteData {
  siteId: string;
  siteName: string;
  isActive: boolean;
  solarGeneration?: number;
  savings?: number;
  error?: string;
}