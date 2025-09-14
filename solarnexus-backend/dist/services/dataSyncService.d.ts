interface SyncStats {
    sitesProcessed: number;
    recordsUpdated: number;
    errors: number;
    lastSync: Date;
}
export declare class DataSyncService {
    private isRunning;
    private syncInterval;
    private stats;
    constructor();
    /**
     * Start the scheduled data synchronization
     */
    start(): void;
    /**
     * Stop the data synchronization service
     */
    stop(): void;
    /**
     * Get current synchronization statistics
     */
    getStats(): SyncStats;
    /**
     * Perform a complete data synchronization
     */
    private performSync;
    /**
     * Sync data for a specific site
     */
    private syncSiteData;
    /**
     * Sync SolaX database data for a site
     */
    private syncSolaxData;
    /**
     * Update site metrics based on recent data
     */
    private updateSiteMetrics;
    /**
     * Sync weather data for all sites
     */
    private syncWeatherData;
    /**
     * Store synchronization statistics
     */
    private storeSyncStats;
    /**
     * Manual sync trigger for testing
     */
    triggerSync(): Promise<SyncStats>;
}
export declare const dataSyncService: DataSyncService;
export {};
//# sourceMappingURL=dataSyncService.d.ts.map