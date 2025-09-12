import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';
import { getErrorMessage } from '../utils/errorHandler';
import { SolarDataService } from './solarDataService';
import { EmailService } from './emailService';

const prisma = new PrismaClient();
const solarDataService = new SolarDataService();
const emailService = new EmailService();

export interface PredictionResult {
  siteId: string;
  siteName: string;
  predictionType: 'performance_degradation' | 'equipment_failure' | 'maintenance_required' | 'weather_impact';
  severity: 'low' | 'medium' | 'high' | 'critical';
  confidence: number; // 0-100
  description: string;
  recommendedAction: string;
  estimatedImpact: {
    energyLoss: number; // kWh
    financialImpact: number; // ZAR
    timeframe: string;
  };
  predictedDate?: Date;
}

export interface SystemHealth {
  siteId: string;
  overallHealth: number; // 0-100
  components: {
    inverters: number;
    panels: number;
    monitoring: number;
    grid: number;
  };
  alerts: number;
  lastUpdate: Date;
}

export class PredictiveAnalyticsService {
  
  /**
   * Analyze system performance and predict potential issues
   */
  async analyzeSitePerformance(siteId: string): Promise<PredictionResult[]> {
    try {
      const site = await prisma.site.findUnique({
        where: { id: siteId },
        include: { organization: true, project: true }
      });

      if (!site || !site.solaxClientId || !site.solaxClientSecret || !site.solaxPlantId) {
        throw new Error('Site not found or SolaX credentials not configured');
      }

      // Get historical data for analysis (last 90 days)
      const endDate = new Date();
      const startDate = new Date(endDate.getTime() - 90 * 24 * 60 * 60 * 1000);

      const energyData = await solarDataService.getEnergyData(
        site.solaxClientId,
        site.solaxClientSecret,
        site.solaxPlantId,
        startDate,
        endDate
      );

      const predictions: PredictionResult[] = [];

      // Performance degradation analysis
      const performancePrediction = await this.analyzePerformanceDegradation(site, energyData);
      if (performancePrediction) {
        predictions.push(performancePrediction);
      }

      // Equipment failure prediction
      const equipmentPrediction = await this.analyzeEquipmentHealth(site, energyData);
      if (equipmentPrediction) {
        predictions.push(equipmentPrediction);
      }

      // Maintenance prediction
      const maintenancePrediction = await this.analyzeMaintenanceNeeds(site, energyData);
      if (maintenancePrediction) {
        predictions.push(maintenancePrediction);
      }

      // Weather impact analysis
      const weatherPrediction = await this.analyzeWeatherImpact(site, energyData);
      if (weatherPrediction) {
        predictions.push(weatherPrediction);
      }

      return predictions;

    } catch (error) {
      logger.error('Failed to analyze site performance', { 
        siteId, 
        error: getErrorMessage(error) 
      });
      throw error;
    }
  }

  /**
   * Analyze performance degradation trends
   */
  private async analyzePerformanceDegradation(site: any, energyData: any): Promise<PredictionResult | null> {
    try {
      if (!energyData.hourlyData || energyData.hourlyData.length < 30) {
        return null; // Not enough data
      }

      // Calculate daily averages for trend analysis
      const dailyAverages = this.calculateDailyAverages(energyData.hourlyData);
      
      if (dailyAverages.length < 7) {
        return null; // Need at least a week of data
      }

      // Simple linear regression to detect degradation trend
      const trend = this.calculateTrend(dailyAverages);
      
      // If trend shows significant decline (>2% per month)
      if (trend.slope < -0.02) {
        const annualDegradation = Math.abs(trend.slope * 12 * 100);
        const energyLoss = site.capacity * 365 * 4 * (annualDegradation / 100); // Assuming 4 hours peak sun
        const financialImpact = energyLoss * 0.85; // Feed-in tariff rate

        return {
          siteId: site.id,
          siteName: site.name,
          predictionType: 'performance_degradation',
          severity: annualDegradation > 5 ? 'high' : annualDegradation > 2 ? 'medium' : 'low',
          confidence: Math.min(95, Math.abs(trend.correlation) * 100),
          description: `System showing ${annualDegradation.toFixed(1)}% annual performance degradation`,
          recommendedAction: 'Schedule comprehensive system inspection and cleaning',
          estimatedImpact: {
            energyLoss,
            financialImpact,
            timeframe: '12 months'
          }
        };
      }

      return null;
    } catch (error) {
      logger.error('Failed to analyze performance degradation', { error: getErrorMessage(error) });
      return null;
    }
  }

  /**
   * Analyze equipment health indicators
   */
  private async analyzeEquipmentHealth(site: any, energyData: any): Promise<PredictionResult | null> {
    try {
      if (!energyData.hourlyData || energyData.hourlyData.length < 24) {
        return null;
      }

      // Analyze for equipment anomalies
      const recentData = energyData.hourlyData.slice(-168); // Last week
      const anomalies = this.detectAnomalies(recentData);

      if (anomalies.count > 10) { // More than 10 anomalies in a week
        const severity = anomalies.count > 50 ? 'critical' : anomalies.count > 25 ? 'high' : 'medium';
        const energyLoss = anomalies.averageImpact * 24 * 30; // Monthly impact
        const financialImpact = energyLoss * 0.85;

        return {
          siteId: site.id,
          siteName: site.name,
          predictionType: 'equipment_failure',
          severity,
          confidence: Math.min(90, (anomalies.count / recentData.length) * 100 * 2),
          description: `${anomalies.count} performance anomalies detected in the last week`,
          recommendedAction: 'Immediate equipment inspection required - potential inverter or panel issues',
          estimatedImpact: {
            energyLoss,
            financialImpact,
            timeframe: '30 days'
          },
          predictedDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // Next week
        };
      }

      return null;
    } catch (error) {
      logger.error('Failed to analyze equipment health', { error: getErrorMessage(error) });
      return null;
    }
  }

  /**
   * Analyze maintenance needs based on system age and performance
   */
  private async analyzeMaintenanceNeeds(site: any, energyData: any): Promise<PredictionResult | null> {
    try {
      const installDate = new Date(site.installDate);
      const monthsSinceInstall = (Date.now() - installDate.getTime()) / (30 * 24 * 60 * 60 * 1000);

      // Check if maintenance is due based on age
      const maintenanceInterval = 6; // months
      const monthsSinceLastMaintenance = monthsSinceInstall % maintenanceInterval;

      if (monthsSinceLastMaintenance > maintenanceInterval - 1) {
        const energyLoss = site.capacity * 24 * 30 * 0.05; // 5% loss without maintenance
        const financialImpact = energyLoss * 0.85;

        return {
          siteId: site.id,
          siteName: site.name,
          predictionType: 'maintenance_required',
          severity: 'medium',
          confidence: 85,
          description: 'Scheduled maintenance due based on system age and performance trends',
          recommendedAction: 'Schedule preventive maintenance: panel cleaning, connection checks, inverter inspection',
          estimatedImpact: {
            energyLoss,
            financialImpact,
            timeframe: '30 days'
          },
          predictedDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // In 2 weeks
        };
      }

      return null;
    } catch (error) {
      logger.error('Failed to analyze maintenance needs', { error: getErrorMessage(error) });
      return null;
    }
  }

  /**
   * Analyze weather impact on performance
   */
  private async analyzeWeatherImpact(site: any, energyData: any): Promise<PredictionResult | null> {
    try {
      // This would integrate with weather APIs in a real implementation
      // For now, we'll simulate weather impact analysis
      
      const currentSeason = this.getCurrentSeason();
      const expectedPerformance = this.getSeasonalExpectedPerformance(currentSeason);
      
      if (energyData.totalGeneration) {
        const actualPerformance = energyData.totalGeneration / (site.capacity * 24 * 30);
        const performanceRatio = actualPerformance / expectedPerformance;

        if (performanceRatio < 0.7) { // 30% below expected
          return {
            siteId: site.id,
            siteName: site.name,
            predictionType: 'weather_impact',
            severity: 'medium',
            confidence: 70,
            description: 'Performance significantly below seasonal expectations - possible weather-related issues',
            recommendedAction: 'Monitor weather conditions and consider protective measures',
            estimatedImpact: {
              energyLoss: (expectedPerformance - actualPerformance) * site.capacity * 24 * 30,
              financialImpact: (expectedPerformance - actualPerformance) * site.capacity * 24 * 30 * 0.85,
              timeframe: 'Current period'
            }
          };
        }
      }

      return null;
    } catch (error) {
      logger.error('Failed to analyze weather impact', { error: getErrorMessage(error) });
      return null;
    }
  }

  /**
   * Get system health overview for all sites
   */
  async getSystemHealthOverview(organizationId: string): Promise<SystemHealth[]> {
    try {
      const sites = await prisma.site.findMany({
        where: {
          organizationId,
          isActive: true
        }
      });

      const healthOverviews = await Promise.all(
        sites.map(async (site) => {
          try {
            const predictions = await this.analyzeSitePerformance(site.id);
            const criticalAlerts = predictions.filter(p => p.severity === 'critical').length;
            const highAlerts = predictions.filter(p => p.severity === 'high').length;
            const mediumAlerts = predictions.filter(p => p.severity === 'medium').length;

            // Calculate overall health score
            let healthScore = 100;
            healthScore -= criticalAlerts * 30;
            healthScore -= highAlerts * 20;
            healthScore -= mediumAlerts * 10;
            healthScore = Math.max(0, healthScore);

            return {
              siteId: site.id,
              overallHealth: healthScore,
              components: {
                inverters: healthScore > 80 ? 95 : healthScore > 60 ? 80 : 60,
                panels: healthScore > 80 ? 90 : healthScore > 60 ? 75 : 55,
                monitoring: 95, // Assuming monitoring is generally good
                grid: healthScore > 80 ? 98 : healthScore > 60 ? 85 : 70
              },
              alerts: predictions.length,
              lastUpdate: new Date()
            };
          } catch (error) {
            logger.error(`Failed to get health for site ${site.id}`, { error: getErrorMessage(error) });
            return {
              siteId: site.id,
              overallHealth: 50, // Unknown status
              components: {
                inverters: 50,
                panels: 50,
                monitoring: 50,
                grid: 50
              },
              alerts: 0,
              lastUpdate: new Date()
            };
          }
        })
      );

      return healthOverviews;
    } catch (error) {
      logger.error('Failed to get system health overview', { error: getErrorMessage(error) });
      throw error;
    }
  }

  /**
   * Send alert notifications for critical predictions
   */
  async sendAlertNotifications(predictions: PredictionResult[], siteId: string): Promise<void> {
    try {
      const criticalPredictions = predictions.filter(p => p.severity === 'critical' || p.severity === 'high');
      
      if (criticalPredictions.length === 0) {
        return;
      }

      // Get O&M users for this site
      const omUsers = await prisma.user.findMany({
        where: {
          organizations: {
            some: {
              organization: {
                sites: {
                  some: { id: siteId }
                }
              },
              role: 'om_provider'
            }
          }
        }
      });

      for (const user of omUsers) {
        const subject = `SolarNexus Alert: Critical Issues Detected`;
        const html = this.generateAlertEmail(criticalPredictions);
        
        await emailService.sendEmail(user.email, subject, html);
      }

      logger.info('Alert notifications sent', { 
        siteId, 
        alertCount: criticalPredictions.length,
        recipientCount: omUsers.length 
      });

    } catch (error) {
      logger.error('Failed to send alert notifications', { 
        siteId, 
        error: getErrorMessage(error) 
      });
    }
  }

  // Helper methods

  private calculateDailyAverages(hourlyData: any[]): number[] {
    const dailyGroups: { [key: string]: number[] } = {};
    
    hourlyData.forEach(hour => {
      const date = new Date(hour.time).toDateString();
      if (!dailyGroups[date]) {
        dailyGroups[date] = [];
      }
      dailyGroups[date].push(hour.generation || 0);
    });

    return Object.values(dailyGroups).map(day => 
      day.reduce((sum, val) => sum + val, 0) / day.length
    );
  }

  private calculateTrend(values: number[]): { slope: number; correlation: number } {
    const n = values.length;
    const x = Array.from({ length: n }, (_, i) => i);
    const y = values;

    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
    const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);
    const sumYY = y.reduce((sum, yi) => sum + yi * yi, 0);

    const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    const correlation = (n * sumXY - sumX * sumY) / 
      Math.sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));

    return { slope, correlation };
  }

  private detectAnomalies(data: any[]): { count: number; averageImpact: number } {
    if (data.length < 24) return { count: 0, averageImpact: 0 };

    const values = data.map(d => d.generation || 0);
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const stdDev = Math.sqrt(values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length);

    let anomalies = 0;
    let totalImpact = 0;

    values.forEach(val => {
      if (Math.abs(val - mean) > 2 * stdDev) {
        anomalies++;
        totalImpact += Math.abs(val - mean);
      }
    });

    return {
      count: anomalies,
      averageImpact: anomalies > 0 ? totalImpact / anomalies : 0
    };
  }

  private getCurrentSeason(): string {
    const month = new Date().getMonth();
    if (month >= 2 && month <= 4) return 'autumn';
    if (month >= 5 && month <= 7) return 'winter';
    if (month >= 8 && month <= 10) return 'spring';
    return 'summer';
  }

  private getSeasonalExpectedPerformance(season: string): number {
    const seasonalFactors = {
      summer: 1.2,
      autumn: 1.0,
      winter: 0.7,
      spring: 1.1
    };
    return seasonalFactors[season as keyof typeof seasonalFactors] || 1.0;
  }

  private generateAlertEmail(predictions: PredictionResult[]): string {
    let html = `
      <h2>SolarNexus System Alert</h2>
      <p>Critical issues have been detected that require immediate attention:</p>
      <ul>
    `;

    predictions.forEach(prediction => {
      html += `
        <li>
          <strong>${prediction.siteName}</strong> - ${prediction.description}
          <br>Severity: ${prediction.severity.toUpperCase()}
          <br>Recommended Action: ${prediction.recommendedAction}
          <br>Estimated Impact: ${prediction.estimatedImpact.energyLoss.toFixed(0)} kWh (R${prediction.estimatedImpact.financialImpact.toFixed(2)})
        </li>
      `;
    });

    html += `
      </ul>
      <p>Please log into the SolarNexus portal for detailed analysis and recommendations.</p>
    `;

    return html;
  }
}