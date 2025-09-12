import mysql from 'mysql2/promise';
import { logger } from '../utils/logger';

interface SolaxDatabaseConfig {
  host: string;
  user: string;
  password: string;
  database: string;
}

interface SolaxEnergyData {
  plantId: string;
  timestamp: Date;
  generation: number;
  consumption: number;
  gridImport: number;
  gridExport: number;
  batteryCharge: number;
  batteryDischarge: number;
  efficiency: number;
  temperature: number;
  irradiance: number;
}

interface SolaxPlantInfo {
  plantId: string;
  plantName: string;
  capacity: number;
  location: string;
  installDate: Date;
  status: string;
}

export class SolaxDatabaseService {
  private connection: mysql.Connection | null = null;
  private config: SolaxDatabaseConfig;

  constructor() {
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
  async connect(): Promise<void> {
    try {
      this.connection = await mysql.createConnection({
        host: this.config.host,
        user: this.config.user,
        password: this.config.password,
        database: this.config.database,
        timezone: '+00:00',
        dateStrings: false,
        supportBigNumbers: true,
        bigNumberStrings: false
      });

      logger.info('Connected to SolaX database successfully');
    } catch (error) {
      logger.error('Failed to connect to SolaX database:', error);
      throw new Error('SolaX database connection failed');
    }
  }

  /**
   * Ensure connection is active
   */
  private async ensureConnection(): Promise<void> {
    if (!this.connection) {
      await this.connect();
    }
  }

  /**
   * Get plant information
   */
  async getPlantInfo(plantId: string): Promise<SolaxPlantInfo | null> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
          plant_id as plantId,
          plant_name as plantName,
          capacity,
          location,
          install_date as installDate,
          status
        FROM plants 
        WHERE plant_id = ?`,
        [plantId]
      );

      const plants = rows as any[];
      return plants.length > 0 ? plants[0] : null;
    } catch (error) {
      logger.error('Error fetching plant info:', error);
      throw error;
    }
  }

  /**
   * Get energy data for a specific time range
   */
  async getEnergyData(
    plantId: string,
    startDate: Date,
    endDate: Date
  ): Promise<SolaxEnergyData[]> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
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
        ORDER BY timestamp ASC`,
        [plantId, startDate, endDate]
      );

      return rows as SolaxEnergyData[];
    } catch (error) {
      logger.error('Error fetching energy data:', error);
      throw error;
    }
  }

  /**
   * Get latest energy data for a plant
   */
  async getLatestEnergyData(plantId: string): Promise<SolaxEnergyData | null> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
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
        LIMIT 1`,
        [plantId]
      );

      const data = rows as any[];
      return data.length > 0 ? data[0] : null;
    } catch (error) {
      logger.error('Error fetching latest energy data:', error);
      throw error;
    }
  }

  /**
   * Get hourly aggregated data
   */
  async getHourlyData(
    plantId: string,
    startDate: Date,
    endDate: Date
  ): Promise<SolaxEnergyData[]> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
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
        ORDER BY timestamp ASC`,
        [plantId, startDate, endDate]
      );

      return rows as SolaxEnergyData[];
    } catch (error) {
      logger.error('Error fetching hourly data:', error);
      throw error;
    }
  }

  /**
   * Get daily aggregated data
   */
  async getDailyData(
    plantId: string,
    startDate: Date,
    endDate: Date
  ): Promise<SolaxEnergyData[]> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
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
        ORDER BY timestamp ASC`,
        [plantId, startDate, endDate]
      );

      return rows as SolaxEnergyData[];
    } catch (error) {
      logger.error('Error fetching daily data:', error);
      throw error;
    }
  }

  /**
   * Get monthly aggregated data
   */
  async getMonthlyData(
    plantId: string,
    startDate: Date,
    endDate: Date
  ): Promise<SolaxEnergyData[]> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
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
        ORDER BY timestamp ASC`,
        [plantId, startDate, endDate]
      );

      return rows as SolaxEnergyData[];
    } catch (error) {
      logger.error('Error fetching monthly data:', error);
      throw error;
    }
  }

  /**
   * Get all plants for an organization
   */
  async getOrganizationPlants(organizationId: string): Promise<SolaxPlantInfo[]> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
          plant_id as plantId,
          plant_name as plantName,
          capacity,
          location,
          install_date as installDate,
          status
        FROM plants 
        WHERE organization_id = ?
        ORDER BY plant_name ASC`,
        [organizationId]
      );

      return rows as SolaxPlantInfo[];
    } catch (error) {
      logger.error('Error fetching organization plants:', error);
      throw error;
    }
  }

  /**
   * Get performance metrics for a plant
   */
  async getPerformanceMetrics(
    plantId: string,
    startDate: Date,
    endDate: Date
  ): Promise<{
    totalGeneration: number;
    totalConsumption: number;
    averageEfficiency: number;
    capacityFactor: number;
    availability: number;
  }> {
    await this.ensureConnection();
    
    try {
      const [rows] = await this.connection!.execute(
        `SELECT 
          SUM(generation) as totalGeneration,
          SUM(consumption) as totalConsumption,
          AVG(efficiency) as averageEfficiency,
          COUNT(*) as totalReadings,
          SUM(CASE WHEN generation > 0 THEN 1 ELSE 0 END) as activeReadings
        FROM energy_data 
        WHERE plant_id = ? 
          AND timestamp >= ? 
          AND timestamp <= ?`,
        [plantId, startDate, endDate]
      );

      const data = (rows as any[])[0];
      
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
    } catch (error) {
      logger.error('Error fetching performance metrics:', error);
      throw error;
    }
  }

  /**
   * Close database connection
   */
  async disconnect(): Promise<void> {
    if (this.connection) {
      await this.connection.end();
      this.connection = null;
      logger.info('Disconnected from SolaX database');
    }
  }
}

// Export singleton instance
export const solaxDatabaseService = new SolaxDatabaseService();