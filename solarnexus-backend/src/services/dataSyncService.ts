import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';
import { solaxDatabaseService } from './solaxDatabaseService';
import { weatherService } from './weatherService';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

interface SyncStats {
  sitesProcessed: number;
  recordsUpdated: number;
  errors: number;
  lastSync: Date;
}

export class DataSyncService {
  private isRunning: boolean = false;
  private syncInterval: string;
  private stats: SyncStats = {
    sitesProcessed: 0,
    recordsUpdated: 0,
    errors: 0,
    lastSync: new Date()
  };

  constructor() {
    // Default to 60 minutes, configurable via environment (60-90 minutes recommended)
    const intervalMinutes = parseInt(process.env.SOLAX_SYNC_INTERVAL_MINUTES || '60');
    
    // Validate interval is between 30-120 minutes for optimal performance
    const validInterval = Math.max(30, Math.min(120, intervalMinutes));
    
    if (validInterval >= 60) {
      // For intervals >= 60 minutes, use hourly cron pattern
      const hours = Math.floor(validInterval / 60);
      const minutes = validInterval % 60;
      if (minutes === 0) {
        this.syncInterval = `0 */${hours} * * *`; // Every N hours
      } else {
        // For non-hour intervals, use minute-based pattern
        this.syncInterval = `*/${validInterval} * * * *`; // Every N minutes
      }
    } else {
      this.syncInterval = `*/${validInterval} * * * *`; // Every N minutes
    }
    
    logger.info(`NexusGreen data sync service initialized with interval: every ${validInterval} minutes`);
    logger.info(`Cron pattern: ${this.syncInterval}`);
  }

  /**
   * Start the scheduled data synchronization
   */
  start(): void {
    logger.info('Starting data synchronization service...');
    
    // Schedule the sync job
    cron.schedule(this.syncInterval, async () => {
      if (!this.isRunning) {
        await this.performSync();
      } else {
        logger.warn('Sync already running, skipping this interval');
      }
    });

    // Run initial sync after 1 minute
    setTimeout(() => {
      this.performSync();
    }, 60000);
  }

  /**
   * Stop the data synchronization service
   */
  stop(): void {
    logger.info('Stopping data synchronization service...');
    this.isRunning = false;
  }

  /**
   * Get current synchronization statistics
   */
  getStats(): SyncStats {
    return { ...this.stats };
  }

  /**
   * Manually trigger a data refresh (useful for on-demand updates)
   */
  async manualRefresh(): Promise<{ success: boolean; message: string; stats?: SyncStats }> {
    if (this.isRunning) {
      return {
        success: false,
        message: 'Data sync already in progress. Please wait for current sync to complete.'
      };
    }

    try {
      logger.info('Manual data refresh triggered');
      await this.performSync();
      return {
        success: true,
        message: 'Data refresh completed successfully',
        stats: this.getStats()
      };
    } catch (error) {
      logger.error('Manual refresh failed:', error);
      return {
        success: false,
        message: `Manual refresh failed: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }
  }

  /**
   * Update sync interval dynamically (60-90 minutes recommended)
   */
  updateSyncInterval(minutes: number): { success: boolean; message: string } {
    const validInterval = Math.max(30, Math.min(120, minutes));
    
    if (validInterval >= 60) {
      const hours = Math.floor(validInterval / 60);
      const mins = validInterval % 60;
      if (mins === 0) {
        this.syncInterval = `0 */${hours} * * *`;
      } else {
        this.syncInterval = `*/${validInterval} * * * *`;
      }
    } else {
      this.syncInterval = `*/${validInterval} * * * *`;
    }

    logger.info(`Sync interval updated to every ${validInterval} minutes (${this.syncInterval})`);
    
    return {
      success: true,
      message: `Sync interval updated to every ${validInterval} minutes. Restart required for changes to take effect.`
    };
  }

  /**
   * Perform a complete data synchronization
   */
  private async performSync(): Promise<void> {
    if (this.isRunning) {
      logger.warn('Sync already in progress');
      return;
    }

    this.isRunning = true;
    const startTime = Date.now();
    
    logger.info('Starting data synchronization...');
    
    try {
      // Reset stats for this sync
      this.stats.sitesProcessed = 0;
      this.stats.recordsUpdated = 0;
      this.stats.errors = 0;

      // Get all active sites
      const sites = await prisma.site.findMany({
        where: {
          isActive: true
        },
        include: {
          devices: true
        }
      });

      logger.info(`Found ${sites.length} active sites to sync`);

      // Process each site
      for (const site of sites) {
        try {
          await this.syncSiteData(site);
          this.stats.sitesProcessed++;
        } catch (error) {
          logger.error(`Error syncing site ${site.id}:`, error);
          this.stats.errors++;
        }
      }

      // Update weather data for all sites
      await this.syncWeatherData();

      // Update sync statistics
      this.stats.lastSync = new Date();
      
      const duration = Date.now() - startTime;
      logger.info(`Data sync completed in ${duration}ms. Sites: ${this.stats.sitesProcessed}, Records: ${this.stats.recordsUpdated}, Errors: ${this.stats.errors}`);

      // Store sync statistics
      await this.storeSyncStats(duration);

    } catch (error) {
      logger.error('Error during data synchronization:', error);
      this.stats.errors++;
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Sync data for a specific site
   */
  private async syncSiteData(site: any): Promise<void> {
    logger.debug(`Syncing data for site: ${site.name} (${site.id})`);

    try {
      // Sync SolaX database data if available
      if (site.solaxStationId) {
        await this.syncSolaxData(site);
      }

      // Update site metrics
      await this.updateSiteMetrics(site);

    } catch (error) {
      logger.error(`Error syncing site ${site.id}:`, error);
      throw error;
    }
  }

  /**
   * Sync SolaX database data for a site
   */
  private async syncSolaxData(site: any): Promise<void> {
    try {
      const solaxData = await solaxDatabaseService.getLatestEnergyData(site.solaxStationId);
      
      if (solaxData) {
        // Create energy data record
        await prisma.energyData.create({
          data: {
            timestamp: solaxData.timestamp,
            solarGeneration: solaxData.generation || 0,
            solarPower: 0, // Not available in this interface
            gridConsumption: solaxData.consumption || 0,
            gridPower: 0, // Not available in this interface
            batteryCharge: solaxData.batteryCharge || 0,
            batterySOC: 0, // Not available in this interface
            temperature: solaxData.temperature || null,
            siteId: site.id,
            deviceId: site.devices[0]?.id || null
          }
        });
        
        this.stats.recordsUpdated++;
      }
    } catch (error) {
      logger.error(`Error syncing SolaX data for site ${site.id}:`, error);
      throw error;
    }
  }

  /**
   * Update site metrics based on recent data
   */
  private async updateSiteMetrics(site: any): Promise<void> {
    try {
      const timestamp = new Date();
      const last24Hours = new Date(timestamp.getTime() - 24 * 60 * 60 * 1000);
      
      // Get recent energy data for the site
      const recentData = await prisma.energyData.findMany({
        where: {
          siteId: site.id,
          timestamp: {
            gte: last24Hours,
            lte: timestamp
          }
        },
        orderBy: {
          timestamp: 'desc'
        }
      });

      if (recentData.length === 0) {
        logger.debug(`No recent data found for site ${site.id}`);
        return;
      }

      // Calculate basic metrics
      const totalGeneration = recentData.reduce((sum, data) => sum + (data.solarGeneration || 0), 0);
      const totalConsumption = recentData.reduce((sum, data) => sum + (data.gridConsumption || 0), 0);
      const totalExported = recentData.reduce((sum, data) => sum + (data.exportedEnergy || 0), 0);
      const avgTemperature = recentData.reduce((sum, data) => sum + (data.temperature || 0), 0) / recentData.length;

      // Calculate capacity factor
      const capacityFactor = site.capacity > 0 ? 
        (totalGeneration / (site.capacity * 24)) * 100 : 0;

      // Calculate availability
      const expectedDataPoints = 24; // Hourly data for 24 hours
      const availability = (recentData.length / expectedDataPoints) * 100;

      // Update site metrics
      await prisma.siteMetrics.upsert({
        where: {
          siteId_date: {
            siteId: site.id,
            date: new Date(timestamp.getFullYear(), timestamp.getMonth(), timestamp.getDate())
          }
        },
        update: {
          totalGeneration,
          totalConsumption,
          totalGridImport: totalConsumption,
          totalGridExport: totalExported,
          averageEfficiency: 0,
          capacityFactor: Math.min(capacityFactor, 100),
          availability: Math.min(availability, 100),
          averageTemperature: avgTemperature,
          lastUpdated: timestamp
        },
        create: {
          siteId: site.id,
          date: new Date(timestamp.getFullYear(), timestamp.getMonth(), timestamp.getDate()),
          totalGeneration,
          totalConsumption,
          totalGridImport: totalConsumption,
          totalGridExport: totalExported,
          averageEfficiency: 0,
          capacityFactor: Math.min(capacityFactor, 100),
          availability: Math.min(availability, 100),
          averageTemperature: avgTemperature,
          lastUpdated: timestamp
        }
      });

      this.stats.recordsUpdated++;
      logger.debug(`Updated metrics for site ${site.id}`);

    } catch (error) {
      logger.error(`Error updating metrics for site ${site.id}:`, error);
      throw error;
    }
  }

  /**
   * Sync weather data for all sites
   */
  private async syncWeatherData(): Promise<void> {
    try {
      logger.debug('Syncing weather data...');
      
      const sites = await prisma.site.findMany({
        where: {
          isActive: true
        }
      });

      for (const site of sites) {
        try {
          const weatherData = await weatherService.getCurrentWeather(
            site.latitude,
            site.longitude
          );

          if (weatherData) {
            // Store weather data
            await prisma.weatherData.create({
              data: {
                timestamp: new Date(),
                temperature: weatherData.temperature,
                humidity: weatherData.humidity,
                windSpeed: weatherData.windSpeed,
                windDirection: weatherData.windDirection,
                pressure: weatherData.pressure,
                visibility: weatherData.visibility,
                uvIndex: weatherData.uvIndex,
                cloudCover: weatherData.cloudCover,
                description: weatherData.description || 'Clear',
                siteId: site.id
              }
            });

            this.stats.recordsUpdated++;
          }
        } catch (error) {
          logger.error(`Error syncing weather data for site ${site.id}:`, error);
          this.stats.errors++;
        }
      }

      logger.debug('Weather data sync completed');
    } catch (error) {
      logger.error('Error syncing weather data:', error);
      throw error;
    }
  }

  /**
   * Store synchronization statistics
   */
  private async storeSyncStats(duration: number): Promise<void> {
    try {
      await prisma.syncStats.create({
        data: {
          timestamp: new Date(),
          sitesProcessed: this.stats.sitesProcessed,
          recordsUpdated: this.stats.recordsUpdated,
          errors: this.stats.errors,
          duration
        }
      });
    } catch (error) {
      logger.error('Error storing sync stats:', error);
    }
  }

  /**
   * Manual sync trigger for testing
   */
  async triggerSync(): Promise<SyncStats> {
    await this.performSync();
    return this.getStats();
  }
}

// Export singleton instance
export const dataSyncService = new DataSyncService();