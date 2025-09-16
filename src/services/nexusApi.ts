// NexusGreen API Service - Production Backend Integration
// Replaces mock data with real API calls

import axios, { AxiosInstance, AxiosResponse } from 'axios';

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

// Types
export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'SUPER_ADMIN' | 'ADMIN' | 'MANAGER' | 'OPERATOR' | 'VIEWER';
  organizationId: string;
  avatar?: string;
  lastLogin?: string;
  isActive: boolean;
  permissions: string[];
  emailVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  type: 'INSTALLER' | 'OEM' | 'ASSET_OWNER' | 'END_CUSTOMER';
  logo?: string;
  address?: string;
  country?: string;
  timezone: string;
  settings: {
    theme: string;
    currency: string;
    timezone: string;
  };
  createdAt: string;
  updatedAt: string;
}

export interface Site {
  id: string;
  name: string;
  organizationId: string;
  location: {
    latitude: number;
    longitude: number;
    address: string;
    city: string;
    country: string;
  };
  capacity: number; // kW
  installationDate: string;
  systemType: 'GRID_TIED' | 'OFF_GRID' | 'HYBRID';
  panelCount: number;
  inverterType: string;
  status: 'ACTIVE' | 'MAINTENANCE' | 'OFFLINE' | 'FAULT';
  performanceRatio: number; // %
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface EnergyData {
  id: string;
  siteId: string;
  timestamp: string;
  generation: number; // kW
  consumption?: number; // kW
  gridExport?: number; // kW
  gridImport?: number; // kW
  batteryLevel?: number; // %
  batteryCharge?: number; // kW
  batteryDischarge?: number; // kW
  irradiance: number; // W/m²
  temperature: number; // °C
  windSpeed?: number; // m/s
}

export interface Alert {
  id: string;
  siteId: string;
  type: 'PERFORMANCE' | 'MAINTENANCE' | 'FAULT' | 'WEATHER' | 'SECURITY';
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  title: string;
  description: string;
  status: 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED';
  createdAt: string;
  resolvedAt?: string;
  assignedTo?: string;
}

export interface DashboardMetrics {
  totalGeneration: number; // kWh today
  totalRevenue: number; // USD today
  totalSavings: number; // USD today
  avgPerformance: number; // %
  activeSites: number;
  totalSites: number;
  totalAlerts: number;
  systemEfficiency: number; // %
  gridExport: number; // kWh today
  totalCO2Saved: number; // kg
  weatherCondition: string;
  lastUpdated: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  organization: Organization;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface SignupRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  organizationName: string;
  role: string;
}

// API Client Class
class NexusApiClient {
  private client: AxiosInstance;
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      (config) => {
        if (this.accessToken) {
          config.headers.Authorization = `Bearer ${this.accessToken}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor to handle token refresh
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config;

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          try {
            await this.refreshAccessToken();
            originalRequest.headers.Authorization = `Bearer ${this.accessToken}`;
            return this.client(originalRequest);
          } catch (refreshError) {
            this.logout();
            window.location.href = '/login';
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      }
    );

    // Load tokens from localStorage
    this.loadTokensFromStorage();
  }

  private loadTokensFromStorage() {
    this.accessToken = localStorage.getItem('nexus-access-token');
    this.refreshToken = localStorage.getItem('nexus-refresh-token');
  }

  private saveTokensToStorage(accessToken: string, refreshToken: string) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    localStorage.setItem('nexus-access-token', accessToken);
    localStorage.setItem('nexus-refresh-token', refreshToken);
  }

  private clearTokensFromStorage() {
    this.accessToken = null;
    this.refreshToken = null;
    localStorage.removeItem('nexus-access-token');
    localStorage.removeItem('nexus-refresh-token');
    localStorage.removeItem('nexus-user');
    localStorage.removeItem('nexus-organization');
  }

  // Authentication Methods
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    try {
      const response: AxiosResponse<LoginResponse> = await this.client.post('/auth/login', credentials);
      const { accessToken, refreshToken, user, organization } = response.data;
      
      this.saveTokensToStorage(accessToken, refreshToken);
      
      // Save user and organization to localStorage
      localStorage.setItem('nexus-user', JSON.stringify(user));
      localStorage.setItem('nexus-organization', JSON.stringify(organization));
      
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Login failed');
    }
  }

  async signup(userData: SignupRequest): Promise<LoginResponse> {
    try {
      const response: AxiosResponse<LoginResponse> = await this.client.post('/auth/signup', userData);
      const { accessToken, refreshToken, user, organization } = response.data;
      
      this.saveTokensToStorage(accessToken, refreshToken);
      
      // Save user and organization to localStorage
      localStorage.setItem('nexus-user', JSON.stringify(user));
      localStorage.setItem('nexus-organization', JSON.stringify(organization));
      
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Signup failed');
    }
  }

  async logout(): Promise<void> {
    try {
      await this.client.post('/auth/logout');
    } catch (error) {
      // Continue with logout even if API call fails
      console.error('Logout API call failed:', error);
    } finally {
      this.clearTokensFromStorage();
    }
  }

  async refreshAccessToken(): Promise<void> {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }

    try {
      const response = await this.client.post('/auth/refresh', {
        refreshToken: this.refreshToken,
      });
      
      const { accessToken, refreshToken } = response.data;
      this.saveTokensToStorage(accessToken, refreshToken);
    } catch (error) {
      this.clearTokensFromStorage();
      throw error;
    }
  }

  async getProfile(): Promise<User> {
    const response: AxiosResponse<User> = await this.client.get('/auth/me');
    return response.data;
  }

  async forgotPassword(email: string): Promise<void> {
    await this.client.post('/auth/forgot-password', { email });
  }

  async resetPassword(token: string, password: string): Promise<void> {
    await this.client.post('/auth/reset-password', { token, password });
  }

  // Dashboard Methods
  async getDashboardMetrics(organizationId: string): Promise<DashboardMetrics> {
    const response: AxiosResponse<DashboardMetrics> = await this.client.get(
      `/analytics/dashboard/${organizationId}`
    );
    return response.data;
  }

  // Site Methods
  async getSites(organizationId: string): Promise<Site[]> {
    const response: AxiosResponse<Site[]> = await this.client.get(
      `/sites?organizationId=${organizationId}`
    );
    return response.data;
  }

  async getSite(siteId: string): Promise<Site> {
    const response: AxiosResponse<Site> = await this.client.get(`/sites/${siteId}`);
    return response.data;
  }

  async createSite(siteData: Partial<Site>): Promise<Site> {
    const response: AxiosResponse<Site> = await this.client.post('/sites', siteData);
    return response.data;
  }

  async updateSite(siteId: string, siteData: Partial<Site>): Promise<Site> {
    const response: AxiosResponse<Site> = await this.client.put(`/sites/${siteId}`, siteData);
    return response.data;
  }

  async deleteSite(siteId: string): Promise<void> {
    await this.client.delete(`/sites/${siteId}`);
  }

  // Energy Data Methods
  async getEnergyData(
    siteId: string,
    startDate: string,
    endDate: string,
    interval: 'hour' | 'day' | 'month' = 'hour'
  ): Promise<EnergyData[]> {
    const response: AxiosResponse<EnergyData[]> = await this.client.get(
      `/energy/${siteId}?startDate=${startDate}&endDate=${endDate}&interval=${interval}`
    );
    return response.data;
  }

  async getRealTimeEnergyData(siteId: string): Promise<EnergyData> {
    const response: AxiosResponse<EnergyData> = await this.client.get(
      `/energy/${siteId}/realtime`
    );
    return response.data;
  }

  // Alert Methods
  async getAlerts(organizationId: string, status?: string): Promise<Alert[]> {
    const params = new URLSearchParams();
    params.append('organizationId', organizationId);
    if (status) params.append('status', status);

    const response: AxiosResponse<Alert[]> = await this.client.get(
      `/alerts?${params.toString()}`
    );
    return response.data;
  }

  async acknowledgeAlert(alertId: string): Promise<Alert> {
    const response: AxiosResponse<Alert> = await this.client.put(
      `/alerts/${alertId}/acknowledge`
    );
    return response.data;
  }

  async resolveAlert(alertId: string, resolution?: string): Promise<Alert> {
    const response: AxiosResponse<Alert> = await this.client.put(
      `/alerts/${alertId}/resolve`,
      { resolution }
    );
    return response.data;
  }

  // Analytics Methods
  async getPerformanceAnalytics(
    siteId: string,
    startDate: string,
    endDate: string
  ): Promise<any> {
    const response = await this.client.get(
      `/analytics/performance/${siteId}?startDate=${startDate}&endDate=${endDate}`
    );
    return response.data;
  }

  async getFinancialAnalytics(
    organizationId: string,
    startDate: string,
    endDate: string
  ): Promise<any> {
    const response = await this.client.get(
      `/analytics/financial/${organizationId}?startDate=${startDate}&endDate=${endDate}`
    );
    return response.data;
  }

  async getEnvironmentalImpact(organizationId: string): Promise<any> {
    const response = await this.client.get(`/analytics/environmental/${organizationId}`);
    return response.data;
  }

  // User Management Methods
  async getUsers(organizationId: string): Promise<User[]> {
    const response: AxiosResponse<User[]> = await this.client.get(
      `/users?organizationId=${organizationId}`
    );
    return response.data;
  }

  async createUser(userData: Partial<User>): Promise<User> {
    const response: AxiosResponse<User> = await this.client.post('/users', userData);
    return response.data;
  }

  async updateUser(userId: string, userData: Partial<User>): Promise<User> {
    const response: AxiosResponse<User> = await this.client.put(`/users/${userId}`, userData);
    return response.data;
  }

  async deleteUser(userId: string): Promise<void> {
    await this.client.delete(`/users/${userId}`);
  }

  // Organization Methods
  async getOrganization(organizationId: string): Promise<Organization> {
    const response: AxiosResponse<Organization> = await this.client.get(
      `/organizations/${organizationId}`
    );
    return response.data;
  }

  async updateOrganization(
    organizationId: string,
    orgData: Partial<Organization>
  ): Promise<Organization> {
    const response: AxiosResponse<Organization> = await this.client.put(
      `/organizations/${organizationId}`,
      orgData
    );
    return response.data;
  }

  // Utility Methods
  isAuthenticated(): boolean {
    return !!this.accessToken;
  }

  getCurrentUser(): User | null {
    const userStr = localStorage.getItem('nexus-user');
    return userStr ? JSON.parse(userStr) : null;
  }

  getCurrentOrganization(): Organization | null {
    const orgStr = localStorage.getItem('nexus-organization');
    return orgStr ? JSON.parse(orgStr) : null;
  }

  // WebSocket connection for real-time updates
  connectWebSocket(organizationId: string): WebSocket | null {
    if (typeof window === 'undefined') return null;

    const wsUrl = API_BASE_URL.replace('http', 'ws').replace('/api/v1', '');
    const ws = new WebSocket(`${wsUrl}?token=${this.accessToken}&org=${organizationId}`);

    ws.onopen = () => {
      console.log('WebSocket connected');
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      // Handle real-time updates
      this.handleRealtimeUpdate(data);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket disconnected');
    };

    return ws;
  }

  private handleRealtimeUpdate(data: any) {
    // Emit custom events for real-time updates
    const event = new CustomEvent('nexus-realtime-update', { detail: data });
    window.dispatchEvent(event);
  }
}

// Create singleton instance
export const nexusApi = new NexusApiClient();

// Export types and API client
export default nexusApi;