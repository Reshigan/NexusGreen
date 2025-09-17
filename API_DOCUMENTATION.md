# NexusGreen - API Documentation

## 📋 Overview

This document provides comprehensive documentation for the NexusGreen REST API. The API provides endpoints for authentication, dashboard metrics, energy data, and system monitoring.

**Base URL:** `http://localhost/api`  
**API Version:** v1  
**Content Type:** `application/json`  
**Authentication:** JWT Bearer Token  

## 🔐 Authentication

### POST /api/auth/login
Authenticate a user and receive a JWT token.

**Request:**
```json
{
  "email": "admin@nexusgreen.com",
  "password": "admin123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "admin@nexusgreen.com",
    "name": "Admin User"
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Email and password are required"
}
```

### POST /api/auth/register
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 2,
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Response (409 Conflict):**
```json
{
  "success": false,
  "message": "User already exists"
}
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Email, password, and name are required"
}
```

## 📊 Dashboard Endpoints

### GET /api/dashboard/metrics
Get overall dashboard metrics and KPIs.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "totalProduction": 45678.5,
    "efficiency": 87.3,
    "revenue": 12450.75,
    "carbonOffset": 23.4,
    "activeSites": 5,
    "totalCapacity": 250.0,
    "systemUptime": 99.2,
    "lastUpdated": "2025-09-17T10:30:00Z"
  }
}
```

**Field Descriptions:**
- `totalProduction`: Total energy production in kWh
- `efficiency`: Overall system efficiency percentage
- `revenue`: Total revenue in USD
- `carbonOffset`: Carbon offset in tons
- `activeSites`: Number of active energy sites
- `totalCapacity`: Total system capacity in kW
- `systemUptime`: System uptime percentage
- `lastUpdated`: Timestamp of last data update

### GET /api/dashboard/energy-production
Get energy production data for charts.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `period` (optional): `day`, `week`, `month`, `year` (default: `month`)
- `site_id` (optional): Filter by specific site ID

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "date": "2025-09-01",
      "production": 1250.5,
      "target": 1200.0,
      "efficiency": 85.2
    },
    {
      "date": "2025-09-02",
      "production": 1380.2,
      "target": 1200.0,
      "efficiency": 88.7
    }
  ]
}
```

### GET /api/dashboard/performance-analytics
Get performance analytics data.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "month": "2025-01",
      "efficiency": 82.5,
      "performance": 95.2,
      "downtime": 2.1,
      "maintenance": 1.2
    },
    {
      "month": "2025-02",
      "efficiency": 85.1,
      "performance": 97.8,
      "downtime": 1.5,
      "maintenance": 0.8
    }
  ]
}
```

### GET /api/dashboard/revenue-trends
Get revenue trend data.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "month": "2025-01",
      "revenue": 2450.75,
      "projection": 2500.00,
      "savings": 1200.50,
      "roi": 15.2
    },
    {
      "month": "2025-02",
      "revenue": 2680.25,
      "projection": 2600.00,
      "savings": 1350.75,
      "roi": 16.8
    }
  ]
}
```

## 🚨 Alerts Endpoints

### GET /api/alerts
Get system alerts and notifications.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `severity` (optional): `low`, `medium`, `high`, `critical`
- `resolved` (optional): `true`, `false`
- `limit` (optional): Number of alerts to return (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "type": "performance",
      "message": "Solar panel efficiency below threshold at Site A",
      "severity": "medium",
      "site_id": 1,
      "site_name": "Solar Farm A",
      "resolved": false,
      "created_at": "2025-09-17T09:15:00Z",
      "resolved_at": null
    },
    {
      "id": 2,
      "type": "maintenance",
      "message": "Scheduled maintenance completed for inverter #3",
      "severity": "low",
      "site_id": 2,
      "site_name": "Rooftop Installation B",
      "resolved": true,
      "created_at": "2025-09-16T14:30:00Z",
      "resolved_at": "2025-09-16T16:45:00Z"
    }
  ],
  "pagination": {
    "total": 25,
    "limit": 50,
    "offset": 0,
    "hasMore": false
  }
}
```

### POST /api/alerts/:id/resolve
Mark an alert as resolved.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Alert resolved successfully",
  "data": {
    "id": 1,
    "resolved": true,
    "resolved_at": "2025-09-17T10:30:00Z"
  }
}
```

## 🏢 Sites Endpoints

### GET /api/sites
Get all energy sites.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Solar Farm A",
      "location": "California, USA",
      "capacity_kw": 100.0,
      "installation_date": "2024-01-15",
      "status": "active",
      "current_production": 85.5,
      "efficiency": 87.2,
      "last_maintenance": "2025-08-15",
      "created_at": "2024-01-10T00:00:00Z"
    },
    {
      "id": 2,
      "name": "Rooftop Installation B",
      "location": "Texas, USA",
      "capacity_kw": 50.0,
      "installation_date": "2024-03-20",
      "status": "active",
      "current_production": 42.8,
      "efficiency": 89.1,
      "last_maintenance": "2025-07-20",
      "created_at": "2024-03-15T00:00:00Z"
    }
  ]
}
```

### GET /api/sites/:id
Get details for a specific site.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Solar Farm A",
    "location": "California, USA",
    "capacity_kw": 100.0,
    "installation_date": "2024-01-15",
    "status": "active",
    "current_production": 85.5,
    "efficiency": 87.2,
    "last_maintenance": "2025-08-15",
    "weather_conditions": {
      "temperature": 25.5,
      "humidity": 45.2,
      "cloud_cover": 20.0,
      "wind_speed": 12.5
    },
    "equipment": [
      {
        "id": 1,
        "type": "inverter",
        "model": "SolarMax 3000",
        "status": "operational",
        "efficiency": 96.5
      },
      {
        "id": 2,
        "type": "panel",
        "model": "SunPower X22",
        "status": "operational",
        "efficiency": 22.1
      }
    ],
    "created_at": "2024-01-10T00:00:00Z"
  }
}
```

## 📈 Energy Data Endpoints

### GET /api/energy-data
Get historical energy data.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `site_id` (optional): Filter by site ID
- `start_date` (optional): Start date (ISO 8601 format)
- `end_date` (optional): End date (ISO 8601 format)
- `granularity` (optional): `hour`, `day`, `week`, `month` (default: `day`)
- `limit` (optional): Number of records (default: 100)

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "site_id": 1,
      "site_name": "Solar Farm A",
      "timestamp": "2025-09-17T10:00:00Z",
      "production_kwh": 85.5,
      "efficiency_percent": 87.2,
      "revenue_usd": 12.45,
      "weather": {
        "temperature": 25.5,
        "irradiance": 850.0,
        "cloud_cover": 15.0
      }
    }
  ],
  "pagination": {
    "total": 1500,
    "limit": 100,
    "offset": 0,
    "hasMore": true
  }
}
```

### POST /api/energy-data
Add new energy data point (for IoT devices or manual entry).

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request:**
```json
{
  "site_id": 1,
  "production_kwh": 95.2,
  "efficiency_percent": 89.5,
  "timestamp": "2025-09-17T11:00:00Z"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Energy data recorded successfully",
  "data": {
    "id": 1501,
    "site_id": 1,
    "production_kwh": 95.2,
    "efficiency_percent": 89.5,
    "revenue_usd": 13.85,
    "timestamp": "2025-09-17T11:00:00Z",
    "created_at": "2025-09-17T11:05:00Z"
  }
}
```

## 🔧 System Endpoints

### GET /api/health
System health check endpoint.

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-17T10:30:00Z",
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "api": "operational",
    "cache": "operational"
  },
  "uptime": 86400
}
```

### GET /api/system/stats
Get system statistics and performance metrics.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "api_requests_today": 1250,
    "active_users": 15,
    "database_size": "125.5 MB",
    "cache_hit_rate": 89.5,
    "average_response_time": 145,
    "error_rate": 0.02,
    "last_backup": "2025-09-17T02:00:00Z"
  }
}
```

## 📊 Reports Endpoints

### GET /api/reports/summary
Generate summary report for specified period.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `period`: `week`, `month`, `quarter`, `year`
- `site_id` (optional): Filter by site ID
- `format` (optional): `json`, `csv`, `pdf` (default: `json`)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "period": "month",
    "start_date": "2025-09-01",
    "end_date": "2025-09-30",
    "summary": {
      "total_production": 2850.5,
      "average_efficiency": 86.8,
      "total_revenue": 415.75,
      "carbon_offset": 1.42,
      "peak_production": 125.8,
      "peak_production_date": "2025-09-15"
    },
    "sites": [
      {
        "site_id": 1,
        "name": "Solar Farm A",
        "production": 1900.3,
        "efficiency": 87.2,
        "revenue": 277.50
      },
      {
        "site_id": 2,
        "name": "Rooftop Installation B",
        "production": 950.2,
        "efficiency": 86.1,
        "revenue": 138.25
      }
    ]
  }
}
```

## ❌ Error Responses

### Standard Error Format
All API errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Additional error details (optional)"
  },
  "timestamp": "2025-09-17T10:30:00Z"
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `BAD_REQUEST` | Invalid request parameters |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource already exists |
| 422 | `VALIDATION_ERROR` | Request validation failed |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |
| 503 | `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

### Example Error Responses

**401 Unauthorized:**
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication token is required"
  },
  "timestamp": "2025-09-17T10:30:00Z"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Site with ID 999 not found"
  },
  "timestamp": "2025-09-17T10:30:00Z"
}
```

**422 Validation Error:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "email": "Valid email address is required",
      "password": "Password must be at least 8 characters"
    }
  },
  "timestamp": "2025-09-17T10:30:00Z"
}
```

## 🔒 Authentication & Security

### JWT Token Format
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImVtYWlsIjoiYWRtaW5AbmV4dXNncmVlbi5jb20iLCJpYXQiOjE2OTQ5NjQwMDAsImV4cCI6MTY5NTA1MDQwMH0.signature
```

### Token Payload
```json
{
  "userId": 1,
  "email": "admin@nexusgreen.com",
  "iat": 1694964000,
  "exp": 1695050400
}
```

### Security Headers
All API responses include security headers:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

## 📝 Rate Limiting

- **Authentication endpoints:** 5 requests per minute per IP
- **Dashboard endpoints:** 100 requests per minute per user
- **Data endpoints:** 200 requests per minute per user
- **System endpoints:** 10 requests per minute per user

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1694964060
```

## 🧪 Testing the API

### Using curl
```bash
# Login
curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusgreen.com","password":"admin123"}'

# Get dashboard metrics
curl -X GET http://localhost/api/dashboard/metrics \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Health check
curl -X GET http://localhost/api/health
```

### Using Postman
1. Import the API collection (if available)
2. Set base URL to `http://localhost/api`
3. Add JWT token to Authorization header
4. Test endpoints with sample data

## 📚 SDK & Client Libraries

### JavaScript/TypeScript Client
```typescript
import axios from 'axios';

class NexusGreenAPI {
  private baseURL = 'http://localhost/api';
  private token: string | null = null;

  async login(email: string, password: string) {
    const response = await axios.post(`${this.baseURL}/auth/login`, {
      email,
      password
    });
    this.token = response.data.token;
    return response.data;
  }

  async getDashboardMetrics() {
    return axios.get(`${this.baseURL}/dashboard/metrics`, {
      headers: { Authorization: `Bearer ${this.token}` }
    });
  }
}
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-09-17  
**Maintained By:** Development Team  
**Contact:** openhands@all-hands.dev