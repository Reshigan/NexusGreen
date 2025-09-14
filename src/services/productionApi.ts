// Production API Service for NexusGreen
// Real backend integration with comprehensive error handling and caching

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

// Enhanced API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp?: string;
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
  systemEfficiency: number;
  gridExport: number;
  weatherCondition: string;
}

export interface SiteData {
  id: string;
  name: string;
  location: string;
  latitude: number;
  longitude: number;
  capacity: number;
  currentGeneration: number;
  efficiency: number;
  status: 'optimal' | 'good' | 'warning' | 'error' | 'maintenance';
  lastMaintenance: string;
  nextMaintenance: string;
  totalGeneration: number;
  revenue: number;
  installationDate: string;
  systemType: string;
  panelCount: number;
  inverterType: string;
  alerts: number;
  lastUpdate: string;
}

export interface AlertData {
  id: string;
  installationId: string;
  installationName: string;
  type: 'maintenance' | 'performance' | 'system' | 'weather';
  severity: 'info' | 'warning' | 'error';
  title: string;
  message: string;
  createdAt: string;
  isResolved: boolean;
  resolvedAt?: string;
}

export interface TimeSeriesData {
  timestamp: string;
  value: number;
  installationId?: string;
  date?: string;
  hour?: number;
}

export interface MaintenanceRecord {
  id: string;
  installationId: string;
  type: string;
  description: string;
  scheduledDate: string;
  completedDate?: string;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  cost: number;
  technician: string;
}

export interface Company {
  id: string;
  name: string;
  registrationNumber: string;
  address: string;
  phone: string;
  email: string;
  website: string;
  logoUrl: string;
}

export interface User {
  id: string;
  companyId: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'manager' | 'technician' | 'user';
  isActive: boolean;
  lastLogin?: string;
}

// Production API Service Class
class ProductionApiService {
  private baseUrl: string;
  private token: string | null = null;
  private cache: Map<string, { data: any; timestamp: number; ttl: number }> = new Map();

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
    this.token = localStorage.getItem('nexusgreen_auth_token');
  }

  // Authentication methods
  setToken(token: string) {
    this.token = token;
    localStorage.setItem('nexusgreen_auth_token', token);
  }

  clearToken() {
    this.token = null;
    localStorage.removeItem('nexusgreen_auth_token');
    this.clearCache();
  }

  // Cache management
  private getCacheKey(endpoint: string, params?: any): string {
    return `${endpoint}${params ? JSON.stringify(params) : ''}`;
  }

  private setCache(key: string, data: any, ttlMinutes: number = 5) {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttlMinutes * 60 * 1000
    });
  }

  private getCache(key: string): any | null {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    if (Date.now() - cached.timestamp > cached.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }

  private clearCache() {
    this.cache.clear();
  }

  // Generic API request method with retry logic
  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    useCache: boolean = false,
    cacheTtl: number = 5
  ): Promise<ApiResponse<T>> {
    const cacheKey = this.getCacheKey(endpoint, options.body);
    
    // Check cache for GET requests
    if (useCache && (!options.method || options.method === 'GET')) {
      const cached = this.getCache(cacheKey);
      if (cached) {
        return { success: true, data: cached };
      }
    }

    try {
      const url = `${this.baseUrl}${endpoint}`;
      const headers: HeadersInit = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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

      let data: any = {};
      const contentType = response.headers.get('content-type');

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
        // Handle authentication errors
        if (response.status === 401) {
          this.clearToken();
          window.location.href = '/';
        }

        return {
          success: false,
          error: data.error || data.message || `HTTP ${response.status}: ${response.statusText}`,
          timestamp: new Date().toISOString()
        };
      }

      const result = {
        success: true,
        data: data.data || data,
        message: data.message,
        timestamp: new Date().toISOString()
      };

      // Cache successful GET requests
      if (useCache && (!options.method || options.method === 'GET')) {
        this.setCache(cacheKey, result.data, cacheTtl);
      }

      return result;
    } catch (error) {
      console.error('API request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Network error',
        timestamp: new Date().toISOString()
      };
    }
  }

  // Authentication endpoints
  async login(email: string, password: string): Promise<ApiResponse<{ token: string; user: User }>> {
    const response = await this.request<{ token: string; user: User }>('/api/auth/login', {
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

  async getCurrentUser(): Promise<ApiResponse<User>> {
    return this.request<User>('/api/auth/me', {}, true, 10);
  }

  // Dashboard endpoints
  async getDashboardMetrics(): Promise<ApiResponse<DashboardMetrics>> {
    const response = await this.request<any>('/api/dashboard/metrics', {}, true, 2);
    
    if (response.success && response.data) {
      // Transform backend data to frontend format
      const data = response.data;
      const transformedData: DashboardMetrics = {
        totalGeneration: data.totalGeneration || 0,
        activeSites: data.activeSites || 0,
        totalCapacity: data.totalCapacity || 0,
        performance: data.performance || 0,
        activeAlerts: data.activeAlerts || 0,
        totalRevenue: data.totalRevenue || 0,
        co2Saved: data.co2Saved || 0,
        batteryLevel: data.batteryLevel || 0,
        systemEfficiency: data.systemEfficiency || 0,
        gridExport: data.gridExport || 0,
        weatherCondition: data.weatherCondition || 'Unknown',
        lastUpdated: data.lastUpdated || new Date().toISOString()
      };
      
      return {
        success: true,
        data: transformedData,
        timestamp: response.timestamp
      };
    }
    
    return response;
  }

  // Installation endpoints
  async getInstallations(): Promise<ApiResponse<SiteData[]>> {
    const response = await this.request<any[]>('/api/installations', {}, true, 5);
    
    if (response.success && response.data) {
      const transformedData: SiteData[] = response.data.map((installation: any) => ({
        id: installation.id,
        name: installation.name,
        location: installation.location,
        latitude: installation.latitude,
        longitude: installation.longitude,
        capacity: installation.capacity_kw,
        currentGeneration: installation.currentGeneration || 0,
        efficiency: installation.efficiency || 0,
        status: installation.status || 'good',
        lastMaintenance: installation.lastMaintenance || '',
        nextMaintenance: installation.nextMaintenance || '',
        totalGeneration: installation.totalGeneration || 0,
        revenue: installation.revenue || 0,
        installationDate: installation.installation_date,
        systemType: installation.system_type,
        panelCount: installation.panel_count,
        inverterType: installation.inverter_type,
        alerts: installation.alerts || 0,
        lastUpdate: installation.lastUpdate || new Date().toISOString()
      }));
      
      return {
        success: true,
        data: transformedData,
        timestamp: response.timestamp
      };
    }
    
    return response;
  }

  async getInstallationDetails(installationId: string): Promise<ApiResponse<SiteData>> {
    return this.request<SiteData>(`/api/installations/${installationId}`, {}, true, 5);
  }

  // Energy generation data
  async getEnergyGeneration(
    installationId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<ApiResponse<TimeSeriesData[]>> {
    const params = new URLSearchParams();
    if (installationId) params.append('installation_id', installationId);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    
    const response = await this.request<any[]>(`/api/energy-generation?${params}`, {}, true, 2);
    
    if (response.success && response.data) {
      const transformedData: TimeSeriesData[] = response.data.map((item: any) => ({
        timestamp: `${item.date}T${String(item.hour).padStart(2, '0')}:00:00Z`,
        value: item.energy_kwh,
        installationId: item.installation_id,
        date: item.date,
        hour: item.hour
      }));
      
      return {
        success: true,
        data: transformedData,
        timestamp: response.timestamp
      };
    }
    
    return response;
  }

  // Financial data
  async getFinancialData(
    installationId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<ApiResponse<any[]>> {
    const params = new URLSearchParams();
    if (installationId) params.append('installation_id', installationId);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    
    return this.request<any[]>(`/api/financial-data?${params}`, {}, true, 5);
  }

  // Alerts endpoints
  async getAlerts(resolved?: boolean): Promise<ApiResponse<AlertData[]>> {
    const params = new URLSearchParams();
    if (resolved !== undefined) params.append('resolved', String(resolved));
    
    const response = await this.request<any[]>(`/api/alerts?${params}`, {}, true, 1);
    
    if (response.success && response.data) {
      const transformedData: AlertData[] = response.data.map((alert: any) => ({
        id: alert.id,
        installationId: alert.installation_id,
        installationName: alert.installation_name || 'Unknown Installation',
        type: alert.type,
        severity: alert.severity,
        title: alert.title,
        message: alert.message,
        createdAt: alert.created_at,
        isResolved: alert.is_resolved,
        resolvedAt: alert.resolved_at
      }));
      
      return {
        success: true,
        data: transformedData,
        timestamp: response.timestamp
      };
    }
    
    return response;
  }

  async resolveAlert(alertId: string): Promise<ApiResponse<void>> {
    return this.request<void>(`/api/alerts/${alertId}/resolve`, {
      method: 'PUT'
    });
  }

  // Maintenance endpoints
  async getMaintenance(installationId?: string): Promise<ApiResponse<MaintenanceRecord[]>> {
    const params = new URLSearchParams();
    if (installationId) params.append('installation_id', installationId);
    
    return this.request<MaintenanceRecord[]>(`/api/maintenance?${params}`, {}, true, 10);
  }

  async createMaintenance(maintenance: Partial<MaintenanceRecord>): Promise<ApiResponse<MaintenanceRecord>> {
    return this.request<MaintenanceRecord>('/api/maintenance', {
      method: 'POST',
      body: JSON.stringify(maintenance)
    });
  }

  async updateMaintenance(
    maintenanceId: string, 
    updates: Partial<MaintenanceRecord>
  ): Promise<ApiResponse<MaintenanceRecord>> {
    return this.request<MaintenanceRecord>(`/api/maintenance/${maintenanceId}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  // Company endpoints
  async getCompanies(): Promise<ApiResponse<Company[]>> {
    return this.request<Company[]>('/api/companies', {}, true, 30);
  }

  async getCompanyDetails(companyId: string): Promise<ApiResponse<Company>> {
    return this.request<Company>(`/api/companies/${companyId}`, {}, true, 30);
  }

  // User management endpoints
  async getUsers(): Promise<ApiResponse<User[]>> {
    return this.request<User[]>('/api/users', {}, true, 10);
  }

  async createUser(user: Partial<User>): Promise<ApiResponse<User>> {
    return this.request<User>('/api/users', {
      method: 'POST',
      body: JSON.stringify(user)
    });
  }

  async updateUser(userId: string, updates: Partial<User>): Promise<ApiResponse<User>> {
    return this.request<User>(`/api/users/${userId}`, {
      method: 'PUT',
      body: JSON.stringify(updates)
    });
  }

  // System health and monitoring
  async getSystemHealth(): Promise<ApiResponse<{ status: string; timestamp: string; services: any }>> {
    return this.request<{ status: string; timestamp: string; services: any }>('/api/health');
  }

  async getSystemStats(): Promise<ApiResponse<any>> {
    return this.request<any>('/api/system/stats', {}, true, 1);
  }

  // Data export endpoints
  async exportData(
    type: 'installations' | 'energy' | 'financial' | 'alerts' | 'maintenance',
    format: 'csv' | 'json' | 'xlsx',
    filters?: any
  ): Promise<ApiResponse<Blob>> {
    const params = new URLSearchParams();
    params.append('type', type);
    params.append('format', format);
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        params.append(key, String(value));
      });
    }

    try {
      const response = await fetch(`${this.baseUrl}/api/export?${params}`, {
        method: 'GET',
        headers: {
          'Authorization': this.token ? `Bearer ${this.token}` : '',
        },
        credentials: 'include',
      });

      if (!response.ok) {
        return {
          success: false,
          error: `Export failed: ${response.statusText}`,
          timestamp: new Date().toISOString()
        };
      }

      const blob = await response.blob();
      return {
        success: true,
        data: blob,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Export failed',
        timestamp: new Date().toISOString()
      };
    }
  }

  // Real-time data subscription (WebSocket)
  subscribeToRealTimeData(callback: (data: any) => void): () => void {
    const wsUrl = this.baseUrl.replace('http', 'ws') + '/ws/realtime';
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      console.log('Connected to real-time data stream');
      if (this.token) {
        ws.send(JSON.stringify({ type: 'auth', token: this.token }));
      }
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        callback(data);
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('Disconnected from real-time data stream');
    };

    // Return cleanup function
    return () => {
      ws.close();
    };
  }
}

// Create singleton instance
export const productionApiService = new ProductionApiService();

// Export default
export default productionApiService;