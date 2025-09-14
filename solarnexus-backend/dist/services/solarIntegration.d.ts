import type { UsageAnalysis, EnvironmentalImpact } from '../types/solar';
declare class SolarIntegrationService {
    private solaxBaseUrl;
    private accessTokens;
    constructor();
    /**
     * Get SolaX access token
     */
    getSolaxToken(clientId: string, clientSecret: string): Promise<string>;
    /**
     * Get plant information
     */
    getPlantInfo(clientId: string, clientSecret: string, pageNo?: number): Promise<any>;
    /**
     * Get device information
     */
    getDeviceInfo(clientId: string, clientSecret: string, plantName: string, pageNo?: number, deviceType?: string): Promise<any>;
    /**
     * Get real-time plant data
     */
    getPlantRealtimeData(clientId: string, clientSecret: string, plantId: string): Promise<any>;
    /**
     * Get historical energy data
     */
    getHistoricalEnergyData(clientId: string, clientSecret: string, plantId: string, startDate: string, endDate: string, timeType?: string): Promise<any>;
    /**
     * Get alarm information
     */
    getAlarmInfo(clientId: string, clientSecret: string, plantId: string, pageNo?: number): Promise<any>;
    /**
     * Calculate solar vs grid usage
     */
    calculateSolarVsGrid(realtimeData: any): UsageAnalysis;
    /**
     * Calculate environmental impact (SDG metrics)
     */
    calculateEnvironmentalImpact(energyData: any): EnvironmentalImpact;
}
declare const _default: SolarIntegrationService;
export default _default;
//# sourceMappingURL=solarIntegration.d.ts.map