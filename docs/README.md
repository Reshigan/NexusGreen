# SolarNexus Documentation

Welcome to the comprehensive documentation for SolarNexus, a solar energy management platform that provides real-time monitoring, predictive analytics, and financial optimization for solar installations.

## Documentation Structure

### 📋 Project Documentation
- **[Project Overview](PROJECT_OVERVIEW.md)** - Executive summary, features, and business value
- **[Requirements](../REQUIREMENTS.md)** - System requirements and specifications
- **[Deployment Guide](../DEPLOYMENT.md)** - Complete deployment instructions

### 🔧 Technical Documentation
- **[Technical Specifications](technical/TECHNICAL_SPECIFICATIONS.md)** - Detailed technical specifications
- **[System Design](design/SYSTEM_DESIGN.md)** - Architecture and design documentation
- **[API Documentation](api/API_DOCUMENTATION.md)** - Complete API reference

### 🚀 Operations Documentation
- **[Handover Documentation](handover/HANDOVER_DOCUMENTATION.md)** - Operations and maintenance guide
- **[User Guide](user/USER_GUIDE.md)** - End-user documentation

## Quick Start

### For Developers
1. **Setup Development Environment**
   ```bash
   git clone https://github.com/Reshigan/SolarNexus.git
   cd SolarNexus
   npm install
   cd solarnexus-backend && npm install
   ```

2. **Start Development Servers**
   ```bash
   # Frontend (port 5173)
   npm run dev
   
   # Backend (port 3000)
   cd solarnexus-backend && npm run dev
   ```

3. **Read Technical Documentation**
   - [Technical Specifications](technical/TECHNICAL_SPECIFICATIONS.md)
   - [System Design](design/SYSTEM_DESIGN.md)
   - [API Documentation](api/API_DOCUMENTATION.md)

### For System Administrators
1. **Deployment**
   ```bash
   # Clone repository on server
   git clone https://github.com/Reshigan/SolarNexus.git /opt/solarnexus
   cd /opt/solarnexus
   
   # Run deployment script
   ./deploy.sh
   ```

2. **Essential Reading**
   - [Deployment Guide](../DEPLOYMENT.md)
   - [Handover Documentation](handover/HANDOVER_DOCUMENTATION.md)
   - [Requirements](../REQUIREMENTS.md)

### For End Users
1. **Access the Platform**
   - Production: https://nexus.gonxt.tech
   - Login with provided credentials

2. **User Documentation**
   - [User Guide](user/USER_GUIDE.md)
   - Built-in help system within the application

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    SolarNexus Platform                     │
├─────────────────────────────────────────────────────────────┤
│  Frontend (React)  │  Backend (Node.js)  │  Database (PG)  │
├─────────────────────────────────────────────────────────────┤
│              External Integrations                          │
│  • SolaX Cloud API    • Weather APIs    • Email Service    │
└─────────────────────────────────────────────────────────────┘
```

### Key Components
- **Frontend**: React 18 with TypeScript and Vite
- **Backend**: Node.js 20 with Express and TypeScript
- **Database**: PostgreSQL 15 with Prisma ORM
- **Cache**: Redis 7 for sessions and caching
- **Infrastructure**: Docker Compose with Nginx reverse proxy

## Features

### Core Features
- ✅ Real-time solar energy monitoring
- ✅ Multi-tenant organization management
- ✅ Predictive analytics and forecasting
- ✅ Financial tracking and ROI analysis
- ✅ Alert system with notifications
- ✅ Comprehensive reporting
- ✅ SDG tracking and sustainability metrics

### Technical Features
- ✅ RESTful API with comprehensive documentation
- ✅ JWT-based authentication and authorization
- ✅ Role-based access control
- ✅ Real-time data updates via WebSockets
- ✅ Automated deployment with Docker
- ✅ SSL/TLS security with Let's Encrypt
- ✅ Automated backups and monitoring

## Deployment Information

### Production Environment
- **URL**: https://nexus.gonxt.tech
- **Server**: AWS EC2 (13.247.192.38)
- **SSL**: Let's Encrypt automated certificates
- **Monitoring**: Health checks and logging
- **Backups**: Daily automated backups

### Deployment Requirements
- **OS**: Ubuntu 20.04+ (recommended 22.04 LTS)
- **CPU**: Minimum 2 vCPUs, recommended 4 vCPUs
- **RAM**: Minimum 4GB, recommended 8GB
- **Storage**: Minimum 20GB SSD, recommended 50GB
- **Network**: 1Gbps connection

## API Overview

### Base URLs
- **Production**: https://nexus.gonxt.tech/api/v1
- **Development**: http://localhost:3000/api/v1

### Authentication
```bash
# Login to get JWT token
curl -X POST https://nexus.gonxt.tech/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Use token in subsequent requests
curl -H "Authorization: Bearer <token>" \
  https://nexus.gonxt.tech/api/v1/sites
```

### Key Endpoints
- `POST /auth/login` - User authentication
- `GET /sites` - List solar sites
- `GET /sites/:id/energy` - Get energy data
- `GET /analytics/performance` - Performance analytics
- `GET /alerts` - System alerts

## Support and Maintenance

### Documentation Updates
This documentation is maintained alongside the codebase and updated with each release. For the most current information:

1. **Check the repository**: Latest docs are always in the main branch
2. **Version information**: Each document includes last updated date
3. **Change log**: Major changes are documented in commit messages

### Getting Help

#### For Technical Issues
- **Email**: support@solarnexus.com
- **Documentation**: This documentation set
- **API Issues**: See [API Documentation](api/API_DOCUMENTATION.md)

#### For Operational Issues
- **System Status**: https://status.nexus.gonxt.tech
- **Emergency Contact**: [See Handover Documentation](handover/HANDOVER_DOCUMENTATION.md)
- **Maintenance Windows**: First Sunday of each month, 2-6 AM UTC

#### For Development Questions
- **Repository**: https://github.com/Reshigan/SolarNexus
- **Issues**: GitHub Issues for bug reports and feature requests
- **Technical Specs**: [Technical Documentation](technical/TECHNICAL_SPECIFICATIONS.md)

## Contributing

### Documentation Contributions
1. **Fork the repository**
2. **Create a feature branch**
3. **Update relevant documentation**
4. **Test documentation accuracy**
5. **Submit pull request**

### Documentation Standards
- **Markdown Format**: All documentation in Markdown
- **Clear Structure**: Use consistent headings and formatting
- **Code Examples**: Include working code examples
- **Screenshots**: Add screenshots for UI documentation
- **Links**: Use relative links for internal documentation

## Version Information

### Current Version
- **Platform Version**: 1.0.0
- **Documentation Version**: 1.0.0
- **Last Updated**: January 15, 2024
- **Next Review**: April 15, 2024

### Version History
- **v1.0.0** (Jan 2024): Initial production release
- **v0.9.0** (Dec 2023): Beta release with core features
- **v0.8.0** (Nov 2023): Alpha release for testing

## License and Legal

### Software License
This software is proprietary and confidential. All rights reserved.

### Documentation License
This documentation is provided for authorized users only and may not be redistributed without permission.

### Third-Party Licenses
- **React**: MIT License
- **Node.js**: MIT License
- **PostgreSQL**: PostgreSQL License
- **Docker**: Apache License 2.0

---

*For questions about this documentation or suggestions for improvements, please contact the development team or create an issue in the GitHub repository.*