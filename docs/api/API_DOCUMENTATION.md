# SolarNexus API Documentation

## Overview

The SolarNexus API is a RESTful web service that provides access to solar energy monitoring and management functionality. This API enables developers to integrate solar data monitoring, analytics, and management capabilities into their applications.

## Base URL
```
Production: https://nexus.gonxt.tech/api/v1
Development: http://localhost:3000/api/v1
```

## Authentication

### JWT Token Authentication
All API endpoints (except authentication endpoints) require a valid JWT token in the Authorization header.

```http
Authorization: Bearer <your-jwt-token>
```

### Token Lifecycle
- **Access Token**: Valid for 15 minutes
- **Refresh Token**: Valid for 7 days
- **Token Refresh**: Use the refresh endpoint to get new tokens

## Rate Limiting

API requests are rate-limited to prevent abuse:
- **Authenticated users**: 1000 requests per hour
- **Unauthenticated users**: 100 requests per hour
- **Burst limit**: 50 requests per minute

Rate limit headers are included in all responses:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0.0",
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0.0"
  }
}
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `AUTHENTICATION_ERROR` | 401 | Authentication required or failed |
| `AUTHORIZATION_ERROR` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

## Authentication Endpoints

### POST /auth/login
Authenticate user and receive JWT tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "manager",
      "organizationId": "org-123"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST /auth/refresh
Refresh JWT tokens using refresh token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST /auth/logout
Logout user and invalidate tokens.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Successfully logged out"
  }
}
```

## User Management

### GET /users/profile
Get current user profile.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "manager",
    "organizationId": "org-123",
    "isActive": true,
    "emailVerified": true,
    "lastLogin": "2024-01-15T10:30:00Z",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
}
```

### PUT /users/profile
Update current user profile.

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Smith",
  "email": "john.smith@example.com"
}
```

### POST /users/change-password
Change user password.

**Request Body:**
```json
{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword"
}
```

## Organization Management

### GET /organizations
List organizations (admin only).

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search term
- `type` (optional): Organization type filter

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "org-123",
      "name": "Solar Solutions Inc",
      "type": "installer",
      "contactEmail": "contact@solarsolutions.com",
      "contactPhone": "+1-555-0123",
      "address": "123 Solar Street, Sun City, SC 12345",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

### POST /organizations
Create new organization (admin only).

**Request Body:**
```json
{
  "name": "Solar Solutions Inc",
  "type": "installer",
  "contactEmail": "contact@solarsolutions.com",
  "contactPhone": "+1-555-0123",
  "address": "123 Solar Street, Sun City, SC 12345"
}
```

### GET /organizations/:id
Get organization by ID.

### PUT /organizations/:id
Update organization (admin or organization manager).

### DELETE /organizations/:id
Delete organization (admin only).

## Site Management

### GET /sites
List sites accessible to current user.

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `organizationId` (optional): Filter by organization
- `isActive` (optional): Filter by active status
- `search` (optional): Search by name

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "site-123",
      "name": "Downtown Solar Farm",
      "organizationId": "org-123",
      "location": {
        "lat": 40.7128,
        "lng": -74.0060
      },
      "capacityKw": 500.5,
      "installationDate": "2023-06-15",
      "isActive": true,
      "createdAt": "2023-06-01T00:00:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### POST /sites
Create new site.

**Request Body:**
```json
{
  "name": "Downtown Solar Farm",
  "organizationId": "org-123",
  "location": {
    "lat": 40.7128,
    "lng": -74.0060
  },
  "capacityKw": 500.5,
  "installationDate": "2023-06-15",
  "solaxClientId": "client-id",
  "solaxClientSecret": "client-secret",
  "solaxPlantId": "plant-123"
}
```

### GET /sites/:id
Get site by ID.

### PUT /sites/:id
Update site.

### DELETE /sites/:id
Delete site.

## Energy Data

### GET /sites/:siteId/energy
Get energy data for a site.

**Query Parameters:**
- `startDate` (required): Start date (ISO 8601 format)
- `endDate` (required): End date (ISO 8601 format)
- `interval` (optional): Data interval ('hour', 'day', 'month')
- `metrics` (optional): Comma-separated list of metrics

**Response:**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "timestamp": "2024-01-15T10:00:00Z",
        "generation": 45.2,
        "consumption": 38.7,
        "gridImport": 5.5,
        "gridExport": 12.0,
        "batteryCharge": 0,
        "batteryDischarge": 0,
        "batterySoc": 85.5
      }
    ],
    "summary": {
      "totalGeneration": 1250.5,
      "totalConsumption": 980.3,
      "totalGridImport": 150.2,
      "totalGridExport": 420.4,
      "averageEfficiency": 92.5,
      "peakGeneration": 85.2,
      "peakConsumption": 65.8
    }
  }
}
```

### POST /sites/:siteId/energy
Add energy data points (bulk insert).

**Request Body:**
```json
{
  "data": [
    {
      "timestamp": "2024-01-15T10:00:00Z",
      "generation": 45.2,
      "consumption": 38.7,
      "gridImport": 5.5,
      "gridExport": 12.0
    }
  ]
}
```

## Analytics

### GET /analytics/performance
Get performance analytics.

**Query Parameters:**
- `siteIds` (optional): Comma-separated site IDs
- `organizationId` (optional): Organization ID
- `startDate` (required): Start date
- `endDate` (required): End date
- `metrics` (optional): Performance metrics to include

**Response:**
```json
{
  "success": true,
  "data": {
    "sites": [
      {
        "siteId": "site-123",
        "siteName": "Downtown Solar Farm",
        "performance": {
          "totalGeneration": 1250.5,
          "expectedGeneration": 1300.0,
          "efficiency": 96.2,
          "availability": 99.1,
          "performanceRatio": 0.85
        }
      }
    ],
    "aggregated": {
      "totalGeneration": 1250.5,
      "averageEfficiency": 96.2,
      "totalAvailability": 99.1
    }
  }
}
```

### GET /analytics/financial
Get financial analytics.

**Query Parameters:**
- `siteIds` (optional): Comma-separated site IDs
- `organizationId` (optional): Organization ID
- `startDate` (required): Start date
- `endDate` (required): End date

**Response:**
```json
{
  "success": true,
  "data": {
    "revenue": {
      "total": 15420.50,
      "fromGeneration": 12340.25,
      "fromExport": 3080.25
    },
    "costs": {
      "total": 2150.75,
      "maintenance": 1200.00,
      "operations": 950.75
    },
    "savings": {
      "total": 8750.25,
      "fromSelfConsumption": 8750.25
    },
    "roi": {
      "monthly": 8.5,
      "annual": 12.3
    }
  }
}
```

### GET /analytics/predictions
Get predictive analytics.

**Query Parameters:**
- `siteId` (required): Site ID
- `days` (optional): Prediction days ahead (default: 7, max: 30)
- `includeWeather` (optional): Include weather data

**Response:**
```json
{
  "success": true,
  "data": {
    "predictions": [
      {
        "date": "2024-01-16",
        "predictedGeneration": 125.5,
        "confidence": 0.85,
        "weatherFactor": 0.92,
        "maintenanceImpact": 0.0
      }
    ],
    "summary": {
      "totalPredictedGeneration": 850.5,
      "averageConfidence": 0.83,
      "maintenanceRecommendations": []
    }
  }
}
```

## Alerts

### GET /alerts
Get alerts for accessible sites.

**Query Parameters:**
- `siteId` (optional): Filter by site
- `severity` (optional): Filter by severity
- `status` (optional): Filter by status
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "alert-123",
      "siteId": "site-123",
      "siteName": "Downtown Solar Farm",
      "type": "performance_degradation",
      "severity": "medium",
      "status": "open",
      "title": "Performance Below Expected",
      "description": "Site performance is 15% below expected for the past 3 days",
      "createdAt": "2024-01-15T08:00:00Z",
      "updatedAt": "2024-01-15T08:00:00Z"
    }
  ]
}
```

### POST /alerts/:id/acknowledge
Acknowledge an alert.

### POST /alerts/:id/resolve
Resolve an alert.

**Request Body:**
```json
{
  "resolution": "Maintenance performed, issue resolved",
  "resolvedBy": "technician-123"
}
```

## Reports

### GET /reports/performance
Generate performance report.

**Query Parameters:**
- `siteIds` (required): Comma-separated site IDs
- `startDate` (required): Start date
- `endDate` (required): End date
- `format` (optional): 'json' or 'pdf' (default: 'json')

### GET /reports/financial
Generate financial report.

### GET /reports/sustainability
Generate sustainability report.

**Response:**
```json
{
  "success": true,
  "data": {
    "reportId": "report-123",
    "type": "sustainability",
    "period": {
      "startDate": "2024-01-01",
      "endDate": "2024-01-31"
    },
    "metrics": {
      "co2Avoided": 1250.5,
      "treesEquivalent": 56,
      "homesEquivalent": 12,
      "sdgContributions": [
        {
          "goal": 7,
          "name": "Affordable and Clean Energy",
          "contribution": "High"
        }
      ]
    },
    "downloadUrl": "https://nexus.gonxt.tech/api/v1/reports/report-123/download"
  }
}
```

## WebSocket Events

### Connection
```javascript
const socket = io('wss://nexus.gonxt.tech', {
  auth: {
    token: 'your-jwt-token'
  }
});
```

### Events

#### Real-time Energy Data
```javascript
// Subscribe to site energy updates
socket.emit('subscribe', { siteId: 'site-123' });

// Receive energy data updates
socket.on('energyData', (data) => {
  console.log('New energy data:', data);
});
```

#### Alert Notifications
```javascript
// Subscribe to organization alerts
socket.emit('subscribeAlerts', { organizationId: 'org-123' });

// Receive new alerts
socket.on('newAlert', (alert) => {
  console.log('New alert:', alert);
});
```

## SDK Examples

### JavaScript/Node.js
```javascript
const SolarNexusAPI = require('@solarnexus/api-client');

const client = new SolarNexusAPI({
  baseURL: 'https://nexus.gonxt.tech/api/v1',
  apiKey: 'your-api-key'
});

// Get sites
const sites = await client.sites.list();

// Get energy data
const energyData = await client.energy.get('site-123', {
  startDate: '2024-01-01',
  endDate: '2024-01-31'
});
```

### Python
```python
from solarnexus import SolarNexusClient

client = SolarNexusClient(
    base_url='https://nexus.gonxt.tech/api/v1',
    api_key='your-api-key'
)

# Get sites
sites = client.sites.list()

# Get energy data
energy_data = client.energy.get(
    site_id='site-123',
    start_date='2024-01-01',
    end_date='2024-01-31'
)
```

## Webhooks

### Configuration
Configure webhooks to receive real-time notifications about events in your SolarNexus account.

### Supported Events
- `site.created`
- `site.updated`
- `alert.created`
- `alert.resolved`
- `energy.data.received`

### Webhook Payload
```json
{
  "event": "alert.created",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "alertId": "alert-123",
    "siteId": "site-123",
    "severity": "high",
    "type": "equipment_failure"
  }
}
```

## Testing

### Postman Collection
A Postman collection is available for testing the API:
```
https://nexus.gonxt.tech/api/postman-collection.json
```

### Test Environment
```
Base URL: https://test.nexus.gonxt.tech/api/v1
Test Account: test@solarnexus.com
Test Password: TestPassword123!
```

## Support

### API Support
- **Email**: api-support@solarnexus.com
- **Documentation**: https://docs.nexus.gonxt.tech
- **Status Page**: https://status.nexus.gonxt.tech

### Rate Limit Increases
Contact support for rate limit increases for production applications.

---

*This API documentation is automatically generated and updated with each release. Last updated: 2024-01-15*