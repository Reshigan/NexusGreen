export interface PredictionResult {
    siteId: string;
    siteName: string;
    predictionType: 'performance_degradation' | 'equipment_failure' | 'maintenance_required' | 'weather_impact';
    severity: 'low' | 'medium' | 'high' | 'critical';
    confidence: number;
    description: string;
    recommendedAction: string;
    estimatedImpact: {
        energyLoss: number;
        financialImpact: number;
        timeframe: string;
    };
    predictedDate?: Date;
}
export interface SystemHealth {
    siteId: string;
    overallHealth: number;
    components: {
        inverters: number;
        panels: number;
        monitoring: number;
        grid: number;
    };
    alerts: number;
    lastUpdate: Date;
}
export declare class PredictiveAnalyticsService {
    /**
     * Analyze system performance and predict potential issues
     */
    analyzeSitePerformance(siteId: string): Promise<PredictionResult[]>;
    /**
     * Analyze performance degradation trends
     */
    private analyzePerformanceDegradation;
    /**
     * Analyze equipment health indicators
     */
    private analyzeEquipmentHealth;
    /**
     * Analyze maintenance needs based on system age and performance
     */
    private analyzeMaintenanceNeeds;
    /**
     * Analyze weather impact on performance
     */
    private analyzeWeatherImpact;
    /**
     * Get system health overview for all sites
     */
    getSystemHealthOverview(organizationId: string): Promise<SystemHealth[]>;
    /**
     * Send alert notifications for critical predictions
     */
    sendAlertNotifications(predictions: PredictionResult[], siteId: string): Promise<void>;
    private calculateDailyAverages;
    private calculateTrend;
    private detectAnomalies;
    private getCurrentSeason;
    private getSeasonalExpectedPerformance;
    private generateAlertEmail;
}
//# sourceMappingURL=predictiveAnalytics.d.ts.map