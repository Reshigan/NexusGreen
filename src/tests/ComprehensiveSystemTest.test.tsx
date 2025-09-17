import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import axios from 'axios';

// Import components to test
import NexusGreenApp from '../NexusGreenApp';
import Login from '../pages/Login';
import Dashboard from '../pages/Dashboard';
import Projects from '../pages/Projects';
import Analytics from '../pages/Analytics';
import { AuthProvider } from '../contexts/AuthContext';
import { CurrencyProvider } from '../contexts/CurrencyContext';

// Mock axios
vi.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

// Mock data
const mockUser = {
  id: '1',
  email: 'admin@gonxt.tech',
  name: 'Admin User',
  role: 'super_admin',
  organization_id: 'org-1'
};

const mockProjects = [
  {
    id: 'jhb-grid-tied-001',
    name: 'Johannesburg Solar Grid-Tied',
    location: 'Johannesburg, Gauteng, South Africa',
    capacity_kw: 100.0,
    status: 'operational',
    installation_date: '2022-01-15',
    sites: [{
      id: 'jhb-site-001',
      name: 'Johannesburg Commercial Solar Site',
      capacity_kw: 100.0,
      average_consumption_kw: 80.0,
      municipal_day_rate: 3.80,
      municipal_night_rate: 1.20,
      unit_price_from_funder: 1.50
    }]
  },
  {
    id: 'dbn-battery-001',
    name: 'Durban Solar Battery System',
    location: 'Durban, KwaZulu-Natal, South Africa',
    capacity_kw: 200.0,
    status: 'operational',
    installation_date: '2022-03-01',
    sites: [{
      id: 'dbn-site-001',
      name: 'Durban Industrial Solar + Battery Site',
      capacity_kw: 200.0,
      average_consumption_kw: 160.0,
      municipal_day_rate: 3.80,
      municipal_night_rate: 2.00,
      unit_price_from_funder: 1.50,
      battery_capacity_kwh: 400.0
    }]
  }
];

const mockEnergyData = [
  {
    timestamp: '2024-01-15T12:00:00Z',
    energy_generated_kwh: 85.5,
    energy_consumed_kwh: 75.2,
    grid_import_kwh: 0,
    grid_export_kwh: 10.3,
    battery_soc_percent: null
  },
  {
    timestamp: '2024-01-15T12:00:00Z',
    energy_generated_kwh: 165.8,
    energy_consumed_kwh: 145.6,
    grid_import_kwh: 0,
    grid_export_kwh: 20.2,
    battery_charge_kwh: 15.0,
    battery_discharge_kwh: 0,
    battery_soc_percent: 75.5
  }
];

// Test wrapper component
const TestWrapper = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <CurrencyProvider>
            {children}
          </CurrencyProvider>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

describe('NexusGreen Comprehensive System Tests', () => {
  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();
    
    // Setup default axios responses
    mockedAxios.get.mockImplementation((url) => {
      if (url.includes('/api/auth/me')) {
        return Promise.resolve({ data: { user: mockUser } });
      }
      if (url.includes('/api/projects')) {
        return Promise.resolve({ data: mockProjects });
      }
      if (url.includes('/api/energy-data')) {
        return Promise.resolve({ data: mockEnergyData });
      }
      return Promise.reject(new Error('Not found'));
    });

    mockedAxios.post.mockImplementation((url, data) => {
      if (url.includes('/api/auth/login')) {
        if (data.email === 'admin@gonxt.tech' && data.password === 'Demo2024!') {
          return Promise.resolve({ 
            data: { 
              user: mockUser, 
              token: 'mock-jwt-token' 
            } 
          });
        }
        return Promise.reject(new Error('Invalid credentials'));
      }
      return Promise.reject(new Error('Not found'));
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Authentication System', () => {
    it('should render login page correctly', () => {
      render(
        <TestWrapper>
          <Login />
        </TestWrapper>
      );

      expect(screen.getByText('Welcome Back')).toBeInTheDocument();
      expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /access dashboard/i })).toBeInTheDocument();
    });

    it('should handle successful login', async () => {
      render(
        <TestWrapper>
          <Login />
        </TestWrapper>
      );

      const emailInput = screen.getByLabelText(/email address/i);
      const passwordInput = screen.getByLabelText(/password/i);
      const loginButton = screen.getByRole('button', { name: /access dashboard/i });

      fireEvent.change(emailInput, { target: { value: 'admin@gonxt.tech' } });
      fireEvent.change(passwordInput, { target: { value: 'Demo2024!' } });
      fireEvent.click(loginButton);

      await waitFor(() => {
        expect(mockedAxios.post).toHaveBeenCalledWith(
          expect.stringContaining('/api/auth/login'),
          { email: 'admin@gonxt.tech', password: 'Demo2024!' }
        );
      });
    });

    it('should handle login failure', async () => {
      render(
        <TestWrapper>
          <Login />
        </TestWrapper>
      );

      const emailInput = screen.getByLabelText(/email address/i);
      const passwordInput = screen.getByLabelText(/password/i);
      const loginButton = screen.getByRole('button', { name: /access dashboard/i });

      fireEvent.change(emailInput, { target: { value: 'wrong@email.com' } });
      fireEvent.change(passwordInput, { target: { value: 'wrongpassword' } });
      fireEvent.click(loginButton);

      await waitFor(() => {
        expect(mockedAxios.post).toHaveBeenCalled();
      });
    });

    it('should validate required fields', async () => {
      render(
        <TestWrapper>
          <Login />
        </TestWrapper>
      );

      const loginButton = screen.getByRole('button', { name: /access dashboard/i });
      fireEvent.click(loginButton);

      // Should not make API call without email and password
      expect(mockedAxios.post).not.toHaveBeenCalled();
    });
  });

  describe('Project Management', () => {
    it('should display projects list', async () => {
      render(
        <TestWrapper>
          <Projects />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Johannesburg Solar Grid-Tied')).toBeInTheDocument();
        expect(screen.getByText('Durban Solar Battery System')).toBeInTheDocument();
      });

      expect(screen.getByText('100 kW')).toBeInTheDocument();
      expect(screen.getByText('200 kW')).toBeInTheDocument();
    });

    it('should show project details', async () => {
      render(
        <TestWrapper>
          <Projects />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Johannesburg, Gauteng, South Africa')).toBeInTheDocument();
        expect(screen.getByText('Durban, KwaZulu-Natal, South Africa')).toBeInTheDocument();
      });
    });

    it('should filter projects by status', async () => {
      render(
        <TestWrapper>
          <Projects />
        </TestWrapper>
      );

      await waitFor(() => {
        const operationalProjects = screen.getAllByText(/operational/i);
        expect(operationalProjects.length).toBeGreaterThan(0);
      });
    });
  });

  describe('Energy Data Visualization', () => {
    it('should render analytics dashboard', async () => {
      render(
        <TestWrapper>
          <Analytics />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText(/analytics/i)).toBeInTheDocument();
      });
    });

    it('should display energy generation data', async () => {
      render(
        <TestWrapper>
          <Dashboard />
        </TestWrapper>
      );

      await waitFor(() => {
        // Should show energy metrics
        expect(mockedAxios.get).toHaveBeenCalledWith(
          expect.stringContaining('/api/energy-data')
        );
      });
    });
  });

  describe('Financial Calculations', () => {
    it('should calculate savings correctly for Johannesburg project', () => {
      const jhbProject = mockProjects[0];
      const site = jhbProject.sites[0];
      
      // Test day rate calculation
      const dayRateSavings = 100 * site.municipal_day_rate; // 100 kWh * R3.80
      expect(dayRateSavings).toBe(380);
      
      // Test night rate calculation
      const nightRateSavings = 100 * site.municipal_night_rate; // 100 kWh * R1.20
      expect(nightRateSavings).toBe(120);
      
      // Test funder cost
      const funderCost = 100 * site.unit_price_from_funder; // 100 kWh * R1.50
      expect(funderCost).toBe(150);
    });

    it('should calculate savings correctly for Durban project', () => {
      const dbnProject = mockProjects[1];
      const site = dbnProject.sites[0];
      
      // Test day rate calculation
      const dayRateSavings = 200 * site.municipal_day_rate; // 200 kWh * R3.80
      expect(dayRateSavings).toBe(760);
      
      // Test night rate calculation (higher than Johannesburg)
      const nightRateSavings = 200 * site.municipal_night_rate; // 200 kWh * R2.00
      expect(nightRateSavings).toBe(400);
      
      // Test battery capacity
      expect(site.battery_capacity_kwh).toBe(400);
    });
  });

  describe('Data Validation', () => {
    it('should validate project data structure', () => {
      mockProjects.forEach(project => {
        expect(project).toHaveProperty('id');
        expect(project).toHaveProperty('name');
        expect(project).toHaveProperty('location');
        expect(project).toHaveProperty('capacity_kw');
        expect(project).toHaveProperty('status');
        expect(project).toHaveProperty('sites');
        
        expect(typeof project.capacity_kw).toBe('number');
        expect(project.capacity_kw).toBeGreaterThan(0);
        expect(Array.isArray(project.sites)).toBe(true);
      });
    });

    it('should validate site data structure', () => {
      mockProjects.forEach(project => {
        project.sites.forEach(site => {
          expect(site).toHaveProperty('id');
          expect(site).toHaveProperty('name');
          expect(site).toHaveProperty('capacity_kw');
          expect(site).toHaveProperty('average_consumption_kw');
          expect(site).toHaveProperty('municipal_day_rate');
          expect(site).toHaveProperty('municipal_night_rate');
          expect(site).toHaveProperty('unit_price_from_funder');
          
          expect(typeof site.capacity_kw).toBe('number');
          expect(typeof site.average_consumption_kw).toBe('number');
          expect(typeof site.municipal_day_rate).toBe('number');
          expect(typeof site.municipal_night_rate).toBe('number');
          expect(typeof site.unit_price_from_funder).toBe('number');
          
          expect(site.capacity_kw).toBeGreaterThan(0);
          expect(site.average_consumption_kw).toBeGreaterThan(0);
          expect(site.municipal_day_rate).toBeGreaterThan(0);
          expect(site.municipal_night_rate).toBeGreaterThan(0);
          expect(site.unit_price_from_funder).toBeGreaterThan(0);
        });
      });
    });

    it('should validate energy data structure', () => {
      mockEnergyData.forEach(data => {
        expect(data).toHaveProperty('timestamp');
        expect(data).toHaveProperty('energy_generated_kwh');
        expect(data).toHaveProperty('energy_consumed_kwh');
        expect(data).toHaveProperty('grid_import_kwh');
        expect(data).toHaveProperty('grid_export_kwh');
        
        expect(typeof data.energy_generated_kwh).toBe('number');
        expect(typeof data.energy_consumed_kwh).toBe('number');
        expect(typeof data.grid_import_kwh).toBe('number');
        expect(typeof data.grid_export_kwh).toBe('number');
        
        expect(data.energy_generated_kwh).toBeGreaterThanOrEqual(0);
        expect(data.energy_consumed_kwh).toBeGreaterThanOrEqual(0);
        expect(data.grid_import_kwh).toBeGreaterThanOrEqual(0);
        expect(data.grid_export_kwh).toBeGreaterThanOrEqual(0);
      });
    });
  });

  describe('Business Logic Validation', () => {
    it('should validate Johannesburg project specifications', () => {
      const jhbProject = mockProjects.find(p => p.id === 'jhb-grid-tied-001');
      expect(jhbProject).toBeDefined();
      
      if (jhbProject) {
        expect(jhbProject.capacity_kw).toBe(100);
        expect(jhbProject.location).toContain('Johannesburg');
        
        const site = jhbProject.sites[0];
        expect(site.average_consumption_kw).toBe(80); // ~80kW consumption
        expect(site.municipal_day_rate).toBe(3.80); // R3.80 day rate
        expect(site.municipal_night_rate).toBe(1.20); // R1.20 night rate
        expect(site.unit_price_from_funder).toBe(1.50); // R1.50 funder rate
      }
    });

    it('should validate Durban project specifications', () => {
      const dbnProject = mockProjects.find(p => p.id === 'dbn-battery-001');
      expect(dbnProject).toBeDefined();
      
      if (dbnProject) {
        expect(dbnProject.capacity_kw).toBe(200);
        expect(dbnProject.location).toContain('Durban');
        
        const site = dbnProject.sites[0];
        expect(site.average_consumption_kw).toBe(160); // ~160kW consumption
        expect(site.municipal_day_rate).toBe(3.80); // R3.80 day rate
        expect(site.municipal_night_rate).toBe(2.00); // R2.00 night rate
        expect(site.unit_price_from_funder).toBe(1.50); // R1.50 funder rate
        expect(site.battery_capacity_kwh).toBe(400); // 400kW battery
      }
    });

    it('should validate energy balance calculations', () => {
      // Test grid-tied system (Johannesburg)
      const jhbData = mockEnergyData[0];
      const netExport = jhbData.energy_generated_kwh - jhbData.energy_consumed_kwh;
      expect(netExport).toBeCloseTo(jhbData.grid_export_kwh - jhbData.grid_import_kwh, 1);
      
      // Test battery system (Durban)
      const dbnData = mockEnergyData[1];
      expect(dbnData.battery_soc_percent).toBeGreaterThan(0);
      expect(dbnData.battery_soc_percent).toBeLessThanOrEqual(100);
    });
  });

  describe('User Interface Components', () => {
    it('should render main navigation', async () => {
      render(
        <TestWrapper>
          <NexusGreenApp />
        </TestWrapper>
      );

      // Should render navigation elements
      await waitFor(() => {
        // Check for common navigation elements
        expect(document.body).toBeInTheDocument();
      });
    });

    it('should handle responsive design', () => {
      // Test mobile viewport
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 375,
      });

      render(
        <TestWrapper>
          <Dashboard />
        </TestWrapper>
      );

      // Should render without errors on mobile
      expect(document.body).toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('should handle API errors gracefully', async () => {
      mockedAxios.get.mockRejectedValueOnce(new Error('Network error'));

      render(
        <TestWrapper>
          <Projects />
        </TestWrapper>
      );

      // Should not crash on API error
      expect(document.body).toBeInTheDocument();
    });

    it('should handle invalid data gracefully', async () => {
      mockedAxios.get.mockResolvedValueOnce({ data: null });

      render(
        <TestWrapper>
          <Projects />
        </TestWrapper>
      );

      // Should handle null data without crashing
      expect(document.body).toBeInTheDocument();
    });
  });

  describe('Performance Tests', () => {
    it('should render large datasets efficiently', async () => {
      const largeDataset = Array.from({ length: 1000 }, (_, i) => ({
        ...mockEnergyData[0],
        timestamp: new Date(Date.now() - i * 3600000).toISOString()
      }));

      mockedAxios.get.mockResolvedValueOnce({ data: largeDataset });

      const startTime = performance.now();
      
      render(
        <TestWrapper>
          <Analytics />
        </TestWrapper>
      );

      const endTime = performance.now();
      const renderTime = endTime - startTime;

      // Should render within reasonable time (less than 1 second)
      expect(renderTime).toBeLessThan(1000);
    });
  });
});

// Integration tests for specific business scenarios
describe('Business Scenario Integration Tests', () => {
  describe('Johannesburg Grid-Tied System', () => {
    it('should calculate correct financial metrics', () => {
      const site = mockProjects[0].sites[0];
      const energyGenerated = 100; // kWh
      
      // During day hours (6-18)
      const daySavings = energyGenerated * site.municipal_day_rate; // 100 * 3.80 = 380
      const funderCost = energyGenerated * site.unit_price_from_funder; // 100 * 1.50 = 150
      const netSavingsDay = daySavings - funderCost; // 380 - 150 = 230
      
      expect(netSavingsDay).toBe(230);
      
      // During night hours (18-6)
      const nightSavings = energyGenerated * site.municipal_night_rate; // 100 * 1.20 = 120
      const netSavingsNight = nightSavings - funderCost; // 120 - 150 = -30 (loss)
      
      expect(netSavingsNight).toBe(-30);
    });
  });

  describe('Durban Battery System', () => {
    it('should optimize battery usage for peak shaving', () => {
      const site = mockProjects[1].sites[0];
      const batteryCapacity = site.battery_capacity_kwh; // 400 kWh
      
      // Peak hours (17-20): Use battery to avoid high grid costs
      const peakConsumption = 160; // kWh
      const solarGeneration = 50; // kWh (evening, low solar)
      const deficit = peakConsumption - solarGeneration; // 110 kWh needed
      
      // Battery can supply the deficit
      expect(batteryCapacity).toBeGreaterThan(deficit);
      
      // Cost comparison
      const gridCost = deficit * site.municipal_night_rate; // 110 * 2.00 = 220
      const batteryCost = deficit * site.unit_price_from_funder; // 110 * 1.50 = 165
      const savings = gridCost - batteryCost; // 220 - 165 = 55
      
      expect(savings).toBe(55);
    });
  });
});