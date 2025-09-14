import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';
import { getErrorMessage } from '../utils/errorHandler';
import { SolarDataService } from './solarDataService';

const prisma = new PrismaClient();
const solarDataService = new SolarDataService();

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

export class SDGTrackingService {

  /**
   * Calculate SDG impact metrics for an organization
   */
  async calculateSDGImpact(organizationId: string): Promise<SDGImpact> {
    try {
      const organization = await prisma.organization.findUnique({
        where: { id: organizationId },
        include: {
          sites: {
            where: { isActive: true }
          }
        }
      });

      if (!organization) {
        throw new Error('Organization not found');
      }

      const sites = organization.sites;
      const totalCapacity = sites.reduce((sum, site) => sum + site.capacity, 0);

      // Get energy data for all sites (last 12 months)
      const endDate = new Date();
      const startDate = new Date(endDate.getTime() - 365 * 24 * 60 * 60 * 1000);

      let totalGeneration = 0;
      let totalCO2Avoided = 0;

      for (const site of sites) {
        if (site.solaxClientId && site.solaxClientSecret && site.solaxPlantId) {
          try {
            const energyData = await solarDataService.getEnergyData(
              site.id,
              startDate,
              endDate
            );
            
            const generation = energyData.totalGeneration || 0;
            totalGeneration += generation;
            
            // Calculate CO2 avoided (0.5 kg CO2 per kWh in South Africa)
            totalCO2Avoided += generation * 0.5;
          } catch (error) {
            logger.error(`Failed to get energy data for SDG calculation for site ${site.id}`, { 
              error: getErrorMessage(error) 
            });
          }
        }
      }

      // Calculate SDG metrics
      const metrics = await this.calculateSDGMetrics(
        totalCapacity,
        totalGeneration,
        totalCO2Avoided,
        sites.length
      );

      return {
        organizationId,
        organizationName: organization.name,
        totalSites: sites.length,
        totalCapacity,
        metrics,
        summary: {
          primaryGoals: [7, 13, 11, 8], // Affordable Clean Energy, Climate Action, Sustainable Cities, Economic Growth
          totalCO2Avoided,
          renewableEnergyGenerated: totalGeneration,
          jobsSupported: Math.round(totalCapacity * 0.1), // Estimate: 0.1 jobs per kW
          communitiesImpacted: sites.length // Assuming each site impacts one community
        }
      };

    } catch (error) {
      logger.error('Failed to calculate SDG impact', { 
        organizationId, 
        error: getErrorMessage(error) 
      });
      throw error;
    }
  }

  /**
   * Calculate specific SDG metrics based on solar energy data
   */
  private async calculateSDGMetrics(
    totalCapacity: number,
    totalGeneration: number,
    totalCO2Avoided: number,
    siteCount: number
  ): Promise<SDGMetric[]> {
    const metrics: SDGMetric[] = [];

    // SDG 7: Affordable and Clean Energy
    metrics.push({
      goal: 7,
      target: '7.2',
      indicator: 'Renewable energy share in total final energy consumption',
      value: totalGeneration,
      unit: 'kWh',
      trend: 'improving',
      lastUpdated: new Date()
    });

    metrics.push({
      goal: 7,
      target: '7.1',
      indicator: 'Access to electricity',
      value: totalCapacity,
      unit: 'kW installed capacity',
      trend: 'improving',
      lastUpdated: new Date()
    });

    // SDG 13: Climate Action
    metrics.push({
      goal: 13,
      target: '13.2',
      indicator: 'CO2 emissions avoided',
      value: totalCO2Avoided,
      unit: 'kg CO2 equivalent',
      trend: 'improving',
      lastUpdated: new Date()
    });

    metrics.push({
      goal: 13,
      target: '13.3',
      indicator: 'Climate change mitigation capacity',
      value: totalCO2Avoided / 1000, // Convert to tonnes
      unit: 'tonnes CO2 avoided',
      trend: 'improving',
      lastUpdated: new Date()
    });

    // SDG 11: Sustainable Cities and Communities
    metrics.push({
      goal: 11,
      target: '11.6',
      indicator: 'Reduce environmental impact of cities',
      value: totalCO2Avoided / siteCount,
      unit: 'kg CO2 avoided per site',
      trend: 'improving',
      lastUpdated: new Date()
    });

    // SDG 8: Decent Work and Economic Growth
    const estimatedJobs = Math.round(totalCapacity * 0.1); // 0.1 jobs per kW
    metrics.push({
      goal: 8,
      target: '8.2',
      indicator: 'Economic productivity through diversification',
      value: estimatedJobs,
      unit: 'jobs supported',
      trend: 'improving',
      lastUpdated: new Date()
    });

    // SDG 9: Industry, Innovation and Infrastructure
    metrics.push({
      goal: 9,
      target: '9.4',
      indicator: 'Clean and environmentally sound technologies',
      value: totalCapacity,
      unit: 'kW clean energy infrastructure',
      trend: 'improving',
      lastUpdated: new Date()
    });

    // SDG 12: Responsible Consumption and Production
    const energyIntensity = totalGeneration / totalCapacity; // kWh per kW
    metrics.push({
      goal: 12,
      target: '12.2',
      indicator: 'Sustainable management of natural resources',
      value: energyIntensity,
      unit: 'kWh/kW efficiency ratio',
      trend: totalGeneration > 0 ? 'improving' : 'stable',
      lastUpdated: new Date()
    });

    return metrics;
  }

  /**
   * Get SDG progress comparison across multiple organizations
   */
  async getSDGComparison(organizationIds: string[]): Promise<{
    organizations: SDGImpact[];
    aggregated: {
      totalCapacity: number;
      totalGeneration: number;
      totalCO2Avoided: number;
      totalJobsSupported: number;
      totalCommunitiesImpacted: number;
    };
  }> {
    try {
      const impacts = await Promise.all(
        organizationIds.map(id => this.calculateSDGImpact(id))
      );

      const aggregated = {
        totalCapacity: impacts.reduce((sum, impact) => sum + impact.totalCapacity, 0),
        totalGeneration: impacts.reduce((sum, impact) => sum + impact.summary.renewableEnergyGenerated, 0),
        totalCO2Avoided: impacts.reduce((sum, impact) => sum + impact.summary.totalCO2Avoided, 0),
        totalJobsSupported: impacts.reduce((sum, impact) => sum + impact.summary.jobsSupported, 0),
        totalCommunitiesImpacted: impacts.reduce((sum, impact) => sum + impact.summary.communitiesImpacted, 0)
      };

      return {
        organizations: impacts,
        aggregated
      };

    } catch (error) {
      logger.error('Failed to get SDG comparison', { error: getErrorMessage(error) });
      throw error;
    }
  }

  /**
   * Generate SDG report for a specific time period
   */
  async generateSDGReport(
    organizationId: string,
    startDate: Date,
    endDate: Date
  ): Promise<{
    period: { start: Date; end: Date };
    impact: SDGImpact;
    trends: {
      energyGeneration: { current: number; previous: number; change: number };
      co2Avoided: { current: number; previous: number; change: number };
      capacity: { current: number; previous: number; change: number };
    };
    recommendations: string[];
  }> {
    try {
      // Get current period impact
      const currentImpact = await this.calculateSDGImpact(organizationId);

      // Calculate previous period for comparison
      const periodLength = endDate.getTime() - startDate.getTime();
      const previousStart = new Date(startDate.getTime() - periodLength);
      const previousEnd = startDate;

      // Get organization sites
      const organization = await prisma.organization.findUnique({
        where: { id: organizationId },
        include: {
          sites: {
            where: { isActive: true }
          }
        }
      });

      if (!organization) {
        throw new Error('Organization not found');
      }

      // Calculate previous period metrics
      let previousGeneration = 0;
      let previousCO2Avoided = 0;

      for (const site of organization.sites) {
        if (site.solaxClientId && site.solaxClientSecret && site.solaxPlantId) {
          try {
            const energyData = await solarDataService.getEnergyData(
              site.id,
              previousStart,
              previousEnd
            );
            
            const generation = energyData.totalGeneration || 0;
            previousGeneration += generation;
            previousCO2Avoided += generation * 0.5;
          } catch (error) {
            logger.error(`Failed to get previous period data for site ${site.id}`, { 
              error: getErrorMessage(error) 
            });
          }
        }
      }

      const trends = {
        energyGeneration: {
          current: currentImpact.summary.renewableEnergyGenerated,
          previous: previousGeneration,
          change: previousGeneration > 0 
            ? ((currentImpact.summary.renewableEnergyGenerated - previousGeneration) / previousGeneration) * 100
            : 0
        },
        co2Avoided: {
          current: currentImpact.summary.totalCO2Avoided,
          previous: previousCO2Avoided,
          change: previousCO2Avoided > 0 
            ? ((currentImpact.summary.totalCO2Avoided - previousCO2Avoided) / previousCO2Avoided) * 100
            : 0
        },
        capacity: {
          current: currentImpact.totalCapacity,
          previous: currentImpact.totalCapacity, // Capacity doesn't change much period to period
          change: 0
        }
      };

      // Generate recommendations
      const recommendations = this.generateRecommendations(currentImpact, trends);

      return {
        period: { start: startDate, end: endDate },
        impact: currentImpact,
        trends,
        recommendations
      };

    } catch (error) {
      logger.error('Failed to generate SDG report', { 
        organizationId, 
        error: getErrorMessage(error) 
      });
      throw error;
    }
  }

  /**
   * Generate recommendations based on SDG performance
   */
  private generateRecommendations(impact: SDGImpact, trends: any): string[] {
    const recommendations: string[] = [];

    // Energy generation recommendations
    if (trends.energyGeneration.change < 5) {
      recommendations.push(
        'Consider expanding solar capacity or optimizing existing systems to increase renewable energy generation (SDG 7)'
      );
    }

    // Climate action recommendations
    if (impact.summary.totalCO2Avoided < impact.totalCapacity * 1000) {
      recommendations.push(
        'Maximize CO2 impact by ensuring optimal system performance and consider additional climate mitigation measures (SDG 13)'
      );
    }

    // Economic growth recommendations
    if (impact.summary.jobsSupported < impact.totalCapacity * 0.15) {
      recommendations.push(
        'Explore opportunities to create more local jobs through maintenance, training, and community programs (SDG 8)'
      );
    }

    // Community impact recommendations
    if (impact.summary.communitiesImpacted < impact.totalSites) {
      recommendations.push(
        'Develop community engagement programs to maximize local benefits and sustainable development impact (SDG 11)'
      );
    }

    // Innovation recommendations
    recommendations.push(
      'Consider implementing smart grid technologies and energy storage to enhance infrastructure resilience (SDG 9)'
    );

    return recommendations;
  }

  /**
   * Get SDG alignment score for an organization
   */
  async getSDGAlignmentScore(organizationId: string): Promise<{
    overallScore: number;
    goalScores: { goal: number; score: number; description: string }[];
    strengths: string[];
    improvements: string[];
  }> {
    try {
      const impact = await this.calculateSDGImpact(organizationId);
      
      // Calculate scores for each relevant SDG (0-100)
      const goalScores = [
        {
          goal: 7,
          score: Math.min(100, (impact.summary.renewableEnergyGenerated / (impact.totalCapacity * 1500)) * 100),
          description: 'Affordable and Clean Energy'
        },
        {
          goal: 8,
          score: Math.min(100, (impact.summary.jobsSupported / (impact.totalCapacity * 0.2)) * 100),
          description: 'Decent Work and Economic Growth'
        },
        {
          goal: 9,
          score: Math.min(100, (impact.totalCapacity / 1000) * 20), // Score based on infrastructure scale
          description: 'Industry, Innovation and Infrastructure'
        },
        {
          goal: 11,
          score: Math.min(100, (impact.summary.communitiesImpacted / impact.totalSites) * 100),
          description: 'Sustainable Cities and Communities'
        },
        {
          goal: 12,
          score: Math.min(100, (impact.summary.renewableEnergyGenerated / (impact.totalCapacity * 1200)) * 100),
          description: 'Responsible Consumption and Production'
        },
        {
          goal: 13,
          score: Math.min(100, (impact.summary.totalCO2Avoided / (impact.totalCapacity * 1000)) * 100),
          description: 'Climate Action'
        }
      ];

      const overallScore = goalScores.reduce((sum, goal) => sum + goal.score, 0) / goalScores.length;

      const strengths = goalScores
        .filter(goal => goal.score >= 80)
        .map(goal => `Strong performance in ${goal.description} (SDG ${goal.goal})`);

      const improvements = goalScores
        .filter(goal => goal.score < 60)
        .map(goal => `Opportunity to improve ${goal.description} (SDG ${goal.goal})`);

      return {
        overallScore: Math.round(overallScore),
        goalScores,
        strengths,
        improvements
      };

    } catch (error) {
      logger.error('Failed to calculate SDG alignment score', { 
        organizationId, 
        error: getErrorMessage(error) 
      });
      throw error;
    }
  }
}