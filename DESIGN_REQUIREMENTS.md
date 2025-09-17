# NexusGreen - Design & Software Requirements Document

## 📋 Project Overview

**Project Name:** NexusGreen  
**Repository:** https://github.com/Reshigan/NexusGreen  
**Current Version:** v2.0 (Docker Compose Architecture)  
**Last Updated:** 2025-09-17  

### Mission Statement
NexusGreen is a comprehensive renewable energy management platform designed to monitor, analyze, and optimize solar energy systems. The platform provides real-time monitoring, advanced analytics, and predictive insights for renewable energy installations.

## 🏗️ System Architecture

### Current Architecture (v2.0 - Docker Compose)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   (nginx:80)    │◄──►│  (Node.js:3001) │◄──►│ (PostgreSQL:5432)│
│                 │    │                 │    │                 │
│ - React App     │    │ - REST API      │    │ - User Data     │
│ - Static Files  │    │ - Authentication│    │ - Energy Data   │
│ - Routing       │    │ - Business Logic│    │ - Alerts        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

**Frontend:**
- React 18.2.0 with TypeScript
- Vite for build tooling
- Tailwind CSS for styling
- Chart.js for data visualizations
- React Router for navigation
- Axios for API communication

**Backend:**
- Node.js 18+ with Express.js
- bcryptjs for password hashing
- pg (node-postgres) for database connectivity
- CORS middleware for cross-origin requests
- JSON Web Tokens (JWT) for authentication

**Database:**
- PostgreSQL 15
- Persistent volume storage
- Automated schema initialization
- Sample data seeding

**Infrastructure:**
- Docker & Docker Compose
- nginx reverse proxy
- Health checks and monitoring
- Automated deployment scripts

## 📊 Feature Requirements

### Phase 1: Enhanced Dashboard Metrics & KPIs ✅
**Status:** Completed

**Requirements:**
- Real-time energy production monitoring
- Performance analytics and trends
- Revenue tracking and projections
- System efficiency metrics
- Environmental impact calculations

**Implementation:**
- Dashboard with comprehensive KPI cards
- Interactive charts for energy production
- Performance analytics with trend analysis
- Revenue calculations based on energy output
- Carbon footprint reduction metrics

### Phase 2: Advanced Data Visualizations ✅
**Status:** Completed

**Requirements:**
- Interactive charts and graphs
- Historical data analysis
- Comparative performance metrics
- Customizable dashboard views
- Export capabilities for reports

**Implementation:**
- Chart.js integration with multiple chart types
- Historical data visualization components
- Performance comparison charts
- Responsive dashboard layout
- Data export functionality

### Phase 3: Real-time Monitoring & Alerts ✅
**Status:** Completed

**Requirements:**
- Real-time system monitoring
- Automated alert system
- Performance threshold management
- Notification system
- System health monitoring

**Implementation:**
- Real-time data updates
- Alert management system
- Threshold-based notifications
- System status monitoring
- Health check endpoints

## 🔧 Technical Requirements

### Frontend Requirements
- **Framework:** React 18+ with TypeScript
- **Build Tool:** Vite for fast development and optimized builds
- **Styling:** Tailwind CSS for responsive design
- **State Management:** React hooks and context
- **Routing:** React Router v6
- **HTTP Client:** Axios with interceptors
- **Charts:** Chart.js for data visualization
- **Authentication:** JWT token management

### Backend Requirements
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** PostgreSQL with pg driver
- **Authentication:** bcryptjs + JWT
- **Security:** CORS, input validation, SQL injection prevention
- **API Design:** RESTful endpoints with proper HTTP status codes
- **Health Monitoring:** Health check endpoints
- **Error Handling:** Comprehensive error handling and logging

### Database Requirements
- **Engine:** PostgreSQL 15+
- **Schema:** Normalized database design
- **Tables:** users, energy_data, alerts, sites
- **Indexes:** Optimized for query performance
- **Constraints:** Foreign keys and data validation
- **Backup:** Persistent volume storage
- **Initialization:** Automated schema creation and data seeding

### Infrastructure Requirements
- **Containerization:** Docker containers for all services
- **Orchestration:** Docker Compose for local development
- **Reverse Proxy:** nginx for routing and static file serving
- **Networking:** Internal Docker network for service communication
- **Storage:** Persistent volumes for database data
- **Health Checks:** Container health monitoring
- **Deployment:** Automated deployment scripts

## 🚀 Deployment Architecture

### Current Deployment (Docker Compose)
```yaml
services:
  frontend:
    - nginx:alpine container
    - Serves React build files
    - Proxies API requests to backend
    - Port 80 exposed

  backend:
    - Node.js application
    - Express.js REST API
    - Database connectivity
    - Port 3001 internal

  database:
    - PostgreSQL 15
    - Persistent data volume
    - Automated initialization
    - Port 5432 internal
```

### Deployment Scripts
- `setup-server.sh` - Server preparation and Docker installation
- `deploy.sh` - Application deployment with health monitoring
- `docker-compose.yml` - Service orchestration configuration

## 📚 API Documentation

### Authentication Endpoints
```
POST /api/auth/login
- Body: { email, password }
- Response: { token, user }

POST /api/auth/register
- Body: { email, password, name }
- Response: { token, user }
```

### Dashboard Endpoints
```
GET /api/dashboard/metrics
- Response: { totalProduction, efficiency, revenue, carbonOffset }

GET /api/dashboard/energy-production
- Response: [{ date, production, target }]

GET /api/dashboard/performance-analytics
- Response: [{ month, efficiency, performance }]

GET /api/dashboard/revenue-trends
- Response: [{ month, revenue, projection }]
```

### System Endpoints
```
GET /api/health
- Response: { status: "healthy", timestamp }

GET /api/alerts
- Response: [{ id, type, message, timestamp, severity }]
```

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Energy Data Table
```sql
CREATE TABLE energy_data (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id),
    timestamp TIMESTAMP NOT NULL,
    production_kwh DECIMAL(10,2) NOT NULL,
    efficiency_percent DECIMAL(5,2),
    revenue_usd DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Alerts Table
```sql
CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id),
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'medium',
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Sites Table
```sql
CREATE TABLE sites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    capacity_kw DECIMAL(10,2),
    installation_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔐 Security Requirements

### Authentication & Authorization
- JWT-based authentication
- Password hashing with bcryptjs
- Secure token storage and transmission
- Session management and expiration

### Data Security
- SQL injection prevention
- Input validation and sanitization
- CORS configuration for cross-origin requests
- Environment variable management for secrets

### Infrastructure Security
- Container isolation
- Internal network communication
- Secure database connections
- Health check endpoints without sensitive data

## 🧪 Testing Requirements

### Frontend Testing
- Component unit tests
- Integration tests for API communication
- E2E tests for critical user flows
- Responsive design testing

### Backend Testing
- API endpoint testing
- Database integration tests
- Authentication flow testing
- Error handling validation

### Infrastructure Testing
- Container health checks
- Service connectivity tests
- Database initialization validation
- Deployment script testing

## 📈 Performance Requirements

### Frontend Performance
- Initial load time < 3 seconds
- Interactive response time < 100ms
- Optimized bundle size
- Lazy loading for components

### Backend Performance
- API response time < 200ms
- Database query optimization
- Connection pooling
- Caching strategies

### Infrastructure Performance
- Container startup time < 30 seconds
- Health check response < 5 seconds
- Database connection establishment < 10 seconds
- Automated recovery mechanisms

## 🔄 Development Workflow

### Version Control
- Git with feature branch workflow
- Conventional commit messages
- Pull request reviews
- Automated CI/CD pipeline

### Development Environment
- Docker Compose for local development
- Hot reload for frontend development
- Database migrations and seeding
- Environment variable management

### Deployment Process
1. Code development and testing
2. Docker image building
3. Container deployment
4. Health check validation
5. Service availability confirmation

## 📋 Current Status & Next Steps

### Completed Features ✅
- Complete React frontend with TypeScript
- Node.js backend with Express.js
- PostgreSQL database with sample data
- Docker Compose deployment
- Authentication system
- Dashboard with metrics and charts
- Real-time monitoring capabilities
- Automated deployment scripts

### Known Issues & Limitations
- No automated testing suite implemented
- Limited error logging and monitoring
- No backup and recovery procedures
- Single-server deployment only
- No SSL/TLS configuration for production

### Recommended Next Steps
1. Implement comprehensive testing suite
2. Add monitoring and logging infrastructure
3. Create backup and recovery procedures
4. Add SSL/TLS for production deployment
5. Implement CI/CD pipeline
6. Add user management and role-based access
7. Enhance real-time capabilities with WebSockets
8. Add data export and reporting features

## 🤝 Contributing Guidelines

### Code Standards
- TypeScript for type safety
- ESLint and Prettier for code formatting
- Conventional commit messages
- Comprehensive documentation

### Development Setup
```bash
# Clone repository
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Setup development environment
chmod +x setup-server.sh && ./setup-server.sh

# Deploy application
chmod +x deploy.sh && ./deploy.sh
```

### Pull Request Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation
4. Submit pull request with description
5. Code review and approval
6. Merge to main branch

---

**Document Version:** 1.0  
**Last Updated:** 2025-09-17  
**Maintained By:** Development Team  
**Contact:** openhands@all-hands.dev