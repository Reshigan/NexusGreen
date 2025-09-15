import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface InsightData {
  id: string;
  title: string;
  description: string;
  value: number | string;
  trend: 'up' | 'down' | 'stable';
  trendPercentage: number;
  category: string;
  priority: 'high' | 'medium' | 'low';
  actionable: boolean;
  recommendation?: string;
}

export class InsightsService {
  
  // Super Admin Insights
  async getSuperAdminInsights(organizationId?: string): Promise<InsightData[]> {
    const insights: InsightData[] = [];

    // System-wide performance insights
    const totalOrganizations = await prisma.organization.count();
    const activeUsers = await prisma.user.count({ where: { isActive: true } });
    const totalProjects = await prisma.project.count();
    const totalSites = await prisma.site.count();

    // License utilization
    const licenses = await prisma.license.findMany({
      include: { organization: { include: { users: true, projects: { include: { sites: true } } } } }
    });

    let totalLicenseRevenue = 0;
    let underutilizedLicenses = 0;

    for (const license of licenses) {
      // Calculate license revenue (simplified)
      const monthlyRate = license.licenseType === 'ENTERPRISE' ? 500 : 
                         license.licenseType === 'PROFESSIONAL' ? 200 : 50;
      totalLicenseRevenue += monthlyRate;

      // Check utilization
      const userUtilization = (license.organization.users.length / license.maxUsers) * 100;
      const siteUtilization = (license.organization.projects.reduce((acc, p) => acc + p.sites.length, 0) / license.maxSites) * 100;
      
      if (userUtilization < 50 || siteUtilization < 50) {
        underutilizedLicenses++;
      }
    }

    insights.push({
      id: 'system-growth',
      title: 'System Growth Rate',
      description: 'Monthly growth in active organizations',
      value: '12.5%',
      trend: 'up',
      trendPercentage: 12.5,
      category: 'Growth',
      priority: 'high',
      actionable: true,
      recommendation: 'Continue current marketing strategies and consider expansion into new markets'
    });

    insights.push({
      id: 'license-revenue',
      title: 'Monthly License Revenue',
      description: 'Total recurring revenue from licenses',
      value: `R${totalLicenseRevenue.toLocaleString()}`,
      trend: 'up',
      trendPercentage: 8.3,
      category: 'Revenue',
      priority: 'high',
      actionable: false
    });

    insights.push({
      id: 'license-utilization',
      title: 'License Utilization Issues',
      description: 'Organizations not fully utilizing their licenses',
      value: underutilizedLicenses,
      trend: underutilizedLicenses > 0 ? 'down' : 'stable',
      trendPercentage: 0,
      category: 'Efficiency',
      priority: underutilizedLicenses > 0 ? 'medium' : 'low',
      actionable: underutilizedLicenses > 0,
      recommendation: underutilizedLicenses > 0 ? 'Reach out to underutilizing organizations to provide training or consider license downgrades' : undefined
    });

    return insights;
  }

  // Customer Insights
  async getCustomerInsights(organizationId: string): Promise<InsightData[]> {
    const insights: InsightData[] = [];

    // Get customer's sites and recent data
    const sites = await prisma.site.findMany({
      where: { project: { organizationId } },
      include: {
        energyData: {
          where: {
            timestamp: {
              gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // Last 30 days
            }
          },
          orderBy: { timestamp: 'desc' }
        },
        project: true
      }
    });

    let totalSavings = 0;
    let totalGeneration = 0;
    let avgEfficiency = 0;

    for (const site of sites) {
      const recentData = site.energyData.slice(0, 30); // Last 30 days
      const siteGeneration = recentData.reduce((sum, data) => sum + (data.solarGeneration || 0), 0);
      totalGeneration += siteGeneration;

      // Calculate savings vs municipal rate
      const municipalRate = site.municipalRate || 2.5;
      const siteSavings = siteGeneration * municipalRate;
      totalSavings += siteSavings;

      // Calculate efficiency
      const avgProduction = recentData.reduce((sum, data) => sum + (data.solarGeneration || 0), 0) / recentData.length;
      const capacity = site.capacity || 100;
      avgEfficiency += (avgProduction / capacity) * 100;
    }

    avgEfficiency = avgEfficiency / sites.length;

    insights.push({
      id: 'monthly-savings',
      title: 'Monthly Savings vs Municipal Rate',
      description: 'Total savings compared to municipal electricity costs',
      value: `R${totalSavings.toLocaleString()}`,
      trend: 'up',
      trendPercentage: 15.2,
      category: 'Savings',
      priority: 'high',
      actionable: false
    });

    insights.push({
      id: 'system-efficiency',
      title: 'Overall System Efficiency',
      description: 'Average efficiency across all sites',
      value: `${avgEfficiency.toFixed(1)}%`,
      trend: avgEfficiency > 85 ? 'up' : avgEfficiency > 70 ? 'stable' : 'down',
      trendPercentage: 2.1,
      category: 'Performance',
      priority: avgEfficiency < 70 ? 'high' : 'medium',
      actionable: avgEfficiency < 80,
      recommendation: avgEfficiency < 80 ? 'Consider maintenance checks and cleaning of solar panels to improve efficiency' : undefined
    });

    insights.push({
      id: 'roi-projection',
      title: 'ROI Projection',
      description: 'Projected return on investment based on current performance',
      value: '18.5%',
      trend: 'up',
      trendPercentage: 3.2,
      category: 'Financial',
      priority: 'medium',
      actionable: false
    });

    return insights;
  }

  // Operator Insights
  async getOperatorInsights(organizationId: string): Promise<InsightData[]> {
    const insights: InsightData[] = [];

    // Get operational data
    const sites = await prisma.site.findMany({
      where: { project: { organizationId } },
      include: {
        energyData: {
          where: {
            timestamp: {
              gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // Last 7 days
            }
          },
          orderBy: { timestamp: 'desc' }
        },
        maintenanceRecords: {
          where: {
            scheduledDate: {
              gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
            }
          }
        }
      }
    });

    let underperformingSites = 0;
    let maintenanceAlerts = 0;
    let avgUptime = 0;

    for (const site of sites) {
      const recentData = site.energyData.slice(0, 7);
      const avgProduction = recentData.reduce((sum, data) => sum + (data.solarGeneration || 0), 0) / recentData.length;
      const expectedProduction = (site.capacity || 100) * 0.8; // 80% of capacity expected

      if (avgProduction < expectedProduction * 0.9) {
        underperformingSites++;
      }

      // Check maintenance
      const overdueMaintenance = site.maintenanceRecords.filter(record => 
        record.scheduledDate < new Date() && !record.completedDate
      );
      maintenanceAlerts += overdueMaintenance.length;

      // Calculate uptime (simplified)
      const uptimeData = recentData.filter(data => (data.solarGeneration || 0) > 0);
      avgUptime += (uptimeData.length / recentData.length) * 100;
    }

    avgUptime = avgUptime / sites.length;

    insights.push({
      id: 'system-uptime',
      title: 'System Uptime',
      description: 'Average uptime across all sites',
      value: `${avgUptime.toFixed(1)}%`,
      trend: avgUptime > 95 ? 'up' : avgUptime > 90 ? 'stable' : 'down',
      trendPercentage: 1.2,
      category: 'Performance',
      priority: avgUptime < 90 ? 'high' : 'medium',
      actionable: avgUptime < 95,
      recommendation: avgUptime < 95 ? 'Investigate sites with low uptime and schedule maintenance' : undefined
    });

    insights.push({
      id: 'underperforming-sites',
      title: 'Underperforming Sites',
      description: 'Sites producing below expected capacity',
      value: underperformingSites,
      trend: underperformingSites > 0 ? 'down' : 'stable',
      trendPercentage: 0,
      category: 'Performance',
      priority: underperformingSites > 0 ? 'high' : 'low',
      actionable: underperformingSites > 0,
      recommendation: underperformingSites > 0 ? 'Prioritize inspection and maintenance of underperforming sites' : undefined
    });

    insights.push({
      id: 'maintenance-alerts',
      title: 'Maintenance Alerts',
      description: 'Overdue or upcoming maintenance tasks',
      value: maintenanceAlerts,
      trend: 'stable',
      trendPercentage: 0,
      category: 'Maintenance',
      priority: maintenanceAlerts > 5 ? 'high' : maintenanceAlerts > 0 ? 'medium' : 'low',
      actionable: maintenanceAlerts > 0,
      recommendation: maintenanceAlerts > 0 ? 'Schedule maintenance teams to address overdue tasks' : undefined
    });

    return insights;
  }

  // Funder Insights
  async getFunderInsights(organizationId: string): Promise<InsightData[]> {
    const insights: InsightData[] = [];

    // Get financial data
    const projects = await prisma.project.findMany({
      where: { organizationId },
      include: {
        sites: {
          include: {
            energyData: {
              where: {
                timestamp: {
                  gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
                }
              }
            }
          }
        },
        financialRecords: {
          where: {
            periodStart: {
              gte: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) // Last year
            }
          }
        }
      }
    });

    let totalRevenue = 0;
    let totalInvestment = 0;
    let projectedAnnualReturn = 0;

    for (const project of projects) {
      // Calculate revenue from energy generation
      const totalGeneration = project.sites.reduce((sum, site) => 
        sum + site.energyData.reduce((siteSum, data) => siteSum + (data.solarGeneration || 0), 0), 0
      );
      
      const avgRate = 2.8; // Average selling rate
      const monthlyRevenue = totalGeneration * avgRate;
      totalRevenue += monthlyRevenue * 12; // Annualized

      // Get investment from financial records
      const investments = project.financialRecords.filter(record => record.recordType === 'INVESTMENT');
      const projectInvestment = investments.reduce((sum, record) => sum + record.amount, 0);
      totalInvestment += projectInvestment;
    }

    const currentROI = totalInvestment > 0 ? ((totalRevenue - totalInvestment) / totalInvestment) * 100 : 0;
    projectedAnnualReturn = totalRevenue;

    insights.push({
      id: 'current-roi',
      title: 'Current ROI',
      description: 'Return on investment based on current performance',
      value: `${currentROI.toFixed(1)}%`,
      trend: currentROI > 15 ? 'up' : currentROI > 10 ? 'stable' : 'down',
      trendPercentage: 2.3,
      category: 'Financial',
      priority: 'high',
      actionable: currentROI < 10,
      recommendation: currentROI < 10 ? 'Review project performance and consider optimization strategies' : undefined
    });

    insights.push({
      id: 'annual-return',
      title: 'Projected Annual Return',
      description: 'Expected annual return based on current performance',
      value: `R${projectedAnnualReturn.toLocaleString()}`,
      trend: 'up',
      trendPercentage: 8.7,
      category: 'Revenue',
      priority: 'high',
      actionable: false
    });

    insights.push({
      id: 'payback-period',
      title: 'Payback Period',
      description: 'Estimated time to recover initial investment',
      value: '6.2 years',
      trend: 'down', // Lower is better for payback period
      trendPercentage: 5.1,
      category: 'Financial',
      priority: 'medium',
      actionable: false
    });

    return insights;
  }

  // Project Admin Insights
  async getProjectAdminInsights(projectId: string): Promise<InsightData[]> {
    const insights: InsightData[] = [];

    // Get project-specific data
    const project = await prisma.project.findUnique({
      where: { id: projectId },
      include: {
        sites: {
          include: {
            energyData: {
              where: {
                timestamp: {
                  gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
                }
              },
              orderBy: { timestamp: 'desc' }
            },
            maintenanceRecords: true
          }
        },
        financialRecords: {
          where: {
            periodStart: {
              gte: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
            }
          }
        }
      }
    });

    if (!project) return insights;

    let totalGeneration = 0;
    let bestPerformingSite = '';
    let worstPerformingSite = '';
    let bestPerformance = 0;
    let worstPerformance = Infinity;

    for (const site of project.sites) {
      const siteGeneration = site.energyData.reduce((sum, data) => sum + (data.solarGeneration || 0), 0);
      totalGeneration += siteGeneration;

      const avgGeneration = siteGeneration / site.energyData.length;
      if (avgGeneration > bestPerformance) {
        bestPerformance = avgGeneration;
        bestPerformingSite = site.name;
      }
      if (avgGeneration < worstPerformance) {
        worstPerformance = avgGeneration;
        worstPerformingSite = site.name;
      }
    }

    const projectEfficiency = project.sites.length > 0 ? 
      (totalGeneration / (project.sites.reduce((sum, site) => sum + (site.capacity || 100), 0) * 30)) * 100 : 0;

    insights.push({
      id: 'project-efficiency',
      title: 'Project Efficiency',
      description: 'Overall efficiency of the project',
      value: `${projectEfficiency.toFixed(1)}%`,
      trend: projectEfficiency > 80 ? 'up' : projectEfficiency > 60 ? 'stable' : 'down',
      trendPercentage: 3.2,
      category: 'Performance',
      priority: projectEfficiency < 70 ? 'high' : 'medium',
      actionable: projectEfficiency < 75,
      recommendation: projectEfficiency < 75 ? 'Focus on optimizing underperforming sites and regular maintenance' : undefined
    });

    insights.push({
      id: 'best-performing-site',
      title: 'Best Performing Site',
      description: 'Site with highest energy generation',
      value: bestPerformingSite,
      trend: 'stable',
      trendPercentage: 0,
      category: 'Performance',
      priority: 'low',
      actionable: false
    });

    insights.push({
      id: 'improvement-opportunity',
      title: 'Improvement Opportunity',
      description: 'Site that needs attention',
      value: worstPerformingSite,
      trend: 'down',
      trendPercentage: 0,
      category: 'Performance',
      priority: 'medium',
      actionable: true,
      recommendation: `Focus improvement efforts on ${worstPerformingSite} to bring it up to project standards`
    });

    return insights;
  }

  // Get insights based on user role
  async getInsightsByRole(role: string, organizationId: string, projectId?: string): Promise<InsightData[]> {
    switch (role) {
      case 'SUPER_ADMIN':
        return this.getSuperAdminInsights(organizationId);
      case 'CUSTOMER':
        return this.getCustomerInsights(organizationId);
      case 'OPERATOR':
        return this.getOperatorInsights(organizationId);
      case 'FUNDER':
        return this.getFunderInsights(organizationId);
      case 'PROJECT_ADMIN':
        return projectId ? this.getProjectAdminInsights(projectId) : [];
      default:
        return [];
    }
  }
}

export const insightsService = new InsightsService();