import { Request, Response } from 'express';
import { PrismaClient, UserRole } from '@prisma/client';
import { AuthenticatedUser } from '../types/express';
import { insightsService } from '../services/insightsService';

interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
}

const prisma = new PrismaClient();

export class DashboardController {
  // Super Admin Dashboard
  static async getSuperAdminDashboard(req: Request, res: Response) {
    try {
      const { user } = req;
      
      if (user?.role !== UserRole.SUPER_ADMIN) {
        return res.status(403).json({ error: 'Access denied' });
      }

      // Get system-wide statistics
      const [
        totalOrganizations,
        totalUsers,
        totalProjects,
        totalSites,
        activeLicenses,
        recentActivity
      ] = await Promise.all([
        prisma.organization.count({ where: { isActive: true } }),
        prisma.user.count({ where: { isActive: true } }),
        prisma.project.count({ where: { isActive: true } }),
        prisma.site.count({ where: { isActive: true } }),
        prisma.license.count({ where: { isActive: true } }),
        prisma.auditLog.findMany({
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { firstName: true, lastName: true, email: true } } }
        })
      ]);

      // Get license revenue and usage
      const licenseStats = await prisma.license.groupBy({
        by: ['licenseType'],
        _count: { id: true },
        where: { isActive: true }
      });

      // Get monthly growth metrics
      const monthlyGrowth = await prisma.organization.groupBy({
        by: ['createdAt'],
        _count: { id: true },
        where: {
          createdAt: {
            gte: new Date(new Date().setMonth(new Date().getMonth() - 12))
          }
        }
      });

      res.json({
        overview: {
          totalOrganizations,
          totalUsers,
          totalProjects,
          totalSites,
          activeLicenses
        },
        licenseStats,
        monthlyGrowth,
        recentActivity
      });
    } catch (error) {
      console.error('Super Admin Dashboard Error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  }

  // Customer Dashboard
  static async getCustomerDashboard(req: Request, res: Response) {
    try {
      const { user } = req;
      
      if (user?.role !== UserRole.CUSTOMER) {
        return res.status(403).json({ error: 'Access denied' });
      }

      const organizationId = user.organizationId;

      // Get customer's sites and projects
      const [sites, projects] = await Promise.all([
        prisma.site.findMany({
          where: { organizationId },
          include: {
            siteMetrics: {
              take: 30,
              orderBy: { date: 'desc' }
            },
            project: true
          }
        }),
        prisma.project.findMany({
          where: { organizationId },
          include: {
            sites: {
              include: {
                siteMetrics: {
                  take: 1,
                  orderBy: { date: 'desc' }
                }
              }
            }
          }
        })
      ]);

      // Calculate total savings vs municipal rates
      const totalSavings = await prisma.financialRecord.aggregate({
        where: {
          OR: [
            { site: { organizationId } },
            { project: { organizationId } }
          ],
          recordType: 'MUNICIPAL_COMPARISON'
        },
        _sum: { savingsVsMunicipal: true }
      });

      // Get efficiency metrics
      const efficiencyMetrics = await prisma.roleKPI.findMany({
        where: {
          role: UserRole.CUSTOMER,
          organizationId,
          kpiName: { in: ['System Efficiency', 'Total Savings', 'Energy Independence'] }
        },
        orderBy: { calculatedAt: 'desc' },
        take: 10
      });

      // Get recent alerts
      const alerts = await prisma.alert.findMany({
        where: {
          site: { organizationId },
          status: { in: ['OPEN', 'ACKNOWLEDGED'] }
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: { site: { select: { name: true } } }
      });

      res.json({
        overview: {
          totalSites: sites.length,
          totalProjects: projects.length,
          totalSavings: totalSavings._sum.savingsVsMunicipal || 0,
          activeAlerts: alerts.length
        },
        sites,
        projects,
        efficiencyMetrics,
        alerts,
        savingsBreakdown: {
          monthly: await calculateMonthlySavings(organizationId),
          yearly: await calculateYearlySavings(organizationId)
        }
      });
    } catch (error) {
      console.error('Customer Dashboard Error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  }

  // Operator Dashboard
  static async getOperatorDashboard(req: Request, res: Response) {
    try {
      const { user } = req;
      
      if (user?.role !== UserRole.OPERATOR) {
        return res.status(403).json({ error: 'Access denied' });
      }

      const organizationId = user.organizationId;

      // Get operational metrics
      const [sites, devices, alerts] = await Promise.all([
        prisma.site.findMany({
          where: { organizationId },
          include: {
            devices: true,
            siteMetrics: {
              take: 1,
              orderBy: { date: 'desc' }
            },
            alerts: {
              where: { status: { in: ['OPEN', 'ACKNOWLEDGED'] } }
            }
          }
        }),
        prisma.device.findMany({
          where: { site: { organizationId } },
          include: { site: { select: { name: true } } }
        }),
        prisma.alert.findMany({
          where: {
            site: { organizationId },
            alertType: { in: ['PERFORMANCE', 'MAINTENANCE'] }
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
          include: { site: { select: { name: true } } }
        })
      ]);

      // Calculate system performance
      const performanceMetrics = await prisma.roleKPI.findMany({
        where: {
          role: UserRole.OPERATOR,
          organizationId,
          kpiName: { in: ['System Availability', 'Performance Ratio', 'Capacity Factor'] }
        },
        orderBy: { calculatedAt: 'desc' },
        take: 10
      });

      // Get maintenance schedule
      const maintenanceSchedule = await prisma.maintenanceRecord.findMany({
        where: {
          site: { organizationId },
          completedDate: null
        },
        orderBy: { scheduledDate: 'asc' },
        take: 10,
        include: { site: { select: { name: true } } }
      });

      res.json({
        overview: {
          totalSites: sites.length,
          totalDevices: devices.length,
          onlineDevices: devices.filter(d => d.status === 'ONLINE').length,
          criticalAlerts: alerts.filter(a => a.severity === 'CRITICAL').length
        },
        sites,
        performanceMetrics,
        alerts,
        maintenanceSchedule,
        deviceStatus: {
          online: devices.filter(d => d.status === 'ONLINE').length,
          offline: devices.filter(d => d.status === 'OFFLINE').length,
          maintenance: devices.filter(d => d.status === 'MAINTENANCE').length,
          error: devices.filter(d => d.status === 'ERROR').length
        }
      });
    } catch (error) {
      console.error('Operator Dashboard Error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  }

  // Funder Dashboard
  static async getFunderDashboard(req: Request, res: Response) {
    try {
      const { user } = req;
      
      if (user?.role !== UserRole.FUNDER) {
        return res.status(403).json({ error: 'Access denied' });
      }

      const organizationId = user.organizationId;

      // Get funded projects
      const projects = await prisma.project.findMany({
        where: { organizationId },
        include: {
          sites: {
            include: {
              siteMetrics: {
                take: 30,
                orderBy: { date: 'desc' }
              }
            }
          },
          financialRecords: {
            where: { recordType: 'FUNDER_RETURN' },
            orderBy: { createdAt: 'desc' }
          }
        }
      });

      // Calculate ROI metrics
      const roiMetrics = await prisma.roleKPI.findMany({
        where: {
          role: UserRole.FUNDER,
          organizationId,
          kpiName: { in: ['ROI', 'Revenue', 'Payback Period'] }
        },
        orderBy: { calculatedAt: 'desc' },
        take: 10
      });

      // Calculate total investment and returns
      const totalInvestment = projects.reduce((sum, project) => 
        sum + (project.totalInvestment || 0), 0);
      
      const totalReturns = await prisma.financialRecord.aggregate({
        where: {
          project: { organizationId },
          recordType: 'FUNDER_RETURN'
        },
        _sum: { amount: true }
      });

      res.json({
        overview: {
          totalProjects: projects.length,
          totalInvestment,
          totalReturns: totalReturns._sum.amount || 0,
          averageROI: roiMetrics.find(m => m.kpiName === 'ROI')?.kpiValue || 0
        },
        projects,
        roiMetrics,
        monthlyReturns: await calculateMonthlyReturns(organizationId),
        performanceByProject: projects.map(project => ({
          id: project.id,
          name: project.name,
          investment: project.totalInvestment,
          expectedROI: project.expectedROI,
          actualROI: calculateProjectROI(project),
          sites: project.sites.length
        }))
      });
    } catch (error) {
      console.error('Funder Dashboard Error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  }

  // Project Admin Dashboard
  static async getProjectAdminDashboard(req: Request, res: Response) {
    try {
      const { user } = req;
      
      if (user?.role !== UserRole.PROJECT_ADMIN) {
        return res.status(403).json({ error: 'Access denied' });
      }

      const projectId = user.projectId;
      if (!projectId) {
        return res.status(400).json({ error: 'No project assigned' });
      }

      // Get project details and sites
      const [project, sites, users] = await Promise.all([
        prisma.project.findUnique({
          where: { id: projectId },
          include: {
            organization: { select: { name: true } },
            financialRecords: {
              orderBy: { createdAt: 'desc' },
              take: 10
            }
          }
        }),
        prisma.site.findMany({
          where: { projectId },
          include: {
            devices: true,
            siteMetrics: {
              take: 1,
              orderBy: { date: 'desc' }
            },
            alerts: {
              where: { status: { in: ['OPEN', 'ACKNOWLEDGED'] } }
            }
          }
        }),
        prisma.user.findMany({
          where: { projectId },
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            role: true,
            isActive: true,
            lastLoginAt: true
          }
        })
      ]);

      if (!project) {
        return res.status(404).json({ error: 'Project not found' });
      }

      // Get project-specific KPIs
      const projectKPIs = await prisma.roleKPI.findMany({
        where: {
          role: UserRole.PROJECT_ADMIN,
          projectId,
          kpiName: { in: ['Project Performance', 'Site Availability', 'User Activity'] }
        },
        orderBy: { calculatedAt: 'desc' },
        take: 10
      });

      res.json({
        project,
        overview: {
          totalSites: sites.length,
          totalUsers: users.length,
          activeUsers: users.filter(u => u.isActive).length,
          totalAlerts: sites.reduce((sum, site) => sum + site.alerts.length, 0)
        },
        sites,
        users,
        projectKPIs,
        recentActivity: await getProjectActivity(projectId)
      });
    } catch (error) {
      console.error('Project Admin Dashboard Error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  }
}

// Helper functions
async function calculateMonthlySavings(organizationId: string) {
  const startDate = new Date();
  startDate.setMonth(startDate.getMonth() - 1);
  
  const savings = await prisma.financialRecord.aggregate({
    where: {
      OR: [
        { site: { organizationId } },
        { project: { organizationId } }
      ],
      recordType: 'MUNICIPAL_COMPARISON',
      createdAt: { gte: startDate }
    },
    _sum: { savingsVsMunicipal: true }
  });
  
  return savings._sum.savingsVsMunicipal || 0;
}

async function calculateYearlySavings(organizationId: string) {
  const startDate = new Date();
  startDate.setFullYear(startDate.getFullYear() - 1);
  
  const savings = await prisma.financialRecord.aggregate({
    where: {
      OR: [
        { site: { organizationId } },
        { project: { organizationId } }
      ],
      recordType: 'MUNICIPAL_COMPARISON',
      createdAt: { gte: startDate }
    },
    _sum: { savingsVsMunicipal: true }
  });
  
  return savings._sum.savingsVsMunicipal || 0;
}

async function calculateMonthlyReturns(organizationId: string) {
  const returns = await prisma.financialRecord.groupBy({
    by: ['createdAt'],
    where: {
      project: { organizationId },
      recordType: 'FUNDER_RETURN'
    },
    _sum: { amount: true },
    orderBy: { createdAt: 'desc' }
  });
  
  return returns;
}

function calculateProjectROI(project: any) {
  if (!project.totalInvestment || project.totalInvestment === 0) return 0;
  
  const totalReturns = project.financialRecords
    .filter((record: any) => record.recordType === 'FUNDER_RETURN')
    .reduce((sum: number, record: any) => sum + record.amount, 0);
  
  return ((totalReturns - project.totalInvestment) / project.totalInvestment) * 100;
}

async function getProjectActivity(projectId: string) {
  return await prisma.auditLog.findMany({
    where: {
      OR: [
        { resource: 'Project', resourceId: projectId },
        { resource: 'Site', resourceId: { in: await getSiteIds(projectId) } }
      ]
    },
    orderBy: { createdAt: 'desc' },
    take: 10,
    include: { user: { select: { firstName: true, lastName: true } } }
  });
}

async function getSiteIds(projectId: string) {
  const sites = await prisma.site.findMany({
    where: { projectId },
    select: { id: true }
  });
  return sites.map(site => site.id);
}

// Insights endpoint
export async function getInsights(req: Request, res: Response) {
  try {
    const user = req.user;
    
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const insights = await insightsService.getInsightsByRole(
      user.role,
      user.organizationId,
      (user as any).projectId || undefined
    );

    res.json({
      success: true,
      data: insights
    });
  } catch (error) {
    console.error('Error fetching insights:', error);
    res.status(500).json({ error: 'Failed to fetch insights' });
  }
}