interface SolaxEnergyData {
    plantId: string;
    timestamp: Date;
    generation: number;
    consumption: number;
    gridImport: number;
    gridExport: number;
    batteryCharge: number;
    batteryDischarge: number;
    efficiency: number;
    temperature: number;
    irradiance: number;
}
interface SolaxPlantInfo {
    plantId: string;
    plantName: string;
    capacity: number;
    location: string;
    installDate: Date;
    status: string;
}
export declare class SolaxDatabaseService {
    private connection;
    private config;
    constructor();
    /**
     * Initialize database connection
     */
    connect(): Promise<void>;
    /**
     * Ensure connection is active
     */
    private ensureConnection;
    /**
     * Get plant information
     */
    getPlantInfo(plantId: string): Promise<SolaxPlantInfo | null>;
    /**
     * Get energy data for a specific time range
     */
    getEnergyData(plantId: string, startDate: Date, endDate: Date): Promise<SolaxEnergyData[]>;
    /**
     * Get latest energy data for a plant
     */
    getLatestEnergyData(plantId: string): Promise<SolaxEnergyData | null>;
    /**
     * Get hourly aggregated data
     */
    getHourlyData(plantId: string, startDate: Date, endDate: Date): Promise<SolaxEnergyData[]>;
    /**
     * Get daily aggregated data
     */
    getDailyData(plantId: string, startDate: Date, endDate: Date): Promise<SolaxEnergyData[]>;
    /**
     * Get monthly aggregated data
     */
    getMonthlyData(plantId: string, startDate: Date, endDate: Date): Promise<SolaxEnergyData[]>;
    /**
     * Get all plants for an organization
     */
    getOrganizationPlants(organizationId: string): Promise<SolaxPlantInfo[]>;
    /**
     * Get performance metrics for a plant
     */
    getPerformanceMetrics(plantId: string, startDate: Date, endDate: Date): Promise<{
        totalGeneration: number;
        totalConsumption: number;
        averageEfficiency: number;
        capacityFactor: number;
        availability: number;
    }>;
    /**
     * Close database connection
     */
    disconnect(): Promise<void>;
}
export declare const solaxDatabaseService: SolaxDatabaseService;
export {};
//# sourceMappingURL=solaxDatabaseService.d.ts.map