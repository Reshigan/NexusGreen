import { logger } from '@/utils/logger';
import { getErrorMessage } from '@/utils/errorUtils';
import type { 
  TariffRates, 
  TimePeriods, 
  SeasonalAdjustments, 
  SavingsCalculation, 
  EnergyData,
  UsageRecommendation
} from '@/types/solar';

class TariffEngine {
  private defaultRates: TariffRates;
  private defaultTimePeriods: TimePeriods;
  private seasonalAdjustments: SeasonalAdjustments;

  constructor() {
    // Default municipal rates (can be overridden per site)
    this.defaultRates = {
      peak: 2.50,      // R/kWh during peak hours
      standard: 1.80,  // R/kWh during standard hours
      offPeak: 1.20,   // R/kWh during off-peak hours
      feedIn: 0.80     // R/kWh for solar feed-in
    };

    // Default time periods (can be customized per municipality)
    this.defaultTimePeriods = {
      peak: [
        { start: '07:00', end: '10:00' },
        { start: '18:00', end: '20:00' }
      ],
      standard: [
        { start: '06:00', end: '07:00' },
        { start: '10:00', end: '18:00' },
        { start: '20:00', end: '22:00' }
      ],
      offPeak: [
        { start: '22:00', end: '06:00' }
      ]
    };

    // Seasonal adjustments (summer/winter rates)
    this.seasonalAdjustments = {
      summer: { // Oct - Mar
        peak: 1.1,
        standard: 1.0,
        offPeak: 0.9
      },
      winter: { // Apr - Sep
        peak: 1.2,
        standard: 1.0,
        offPeak: 0.8
      }
    };
  }

  /**
   * Get current season based on South African seasons
   */
  getCurrentSeason(date: Date = new Date()): keyof SeasonalAdjustments {
    const month = date.getMonth() + 1; // 1-12
    // Summer: Oct-Mar (10,11,12,1,2,3), Winter: Apr-Sep (4,5,6,7,8,9)
    return (month >= 10 || month <= 3) ? 'summer' : 'winter';
  }

  /**
   * Determine tariff period for a given time
   */
  getTariffPeriod(time: string | Date, timePeriods: TimePeriods = this.defaultTimePeriods): keyof TariffRates {
    const timeStr = typeof time === 'string' ? time : time.toTimeString().slice(0, 5);
    
    for (const [period, ranges] of Object.entries(timePeriods)) {
      for (const range of ranges) {
        if (this.isTimeInRange(timeStr, range.start, range.end)) {
          return period as keyof TariffRates;
        }
      }
    }
    
    return 'standard'; // Default fallback
  }

  /**
   * Check if time is within a range (handles overnight ranges)
   */
  isTimeInRange(time: string, start: string, end: string): boolean {
    const timeMinutes = this.timeToMinutes(time);
    const startMinutes = this.timeToMinutes(start);
    const endMinutes = this.timeToMinutes(end);

    if (startMinutes <= endMinutes) {
      // Same day range
      return timeMinutes >= startMinutes && timeMinutes < endMinutes;
    } else {
      // Overnight range
      return timeMinutes >= startMinutes || timeMinutes < endMinutes;
    }
  }

  /**
   * Convert time string to minutes since midnight
   */
  timeToMinutes(timeStr: string): number {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
  }

  /**
   * Get municipal rates for a specific location
   */
  async getMunicipalRates(address: string, municipality: string | null = null): Promise<TariffRates> {
    try {
      // In a real implementation, this would query a database or external API
      // For now, we'll use default rates with some location-based adjustments
      
      const baseRates = { ...this.defaultRates };
      
      // Apply location-based adjustments
      if (municipality) {
        const adjustments = this.getMunicipalityAdjustments(municipality);
        Object.keys(baseRates).forEach(key => {
          baseRates[key as keyof TariffRates] *= adjustments[key as keyof TariffRates] || 1.0;
        });
      }

      logger.info('Retrieved municipal rates', { address, municipality, rates: baseRates });
      return baseRates;
    } catch (error) {
      logger.error('Failed to get municipal rates', { error: getErrorMessage(error), address });
      return this.defaultRates;
    }
  }

  /**
   * Get municipality-specific rate adjustments
   */
  getMunicipalityAdjustments(municipality: string): TariffRates {
    const adjustments = {
      'city-of-cape-town': {
        peak: 1.05,
        standard: 1.02,
        offPeak: 0.98,
        feedIn: 0.95
      },
      'city-of-johannesburg': {
        peak: 1.08,
        standard: 1.03,
        offPeak: 0.97,
        feedIn: 0.90
      },
      'ethekwini': {
        peak: 1.06,
        standard: 1.01,
        offPeak: 0.99,
        feedIn: 0.92
      },
      'tshwane': {
        peak: 1.04,
        standard: 1.00,
        offPeak: 1.00,
        feedIn: 0.88
      }
    };

    return adjustments[municipality.toLowerCase() as keyof typeof adjustments] || {
      peak: 1.0,
      standard: 1.0,
      offPeak: 1.0,
      feedIn: 1.0
    };
  }

  /**
   * Calculate savings for a specific time period
   */
  calculateSavings(energyData: EnergyData, rates: TariffRates, timePeriods: TimePeriods = this.defaultTimePeriods): SavingsCalculation {
    try {
      let totalGridCost = 0;
      let totalSolarSavings = 0;
      let totalFeedInEarnings = 0;

      const season = this.getCurrentSeason();
      const seasonalAdj = this.seasonalAdjustments[season as keyof SeasonalAdjustments];

      // Process hourly data if available
      if (energyData.hourlyData && Array.isArray(energyData.hourlyData)) {
        energyData.hourlyData.forEach(hourData => {
          const period = this.getTariffPeriod(hourData.time, timePeriods);
          const rate = rates[period as keyof TariffRates] * ((seasonalAdj as any)[period] || 1.0);
          
          const gridConsumption = hourData.gridConsumption || 0;
          const solarUsage = hourData.solarUsage || 0;
          const feedIn = hourData.feedIn || 0;

          totalGridCost += gridConsumption * rate;
          totalSolarSavings += solarUsage * rate;
          totalFeedInEarnings += feedIn * rates.feedIn;
        });
      } else {
        // Use daily totals with average rates
        const avgRate = (rates.peak + rates.standard + rates.offPeak) / 3;
        const seasonalAvgRate = avgRate * ((seasonalAdj.peak + seasonalAdj.standard + seasonalAdj.offPeak) / 3);
        
        totalGridCost = (energyData.gridConsumption || 0) * seasonalAvgRate;
        totalSolarSavings = (energyData.solarUsage || 0) * seasonalAvgRate;
        totalFeedInEarnings = (energyData.feedIn || 0) * rates.feedIn;
      }

      const netSavings = totalSolarSavings + totalFeedInEarnings;
      const totalBenefit = netSavings;
      const savingsPercentage = totalGridCost > 0 ? (netSavings / (totalGridCost + netSavings)) * 100 : 0;

      return {
        totalGridCost: Math.round(totalGridCost * 100) / 100,
        totalSolarSavings: Math.round(totalSolarSavings * 100) / 100,
        totalFeedInEarnings: Math.round(totalFeedInEarnings * 100) / 100,
        netSavings: Math.round(netSavings * 100) / 100,
        totalBenefit: Math.round(totalBenefit * 100) / 100,
        savingsPercentage: Math.round(savingsPercentage * 100) / 100,
        season,
        currency: 'ZAR'
      };
    } catch (error) {
      logger.error('Failed to calculate savings', { error: getErrorMessage(error) });
      throw error;
    }
  }

  /**
   * Calculate savings for different time periods
   */
  async calculatePeriodSavings(siteId: string, energyData: any, address: string, period: string = 'day') {
    try {
      const rates = await this.getMunicipalRates(address);
      const savings = this.calculateSavings(energyData, rates);

      // Extrapolate for different periods
      let multiplier = 1;
      switch (period) {
        case 'week':
          multiplier = 7;
          break;
        case 'month':
          multiplier = 30;
          break;
        case 'year':
          multiplier = 365;
          break;
        case 'lifetime':
          multiplier = 365 * 25; // Assume 25-year system life
          break;
      }

      const periodSavings = {
        ...savings,
        period,
        totalGridCost: savings.totalGridCost * multiplier,
        totalSolarSavings: savings.totalSolarSavings * multiplier,
        totalFeedInEarnings: savings.totalFeedInEarnings * multiplier,
        netSavings: savings.netSavings * multiplier,
        totalBenefit: savings.totalBenefit * multiplier
      };

      logger.info('Calculated period savings', { siteId, period, savings: periodSavings });
      return periodSavings;
    } catch (error) {
      logger.error('Failed to calculate period savings', { error: getErrorMessage(error), siteId, period });
      throw error;
    }
  }

  /**
   * Get optimal usage recommendations
   */
  getUsageRecommendations(energyData: any, rates: TariffRates, timePeriods: TimePeriods = this.defaultTimePeriods) {
    try {
      const recommendations = [];

      // Analyze current usage patterns
      const peakUsage = energyData.peakUsage || 0;
      const offPeakUsage = energyData.offPeakUsage || 0;
      const totalUsage = peakUsage + offPeakUsage + (energyData.standardUsage || 0);

      if (peakUsage > totalUsage * 0.3) {
        recommendations.push({
          type: 'peak_reduction',
          title: 'Reduce Peak Hour Usage',
          description: 'Consider shifting high-energy activities to off-peak hours (22:00-06:00) to save up to 52% on electricity costs.',
          potentialSaving: (peakUsage * 0.3 * (rates.peak - rates.offPeak)),
          priority: 'high'
        });
      }

      if (energyData.solarGeneration > energyData.solarUsage * 1.5) {
        recommendations.push({
          type: 'solar_optimization',
          title: 'Optimize Solar Usage',
          description: 'You\'re generating more solar power than you\'re using. Consider running appliances during peak solar hours (10:00-15:00).',
          potentialSaving: ((energyData.solarGeneration - energyData.solarUsage) * 0.5 * rates.standard),
          priority: 'medium'
        });
      }

      if (energyData.feedIn < energyData.solarGeneration * 0.1) {
        recommendations.push({
          type: 'battery_storage',
          title: 'Consider Battery Storage',
          description: 'Adding battery storage could help you use more of your solar power during peak rate periods.',
          potentialSaving: (energyData.solarGeneration * 0.2 * (rates.peak - rates.feedIn)),
          priority: 'medium'
        });
      }

      return recommendations.sort((a, b) => {
        const priorityOrder = { high: 3, medium: 2, low: 1 };
        return priorityOrder[b.priority as keyof typeof priorityOrder] - priorityOrder[a.priority as keyof typeof priorityOrder];
      });
    } catch (error) {
      logger.error('Failed to get usage recommendations', { error: getErrorMessage(error) });
      return [];
    }
  }
}

export default new TariffEngine();