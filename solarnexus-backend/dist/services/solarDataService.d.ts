export declare class SolarDataService {
    getData(): Promise<never[]>;
    getEnergyData(siteId: string, startDate: Date, endDate: Date): Promise<{
        totalGeneration: number;
        totalConsumption: number;
        hourlyData: never[];
    }>;
}
//# sourceMappingURL=solarDataService.d.ts.map