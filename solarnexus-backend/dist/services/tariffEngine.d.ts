import type { TariffRates, TimePeriods, SeasonalAdjustments, SavingsCalculation, EnergyData } from '@/types/solar';
declare class TariffEngine {
    private defaultRates;
    private defaultTimePeriods;
    private seasonalAdjustments;
    constructor();
    /**
     * Get current season based on South African seasons
     */
    getCurrentSeason(date?: Date): keyof SeasonalAdjustments;
    /**
     * Determine tariff period for a given time
     */
    getTariffPeriod(time: string | Date, timePeriods?: TimePeriods): keyof TariffRates;
    /**
     * Check if time is within a range (handles overnight ranges)
     */
    isTimeInRange(time: string, start: string, end: string): boolean;
    /**
     * Convert time string to minutes since midnight
     */
    timeToMinutes(timeStr: string): number;
    /**
     * Get municipal rates for a specific location
     */
    getMunicipalRates(address: string, municipality?: string | null): Promise<TariffRates>;
    /**
     * Get municipality-specific rate adjustments
     */
    getMunicipalityAdjustments(municipality: string): TariffRates;
    /**
     * Calculate savings for a specific time period
     */
    calculateSavings(energyData: EnergyData, rates: TariffRates, timePeriods?: TimePeriods): SavingsCalculation;
    /**
     * Calculate savings for different time periods
     */
    calculatePeriodSavings(siteId: string, energyData: any, address: string, period?: string): Promise<{
        period: string;
        totalGridCost: number;
        totalSolarSavings: number;
        totalFeedInEarnings: number;
        netSavings: number;
        totalBenefit: number;
        savingsPercentage: number;
        season: string;
        currency: string;
    }>;
    /**
     * Get optimal usage recommendations
     */
    getUsageRecommendations(energyData: any, rates: TariffRates, timePeriods?: TimePeriods): {
        type: string;
        title: string;
        description: string;
        potentialSaving: number;
        priority: string;
    }[];
}
declare const _default: TariffEngine;
export default _default;
//# sourceMappingURL=tariffEngine.d.ts.map