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
- **[🚀 Production Deployment Guide](PRODUCTION_DEPLOYMENT_GUIDE.md)** - Complete production setup
- **[📖 User Guide](docs/user/USER_GUIDE.md)** - End-user documentation
- **[🔄 Handover Documentation](docs/handover/HANDOVER_DOCUMENTATION.md)** - Operations and maintenance

### Quick Links
- **[All Documentation](docs/README.md)** - Documentation index
- **[System Requirements](REQUIREMENTS.md)** - Production requirements and dependencies
- **[Production Deployment](PRODUCTION_DEPLOYMENT_GUIDE.md)** - One-command production setup

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

**🚀 Complete Production Setup**:

```bash
# Download and run the production deployment script
curl -o production-deploy.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/production-deploy.sh
chmod +x production-deploy.sh
sudo ./production-deploy.sh
```

**✨ Production Features**:
- ✅ **SSL Certificate**: Let's Encrypt with auto-renewal
- ✅ **South African Timezone**: SAST (Africa/Johannesburg)
- ✅ **Demo Data**: GonXT Solar Solutions with test users
- ✅ **Security**: Firewall, security headers, rate limiting
- ✅ **Monitoring**: Health checks, logging, backups
- ✅ **Performance**: Nginx optimization, Redis caching
- ✅ **Automation**: Container orchestration with Docker Compose

**🎯 Demo Credentials**:
- **Admin**: admin@gonxt.tech / Demo2024!
- **User**: user@gonxt.tech / Demo2024!

**📋 Complete Guide**: [Production Deployment Guide](PRODUCTION_DEPLOYMENT_GUIDE.md)

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
├── 🐳 docker-compose.yml        # Container orchestration
├── 🚀 deploy.sh                 # Clean automated deployment script
├── 🔄 auto-upgrade.sh           # Auto-upgrade system with webhook support
├── 🎛️ manage-solarnexus.sh      # Comprehensive management tool
├── 🔗 setup-github-webhook.sh   # GitHub webhook configuration
├── ⚙️ solarnexus.service        # Systemd service for auto-startup
├── 🔄 solarnexus-updater.service # Systemd service for auto-updates
└── 📋 DEPLOYMENT_GUIDE.md       # Comprehensive deployment guide
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

## 🤖 Auto-Management Features

### 🚀 Auto-Startup on Boot
SolarNexus automatically starts when the server boots using systemd services:

```bash
# Check service status
systemctl status solarnexus
systemctl status solarnexus-updater

# Manual service control
sudo systemctl start solarnexus      # Start services
sudo systemctl stop solarnexus       # Stop services
sudo systemctl restart solarnexus    # Restart services
```

### 🔄 Auto-Upgrade System
Automatically monitors GitHub repository and upgrades when new commits are pushed:

**Features:**
- 🔍 **Polling**: Checks for updates every 5 minutes
- 🎣 **Webhooks**: Instant updates via GitHub webhooks
- 🛡️ **Safe Upgrades**: Automatic backups before upgrades
- 📊 **Health Monitoring**: Validates services after upgrades
- 📝 **Comprehensive Logging**: Detailed upgrade logs

**Setup GitHub Webhook:**
```bash
# Setup automatic webhook (requires GitHub token)
sudo ./setup-github-webhook.sh --server-ip YOUR_SERVER_IP --token YOUR_GITHUB_TOKEN

# Manual webhook URL: http://YOUR_SERVER_IP:9876
```

**Manual Operations:**
```bash
# Check for updates
sudo ./auto-upgrade.sh --check

# Force upgrade
sudo ./auto-upgrade.sh --upgrade

# Dry run (see what would be upgraded)
sudo ./auto-upgrade.sh --upgrade --dry-run

# View upgrade logs
sudo journalctl -u solarnexus-updater -f
```

### 🎛️ Management Tool
Comprehensive management with a single command:

```bash
# System overview
sudo ./manage-solarnexus.sh status

# Service management
sudo ./manage-solarnexus.sh start|stop|restart

# View logs
sudo ./manage-solarnexus.sh logs updater
sudo ./manage-solarnexus.sh logs docker

# Health check
sudo ./manage-solarnexus.sh health

# Setup webhook
sudo ./manage-solarnexus.sh webhook YOUR_IP YOUR_TOKEN
```

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

**✅ Production Ready** - Complete production deployment ready

- **Version**: 1.0.0-production
- **Last Updated**: December 2024
- **Deployment**: One-command automated production setup
- **Security**: SSL/TLS, JWT authentication, role-based access, firewall
- **Demo Data**: GonXT Solar Solutions with realistic test data
- **Monitoring**: Health checks, logging, automated backups
- **Documentation**: Complete production deployment guide

---

*For detailed information about any aspect of the system, please refer to the [complete documentation suite](docs/README.md).*