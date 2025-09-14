# SolarNexus

A comprehensive solar energy management platform for monitoring, analytics, and optimization of solar installations.

## 🚀 Quick Production Deployment

**Server**: 13.247.192.38 | **Domain**: nexus.gonxt.tech | **SSL**: reshigan@gonxt.tech

### One-Command Deployment
```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy-production.sh | bash
```

### Manual Deployment
```bash
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus
chmod +x deploy-production.sh
./deploy-production.sh
```

### Test Deployment
```bash
./test-production.sh
```

📖 **Full deployment guide**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

## 🌟 Overview

SolarNexus provides real-time monitoring, predictive analytics, and financial optimization for solar installations across multiple stakeholders including solar installers, O&M providers, asset owners, and end customers.

**🚀 Production Ready**: https://nexus.gonxt.tech

## ✨ Key Features

- **Real-time Monitoring**: Live solar energy production and system health
- **Multi-tenant Architecture**: Organization and site management
- **Predictive Analytics**: AI-powered performance forecasting
- **Financial Tracking**: ROI analysis and cost optimization
- **Alert System**: Proactive notifications and issue detection
- **Comprehensive Reporting**: Performance, financial, and sustainability reports
- **SDG Tracking**: UN Sustainable Development Goals alignment

## 🏗️ Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| **Frontend** | React + TypeScript | 18.2.0 |
| **Build Tool** | Vite | 4.4.5 |
| **Styling** | Tailwind CSS | 3.3.0 |
| **Backend** | Node.js + Express | 20.x |
| **Database** | PostgreSQL | 15 |
| **Cache** | Redis | 7 |
| **ORM** | Prisma | 5.0.0 |
| **Infrastructure** | Docker Compose | - |
| **Web Server** | Nginx | Alpine |
| **SSL** | Let's Encrypt | Auto-renewal |

## 📚 Documentation

### Complete Documentation Suite
- **[📋 Project Overview](docs/PROJECT_OVERVIEW.md)** - Executive summary and business value
- **[🔧 Technical Specifications](docs/technical/TECHNICAL_SPECIFICATIONS.md)** - Detailed technical documentation
- **[🏗️ System Design](docs/design/SYSTEM_DESIGN.md)** - Architecture and design patterns
- **[📡 API Documentation](docs/api/API_DOCUMENTATION.md)** - Complete API reference
- **[🚀 Deployment Guide](DEPLOYMENT.md)** - Production deployment instructions
- **[📖 User Guide](docs/user/USER_GUIDE.md)** - End-user documentation
- **[🔄 Handover Documentation](docs/handover/HANDOVER_DOCUMENTATION.md)** - Operations and maintenance

### Quick Links
- **[All Documentation](docs/README.md)** - Documentation index
- **[Requirements](REQUIREMENTS.md)** - System requirements
- **[Deployment Instructions](DEPLOYMENT.md)** - Step-by-step deployment

## 🚀 Quick Start

### Development Setup

```bash
# 1. Clone repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# 2. Install dependencies
npm install
cd solarnexus-backend && npm install && cd ..

# 3. Configure environment
cp .env.production.template .env
# Edit .env with your configuration

# 4. Start development servers
npm run dev                    # Frontend (port 5173)
cd solarnexus-backend && npm run dev  # Backend (port 3000)
```

### Production Deployment

**One-Command Deployment** on AWS server:

```bash
# Deploy to production server (13.247.192.38)
ssh root@13.247.192.38
git clone https://github.com/Reshigan/SolarNexus.git /opt/solarnexus
cd /opt/solarnexus && ./deploy.sh
```

**Result**: Fully configured production environment at https://nexus.gonxt.tech

## 🏗️ Project Structure

```
SolarNexus/
├── 📁 src/                      # Frontend React application
│   ├── components/              # Reusable UI components
│   ├── pages/                   # Page components and routing
│   ├── hooks/                   # Custom React hooks
│   ├── utils/                   # Frontend utilities
│   └── types/                   # TypeScript definitions
├── 📁 solarnexus-backend/       # Backend Node.js application
│   ├── src/
│   │   ├── controllers/         # API request handlers
│   │   ├── routes/              # API route definitions
│   │   ├── services/            # Business logic layer
│   │   ├── middleware/          # Express middleware
│   │   ├── utils/               # Backend utilities
│   │   └── types/               # TypeScript definitions
│   └── prisma/                  # Database schema and migrations
├── 📁 docs/                     # Comprehensive documentation
│   ├── technical/               # Technical specifications
│   ├── design/                  # System design documents
│   ├── api/                     # API documentation
│   ├── handover/                # Operations documentation
│   └── user/                    # User guides
├── 📁 dist/                     # Frontend production build
├── 🐳 docker-compose.yml        # Container orchestration
├── 🚀 deploy.sh                 # Automated deployment script
├── ✅ validate-build.sh         # Build validation script
└── 📋 DEPLOYMENT.md             # Deployment instructions
```

## 🔌 API Overview

### Base URLs
- **Production**: `https://nexus.gonxt.tech/api/v1`
- **Development**: `http://localhost:3000/api/v1`

### Quick API Example
```bash
# Authenticate
curl -X POST https://nexus.gonxt.tech/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Get sites (using returned JWT token)
curl -H "Authorization: Bearer <token>" \
  https://nexus.gonxt.tech/api/v1/sites

# Get energy data
curl -H "Authorization: Bearer <token>" \
  "https://nexus.gonxt.tech/api/v1/sites/site-id/energy?startDate=2024-01-01&endDate=2024-01-31"
```

**📡 [Complete API Documentation](docs/api/API_DOCUMENTATION.md)**

## 🌍 Production Environment

### Deployment Status
| Component | Status | Details |
|-----------|--------|---------|
| **Application** | ✅ Live | https://nexus.gonxt.tech |
| **SSL Certificate** | ✅ Active | Let's Encrypt auto-renewal |
| **Database** | ✅ Running | PostgreSQL 15 with backups |
| **Monitoring** | ✅ Active | Health checks and logging |
| **Backups** | ✅ Automated | Daily database and file backups |

### Server Information
- **Server**: AWS EC2 Instance
- **IP Address**: 13.247.192.38
- **Domain**: nexus.gonxt.tech
- **OS**: Ubuntu 22.04 LTS
- **Resources**: 4 vCPUs, 8GB RAM, 50GB SSD

## 🔧 Development

### Prerequisites
- Node.js 20+
- npm 10+
- Docker 24+
- Git 2.30+

### Build Process
```bash
# Frontend build
npm run build                    # Creates dist/ directory

# Backend build  
cd solarnexus-backend
npm run build                    # Creates dist/ directory with compiled TypeScript
```

### Validation
```bash
# Validate build artifacts
./validate-build.sh             # Comprehensive build validation
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow TypeScript best practices
- Write comprehensive tests
- Update documentation
- Follow conventional commit messages

## 📞 Support

### Getting Help
- **📧 Email**: support@solarnexus.com
- **📚 Documentation**: [Complete Documentation Suite](docs/README.md)
- **🐛 Issues**: GitHub Issues for bug reports
- **💬 Discussions**: GitHub Discussions for questions

### System Status
- **Status Page**: https://status.nexus.gonxt.tech
- **Uptime Target**: 99.9%
- **Maintenance Window**: First Sunday of each month, 2-6 AM UTC

## 📄 License

This project is proprietary and confidential. All rights reserved.

## 🏆 Project Status

**✅ Production Ready** - Fully deployed and operational

- **Version**: 1.0.0
- **Last Updated**: January 15, 2024
- **Deployment**: Automated with Docker Compose
- **Security**: SSL/TLS, JWT authentication, role-based access
- **Monitoring**: Health checks, logging, automated backups
- **Documentation**: Comprehensive technical and user documentation

---

*For detailed information about any aspect of the system, please refer to the [complete documentation suite](docs/README.md).*