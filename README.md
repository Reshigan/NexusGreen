# SolarNexus - Multi-Tenant Solar Energy Management Platform

<div align="center">
  <img src="public/solarnexus-logo.svg" alt="SolarNexus Logo" width="300"/>
  
  **Empowering Solar Energy Through Intelligent Analytics**
  
  [![Production Ready](https://img.shields.io/badge/Production-Ready-green.svg)](https://github.com/Reshigan/PPA-Frontend)
  [![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://docker.com)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue.svg)](https://typescriptlang.org)
  [![React](https://img.shields.io/badge/React-18.0-blue.svg)](https://reactjs.org)
  [![Node.js](https://img.shields.io/badge/Node.js-20.0-green.svg)](https://nodejs.org)
  [![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.0-blue.svg)](https://postgresql.org)
</div>

## 🌟 Overview

SolarNexus is a sophisticated, production-ready multi-tenant solar energy management platform designed for the modern renewable energy ecosystem. Built with cutting-edge technology, it provides comprehensive analytics, predictive maintenance, and SDG impact tracking for solar installations.

### 🎯 Key Features

- **🏢 Multi-Tenant Architecture** - Organization-based access control with role-based permissions
- **📊 Real-Time Analytics** - Live solar generation, consumption, and performance monitoring
- **🤖 AI-Powered Predictions** - Machine learning for predictive maintenance and issue detection
- **💰 Financial Analytics** - Time-of-use tariff calculations and savings optimization
- **🌍 SDG Impact Tracking** - UN Sustainable Development Goals metrics and ESG reporting
- **⚡ SolaX Integration** - Direct API integration with SolaX solar monitoring systems
- **📧 Smart Notifications** - Automated alerts and email notifications
- **🔒 Enterprise Security** - JWT authentication with comprehensive role-based access

## 🏗️ Architecture

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  Node.js Backend │    │   PostgreSQL    │
│   (Port 3000)   │◄──►│   (Port 5000)   │◄──►│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Nginx      │    │  Prisma ORM     │    │   Redis Cache   │
│   (Port 80/443) │    │   Type Safety   │    │   (Optional)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

**Frontend:**
- React 18 with TypeScript
- Shadcn-ui & Tailwind CSS for modern UI
- React Router for navigation
- Axios for API communication

**Backend:**
- Node.js 20 with Express.js
- TypeScript for type safety
- Prisma ORM for database management
- JWT for authentication
- Nodemailer for email services

**Database:**
- PostgreSQL 15 for primary data storage
- Prisma migrations for schema management
- Multi-tenant data isolation

**Infrastructure:**
- Docker & Docker Compose
- Nginx reverse proxy with SSL
- Production-ready containerization

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+ (for development)
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/Reshigan/PPA-Frontend.git
cd PPA-Frontend
```

### 2. Environment Setup

Copy the production environment file:

```bash
cp .env.production .env
```

Update the environment variables in `.env`:

```env
# Database
DATABASE_URL="postgresql://solarnexus:your_secure_password@postgres:5432/solarnexus"

# JWT
JWT_SECRET="your_jwt_secret_key_here"

# Email Configuration
EMAIL_HOST="smtp.gmail.com"
EMAIL_PORT=587
EMAIL_USER="your-email@gmail.com"
EMAIL_PASS="your-app-password"

# SolaX API
SOLAX_API_TOKEN="your_solax_api_token"

# Server
PORT=5000
NODE_ENV=production
```

### 3. Deploy with Docker

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 4. Initialize Database

```bash
# Run database migrations
docker-compose exec backend npx prisma migrate deploy

# (Optional) Seed initial data
docker-compose exec backend npx prisma db seed
```

### 5. Access the Application

- **Frontend:** http://localhost (or your domain)
- **Backend API:** http://localhost/api
- **Database:** localhost:5432

## 👥 User Roles & Permissions

### 🏢 Customer
- View solar generation and consumption analytics
- Track energy savings across multiple sites
- Monitor performance by project groupings
- Access environmental impact metrics

### 💰 Funder
- Monitor solar generation KPIs
- Track earnings and ROI metrics
- View performance against targets
- Access detailed financial analytics

### 🔧 O&M Provider
- System health monitoring
- Predictive maintenance alerts
- Performance trend analysis
- Automated issue notifications

### 👑 Super Admin
- Full system access and management
- User and organization administration
- System-wide analytics and reporting
- SDG impact across all organizations

## 📊 Analytics Modules

### Customer Analytics
- **Overview Dashboard:** Multi-site summary with key metrics
- **Site Details:** Drill-down analytics for individual sites
- **Savings Analysis:** Time-of-use tariff calculations
- **Project Grouping:** Sites organized by project

### Funder Analytics
- **Generation KPIs:** Performance metrics and targets
- **Earnings Tracking:** Revenue and ROI calculations
- **Performance Monitoring:** Capacity factor and availability
- **Comparative Analysis:** Multi-site performance comparison

### O&M Analytics
- **System Health:** Real-time component status
- **Predictive Maintenance:** AI-powered issue prediction
- **Performance Trends:** Historical analysis and forecasting
- **Alert Management:** Automated notification system

### SDG Impact Tracking
- **Goal 7:** Affordable and Clean Energy metrics
- **Goal 13:** Climate Action and CO2 reduction
- **Goal 11:** Sustainable Cities impact
- **Goal 8:** Economic Growth and job creation

## 🔌 API Integration

### SolaX Solar Systems

The platform integrates directly with SolaX monitoring systems:

```typescript
// Example API call
const energyData = await solarDataService.getEnergyData(
  clientId,
  clientSecret,
  plantId,
  startDate,
  endDate
);
```

### Supported Endpoints
- Real-time generation data
- Historical energy production
- System performance metrics
- Equipment status monitoring

## 🛠️ Development

### Local Development Setup

```bash
# Install dependencies
npm install

# Start development servers
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Database Management

```bash
# Generate Prisma client
npx prisma generate

# Create migration
npx prisma migrate dev --name your_migration_name

# Reset database
npx prisma migrate reset

# View database
npx prisma studio
```

### API Documentation

The backend provides comprehensive API documentation:

- **Authentication:** `/api/auth/*`
- **Analytics:** `/api/analytics/*`
- **Solar Data:** `/api/solar/*`
- **SDG Tracking:** `/api/analytics/sdg/*`
- **Organizations:** `/api/organizations/*`

## 🔒 Security Features

- **JWT Authentication** with secure token management
- **Role-Based Access Control** (RBAC) for all endpoints
- **Multi-Tenant Data Isolation** at the database level
- **Rate Limiting** to prevent API abuse
- **Input Validation** and sanitization
- **HTTPS/SSL** encryption in production

## 📈 Performance & Scalability

- **Docker Containerization** for easy scaling
- **Database Indexing** for optimal query performance
- **Caching Strategies** for frequently accessed data
- **Async Processing** for heavy computational tasks
- **Load Balancing** ready with Nginx

## 🌍 Environmental Impact

SolarNexus helps track and maximize environmental benefits:

- **CO2 Reduction Tracking:** Monitor carbon footprint reduction
- **Renewable Energy Metrics:** Track clean energy generation
- **SDG Alignment:** Measure progress against UN goals
- **ESG Reporting:** Generate sustainability reports

## 📋 Production Deployment

### Server Requirements

- **CPU:** 2+ cores recommended
- **RAM:** 4GB+ recommended
- **Storage:** 20GB+ for database and logs
- **Network:** Stable internet for API integrations

### SSL Configuration

The platform includes automatic SSL setup:

```bash
# Generate SSL certificates (included in docker-compose)
docker-compose exec nginx certbot --nginx -d yourdomain.com
```

### Monitoring & Logging

- Application logs via Docker logging driver
- Database performance monitoring
- API endpoint monitoring
- Error tracking and alerting

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Documentation:** Check this README and inline code comments
- **Issues:** Create a GitHub issue for bugs or feature requests
- **Email:** Contact the development team

## 🎉 Acknowledgments

- **SolaX Power** for API integration support
- **UN SDG Framework** for sustainability metrics
- **Open Source Community** for the amazing tools and libraries

---

<div align="center">
  <strong>Built with ❤️ for a sustainable future</strong>
  
  [Website](https://solarnexus.com) • [Documentation](https://docs.solarnexus.com) • [Support](mailto:support@solarnexus.com)
</div>
