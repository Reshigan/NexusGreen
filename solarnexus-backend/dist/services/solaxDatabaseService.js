"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.solaxDatabaseService = exports.SolaxDatabaseService = void 0;
const promise_1 = __importDefault(require("mysql2/promise"));
const logger_1 = require("../utils/logger");
class SolaxDatabaseService {
    constructor() {
        this.connection = null;
        this.config = {
            host: process.env.SOLAX_DB_HOST || 'localhost',
            user: process.env.SOLAX_DB_USER || 'dev',
            password: process.env.SOLAX_DB_PASSWORD || '',
            database: process.env.SOLAX_DB_NAME || 'PPA_Reporting'
        };
    }
    /**
     * Initialize database connection
     */
    async connect() {
        try {
            this.connection = await promise_1.default.createConnection({
                host: this.config.host,
                user: this.config.user,
                password: this.config.password,
                database: this.config.database,
                timezone: '+00:00',
                dateStrings: false,
                supportBigNumbers: true,
                bigNumberStrings: false
            });
            logger_1.logger.info('Connected to SolaX database successfully');
        }
        catch (error) {
            logger_1.logger.error('Failed to connect to SolaX database:', error);
            throw new Error('SolaX database connection failed');
        }
    }
    /**
     * Ensure connection is active
     */
    async ensureConnection() {
        if (!this.connection) {
            await this.connect();
        }
    }
    /**
     * Get plant information
     */
    async getPlantInfo(plantId) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          plant_name as plantName,
          capacity,
          location,
          install_date as installDate,
          status
        FROM plants 
        WHERE plant_id = ?`, [plantId]);
            const plants = rows;
            return plants.length > 0 ? plants[0] : null;
        }
        catch (error) {
            logger_1.logger.error('Error fetching plant info:', error);
            throw error;
        }
    }
    /**
     * Get energy data for a specific time range
     */
    async getEnergyData(plantId, startDate, endDate) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          timestamp,
          generation,
          consumption,
          grid_import as gridImport,
          grid_export as gridExport,
          battery_charge as batteryCharge,
          battery_discharge as batteryDischarge,
          efficiency,
          temperature,
          irradiance
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?
        ORDER BY timestamp ASC`, [plantId, startDate, endDate]);
            return rows;
        }
        catch (error) {
            logger_1.logger.error('Error fetching energy data:', error);
            throw error;
        }
    }
    /**
     * Get latest energy data for a plant
     */
    async getLatestEnergyData(plantId) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          timestamp,
          generation,
          consumption,
          grid_import as gridImport,
          grid_export as gridExport,
          battery_charge as batteryCharge,
          battery_discharge as batteryDischarge,
          efficiency,
          temperature,
          irradiance
        FROM energy_data 
        WHERE plant_id = ?
        ORDER BY timestamp DESC 
        LIMIT 1`, [plantId]);
            const data = rows;
            return data.length > 0 ? data[0] : null;
        }
        catch (error) {
            logger_1.logger.error('Error fetching latest energy data:', error);
            throw error;
        }
    }
    /**
     * Get hourly aggregated data
     */
    async getHourlyData(plantId, startDate, endDate) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00') as timestamp,
          AVG(generation) as generation,
          AVG(consumption) as consumption,
          AVG(grid_import) as gridImport,
          AVG(grid_export) as gridExport,
          AVG(battery_charge) as batteryCharge,
          AVG(battery_discharge) as batteryDischarge,
          AVG(efficiency) as efficiency,
          AVG(temperature) as temperature,
          AVG(irradiance) as irradiance
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?
        GROUP BY plant_id, DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00')
        ORDER BY timestamp ASC`, [plantId, startDate, endDate]);
            return rows;
        }
        catch (error) {
            logger_1.logger.error('Error fetching hourly data:', error);
            throw error;
        }
    }
    /**
     * Get daily aggregated data
     */
    async getDailyData(plantId, startDate, endDate) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          DATE(timestamp) as timestamp,
          SUM(generation) as generation,
          SUM(consumption) as consumption,
          SUM(grid_import) as gridImport,
          SUM(grid_export) as gridExport,
          SUM(battery_charge) as batteryCharge,
          SUM(battery_discharge) as batteryDischarge,
          AVG(efficiency) as efficiency,
          AVG(temperature) as temperature,
          AVG(irradiance) as irradiance
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?
        GROUP BY plant_id, DATE(timestamp)
        ORDER BY timestamp ASC`, [plantId, startDate, endDate]);
            return rows;
        }
        catch (error) {
            logger_1.logger.error('Error fetching daily data:', error);
            throw error;
        }
    }
    /**
     * Get monthly aggregated data
     */
    async getMonthlyData(plantId, startDate, endDate) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          DATE_FORMAT(timestamp, '%Y-%m-01') as timestamp,
          SUM(generation) as generation,
          SUM(consumption) as consumption,
          SUM(grid_import) as gridImport,
          SUM(grid_export) as gridExport,
          SUM(battery_charge) as batteryCharge,
          SUM(battery_discharge) as batteryDischarge,
          AVG(efficiency) as efficiency,
          AVG(temperature) as temperature,
          AVG(irradiance) as irradiance
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?
        GROUP BY plant_id, DATE_FORMAT(timestamp, '%Y-%m')
        ORDER BY timestamp ASC`, [plantId, startDate, endDate]);
            return rows;
        }
        catch (error) {
            logger_1.logger.error('Error fetching monthly data:', error);
            throw error;
        }
    }
    /**
     * Get all plants for an organization
     */
    async getOrganizationPlants(organizationId) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          plant_id as plantId,
          plant_name as plantName,
          capacity,
          location,
          install_date as installDate,
          status
        FROM plants 
        WHERE organization_id = ?
        ORDER BY plant_name ASC`, [organizationId]);
            return rows;
        }
        catch (error) {
            logger_1.logger.error('Error fetching organization plants:', error);
            throw error;
        }
    }
    /**
     * Get performance metrics for a plant
     */
    async getPerformanceMetrics(plantId, startDate, endDate) {
        await this.ensureConnection();
        try {
            const [rows] = await this.connection.execute(`SELECT 
          SUM(generation) as totalGeneration,
          SUM(consumption) as totalConsumption,
          AVG(efficiency) as averageEfficiency,
          COUNT(*) as totalReadings,
          SUM(CASE WHEN generation > 0 THEN 1 ELSE 0 END) as activeReadings
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?`, [plantId, startDate, endDate]);
            const data = rows[0];
            // Get plant capacity for capacity factor calculation
            const plantInfo = await this.getPlantInfo(plantId);
            const capacity = plantInfo?.capacity || 1;
            // Calculate capacity factor (actual generation / theoretical maximum)
            const hours = (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60);
            const theoreticalMax = capacity * hours;
            const capacityFactor = theoreticalMax > 0 ? (data.totalGeneration / theoreticalMax) * 100 : 0;
            // Calculate availability (percentage of time system was generating)
            const availability = data.totalReadings > 0 ? (data.activeReadings / data.totalReadings) * 100 : 0;
            return {
                totalGeneration: data.totalGeneration || 0,
                totalConsumption: data.totalConsumption || 0,
                averageEfficiency: data.averageEfficiency || 0,
                capacityFactor: Math.min(capacityFactor, 100), // Cap at 100%
                availability: availability
            };
        }
        catch (error) {
            logger_1.logger.error('Error fetching performance metrics:', error);
            throw error;
        }
    }
    /**
     * Close database connection
     */
    async disconnect() {
        if (this.connection) {
            await this.connection.end();
            this.connection = null;
            logger_1.logger.info('Disconnected from SolaX database');
        }
    }
}
exports.SolaxDatabaseService = SolaxDatabaseService;
// Export singleton instance
exports.solaxDatabaseService = new SolaxDatabaseService();
//# sourceMappingURL=solaxDatabaseService.js.map