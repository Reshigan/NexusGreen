import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

// Get solar data for a site
router.get('/site/:siteId/data', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { siteId } = req.params;
    
    const site = await prisma.site.findUnique({
      where: { id: siteId },
      include: {
        energyData: {
          take: 100,
          orderBy: { timestamp: 'desc' }
        }
      }
    });

    if (!site) {
      return res.status(404).json({ error: 'Site not found' });
    }

    // Calculate basic solar metrics
    let totalGeneration = 0;
    let totalConsumption = 0;
    let totalExport = 0;

    site.energyData.forEach(data => {
      totalGeneration += data.solarGeneration || 0;
      totalConsumption += data.gridConsumption || 0;
      totalExport += data.exportedEnergy || 0;
    });

    res.json({
      site: {
        id: site.id,
        name: site.name,
        capacity: site.capacity,
        isActive: site.isActive
      },
      metrics: {
        totalGeneration,
        totalConsumption,
        totalExport,
        selfConsumption: Math.max(0, totalGeneration - totalExport),
        dataPoints: site.energyData.length
      },
      recentData: site.energyData.slice(0, 10).map(data => ({
        timestamp: data.timestamp,
        solarGeneration: data.solarGeneration,
        gridConsumption: data.gridConsumption,
        batterySOC: data.batterySOC,
        temperature: data.temperature
      }))
    });

  } catch (error) {
    console.error('Solar data error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get solar overview for user
router.get('/overview/:userId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        organization: {
          include: {
            sites: {
              include: {
                energyData: {
                  take: 10,
                  orderBy: { timestamp: 'desc' }
                }
              }
            }
          }
        }
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const sites = user.organization.sites;
    let totalCapacity = 0;
    let totalGeneration = 0;
    let activeSites = 0;

    const siteMetrics = sites.map(site => {
      if (site.isActive) activeSites++;
      totalCapacity += site.capacity;

      let siteGeneration = 0;
      site.energyData.forEach(data => {
        siteGeneration += data.solarGeneration || 0;
      });
      totalGeneration += siteGeneration;

      return {
        id: site.id,
        name: site.name,
        capacity: site.capacity,
        isActive: site.isActive,
        generation: siteGeneration,
        lastUpdate: site.energyData[0]?.timestamp || null
      };
    });

    res.json({
      overview: {
        totalSites: sites.length,
        activeSites,
        totalCapacity,
        totalGeneration
      },
      sites: siteMetrics
    });

  } catch (error) {
    console.error('Solar overview error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get solar performance metrics
router.get('/performance/:siteId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { siteId } = req.params;
    const { period = '7d' } = req.query;

    // Calculate date range based on period
    const now = new Date();
    let startDate = new Date();
    
    switch (period) {
      case '1d':
        startDate.setDate(now.getDate() - 1);
        break;
      case '7d':
        startDate.setDate(now.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(now.getDate() - 30);
        break;
      case '1y':
        startDate.setFullYear(now.getFullYear() - 1);
        break;
      default:
        startDate.setDate(now.getDate() - 7);
    }

    const site = await prisma.site.findUnique({
      where: { id: siteId },
      include: {
        energyData: {
          where: {
            timestamp: {
              gte: startDate,
              lte: now
            }
          },
          orderBy: { timestamp: 'asc' }
        }
      }
    });

    if (!site) {
      return res.status(404).json({ error: 'Site not found' });
    }

    // Calculate performance metrics
    const performanceData = site.energyData.map(data => ({
      timestamp: data.timestamp,
      generation: data.solarGeneration || 0,
      consumption: data.gridConsumption || 0,
      efficiency: data.solarGeneration ? 
        ((data.solarGeneration / site.capacity) * 100) : 0,
      temperature: data.temperature,
      irradiance: data.irradiance
    }));

    const totalGeneration = performanceData.reduce((sum, data) => sum + data.generation, 0);
    const avgEfficiency = performanceData.length > 0 ? 
      performanceData.reduce((sum, data) => sum + data.efficiency, 0) / performanceData.length : 0;

    res.json({
      site: {
        id: site.id,
        name: site.name,
        capacity: site.capacity
      },
      period,
      metrics: {
        totalGeneration,
        averageEfficiency: avgEfficiency,
        dataPoints: performanceData.length
      },
      data: performanceData
    });

  } catch (error) {
    console.error('Solar performance error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check endpoint
router.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;