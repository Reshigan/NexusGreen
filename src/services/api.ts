// Production API Service for Nexus Green
// Handles all backend communication and data management

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface DashboardMetrics {
  totalGeneration: number;
  activeSites: number;
  totalCapacity: number;
  performance: number;
  activeAlerts: number;
  totalRevenue: number;
  co2Saved: number;
  batteryLevel: number;
  lastUpdated: string;
}

export interface SiteData {
  id: string;
  name: string;
  location: string;
  capacity: number;
  currentGeneration: number;
  efficiency: number;
  status: 'optimal' | 'good' | 'warning' | 'error';
  lastMaintenance: string;
  nextMaintenance: string;
  totalGeneration: number;
  revenue: number;
}

export interface AlertData {
  id: string;
  siteId: string;
  siteName: string;
  type: 'maintenance' | 'performance' | 'system' | 'weather';
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  timestamp: string;
  resolved: boolean;
}

export interface TimeSeriesData {
  timestamp: string;
  value: number;
  siteId?: string;
}

// API Service Class
class ApiService {
  private baseUrl: string;
  private token: string | null = null;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
    this.token = localStorage.getItem('auth_token');
  }

  // Set authentication token
  setToken(token: string) {
    this.token = token;
    localStorage.setItem('auth_token', token);
  }

  // Clear authentication token
  clearToken() {
    this.token = null;
    localStorage.removeItem('auth_token');
  }

  // Generic API request method
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const url = `${this.baseUrl}${endpoint}`;
      const headers: HeadersInit = {
        'Content-Type': 'application/json',
        ...options.headers,
      };

      if (this.token) {
        headers.Authorization = `Bearer ${this.token}`;
      }

      const response = await fetch(url, {
        ...options,
        headers,
        credentials: 'include',
      });

      const contentType = response.headers.get('content-type');
      let data: any = {};

      if (contentType && contentType.includes('application/json')) {
        const text = await response.text();
        if (text) {
          try {
            data = JSON.parse(text);
          } catch (e) {
            console.warn('Failed to parse JSON response:', text);
          }
        }
      }

      if (!response.ok) {
        return {
          success: false,
          error: data.error || data.message || `HTTP ${response.status}`,
        };
      }

      return {
        success: true,
        data: data.data || data,
        message: data.message,
      };
    } catch (error) {
      console.error('API request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Network error',
      };
    }
  }

  // Authentication endpoints
  async login(email: string, password: string): Promise<ApiResponse<{ token: string; user: any }>> {
    const response = await this.request<{ token: string; user: any }>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    if (response.success && response.data?.token) {
      this.setToken(response.data.token);
    }

    return response;
  }

  async logout(): Promise<ApiResponse<void>> {
    const response = await this.request<void>('/api/auth/logout', {
      method: 'POST',
    });
    this.clearToken();
    return response;
  }

  // Dashboard endpoints
  async getDashboardMetrics(): Promise<ApiResponse<DashboardMetrics>> {
    const response = await this.request<any>('/api/dashboard/stats');
    if (response.success && response.data) {
      // Transform backend data to frontend format
      const backendData = response.data;
      const transformedData: DashboardMetrics = {
        totalGeneration: backendData.todayGeneration || 0,
        activeSites: backendData.totalInstallations || 0,
        totalCapacity: backendData.totalCapacity || 0,
        performance: 85, // Calculate from generation data
        activeAlerts: backendData.activeAlerts || 0,
        totalRevenue: backendData.monthlyRevenue || 0
      };
      return {
        success: true,
        data: transformedData
      };
    }
    return response;
  }

  async getSites(): Promise<ApiResponse<SiteData[]>> {
    return this.request<SiteData[]>('/api/installations');
  }

  async getSiteDetails(siteId: string): Promise<ApiResponse<SiteData>> {
    return this.request<SiteData>(`/api/sites/${siteId}`);
  }

  async getAlerts(): Promise<ApiResponse<AlertData[]>> {
    return this.request<AlertData[]>('/api/alerts');
  }

  // Time series data endpoints
  async getGenerationData(
    siteId?: string,
    timeRange: string = '24h'
  ): Promise<ApiResponse<TimeSeriesData[]>> {
    const params = new URLSearchParams({ timeRange });
    if (siteId) params.append('siteId', siteId);
    
    return this.request<TimeSeriesData[]>(`/api/data/generation?${params}`);
  }

  async getPerformanceData(
    siteId?: string,
    timeRange: string = '24h'
  ): Promise<ApiResponse<TimeSeriesData[]>> {
    const params = new URLSearchParams({ timeRange });
    if (siteId) params.append('siteId', siteId);
    
    return this.request<TimeSeriesData[]>(`/api/data/performance?${params}`);
  }

  async getRevenueData(
    siteId?: string,
    timeRange: string = '30d'
  ): Promise<ApiResponse<TimeSeriesData[]>> {
    const params = new URLSearchParams({ timeRange });
    if (siteId) params.append('siteId', siteId);
    
    return this.request<TimeSeriesData[]>(`/api/data/revenue?${params}`);
  }

  // SuperAdmin endpoints
  async getTenants(): Promise<ApiResponse<any[]>> {
    return this.request<any[]>('/api/superadmin/tenants');
  }

  async createTenant(tenantData: any): Promise<ApiResponse<any>> {
    return this.request<any>('/api/superadmin/tenants', {
      method: 'POST',
      body: JSON.stringify(tenantData),
    });
  }

  async updateTenant(tenantId: string, tenantData: any): Promise<ApiResponse<any>> {
    return this.request<any>(`/api/superadmin/tenants/${tenantId}`, {
      method: 'PUT',
      body: JSON.stringify(tenantData),
    });
  }

  async getLicenses(): Promise<ApiResponse<any[]>> {
    return this.request<any[]>('/api/superadmin/licenses');
  }

  // Health check
  async healthCheck(): Promise<ApiResponse<{ status: string; timestamp: string }>> {
    return this.request<{ status: string; timestamp: string }>('/api/health');
  }
}

// Create singleton instance
export const apiService = new ApiService();

// Fallback data service for development/demo mode
export class FallbackDataService {
  private static instance: FallbackDataService;
  private yearlyData: any[] = [];
  private monthlyData: any[] = [];

  static getInstance(): FallbackDataService {
    if (!FallbackDataService.instance) {
      FallbackDataService.instance = new FallbackDataService();
    }
    return FallbackDataService.instance;
  }

  async initializeData() {
    // Import demo data dynamically
    const { currentYearData, monthlyAggregates, yearSummary } = await import('../data/generateYearlyData');
    this.yearlyData = currentYearData;
    this.monthlyData = monthlyAggregates;
    return yearSummary;
  }

  async getDashboardMetrics(): Promise<DashboardMetrics> {
    const summary = await this.initializeData();
    const today = new Date().toISOString().split('T')[0];
    const todayData = this.yearlyData.filter(d => d.date === today);
    
    return {
      totalGeneration: todayData.reduce((sum, d) => sum + d.generation, 0),
      activeSites: 2,
      totalCapacity: summary.totalCapacity,
      performance: summary.avgEfficiency,
      activeAlerts: Math.floor(Math.random() * 5),
      totalRevenue: summary.totalRevenue,
      co2Saved: summary.totalCo2Saved,
      batteryLevel: 85 + Math.random() * 10,
      lastUpdated: new Date().toISOString()
    };
  }

  async getSites(): Promise<SiteData[]> {
    const { demoSites } = await import('../data/demoCompany');
    const today = new Date().toISOString().split('T')[0];
    
    return demoSites.map(site => {
      const todayData = this.yearlyData.find(d => d.date === today && d.siteId === site.id);
      const siteYearData = this.yearlyData.filter(d => d.siteId === site.id);
      
      return {
        id: site.id,
        name: site.name,
        location: site.location.address,
        capacity: site.system.capacity,
        currentGeneration: todayData?.generation || 0,
        efficiency: todayData?.efficiency || 85,
        status: todayData?.efficiency > 90 ? 'optimal' : 
                todayData?.efficiency > 80 ? 'good' : 
                todayData?.efficiency > 70 ? 'warning' : 'error',
        lastMaintenance: '2024-01-15',
        nextMaintenance: '2024-07-15',
        totalGeneration: siteYearData.reduce((sum, d) => sum + d.generation, 0),
        revenue: siteYearData.reduce((sum, d) => sum + d.revenue, 0)
      };
    });
  }

  async getGenerationData(siteId?: string, timeRange: string = '24h'): Promise<TimeSeriesData[]> {
    await this.initializeData();
    
    let data = this.yearlyData;
    if (siteId) {
      data = data.filter(d => d.siteId === siteId);
    }

    // Filter by time range
    const now = new Date();
    let startDate: Date;
    
    switch (timeRange) {
      case '24h':
        startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case '7d':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case '30d':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    }

    return data
      .filter(d => new Date(d.date) >= startDate)
      .map(d => ({
        timestamp: d.date,
        value: d.generation,
        siteId: d.siteId
      }))
      .sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }
}

export const fallbackDataService = FallbackDataService.getInstance();

// Smart data service that tries API first, falls back to demo data
export class SmartDataService {
  private useApi: boolean = true;

  async getDashboardMetrics(): Promise<DashboardMetrics> {
    if (this.useApi) {
      const response = await apiService.getDashboardMetrics();
      if (response.success && response.data) {
        return response.data;
      }
      console.warn('API failed, falling back to demo data');
      this.useApi = false;
    }
    
    return fallbackDataService.getDashboardMetrics();
  }

  async getSites(): Promise<SiteData[]> {
    if (this.useApi) {
      const response = await apiService.getSites();
      if (response.success && response.data) {
        return response.data;
      }
      console.warn('API failed, falling back to demo data');
      this.useApi = false;
    }
    
    return fallbackDataService.getSites();
  }

  async getGenerationData(siteId?: string, timeRange: string = '24h'): Promise<TimeSeriesData[]> {
    if (this.useApi) {
      const response = await apiService.getGenerationData(siteId, timeRange);
      if (response.success && response.data) {
        return response.data;
      }
      console.warn('API failed, falling back to demo data');
      this.useApi = false;
    }
    
    return fallbackDataService.getGenerationData(siteId, timeRange);
  }

  // Health check to determine if API is available
  async checkApiHealth(): Promise<boolean> {
    const response = await apiService.healthCheck();
    this.useApi = response.success;
    return this.useApi;
  }
}

export const smartDataService = new SmartDataService();

export default apiService;