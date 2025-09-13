# SolarNexus System Design Document

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Design](#architecture-design)
3. [Database Design](#database-design)
4. [API Design](#api-design)
5. [Security Architecture](#security-architecture)
6. [Data Flow](#data-flow)
7. [Integration Architecture](#integration-architecture)
8. [Performance & Scalability](#performance--scalability)
9. [Monitoring & Observability](#monitoring--observability)
10. [Deployment Architecture](#deployment-architecture)

## 🌟 System Overview

SolarNexus is a comprehensive multi-tenant solar energy management platform designed to serve three primary stakeholder groups: Customers, Funders, and O&M Providers. The system provides real-time analytics, predictive maintenance, financial tracking, and SDG impact measurement.

### Key Features

- **Multi-Tenant Architecture** with organization-based isolation
- **Real-Time Data Processing** from multiple solar monitoring systems
- **Predictive Analytics** using machine learning for maintenance optimization
- **Financial Analytics** with time-of-use tariff calculations
- **SDG Impact Tracking** aligned with UN Sustainable Development Goals
- **Weather Integration** for performance correlation
- **Automated Data Synchronization** from external systems

### Stakeholder Roles

| Role | Primary Use Cases | Key Metrics |
|------|------------------|-------------|
| **Customer** | Energy usage monitoring, savings tracking | kWh generated, cost savings, environmental impact |
| **Funder** | Investment performance, ROI tracking | Generation KPIs, earnings, capacity factors |
| **O&M Provider** | System maintenance, performance optimization | System health, predictive alerts, availability |
| **Super Admin** | Platform management, user administration | System-wide analytics, user management |

## 🏗️ Architecture Design

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SolarNexus Platform                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Client    │    │   Client    │    │   Client    │    │   Client    │  │
│  │ (Customer)  │    │  (Funder)   │    │   (O&M)     │    │(Super Admin)│  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│         │                   │                   │                   │       │
│         └───────────────────┼───────────────────┼───────────────────┘       │
│                             │                   │                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                        Load Balancer / Nginx                           │  │
│  │                     (SSL Termination, Routing)                         │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
│         ┌───────────────────────────┼───────────────────────────┐           │
│         │                           │                           │           │
│  ┌─────────────┐            ┌─────────────┐            ┌─────────────┐      │
│  │   React     │            │   Node.js   │            │  WebSocket  │      │
│  │  Frontend   │◄──────────►│   Backend   │◄──────────►│   Server    │      │
│  │             │            │   (API)     │            │ (Real-time) │      │
│  └─────────────┘            └─────────────┘            └─────────────┘      │
│                                     │                                       │
│                    ┌────────────────┼────────────────┐                      │
│                    │                │                │                      │
│            ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│            │ PostgreSQL  │  │    Redis    │  │   File      │                │
│            │  Database   │  │    Cache    │  │  Storage    │                │
│            └─────────────┘  └─────────────┘  └─────────────┘                │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                           External Integrations                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   SolaX     │    │   SolaX     │    │OpenWeather  │    │   Email     │  │
│  │    API      │    │  Database   │    │     API     │    │  Service    │  │
│  │ (EU Cloud)  │    │  (MySQL)    │    │ (Weather)   │    │ (SMTP)      │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### Frontend Layer
- **Technology**: React 18 with TypeScript
- **UI Framework**: Shadcn-ui with Tailwind CSS
- **State Management**: React Context + Custom hooks
- **Routing**: React Router v6
- **Build Tool**: Vite
- **Authentication**: JWT token-based

#### Backend Layer
- **Technology**: Node.js 20 with Express.js
- **Language**: TypeScript
- **ORM**: Prisma with PostgreSQL
- **Authentication**: JWT with role-based access control
- **Caching**: Redis for session and data caching
- **File Upload**: Multer with local storage
- **Real-time**: Socket.IO for live updates

#### Data Layer
- **Primary Database**: PostgreSQL 15
- **Cache**: Redis 7
- **External Database**: MySQL (SolaX data)
- **File Storage**: Local filesystem (scalable to S3)

## 🗄️ Database Design

### Entity Relationship Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Organization   │    │     Project     │    │      Site       │
│                 │    │                 │    │                 │
│ • id            │◄──►│ • id            │◄──►│ • id            │
│ • name          │    │ • name          │    │ • name          │
│ • slug          │    │ • description   │    │ • address       │
│ • domain        │    │ • organizationId│    │ • latitude      │
│ • settings      │    │ • isActive      │    │ • longitude     │
│ • isActive      │    │                 │    │ • capacity      │
└─────────────────┘    └─────────────────┘    │ • projectId     │
                                              │ • solaxClientId │
                                              │ • municipality  │
                                              └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      User       │    │     Device      │    │   EnergyData    │
│                 │    │                 │    │                 │
│ • id            │    │ • id            │    │ • id            │
│ • email         │    │ • name          │    │ • siteId        │
│ • role          │    │ • type          │    │ • timestamp     │
│ • organizationId│    │ • siteId        │    │ • generation    │
│ • isActive      │    │ • serialNumber  │    │ • consumption   │
│                 │    │ • isActive      │    │ • gridImport    │
└─────────────────┘    └─────────────────┘    │ • gridExport    │
                                              │ • efficiency    │
                                              └─────────────────┘
```

### Key Tables

#### Core Tables
- **organizations** - Multi-tenant organization data
- **users** - User accounts with role-based access
- **projects** - Project groupings for sites
- **sites** - Solar installation sites
- **devices** - Solar equipment (inverters, meters, etc.)

#### Data Tables
- **energy_data** - Time-series energy generation/consumption
- **weather_data** - Weather information for performance correlation
- **site_metrics** - Daily aggregated performance metrics
- **sync_stats** - Data synchronization statistics

#### Analytics Tables
- **sdg_metrics** - UN SDG impact tracking
- **financial_records** - Financial performance data
- **predictions** - ML-based predictions for maintenance
- **alerts** - System alerts and notifications

### Data Retention Policy

| Data Type | Retention Period | Aggregation |
|-----------|------------------|-------------|
| Raw Energy Data | 2 years | Hourly → Daily → Monthly |
| Weather Data | 1 year | Hourly → Daily |
| Site Metrics | 5 years | Daily aggregates |
| Audit Logs | 1 year | No aggregation |
| Predictions | 6 months | No aggregation |

## 🔌 API Design

### RESTful API Structure

```
/api/
├── auth/
│   ├── POST /login
│   ├── POST /register
│   ├── POST /refresh
│   └── POST /logout
├── users/
│   ├── GET /
│   ├── GET /:id
│   ├── PUT /:id
│   └── DELETE /:id
├── organizations/
│   ├── GET /
│   ├── POST /
│   ├── GET /:id
│   └── PUT /:id
├── sites/
│   ├── GET /
│   ├── POST /
│   ├── GET /:id
│   ├── PUT /:id
│   └── DELETE /:id
├── analytics/
│   ├── GET /customer/overview
│   ├── GET /customer/site/:siteId
│   ├── GET /funder/overview
│   ├── GET /funder/site/:siteId
│   ├── GET /om/overview
│   ├── GET /om/predictions/:siteId
│   └── GET /sdg/impact
└── solar/
    ├── GET /energy-data/:siteId
    ├── GET /real-time/:siteId
    └── POST /sync/:siteId
```

### Authentication & Authorization

#### JWT Token Structure
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "role": "customer|funder|om|super_admin",
  "organizationId": "org_id",
  "permissions": ["read:sites", "write:analytics"],
  "iat": 1640995200,
  "exp": 1641081600
}
```

#### Role-Based Permissions

| Role | Permissions | Scope |
|------|-------------|-------|
| **customer** | Read own sites, analytics | Organization sites |
| **funder** | Read funded sites, financial data | Funded sites only |
| **om** | Read/write maintenance, predictions | Managed sites |
| **super_admin** | Full system access | All organizations |

### API Response Format

```json
{
  "success": true,
  "data": {
    // Response data
  },
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0",
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100
    }
  }
}
```

## 🔒 Security Architecture

### Security Layers

1. **Network Security**
   - HTTPS/TLS 1.3 encryption
   - Rate limiting (10 req/s API, 1 req/s auth)
   - DDoS protection via Nginx
   - Firewall rules (ports 80, 443 only)

2. **Application Security**
   - JWT authentication with refresh tokens
   - Role-based access control (RBAC)
   - Input validation and sanitization
   - SQL injection prevention via Prisma ORM
   - XSS protection headers

3. **Data Security**
   - Database encryption at rest
   - Sensitive data hashing (bcrypt)
   - Multi-tenant data isolation
   - Audit logging for all operations

4. **Infrastructure Security**
   - Container isolation via Docker
   - Non-root container execution
   - Secret management via environment variables
   - Regular security updates

### Security Headers

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'" always;
add_header Strict-Transport-Security "max-age=31536000" always;
```

## 🔄 Data Flow

### Real-Time Data Synchronization

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cron Job      │    │  Data Sync      │    │   External      │
│  (Every Hour)   │───►│   Service       │◄──►│   Systems       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │    Database     │
                    └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   Analytics     │
                    │   Processing    │
                    └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   WebSocket     │
                    │   Updates       │
                    └─────────────────┘
```

### Data Processing Pipeline

1. **Data Ingestion**
   - SolaX API polling (hourly)
   - SolaX database synchronization
   - Weather data collection
   - Manual data uploads

2. **Data Processing**
   - Data validation and cleaning
   - Unit conversions and normalization
   - Aggregation calculations
   - Performance metric computation

3. **Data Storage**
   - Time-series data in PostgreSQL
   - Aggregated metrics in dedicated tables
   - Cache frequently accessed data in Redis
   - File storage for uploads

4. **Data Distribution**
   - Real-time updates via WebSocket
   - API responses for dashboard queries
   - Scheduled reports via email
   - Export functionality for analysis

## 🔗 Integration Architecture

### External System Integrations

#### SolaX Cloud API Integration
```typescript
interface SolaxApiConfig {
  baseUrl: 'https://openapi-eu.solaxcloud.com';
  bearerToken: string;
  deviceType: 1;
  businessType: 4;
}
```

#### SolaX Database Integration
```typescript
interface SolaxDatabaseConfig {
  host: '13.245.249.110';
  user: 'dev';
  password: 'Developer1234#';
  database: 'PPA_Reporting';
}
```

#### OpenWeatherMap Integration
```typescript
interface WeatherApiConfig {
  apiKey: string;
  baseUrl: 'https://api.openweathermap.org/data/2.5';
}
```

### Integration Patterns

1. **Polling Pattern** - Hourly data synchronization
2. **Webhook Pattern** - Real-time notifications (future)
3. **Batch Processing** - Historical data imports
4. **Circuit Breaker** - Fault tolerance for external APIs

## 📈 Performance & Scalability

### Performance Optimization

1. **Database Optimization**
   - Proper indexing on frequently queried columns
   - Query optimization with Prisma
   - Connection pooling
   - Read replicas for analytics queries

2. **Caching Strategy**
   - Redis caching for frequently accessed data
   - Application-level caching
   - CDN for static assets
   - Browser caching headers

3. **API Optimization**
   - Pagination for large datasets
   - Field selection to reduce payload
   - Compression (gzip)
   - Response caching

### Scalability Architecture

#### Horizontal Scaling
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Load Balancer  │    │  Load Balancer  │    │  Load Balancer  │
│    (Nginx)      │    │    (Nginx)      │    │    (Nginx)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backend       │    │   Backend       │    │   Backend       │
│  Instance 1     │    │  Instance 2     │    │  Instance 3     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │    Cluster      │
                    └─────────────────┘
```

#### Vertical Scaling
- CPU: 2-8 cores per service
- RAM: 4-16GB per service
- Storage: SSD with 1000+ IOPS
- Network: 1Gbps+ bandwidth

### Performance Metrics

| Metric | Target | Monitoring |
|--------|--------|------------|
| API Response Time | < 200ms | Application logs |
| Database Query Time | < 50ms | PostgreSQL logs |
| Page Load Time | < 2s | Browser metrics |
| Uptime | 99.9% | Health checks |
| Data Sync Latency | < 5min | Sync service logs |

## 📊 Monitoring & Observability

### Monitoring Stack

1. **Application Monitoring**
   - Winston logging with structured logs
   - Health check endpoints
   - Performance metrics collection
   - Error tracking and alerting

2. **Infrastructure Monitoring**
   - Docker container metrics
   - System resource monitoring
   - Network performance tracking
   - Database performance metrics

3. **Business Metrics**
   - User activity tracking
   - Data synchronization success rates
   - API usage patterns
   - System utilization trends

### Logging Strategy

```typescript
// Structured logging format
{
  timestamp: '2024-01-01T00:00:00Z',
  level: 'info|warn|error',
  service: 'backend|frontend|sync',
  userId: 'user_id',
  organizationId: 'org_id',
  action: 'api_call|data_sync|user_action',
  message: 'Human readable message',
  metadata: {
    // Additional context
  }
}
```

### Alerting Rules

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| API Error Rate | > 5% | High | Email + SMS |
| Database Connection | Failed | Critical | Immediate escalation |
| Data Sync Failure | > 2 hours | Medium | Email notification |
| Disk Space | > 85% | Medium | Email notification |
| Memory Usage | > 90% | High | Auto-scaling trigger |

## 🚀 Deployment Architecture

### Container Architecture

```dockerfile
# Multi-stage build for optimization
FROM node:20-slim as base
FROM base as production
# Optimized for production deployment
```

### Docker Compose Services

```yaml
services:
  frontend:
    build: .
    ports: ["3000:3000"]
    depends_on: [backend]
    
  backend:
    build: ./solarnexus-backend
    ports: ["3000:3000"]
    depends_on: [postgres, redis]
    
  postgres:
    image: postgres:15-alpine
    volumes: ["postgres_data:/var/lib/postgresql/data"]
    
  redis:
    image: redis:7-alpine
    volumes: ["redis_data:/data"]
    
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    depends_on: [frontend, backend]
```

### CI/CD Pipeline

1. **Development**
   - Feature branch development
   - Automated testing on PR
   - Code quality checks

2. **Staging**
   - Automated deployment to staging
   - Integration testing
   - Performance testing

3. **Production**
   - Manual approval for production
   - Blue-green deployment
   - Automated rollback on failure

### Infrastructure as Code

```bash
# Deployment automation
./deploy-production.sh

# Health verification
curl https://nexus.gonxt.tech/health

# Monitoring setup
docker compose logs -f
```

---

This system design provides a robust, scalable, and secure foundation for the SolarNexus platform, ensuring reliable operation in production environments while maintaining flexibility for future enhancements and scaling requirements.