import axios from 'axios';
import { logger } from '../utils/logger';
import { getErrorMessage } from '../utils/errorUtils';
import type { 
  SolaxTokenData, 
  SolaxPlantInfo, 
  SolaxRealtimeData, 
  SolaxHistoricalData, 
  SolaxAlarmInfo,
  UsageAnalysis,
  EnvironmentalImpact
} from '../types/solar';

class SolarIntegrationService {
  private solaxBaseUrl: string;
  private accessTokens: Map<string, SolaxTokenData>;

  constructor() {
    this.solaxBaseUrl = 'https://www.solaxcloud.com';
    this.accessTokens = new Map(); // Store tokens per client
  }

  /**
   * Get SolaX access token
   */
  async getSolaxToken(clientId: string, clientSecret: string): Promise<string> {
    try {
      const cacheKey = `${clientId}_${clientSecret}`;
      
      // Check if we have a valid cached token
      if (this.accessTokens.has(cacheKey)) {
        const tokenData = this.accessTokens.get(cacheKey);
        if (tokenData && tokenData.expiresAt > Date.now()) {
          return tokenData.token;
        }
      }

      const response = await axios.post(`${this.solaxBaseUrl}/openapi/auth/get_token`, {
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: 'CICS'
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (response.data.code === 10000) {
        const token = response.data.result.access_token;
        const expiresIn = response.data.result.expires_in || 3600; // Default 1 hour
        
        // Cache the token
        this.accessTokens.set(cacheKey, {
          token,
          expiresAt: Date.now() + (expiresIn * 1000)
        });

        logger.info('SolaX access token obtained successfully', { clientId });
        return token;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get SolaX access token', { error: getErrorMessage(error), clientId });
      throw error;
    }
  }

  /**
   * Get plant information
   */
  async getPlantInfo(clientId: string, clientSecret: string, pageNo: number = 1): Promise<any> {
    try {
      const token = await this.getSolaxToken(clientId, clientSecret);
      
      const response = await axios.get(`${this.solaxBaseUrl}/openapi/v2/plant/page_plant_info`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        params: {
          pageNo,
          businessType: '1'
        }
      });

      if (response.data.code === 10000) {
        return response.data.result;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get plant info', { error: getErrorMessage(error), clientId });
      throw error;
    }
  }

  /**
   * Get device information
   */
  async getDeviceInfo(clientId: string, clientSecret: string, plantName: string, pageNo: number = 1, deviceType: string = '1'): Promise<any> {
    try {
      const token = await this.getSolaxToken(clientId, clientSecret);
      
      const response = await axios.get(`${this.solaxBaseUrl}/openapi/v2/device/page_device_info`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        data: {
          plantName,
          pageNo: pageNo.toString(),
          businessType: '4',
          deviceType
        }
      });

      if (response.data.code === 10000) {
        return response.data.result;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get device info', { error: getErrorMessage(error), clientId, plantName });
      throw error;
    }
  }

  /**
   * Get real-time plant data
   */
  async getPlantRealtimeData(clientId: string, clientSecret: string, plantId: string): Promise<any> {
    try {
      const token = await this.getSolaxToken(clientId, clientSecret);
      
      const response = await axios.get(`${this.solaxBaseUrl}/openapi/v2/plant/realtime_data`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        data: {
          plantId,
          businessType: '1'
        }
      });

      if (response.data.code === 10000) {
        return response.data.result;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get plant realtime data', { error: getErrorMessage(error), clientId, plantId });
      throw error;
    }
  }

  /**
   * Get historical energy data
   */
  async getHistoricalEnergyData(clientId: string, clientSecret: string, plantId: string, startDate: string, endDate: string, timeType: string = 'day'): Promise<any> {
    try {
      const token = await this.getSolaxToken(clientId, clientSecret);
      
      const response = await axios.get(`${this.solaxBaseUrl}/openapi/v2/plant/energy_data`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        data: {
          plantId,
          startDate,
          endDate,
          timeType, // day, month, year
          businessType: '1'
        }
      });

      if (response.data.code === 10000) {
        return response.data.result;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get historical energy data', { 
        error: getErrorMessage(error), 
        clientId, 
        plantId, 
        startDate, 
        endDate 
      });
      throw error;
    }
  }

  /**
   * Get alarm information
   */
  async getAlarmInfo(clientId: string, clientSecret: string, plantId: string, pageNo: number = 1): Promise<any> {
    try {
      const token = await this.getSolaxToken(clientId, clientSecret);
      
      const response = await axios.get(`${this.solaxBaseUrl}/openapi/v2/plant/alarm_info`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        params: {
          plantId,
          pageNo,
          businessType: '1'
        }
      });

      if (response.data.code === 10000) {
        return response.data.result;
      } else {
        throw new Error(`SolaX API error: ${response.data.message}`);
      }
    } catch (error) {
      logger.error('Failed to get alarm info', { error: getErrorMessage(error), clientId, plantId });
      throw error;
    }
  }

  /**
   * Calculate solar vs grid usage
   */
  calculateSolarVsGrid(realtimeData: any): UsageAnalysis {
    try {
      const solarGeneration = realtimeData.yieldtoday || 0; // kWh today
      const gridConsumption = realtimeData.consumeEnergyToday || 0; // kWh today
      const gridFeedIn = realtimeData.feedinEnergyToday || 0; // kWh fed back to grid
      
      const totalConsumption = gridConsumption + solarGeneration - gridFeedIn;
      const solarUsage = Math.max(0, solarGeneration - gridFeedIn);
      const gridUsage = Math.max(0, gridConsumption);
      
      const solarPercentage = totalConsumption > 0 ? (solarUsage / totalConsumption) * 100 : 0;
      const gridPercentage = totalConsumption > 0 ? (gridUsage / totalConsumption) * 100 : 0;

      return {
        solarGeneration,
        solarUsage,
        gridUsage,
        gridFeedIn,
        totalConsumption,
        solarPercentage: Math.round(solarPercentage * 100) / 100,
        gridPercentage: Math.round(gridPercentage * 100) / 100
      };
    } catch (error) {
      logger.error('Failed to calculate solar vs grid usage', { error: getErrorMessage(error) });
      throw error;
    }
  }

  /**
   * Calculate environmental impact (SDG metrics)
   */
  calculateEnvironmentalImpact(energyData: any): EnvironmentalImpact {
    try {
      const totalSolarGeneration = energyData.totalYield || 0; // Total kWh generated
      
      // Standard conversion factors
      const co2ReductionPerKwh = 0.4; // kg CO2 per kWh (varies by region)
      const treesEquivalent = totalSolarGeneration / 2000; // Rough estimate: 1 tree = 2000 kWh offset per year
      const homesEquivalent = totalSolarGeneration / 10000; // Average home uses ~10,000 kWh/year
      
      return {
        totalSolarGeneration,
        co2Reduction: Math.round(totalSolarGeneration * co2ReductionPerKwh * 100) / 100, // kg CO2
        treesEquivalent: Math.round(treesEquivalent * 100) / 100,
        homesEquivalent: Math.round(homesEquivalent * 100) / 100,
        sdgGoals: {
          goal7: { // Affordable and Clean Energy
            description: 'Clean energy generated',
            value: totalSolarGeneration,
            unit: 'kWh'
          },
          goal13: { // Climate Action
            description: 'CO2 emissions avoided',
            value: Math.round(totalSolarGeneration * co2ReductionPerKwh * 100) / 100,
            unit: 'kg CO2'
          },
          goal11: { // Sustainable Cities and Communities
            description: 'Homes powered by clean energy',
            value: Math.round(homesEquivalent * 100) / 100,
            unit: 'homes'
          }
        }
      };
    } catch (error) {
      logger.error('Failed to calculate environmental impact', { error: getErrorMessage(error) });
      throw error;
    }
  }
}

export default new SolarIntegrationService();