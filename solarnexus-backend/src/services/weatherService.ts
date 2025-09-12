import axios from 'axios';
import { logger } from '../utils/logger';

interface WeatherData {
  temperature: number;
  humidity: number;
  pressure: number;
  windSpeed: number;
  windDirection: number;
  cloudCover: number;
  visibility: number;
  uvIndex: number;
  description: string;
  icon: string;
  timestamp: Date;
}

interface WeatherForecast {
  date: Date;
  temperature: {
    min: number;
    max: number;
    day: number;
    night: number;
  };
  humidity: number;
  pressure: number;
  windSpeed: number;
  cloudCover: number;
  uvIndex: number;
  description: string;
  icon: string;
  precipitationProbability: number;
  precipitationAmount: number;
}

interface SolarIrradiance {
  ghi: number; // Global Horizontal Irradiance
  dni: number; // Direct Normal Irradiance
  dhi: number; // Diffuse Horizontal Irradiance
  timestamp: Date;
}

export class WeatherService {
  private apiKey: string;
  private baseUrl: string = 'https://api.openweathermap.org/data/2.5';
  private oneCallUrl: string = 'https://api.openweathermap.org/data/3.0/onecall';

  constructor() {
    this.apiKey = process.env.OPENWEATHERMAP_API_KEY || '';
    if (!this.apiKey) {
      logger.warn('OpenWeatherMap API key not configured');
    }
  }

  /**
   * Get current weather data for a location
   */
  async getCurrentWeather(latitude: number, longitude: number): Promise<WeatherData> {
    try {
      const response = await axios.get(`${this.baseUrl}/weather`, {
        params: {
          lat: latitude,
          lon: longitude,
          appid: this.apiKey,
          units: 'metric'
        }
      });

      const data = response.data;
      
      return {
        temperature: data.main.temp,
        humidity: data.main.humidity,
        pressure: data.main.pressure,
        windSpeed: data.wind?.speed || 0,
        windDirection: data.wind?.deg || 0,
        cloudCover: data.clouds?.all || 0,
        visibility: data.visibility || 10000,
        uvIndex: 0, // Not available in current weather API
        description: data.weather[0]?.description || '',
        icon: data.weather[0]?.icon || '',
        timestamp: new Date()
      };
    } catch (error) {
      logger.error('Error fetching current weather:', error);
      throw new Error('Failed to fetch current weather data');
    }
  }

  /**
   * Get weather forecast for a location
   */
  async getWeatherForecast(latitude: number, longitude: number, days: number = 7): Promise<WeatherForecast[]> {
    try {
      const response = await axios.get(`${this.oneCallUrl}`, {
        params: {
          lat: latitude,
          lon: longitude,
          appid: this.apiKey,
          units: 'metric',
          exclude: 'minutely,alerts'
        }
      });

      const data = response.data;
      const forecasts: WeatherForecast[] = [];

      // Process daily forecast data
      for (let i = 0; i < Math.min(days, data.daily?.length || 0); i++) {
        const day = data.daily[i];
        
        forecasts.push({
          date: new Date(day.dt * 1000),
          temperature: {
            min: day.temp.min,
            max: day.temp.max,
            day: day.temp.day,
            night: day.temp.night
          },
          humidity: day.humidity,
          pressure: day.pressure,
          windSpeed: day.wind_speed,
          cloudCover: day.clouds,
          uvIndex: day.uvi,
          description: day.weather[0]?.description || '',
          icon: day.weather[0]?.icon || '',
          precipitationProbability: day.pop * 100,
          precipitationAmount: day.rain?.['1h'] || day.snow?.['1h'] || 0
        });
      }

      return forecasts;
    } catch (error) {
      logger.error('Error fetching weather forecast:', error);
      throw new Error('Failed to fetch weather forecast data');
    }
  }

  /**
   * Get historical weather data
   */
  async getHistoricalWeather(
    latitude: number, 
    longitude: number, 
    timestamp: Date
  ): Promise<WeatherData> {
    try {
      const unixTimestamp = Math.floor(timestamp.getTime() / 1000);
      
      const response = await axios.get(`${this.oneCallUrl}/timemachine`, {
        params: {
          lat: latitude,
          lon: longitude,
          dt: unixTimestamp,
          appid: this.apiKey,
          units: 'metric'
        }
      });

      const data = response.data.data[0];
      
      return {
        temperature: data.temp,
        humidity: data.humidity,
        pressure: data.pressure,
        windSpeed: data.wind_speed,
        windDirection: data.wind_deg,
        cloudCover: data.clouds,
        visibility: data.visibility || 10000,
        uvIndex: data.uvi || 0,
        description: data.weather[0]?.description || '',
        icon: data.weather[0]?.icon || '',
        timestamp: new Date(data.dt * 1000)
      };
    } catch (error) {
      logger.error('Error fetching historical weather:', error);
      throw new Error('Failed to fetch historical weather data');
    }
  }

  /**
   * Calculate solar irradiance based on weather conditions
   * This is a simplified calculation - in production, you might want to use
   * specialized solar irradiance APIs or more complex models
   */
  calculateSolarIrradiance(
    weather: WeatherData,
    latitude: number,
    longitude: number,
    timestamp: Date = new Date()
  ): SolarIrradiance {
    // Solar constant (W/m²)
    const solarConstant = 1361;
    
    // Calculate solar elevation angle (simplified)
    const dayOfYear = Math.floor((timestamp.getTime() - new Date(timestamp.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24));
    const declination = 23.45 * Math.sin((360 * (284 + dayOfYear) / 365) * Math.PI / 180);
    const hour = timestamp.getHours() + timestamp.getMinutes() / 60;
    const hourAngle = 15 * (hour - 12);
    
    const elevationAngle = Math.asin(
      Math.sin(declination * Math.PI / 180) * Math.sin(latitude * Math.PI / 180) +
      Math.cos(declination * Math.PI / 180) * Math.cos(latitude * Math.PI / 180) * Math.cos(hourAngle * Math.PI / 180)
    ) * 180 / Math.PI;
    
    // Calculate air mass
    const airMass = elevationAngle > 0 ? 1 / Math.sin(elevationAngle * Math.PI / 180) : 0;
    
    // Calculate clear sky irradiance
    const clearSkyGHI = elevationAngle > 0 ? 
      solarConstant * Math.sin(elevationAngle * Math.PI / 180) * Math.pow(0.7, Math.pow(airMass, 0.678)) : 0;
    
    // Adjust for cloud cover
    const cloudFactor = 1 - (weather.cloudCover / 100) * 0.75;
    const actualGHI = clearSkyGHI * cloudFactor;
    
    // Estimate DNI and DHI (simplified)
    const dni = actualGHI * 0.8; // Direct component
    const dhi = actualGHI * 0.2; // Diffuse component
    
    return {
      ghi: Math.max(0, actualGHI),
      dni: Math.max(0, dni),
      dhi: Math.max(0, dhi),
      timestamp
    };
  }

  /**
   * Get weather impact on solar performance
   */
  async getSolarWeatherImpact(
    latitude: number,
    longitude: number,
    timestamp: Date = new Date()
  ): Promise<{
    weather: WeatherData;
    irradiance: SolarIrradiance;
    performanceRatio: number;
    impactFactors: {
      temperature: number;
      clouds: number;
      humidity: number;
      overall: number;
    };
  }> {
    try {
      const weather = await this.getCurrentWeather(latitude, longitude);
      const irradiance = this.calculateSolarIrradiance(weather, latitude, longitude, timestamp);
      
      // Calculate performance impact factors
      const temperatureImpact = this.calculateTemperatureImpact(weather.temperature);
      const cloudImpact = 1 - (weather.cloudCover / 100);
      const humidityImpact = 1 - (weather.humidity / 100) * 0.1; // Minimal humidity impact
      
      const overallImpact = temperatureImpact * cloudImpact * humidityImpact;
      const performanceRatio = Math.max(0, Math.min(1, overallImpact));
      
      return {
        weather,
        irradiance,
        performanceRatio,
        impactFactors: {
          temperature: temperatureImpact,
          clouds: cloudImpact,
          humidity: humidityImpact,
          overall: overallImpact
        }
      };
    } catch (error) {
      logger.error('Error calculating solar weather impact:', error);
      throw error;
    }
  }

  /**
   * Calculate temperature impact on solar panel performance
   * Solar panels lose efficiency as temperature increases
   */
  private calculateTemperatureImpact(temperature: number): number {
    // Standard Test Conditions (STC) temperature is 25°C
    const stcTemperature = 25;
    const temperatureCoefficient = -0.004; // Typical value: -0.4% per °C
    
    const temperatureDifference = temperature - stcTemperature;
    const impact = 1 + (temperatureCoefficient * temperatureDifference);
    
    return Math.max(0.5, Math.min(1.2, impact)); // Clamp between 50% and 120%
  }

  /**
   * Get optimal solar conditions forecast
   */
  async getOptimalSolarForecast(
    latitude: number,
    longitude: number,
    days: number = 7
  ): Promise<Array<{
    date: Date;
    forecast: WeatherForecast;
    irradiance: SolarIrradiance;
    performanceRatio: number;
    optimalHours: number[];
  }>> {
    try {
      const forecasts = await this.getWeatherForecast(latitude, longitude, days);
      const results = [];
      
      for (const forecast of forecasts) {
        // Calculate irradiance for midday
        const midday = new Date(forecast.date);
        midday.setHours(12, 0, 0, 0);
        
        const weather: WeatherData = {
          temperature: forecast.temperature.day,
          humidity: forecast.humidity,
          pressure: forecast.pressure,
          windSpeed: forecast.windSpeed,
          windDirection: 0,
          cloudCover: forecast.cloudCover,
          visibility: 10000,
          uvIndex: forecast.uvIndex,
          description: forecast.description,
          icon: forecast.icon,
          timestamp: midday
        };
        
        const irradiance = this.calculateSolarIrradiance(weather, latitude, longitude, midday);
        
        // Calculate performance ratio
        const temperatureImpact = this.calculateTemperatureImpact(forecast.temperature.day);
        const cloudImpact = 1 - (forecast.cloudCover / 100);
        const performanceRatio = temperatureImpact * cloudImpact;
        
        // Determine optimal hours (when sun is high and conditions are good)
        const optimalHours = [];
        for (let hour = 8; hour <= 16; hour++) {
          if (forecast.cloudCover < 50 && forecast.precipitationProbability < 30) {
            optimalHours.push(hour);
          }
        }
        
        results.push({
          date: forecast.date,
          forecast,
          irradiance,
          performanceRatio,
          optimalHours
        });
      }
      
      return results;
    } catch (error) {
      logger.error('Error getting optimal solar forecast:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const weatherService = new WeatherService();