# SolarNexus - Technical Specifications

## System Architecture

### Overview
SolarNexus follows a modern three-tier architecture with a React frontend, Node.js backend, and PostgreSQL database, all containerized using Docker and deployed behind an Nginx reverse proxy.

### Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Web    │    │     Nginx       │    │   React App     │
│    Browser      │◄──►│ Reverse Proxy   │◄──►│   (Frontend)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Node.js API   │
                       │   (Backend)     │
                       └─────────────────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
            ┌─────────────┐ ┌─────────┐ ┌─────────────┐
            │ PostgreSQL  │ │  Redis  │ │ External    │
            │ Database    │ │ Cache   │ │ APIs        │
            └─────────────┘ └─────────┘ └─────────────┘
```

## Technology Stack

### Frontend Technologies
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Framework | React | 18.2.0 | UI framework |
| Language | TypeScript | 5.0.0 | Type-safe JavaScript |
| Build Tool | Vite | 4.4.5 | Fast build tool and dev server |
| Styling | Tailwind CSS | 3.3.0 | Utility-first CSS framework |
| UI Components | Radix UI | Various | Accessible component primitives |
| Icons | Lucide React | 0.263.1 | Icon library |
| Charts | Recharts | 2.8.0 | Data visualization |
| HTTP Client | Axios | 1.3.0 | API communication |
| Routing | React Router | 6.8.0 | Client-side routing |

### Backend Technologies
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Runtime | Node.js | 20.x | JavaScript runtime |
| Framework | Express.js | 4.18.0 | Web application framework |
| Language | TypeScript | 5.0.0 | Type-safe JavaScript |
| ORM | Prisma | 5.0.0 | Database ORM and migrations |
| Authentication | JWT | 9.0.0 | Token-based authentication |
| Validation | Joi/Zod | Latest | Request validation |
| Logging | Winston | 3.10.0 | Structured logging |
| Email | Nodemailer | 6.9.0 | Email service |
| WebSockets | Socket.io | 4.7.0 | Real-time communication |

### Database & Storage
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Primary DB | PostgreSQL | 15 | Relational database |
| Cache | Redis | 7 | Session store and caching |
| File Storage | Local/S3 | - | File uploads and assets |

### Infrastructure
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Containerization | Docker | 24.x | Application containerization |
| Orchestration | Docker Compose | 2.x | Multi-container orchestration |
| Web Server | Nginx | Alpine | Reverse proxy and static files |
| SSL/TLS | Let's Encrypt | - | SSL certificate management |
| Process Manager | PM2 | 5.x | Node.js process management |

## Database Schema

### Core Entities

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    organization_id UUID REFERENCES organizations(id),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Organizations Table
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type organization_type NOT NULL,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Sites Table
```sql
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    organization_id UUID REFERENCES organizations(id) NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    capacity_kw DECIMAL(10, 2) NOT NULL,
    installation_date DATE,
    solax_client_id VARCHAR(255),
    solax_client_secret VARCHAR(255),
    solax_plant_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Energy Data Table
```sql
CREATE TABLE energy_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    generation_kwh DECIMAL(10, 4),
    consumption_kwh DECIMAL(10, 4),
    grid_import_kwh DECIMAL(10, 4),
    grid_export_kwh DECIMAL(10, 4),
    battery_charge_kwh DECIMAL(10, 4),
    battery_discharge_kwh DECIMAL(10, 4),
    battery_soc DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Enums and Types
```sql
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'user', 'viewer');
CREATE TYPE organization_type AS ENUM ('installer', 'om_provider', 'asset_owner', 'customer');
CREATE TYPE alert_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE alert_status AS ENUM ('open', 'acknowledged', 'resolved', 'closed');
```

## API Specifications

### Authentication Endpoints

#### POST /api/auth/login
```typescript
interface LoginRequest {
  email: string;
  password: string;
}

interface LoginResponse {
  user: {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: string;
    organizationId: string;
  };
  accessToken: string;
  refreshToken: string;
}
```

#### POST /api/auth/refresh
```typescript
interface RefreshRequest {
  refreshToken: string;
}

interface RefreshResponse {
  accessToken: string;
  refreshToken: string;
}
```

### Site Management Endpoints

#### GET /api/sites
```typescript
interface SiteListResponse {
  sites: Site[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

interface Site {
  id: string;
  name: string;
  organizationId: string;
  location: {
    lat: number;
    lng: number;
  };
  capacityKw: number;
  installationDate: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
```

#### POST /api/sites
```typescript
interface CreateSiteRequest {
  name: string;
  organizationId: string;
  location?: {
    lat: number;
    lng: number;
  };
  capacityKw: number;
  installationDate?: string;
  solaxClientId?: string;
  solaxClientSecret?: string;
  solaxPlantId?: string;
}
```

### Energy Data Endpoints

#### GET /api/sites/:siteId/energy
```typescript
interface EnergyDataRequest {
  startDate: string; // ISO 8601
  endDate: string;   // ISO 8601
  interval?: 'hour' | 'day' | 'month';
}

interface EnergyDataResponse {
  data: EnergyDataPoint[];
  summary: {
    totalGeneration: number;
    totalConsumption: number;
    totalGridImport: number;
    totalGridExport: number;
    averageEfficiency: number;
  };
}

interface EnergyDataPoint {
  timestamp: string;
  generation: number;
  consumption: number;
  gridImport: number;
  gridExport: number;
  batteryCharge?: number;
  batteryDischarge?: number;
  batterySoc?: number;
}
```

### Analytics Endpoints

#### GET /api/analytics/performance
```typescript
interface PerformanceAnalyticsRequest {
  siteIds: string[];
  startDate: string;
  endDate: string;
  metrics: ('generation' | 'efficiency' | 'availability')[];
}

interface PerformanceAnalyticsResponse {
  sites: SitePerformance[];
  aggregated: {
    totalGeneration: number;
    averageEfficiency: number;
    totalAvailability: number;
  };
}
```

## Security Specifications

### Authentication & Authorization

#### JWT Token Structure
```typescript
interface JWTPayload {
  sub: string;        // User ID
  email: string;      // User email
  role: string;       // User role
  orgId: string;      // Organization ID
  iat: number;        // Issued at
  exp: number;        // Expiration
}
```

#### Role-Based Access Control
| Role | Permissions |
|------|-------------|
| admin | Full system access |
| manager | Organization-level access |
| user | Site-level access |
| viewer | Read-only access |

### Data Protection

#### Encryption
- **At Rest**: AES-256 encryption for sensitive data
- **In Transit**: TLS 1.2+ for all communications
- **Passwords**: bcrypt with salt rounds 12

#### Input Validation
```typescript
// Example validation schema
const siteSchema = Joi.object({
  name: Joi.string().min(1).max(255).required(),
  capacityKw: Joi.number().positive().max(10000).required(),
  location: Joi.object({
    lat: Joi.number().min(-90).max(90),
    lng: Joi.number().min(-180).max(180)
  }).optional()
});
```

## Performance Specifications

### Response Time Requirements
| Endpoint Type | Target Response Time | Maximum Response Time |
|---------------|---------------------|----------------------|
| Authentication | < 200ms | < 500ms |
| Data Retrieval | < 300ms | < 1000ms |
| Data Updates | < 500ms | < 2000ms |
| Analytics | < 1000ms | < 5000ms |
| File Uploads | < 2000ms | < 10000ms |

### Scalability Targets
| Metric | Current | Target |
|--------|---------|--------|
| Concurrent Users | 100 | 1000 |
| API Requests/min | 1000 | 10000 |
| Database Connections | 50 | 200 |
| Storage | 10GB | 1TB |

### Caching Strategy
```typescript
// Redis caching configuration
interface CacheConfig {
  sessions: {
    ttl: 86400; // 24 hours
    prefix: 'sess:';
  };
  apiResponses: {
    ttl: 300; // 5 minutes
    prefix: 'api:';
  };
  analytics: {
    ttl: 3600; // 1 hour
    prefix: 'analytics:';
  };
}
```

## Integration Specifications

### SolaX Cloud API Integration
```typescript
interface SolaxApiConfig {
  baseUrl: 'https://www.solaxcloud.com:9443/proxy/api';
  endpoints: {
    realtimeInfo: '/getRealtimeInfo.do';
    historicalData: '/getHistoricalData.do';
    plantList: '/getPlantList.do';
  };
  authentication: {
    method: 'token';
    tokenHeader: 'X-Access-Token';
  };
  rateLimits: {
    requestsPerMinute: 60;
    requestsPerHour: 1000;
  };
}
```

### Weather API Integration
```typescript
interface WeatherApiConfig {
  provider: 'OpenWeatherMap' | 'WeatherAPI';
  endpoints: {
    current: '/weather/current';
    forecast: '/weather/forecast';
    historical: '/weather/historical';
  };
  updateInterval: 300000; // 5 minutes
}
```

## Monitoring & Logging

### Health Check Endpoints
```typescript
interface HealthCheckResponse {
  status: 'healthy' | 'unhealthy';
  timestamp: string;
  services: {
    database: 'up' | 'down';
    redis: 'up' | 'down';
    externalApis: 'up' | 'down';
  };
  metrics: {
    uptime: number;
    memoryUsage: number;
    cpuUsage: number;
  };
}
```

### Logging Configuration
```typescript
interface LoggingConfig {
  level: 'error' | 'warn' | 'info' | 'debug';
  format: 'json' | 'simple';
  transports: {
    console: boolean;
    file: {
      enabled: boolean;
      filename: string;
      maxSize: string;
      maxFiles: number;
    };
    database: {
      enabled: boolean;
      table: string;
    };
  };
}
```

## Deployment Specifications

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
POSTGRES_PASSWORD=secure_password

# Redis
REDIS_URL=redis://user:pass@host:6379
REDIS_PASSWORD=secure_password

# Authentication
JWT_SECRET=secure_jwt_secret
JWT_REFRESH_SECRET=secure_refresh_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# External APIs
SOLAX_API_TOKEN=api_token
WEATHER_API_KEY=api_key

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=user@domain.com
EMAIL_PASS=app_password

# Application
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://nexus.gonxt.tech
```

### Docker Configuration
```yaml
# docker-compose.yml key configurations
services:
  backend:
    build:
      context: ./solarnexus-backend
      dockerfile: Dockerfile.debian
    environment:
      NODE_ENV: production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: solarnexus
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U solarnexus -d solarnexus"]
```

## Testing Specifications

### Unit Testing
```typescript
// Example test structure
describe('SiteService', () => {
  describe('createSite', () => {
    it('should create a site with valid data', async () => {
      const siteData = {
        name: 'Test Site',
        organizationId: 'org-123',
        capacityKw: 100
      };
      
      const result = await siteService.createSite(siteData);
      
      expect(result).toHaveProperty('id');
      expect(result.name).toBe(siteData.name);
    });
  });
});
```

### Integration Testing
```typescript
// API endpoint testing
describe('POST /api/sites', () => {
  it('should create a new site', async () => {
    const response = await request(app)
      .post('/api/sites')
      .set('Authorization', `Bearer ${authToken}`)
      .send(validSiteData)
      .expect(201);
      
    expect(response.body).toHaveProperty('id');
  });
});
```

### Performance Testing
```javascript
// Load testing configuration
export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Ramp up to 100
    { duration: '5m', target: 100 },  // Stay at 100
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
  },
};
```

## Backup & Recovery

### Backup Strategy
```bash
#!/bin/bash
# Automated backup script
BACKUP_DIR="/opt/backups/solarnexus"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker-compose exec -T postgres pg_dump -U solarnexus solarnexus > $BACKUP_DIR/db_$DATE.sql

# Files backup
tar -czf $BACKUP_DIR/files_$DATE.tar.gz uploads/ logs/ ssl/

# Retention policy (keep 30 days)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

### Recovery Procedures
```bash
# Database recovery
docker-compose exec -T postgres psql -U solarnexus -d solarnexus < backup.sql

# Files recovery
tar -xzf files_backup.tar.gz -C /opt/solarnexus/

# Service restart
docker-compose restart
```

---

*This technical specification document is maintained by the development team and updated with each major release.*