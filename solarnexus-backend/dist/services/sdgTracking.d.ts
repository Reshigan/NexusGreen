export interface SDGMetric {
    goal: number;
    target: string;
    indicator: string;
    value: number;
    unit: string;
    trend: 'improving' | 'stable' | 'declining';
    lastUpdated: Date;
}
export interface SDGImpact {
    organizationId: string;
    organizationName: string;
    totalSites: number;
    totalCapacity: number;
    metrics: SDGMetric[];
    summary: {
        primaryGoals: number[];
        totalCO2Avoided: number;
        renewableEnergyGenerated: number;
        jobsSupported: number;
        communitiesImpacted: number;
    };
}
export declare class SDGTrackingService {
    /**
     * Calculate SDG impact metrics for an organization
     */
    calculateSDGImpact(organizationId: string): Promise<SDGImpact>;
    /**
     * Calculate specific SDG metrics based on solar energy data
     */
    private calculateSDGMetrics;
    /**
     * Get SDG progress comparison across multiple organizations
     */
    getSDGComparison(organizationIds: string[]): Promise<{
        organizations: SDGImpact[];
        aggregated: {
            totalCapacity: number;
            totalGeneration: number;
            totalCO2Avoided: number;
            totalJobsSupported: number;
            totalCommunitiesImpacted: number;
        };
    }>;
    /**
     * Generate SDG report for a specific time period
     */
    generateSDGReport(organizationId: string, startDate: Date, endDate: Date): Promise<{
        period: {
            start: Date;
            end: Date;
        };
        impact: SDGImpact;
        trends: {
            energyGeneration: {
                current: number;
                previous: number;
                change: number;
            };
            co2Avoided: {
                current: number;
                previous: number;
                change: number;
            };
            capacity: {
                current: number;
                previous: number;
                change: number;
            };
        };
        recommendations: string[];
    }>;
    /**
     * Generate recommendations based on SDG performance
     */
    private generateRecommendations;
    /**
     * Get SDG alignment score for an organization
     */
    getSDGAlignmentScore(organizationId: string): Promise<{
        overallScore: number;
        goalScores: {
            goal: number;
            score: number;
            description: string;
        }[];
        strengths: string[];
        improvements: string[];
    }>;
}
//# sourceMappingURL=sdgTracking.d.ts.map