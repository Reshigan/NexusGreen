# 🌞 SolarNexus - Unified Solar Energy Management Platform

<div align="center">
  <img src="public/nexus-green-logo.svg" alt="SolarNexus Logo" width="300"/>
  
  **⚡ Complete Solar Energy Management Solution ⚡**
  
  [![Production Ready](https://img.shields.io/badge/Production-Ready-00FF88.svg)](https://github.com/Reshigan/SolarNexus)
  [![Docker](https://img.shields.io/badge/Docker-Enabled-00D4FF.svg)](https://docker.com)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.0-00FF88.svg)](https://typescriptlang.org)
  [![React](https://img.shields.io/badge/React-18.0-00D4FF.svg)](https://reactjs.org)
  [![Node.js](https://img.shields.io/badge/Node.js-20.0-00FF88.svg)](https://nodejs.org)
  [![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.0-00D4FF.svg)](https://postgresql.org)
</div>

## 🚀 Quick Installation

### Option 1: One-Command Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/quick-install.sh | bash
```

### Option 2: Manual Install

```bash
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus
./install.sh
```

**What this does:**
- ✅ Automatically sets up Docker containers
- ✅ Builds and starts all services (Frontend, Backend, Database, Cache)
- ✅ Creates secure default configuration
- ✅ Provides health checks and monitoring
- ✅ Ready to use in under 2 minutes!

**Access your application:**
- **Web App**: http://localhost:80
- **API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

📖 **Need help?** See [SIMPLE-INSTALL.md](SIMPLE-INSTALL.md) for detailed instructions.

## 🌟 Overview

**SolarNexus** is a comprehensive, production-ready solar energy management platform that combines frontend and backend components in a single, unified repository. Built with modern technologies and designed for scalability, it provides real-time analytics, multi-tenant architecture, and comprehensive solar installation management.

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

### 🏗️ Unified Repository Structure

This repository contains both frontend and backend components:

```
SolarNexus/
├── 📱 Frontend (React + TypeScript + Vite)
│   ├── src/                    # React application source
│   ├── public/                 # Static assets
│   ├── package.json           # Frontend dependencies
│   └── Dockerfile             # Frontend container
│
├── 🔧 Backend (Node.js + Express + Prisma)
│   └── solarnexus-backend/
│       ├── src/               # Backend API source
│       ├── prisma/            # Database schema
│       ├── package.json       # Backend dependencies
│       └── Dockerfile         # Backend container
│
├── 🐳 Infrastructure
│   ├── deploy/                # Deployment scripts
│   ├── docker-compose.yml     # Service orchestration
│   └── nginx/                 # Reverse proxy config
│
└── 📚 Documentation
    ├── README.md              # This file
    ├── PROJECT_STRUCTURE.md   # Detailed structure
    └── DEPLOYMENT_INSTRUCTIONS.md
```

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  Node.js Backend │    │   PostgreSQL    │
│   (Port 80)     │◄──►│   (Port 3000)   │◄──►│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Nginx      │    │  Prisma ORM     │    │   Redis Cache   │
│   (Port 80/443) │    │   Type Safety   │    │   (Port 6379)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

**Frontend:**
- React 18 with TypeScript
- Vite for fast development and building
- Tailwind CSS + shadcn/ui components
- React Router for navigation
- Recharts for data visualization

**Backend:**
- Node.js 20 with Express.js
- TypeScript for type safety
- Prisma ORM for database management
- JWT for authentication
- Redis for caching and sessions

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

### 🚀 Production Deployment (Recommended)

**One-Command Installation:**

```bash
# Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Run the complete installation script
sudo ./deploy/clean-install.sh
```

This script will:
- ✅ Clean up any existing installations
- ✅ Install in current directory (`$(pwd)/SolarNexus`)
- ✅ Set up all services with Docker Compose
- ✅ Initialize database with sample data
- ✅ Configure Nginx reverse proxy
- ✅ Test all services

### 🛠️ Development Setup

**Backend Services Only:**

```bash
# Clone and start backend services
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Start PostgreSQL, Redis, and Backend API
./deploy/quick-backend-start.sh
```

**Full Development Environment:**

```bash
# Start all services
docker-compose up -d

# Or start specific services
docker-compose up -d postgres redis backend

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

**Frontend Development Server:**

```bash
# Install frontend dependencies
npm install

# Start development server (with hot reload)
npm run dev

# Build for production
npm run build
```

### 🌐 Access Points

After successful deployment:

- **Frontend Application:** http://localhost/
- **Backend API:** http://localhost:3000/
- **API Health Check:** http://localhost:3000/health
- **Database:** localhost:5432 (user: solarnexus, db: solarnexus)
- **Redis:** localhost:6379

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

## 🛠️ Development Guide

### Frontend Development

```bash
# Install dependencies
npm install

# Start development server (with hot reload)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

### Backend Development

```bash
cd solarnexus-backend

# Install dependencies
npm install

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev

# Start development server
npm run dev

# View database in browser
npx prisma studio
```

### Database Management

```bash
# Create new migration
npx prisma migrate dev --name your_migration_name

# Deploy migrations to production
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Seed database with sample data
npx prisma db seed
```

### Docker Development

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres redis

# View logs
docker-compose logs -f backend

# Rebuild services
docker-compose up -d --build

# Stop all services
docker-compose down
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

## 📁 Repository Structure

For detailed information about the repository structure, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md).

## 📋 Additional Documentation

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Detailed repository structure and architecture
- **[DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md)** - Comprehensive deployment guide
- **[SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)** - System architecture and design decisions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions

---

<div align="center">
  <strong>🌞 SolarNexus - Unified Solar Energy Management Platform 🌞</strong>
  
  <p><em>Built with ❤️ for a sustainable future</em></p>
  
  **This repository serves as the single source of truth for the entire SolarNexus application.**
</div>
