const request = require('supertest');
const { Pool } = require('pg');

// Mock the database pool
jest.mock('pg', () => {
  const mPool = {
    connect: jest.fn(),
    query: jest.fn(),
    end: jest.fn(),
  };
  return { Pool: jest.fn(() => mPool) };
});

// Import the app after mocking
const app = require('../server');

describe('NexusGreen API Tests', () => {
  let mockPool;

  beforeAll(() => {
    mockPool = new Pool();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Health Endpoints', () => {
    test('GET /health should return healthy status', async () => {
      const mockClient = { release: jest.fn() };
      mockPool.connect.mockResolvedValue(mockClient);

      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.database).toBe('connected');
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('GET /api/health should return healthy status', async () => {
      const mockClient = { release: jest.fn() };
      mockPool.connect.mockResolvedValue(mockClient);

      const response = await request(app).get('/api/health');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.database).toBe('connected');
    });

    test('GET /health should return unhealthy when database fails', async () => {
      mockPool.connect.mockRejectedValue(new Error('Database connection failed'));

      const response = await request(app).get('/health');
      
      expect(response.status).toBe(503);
      expect(response.body.status).toBe('unhealthy');
      expect(response.body.database).toBe('disconnected');
    });
  });

  describe('Authentication Endpoints', () => {
    test('POST /api/v1/auth/login should authenticate valid user', async () => {
      const mockUser = {
        id: '550e8400-e29b-41d4-a716-446655440001',
        email: 'admin@nexusgreen.demo',
        first_name: 'Super',
        last_name: 'Admin',
        role: 'super_admin',
        company_id: '550e8400-e29b-41d4-a716-446655440000',
        is_active: true,
        permissions: { all_access: true },
        created_at: new Date(),
        updated_at: new Date()
      };

      const mockCompany = {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'NexusGreen Demo Corp'
      };

      mockPool.query
        .mockResolvedValueOnce({ rows: [{ ...mockUser, company_name: mockCompany.name }] })
        .mockResolvedValueOnce({ rows: [] }) // Update last login
        .mockResolvedValueOnce({ rows: [mockCompany] });

      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'admin@nexusgreen.demo',
          password: 'Demo2024!'
        });

      expect(response.status).toBe(200);
      expect(response.body.user.email).toBe('admin@nexusgreen.demo');
      expect(response.body.user.role).toBe('super_admin');
      expect(response.body.organization.name).toBe('NexusGreen Demo Corp');
    });

    test('POST /api/v1/auth/login should reject invalid credentials', async () => {
      mockPool.query.mockResolvedValue({ rows: [] });

      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'invalid@example.com',
          password: 'wrongpassword'
        });

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Invalid credentials');
    });

    test('POST /api/v1/auth/login should require email and password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Email and password are required');
    });
  });

  describe('Dashboard Endpoints', () => {
    test('GET /api/dashboard/stats should return dashboard statistics', async () => {
      mockPool.query
        .mockResolvedValueOnce({ rows: [{ count: '5' }] }) // installations
        .mockResolvedValueOnce({ rows: [{ total: '1500.00' }] }) // capacity
        .mockResolvedValueOnce({ rows: [{ total: '250.50' }] }) // today generation
        .mockResolvedValueOnce({ rows: [{ total: '1200.75' }] }) // monthly revenue
        .mockResolvedValueOnce({ rows: [{ count: '2' }] }); // active alerts

      const response = await request(app).get('/api/dashboard/stats');

      expect(response.status).toBe(200);
      expect(response.body.totalInstallations).toBe(5);
      expect(response.body.totalCapacity).toBe(1500);
      expect(response.body.todayGeneration).toBe(250.5);
      expect(response.body.monthlyRevenue).toBe(1200.75);
      expect(response.body.activeAlerts).toBe(2);
    });
  });

  describe('Installation Endpoints', () => {
    test('GET /api/installations should return installations list', async () => {
      const mockInstallations = [
        {
          id: '550e8400-e29b-41d4-a716-446655440010',
          name: 'Demo Solar Farm Alpha',
          location: 'Green Valley, CA',
          capacity_kw: '500.00',
          status: 'active',
          total_generation: '1250.75',
          avg_daily_generation: '41.69'
        }
      ];

      mockPool.query.mockResolvedValue({ rows: mockInstallations });

      const response = await request(app).get('/api/installations');

      expect(response.status).toBe(200);
      expect(response.body).toHaveLength(1);
      expect(response.body[0].name).toBe('Demo Solar Farm Alpha');
      expect(response.body[0].capacity_kw).toBe('500.00');
    });
  });

  describe('Company Endpoints', () => {
    test('GET /api/company should return company information', async () => {
      const mockCompany = {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'NexusGreen Demo Corp',
        registration_number: 'NGC-2024-001',
        address: '123 Solar Street, Green Valley, CA 90210',
        phone: '+1-555-SOLAR-01',
        email: 'info@nexusgreen.demo',
        website: 'https://nexusgreen.demo',
        logo_url: '/nexus-green-logo.svg'
      };

      mockPool.query.mockResolvedValue({ rows: [mockCompany] });

      const response = await request(app).get('/api/company');

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('NexusGreen Demo Corp');
      expect(response.body.email).toBe('info@nexusgreen.demo');
    });

    test('GET /api/company should return 404 when no company found', async () => {
      mockPool.query.mockResolvedValue({ rows: [] });

      const response = await request(app).get('/api/company');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Company not found');
    });
  });

  describe('Error Handling', () => {
    test('Should handle database errors gracefully', async () => {
      mockPool.query.mockRejectedValue(new Error('Database error'));

      const response = await request(app).get('/api/installations');

      expect(response.status).toBe(500);
      expect(response.body.error).toBe('Internal server error');
    });
  });
});