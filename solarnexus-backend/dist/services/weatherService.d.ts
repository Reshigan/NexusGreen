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
    ghi: number;
    dni: number;
    dhi: number;
    timestamp: Date;
}
export declare class WeatherService {
    private apiKey;
    private baseUrl;
    private oneCallUrl;
    constructor();
    /**
     * Get current weather data for a location
     */
    getCurrentWeather(latitude: number, longitude: number): Promise<WeatherData>;
    /**
     * Get weather forecast for a location
     */
    getWeatherForecast(latitude: number, longitude: number, days?: number): Promise<WeatherForecast[]>;
    /**
     * Get historical weather data
     */
    getHistoricalWeather(latitude: number, longitude: number, timestamp: Date): Promise<WeatherData>;
    /**
     * Calculate solar irradiance based on weather conditions
     * This is a simplified calculation - in production, you might want to use
     * specialized solar irradiance APIs or more complex models
     */
    calculateSolarIrradiance(weather: WeatherData, latitude: number, longitude: number, timestamp?: Date): SolarIrradiance;
    /**
     * Get weather impact on solar performance
     */
    getSolarWeatherImpact(latitude: number, longitude: number, timestamp?: Date): Promise<{
        weather: WeatherData;
        irradiance: SolarIrradiance;
        performanceRatio: number;
        impactFactors: {
            temperature: number;
            clouds: number;
            humidity: number;
            overall: number;
        };
    }>;
    /**
     * Calculate temperature impact on solar panel performance
     * Solar panels lose efficiency as temperature increases
     */
    private calculateTemperatureImpact;
    /**
     * Get optimal solar conditions forecast
     */
    getOptimalSolarForecast(latitude: number, longitude: number, days?: number): Promise<Array<{
        date: Date;
        forecast: WeatherForecast;
        irradiance: SolarIrradiance;
        performanceRatio: number;
        optimalHours: number[];
    }>>;
}
export declare const weatherService: WeatherService;
export {};
//# sourceMappingURL=weatherService.d.ts.map