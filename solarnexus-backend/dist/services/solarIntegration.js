"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const axios_1 = __importDefault(require("axios"));
const logger_1 = require("../utils/logger");
const errorUtils_1 = require("../utils/errorUtils");
class SolarIntegrationService {
    constructor() {
        this.solaxBaseUrl = 'https://www.solaxcloud.com';
        this.accessTokens = new Map(); // Store tokens per client
    }
    /**
     * Get SolaX access token
     */
    async getSolaxToken(clientId, clientSecret) {
        try {
            const cacheKey = `${clientId}_${clientSecret}`;
            // Check if we have a valid cached token
            if (this.accessTokens.has(cacheKey)) {
                const tokenData = this.accessTokens.get(cacheKey);
                if (tokenData && tokenData.expiresAt > Date.now()) {
                    return tokenData.token;
                }
            }
            const response = await axios_1.default.post(`${this.solaxBaseUrl}/openapi/auth/get_token`, {
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
                logger_1.logger.info('SolaX access token obtained successfully', { clientId });
                return token;
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get SolaX access token', { error: (0, errorUtils_1.getErrorMessage)(error), clientId });
            throw error;
        }
    }
    /**
     * Get plant information
     */
    async getPlantInfo(clientId, clientSecret, pageNo = 1) {
        try {
            const token = await this.getSolaxToken(clientId, clientSecret);
            const response = await axios_1.default.get(`${this.solaxBaseUrl}/openapi/v2/plant/page_plant_info`, {
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
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get plant info', { error: (0, errorUtils_1.getErrorMessage)(error), clientId });
            throw error;
        }
    }
    /**
     * Get device information
     */
    async getDeviceInfo(clientId, clientSecret, plantName, pageNo = 1, deviceType = '1') {
        try {
            const token = await this.getSolaxToken(clientId, clientSecret);
            const response = await axios_1.default.get(`${this.solaxBaseUrl}/openapi/v2/device/page_device_info`, {
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
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get device info', { error: (0, errorUtils_1.getErrorMessage)(error), clientId, plantName });
            throw error;
        }
    }
    /**
     * Get real-time plant data
     */
    async getPlantRealtimeData(clientId, clientSecret, plantId) {
        try {
            const token = await this.getSolaxToken(clientId, clientSecret);
            const response = await axios_1.default.get(`${this.solaxBaseUrl}/openapi/v2/plant/realtime_data`, {
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
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get plant realtime data', { error: (0, errorUtils_1.getErrorMessage)(error), clientId, plantId });
            throw error;
        }
    }
    /**
     * Get historical energy data
     */
    async getHistoricalEnergyData(clientId, clientSecret, plantId, startDate, endDate, timeType = 'day') {
        try {
            const token = await this.getSolaxToken(clientId, clientSecret);
            const response = await axios_1.default.get(`${this.solaxBaseUrl}/openapi/v2/plant/energy_data`, {
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
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get historical energy data', {
                error: (0, errorUtils_1.getErrorMessage)(error),
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
    async getAlarmInfo(clientId, clientSecret, plantId, pageNo = 1) {
        try {
            const token = await this.getSolaxToken(clientId, clientSecret);
            const response = await axios_1.default.get(`${this.solaxBaseUrl}/openapi/v2/plant/alarm_info`, {
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
            }
            else {
                throw new Error(`SolaX API error: ${response.data.message}`);
            }
        }
        catch (error) {
            logger_1.logger.error('Failed to get alarm info', { error: (0, errorUtils_1.getErrorMessage)(error), clientId, plantId });
            throw error;
        }
    }
    /**
     * Calculate solar vs grid usage
     */
    calculateSolarVsGrid(realtimeData) {
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
        }
        catch (error) {
            logger_1.logger.error('Failed to calculate solar vs grid usage', { error: (0, errorUtils_1.getErrorMessage)(error) });
            throw error;
        }
    }
    /**
     * Calculate environmental impact (SDG metrics)
     */
    calculateEnvironmentalImpact(energyData) {
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
                    goal7: {
                        description: 'Clean energy generated',
                        value: totalSolarGeneration,
                        unit: 'kWh'
                    },
                    goal13: {
                        description: 'CO2 emissions avoided',
                        value: Math.round(totalSolarGeneration * co2ReductionPerKwh * 100) / 100,
                        unit: 'kg CO2'
                    },
                    goal11: {
                        description: 'Homes powered by clean energy',
                        value: Math.round(homesEquivalent * 100) / 100,
                        unit: 'homes'
                    }
                }
            };
        }
        catch (error) {
            logger_1.logger.error('Failed to calculate environmental impact', { error: (0, errorUtils_1.getErrorMessage)(error) });
            throw error;
        }
    }
}
exports.default = new SolarIntegrationService();
//# sourceMappingURL=solarIntegration.js.map