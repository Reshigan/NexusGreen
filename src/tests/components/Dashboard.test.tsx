import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Dashboard from '../../pages/Dashboard';
import * as nexusApi from '../../services/nexusApi';

// Mock the API service
jest.mock('../../services/nexusApi');
const mockNexusApi = nexusApi as jest.Mocked<typeof nexusApi>;

// Mock Chart.js
jest.mock('react-chartjs-2', () => ({
  Line: () => <div data-testid="line-chart">Line Chart</div>,
  Bar: () => <div data-testid="bar-chart">Bar Chart</div>,
  Doughnut: () => <div data-testid="doughnut-chart">Doughnut Chart</div>,
}));

const mockDashboardData = {
  totalInstallations: 5,
  totalCapacity: 1500,
  todayGeneration: 250.5,
  monthlyRevenue: 1200.75,
  activeAlerts: 2,
  performanceRatio: 0.85,
  co2Saved: 125.3,
  systemEfficiency: 92.5
};

const mockInstallations = [
  {
    id: '1',
    name: 'Solar Farm Alpha',
    location: 'Green Valley, CA',
    capacity_kw: 500,
    status: 'active',
    total_generation: 1250.75,
    avg_daily_generation: 41.69
  }
];

const renderDashboard = () => {
  return render(
    <BrowserRouter>
      <Dashboard />
    </BrowserRouter>
  );
};

describe('Dashboard Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockNexusApi.getDashboardStats.mockResolvedValue(mockDashboardData);
    mockNexusApi.getInstallations.mockResolvedValue(mockInstallations);
  });

  test('renders dashboard title', async () => {
    renderDashboard();
    
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });

  test('displays loading state initially', () => {
    renderDashboard();
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('displays dashboard stats after loading', async () => {
    renderDashboard();
    
    await waitFor(() => {
      expect(screen.getByText('5')).toBeInTheDocument(); // Total installations
      expect(screen.getByText('1,500 kW')).toBeInTheDocument(); // Total capacity
      expect(screen.getByText('250.5 kWh')).toBeInTheDocument(); // Today generation
      expect(screen.getByText('$1,200.75')).toBeInTheDocument(); // Monthly revenue
    });
  });

  test('displays performance metrics', async () => {
    renderDashboard();
    
    await waitFor(() => {
      expect(screen.getByText('85%')).toBeInTheDocument(); // Performance ratio
      expect(screen.getByText('125.3 kg')).toBeInTheDocument(); // CO2 saved
      expect(screen.getByText('92.5%')).toBeInTheDocument(); // System efficiency
    });
  });

  test('displays active alerts count', async () => {
    renderDashboard();
    
    await waitFor(() => {
      expect(screen.getByText('2')).toBeInTheDocument(); // Active alerts
    });
  });

  test('renders charts', async () => {
    renderDashboard();
    
    await waitFor(() => {
      expect(screen.getByTestId('line-chart')).toBeInTheDocument();
      expect(screen.getByTestId('bar-chart')).toBeInTheDocument();
      expect(screen.getByTestId('doughnut-chart')).toBeInTheDocument();
    });
  });

  test('handles API errors gracefully', async () => {
    mockNexusApi.getDashboardStats.mockRejectedValue(new Error('API Error'));
    
    renderDashboard();
    
    await waitFor(() => {
      expect(screen.getByText('Error loading dashboard data')).toBeInTheDocument();
    });
  });

  test('calls API functions on mount', async () => {
    renderDashboard();
    
    await waitFor(() => {
      expect(mockNexusApi.getDashboardStats).toHaveBeenCalledTimes(1);
      expect(mockNexusApi.getInstallations).toHaveBeenCalledTimes(1);
    });
  });
});