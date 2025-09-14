"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.dataSyncService = exports.DataSyncService = void 0;
const node_cron_1 = __importDefault(require("node-cron"));
const client_1 = require("@prisma/client");
const solaxDatabaseService_1 = require("./solaxDatabaseService");
const weatherService_1 = require("./weatherService");
const logger_1 = require("../utils/logger");
const prisma = new client_1.PrismaClient();
class DataSyncService {
    constructor() {
        this.isRunning = false;
        this.stats = {
            sitesProcessed: 0,
            recordsUpdated: 0,
            errors: 0,
            lastSync: new Date()
        };
        // Default to hourly sync, configurable via environment
        const intervalHours = parseInt(process.env.SOLAX_SYNC_INTERVAL_HOURS || '1');
        this.syncInterval = `0 */${intervalHours} * * *`; // Every N hours
        logger_1.logger.info(`Data sync service initialized with interval: every ${intervalHours} hour(s)`);
    }
    /**
     * Start the scheduled data synchronization
     */
    start() {
        logger_1.logger.info('Starting data synchronization service...');
        // Schedule the sync job
        node_cron_1.default.schedule(this.syncInterval, async () => {
            if (!this.isRunning) {
                await this.performSync();
            }
            else {
                logger_1.logger.warn('Sync already running, skipping this interval');
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
    stop() {
        logger_1.logger.info('Stopping data synchronization service...');
        this.isRunning = false;
    }
    /**
     * Get current synchronization statistics
     */
    getStats() {
        return { ...this.stats };
    }
    /**
     * Perform a complete data synchronization
     */
    async performSync() {
        if (this.isRunning) {
            logger_1.logger.warn('Sync already in progress');
            return;
        }
        this.isRunning = true;
        const startTime = Date.now();
        logger_1.logger.info('Starting data synchronization...');
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
            logger_1.logger.info(`Found ${sites.length} active sites to sync`);
            // Process each site
            for (const site of sites) {
                try {
                    await this.syncSiteData(site);
                    this.stats.sitesProcessed++;
                }
                catch (error) {
                    logger_1.logger.error(`Error syncing site ${site.id}:`, error);
                    this.stats.errors++;
                }
            }
            // Update weather data for all sites
            await this.syncWeatherData();
            // Update sync statistics
            this.stats.lastSync = new Date();
            const duration = Date.now() - startTime;
            logger_1.logger.info(`Data sync completed in ${duration}ms. Sites: ${this.stats.sitesProcessed}, Records: ${this.stats.recordsUpdated}, Errors: ${this.stats.errors}`);
            // Store sync statistics
            await this.storeSyncStats(duration);
        }
        catch (error) {
            logger_1.logger.error('Error during data synchronization:', error);
            this.stats.errors++;
        }
        finally {
            this.isRunning = false;
        }
    }
    /**
     * Sync data for a specific site
     */
    async syncSiteData(site) {
        logger_1.logger.debug(`Syncing data for site: ${site.name} (${site.id})`);
        try {
            // Sync SolaX database data if available
            if (site.solaxStationId) {
                await this.syncSolaxData(site);
            }
            // Update site metrics
            await this.updateSiteMetrics(site);
        }
        catch (error) {
            logger_1.logger.error(`Error syncing site ${site.id}:`, error);
            throw error;
        }
    }
    /**
     * Sync SolaX database data for a site
     */
    async syncSolaxData(site) {
        try {
            const solaxData = await solaxDatabaseService_1.solaxDatabaseService.getLatestData(site.solaxStationId);
            if (solaxData && solaxData.length > 0) {
                for (const data of solaxData) {
                    // Create or update energy data record
                    await prisma.energyData.create({
                        data: {
                            timestamp: new Date(data.uploadTime),
                            solarGeneration: data.yieldtoday || 0,
                            solarPower: data.acpower || 0,
                            gridConsumption: data.consumeenergy || 0,
                            gridPower: data.feedinpower || 0,
                            batteryCharge: data.batPower || 0,
                            batterySOC: data.soc || 0,
                            temperature: data.temperature || null,
                            siteId: site.id,
                            deviceId: site.devices[0]?.id || null
                        }
                    });
                    this.stats.recordsUpdated++;
                }
            }
        }
        catch (error) {
            logger_1.logger.error(`Error syncing SolaX data for site ${site.id}:`, error);
            throw error;
        }
    }
    /**
     * Update site metrics based on recent data
     */
    async updateSiteMetrics(site) {
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
                logger_1.logger.debug(`No recent data found for site ${site.id}`);
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
                    averageEfficiency: 0, // Calculate from available data
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
            logger_1.logger.debug(`Updated metrics for site ${site.id}`);
        }
        catch (error) {
            logger_1.logger.error(`Error updating metrics for site ${site.id}:`, error);
            throw error;
        }
    }
    /**
     * Sync weather data for all sites
     */
    async syncWeatherData() {
        try {
            logger_1.logger.debug('Syncing weather data...');
            const sites = await prisma.site.findMany({
                where: {
                    isActive: true,
                    latitude: { not: null },
                    longitude: { not: null }
                }
            });
            for (const site of sites) {
                try {
                    const weatherData = await weatherService_1.weatherService.getCurrentWeather(site.latitude, site.longitude);
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
                                condition: weatherData.condition,
                                latitude: site.latitude,
                                longitude: site.longitude,
                                siteId: site.id
                            }
                        });
                        this.stats.recordsUpdated++;
                    }
                }
                catch (error) {
                    logger_1.logger.error(`Error syncing weather data for site ${site.id}:`, error);
                    this.stats.errors++;
                }
            }
            logger_1.logger.debug('Weather data sync completed');
        }
        catch (error) {
            logger_1.logger.error('Error syncing weather data:', error);
            throw error;
        }
    }
    /**
     * Store synchronization statistics
     */
    async storeSyncStats(duration) {
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
        }
        catch (error) {
            logger_1.logger.error('Error storing sync stats:', error);
        }
    }
    /**
     * Manual sync trigger for testing
     */
    async triggerSync() {
        await this.performSync();
        return this.getStats();
    }
}
exports.DataSyncService = DataSyncService;
// Export singleton instance
exports.dataSyncService = new DataSyncService();
//# sourceMappingURL=dataSyncService.old.js.map