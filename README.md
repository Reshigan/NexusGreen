# NexusGreen

A comprehensive solar energy management platform built with React, TypeScript, and Node.js, optimized for AWS t4g.medium ARM64 instances.

## Features

- **Dashboard**: Real-time solar energy monitoring and analytics
- **Energy Management**: Track energy production, consumption, and savings
- **Financial Tracking**: Monitor costs, savings, and ROI
- **System Monitoring**: Real-time system health and performance metrics
- **User Management**: Multi-user support with role-based access
- **Responsive Design**: Works seamlessly on desktop and mobile devices

## Tech Stack

- **Frontend**: React 18, TypeScript, Vite, Tailwind CSS
- **UI Components**: Radix UI, Lucide React
- **Charts**: Recharts
- **Backend**: Node.js, Express
- **Database**: PostgreSQL
- **Deployment**: Docker, Docker Compose (ARM64 optimized)

## AWS t4g.medium Deployment

This application is specifically optimized for AWS t4g.medium instances (ARM64 architecture with 4GB RAM).

### Quick Deployment

1. Clone the repository:
```bash
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen
```

2. Deploy with the optimized script:
```bash
./deploy-aws-t4g.sh
```

3. Access the application at `http://your-instance-ip`

### Deployment Script Options

```bash
# Standard deployment
./deploy-aws-t4g.sh

# Clean deployment (removes all containers and images)
./deploy-aws-t4g.sh clean

# View logs
./deploy-aws-t4g.sh logs

# Check status
./deploy-aws-t4g.sh status

# Stop services
./deploy-aws-t4g.sh stop

# Restart services
./deploy-aws-t4g.sh restart
```

## System Requirements

### Minimum Requirements (AWS t4g.medium)
- **CPU**: 2 vCPUs (ARM64)
- **RAM**: 4GB
- **Storage**: 20GB SSD
- **OS**: Ubuntu 22.04 LTS (ARM64)

### Software Requirements
- Docker 20.10+
- Docker Compose 2.0+
- curl (for health checks)

## Architecture

The application uses a multi-container architecture optimized for ARM64:

- **Frontend Container**: Nginx serving React SPA (512MB limit)
- **API Container**: Node.js Express server (256MB limit)
- **Database Container**: PostgreSQL 15 (512MB limit)

Total memory usage: ~1.3GB (leaving 2.7GB for system and build processes)

## Development

### Prerequisites

- Node.js 18+ (ARM64 compatible)
- npm or yarn
- Docker and Docker Compose

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Start the API server:
```bash
cd api
npm install
npm start
```

4. Start the database:
```bash
docker-compose up -d nexus-db
```

## Configuration

### Environment Variables

The application uses the following environment variables:

```env
# Production
NODE_ENV=production
VITE_ENVIRONMENT=production

# Database
DATABASE_URL=postgresql://nexususer:nexuspass123@nexus-db:5432/nexusgreen

# Security
JWT_SECRET=nexus-green-jwt-secret-2024

# Application
VITE_APP_NAME=NexusGreen
VITE_APP_VERSION=6.1.0
VITE_API_URL=/api
VITE_COMPANY_NAME=SolarTech Solutions (Pty) Ltd
VITE_COMPANY_REG=2019/123456/07
VITE_PPA_RATE=1.20

# Sync
SOLAX_SYNC_INTERVAL_MINUTES=60
```

## Troubleshooting

### Common Issues on AWS t4g.medium

1. **Build fails with out of memory**:
   - The deployment script sets `NODE_OPTIONS="--max-old-space-size=3072"`
   - Ensure no other memory-intensive processes are running

2. **Container fails to start**:
   - Check logs: `./deploy-aws-t4g.sh logs`
   - Verify memory limits are not exceeded

3. **Database connection issues**:
   - Ensure PostgreSQL container is healthy
   - Check network connectivity between containers

### Performance Optimization

- Build process uses memory optimization for ARM64
- Vite configuration optimized for production builds
- Docker images use multi-stage builds to reduce size
- Memory limits prevent OOM kills on t4g.medium

## API Documentation

The API provides endpoints for:

- User authentication and management (`/api/auth/*`)
- Energy data collection and analysis (`/api/energy/*`)
- System monitoring and alerts (`/api/system/*`)
- Financial calculations and reporting (`/api/financial/*`)

Health check endpoint: `/api/health`

## Monitoring

### Health Checks

All services include health checks:
- Frontend: `http://localhost/health`
- API: `http://localhost:3001/health`
- Database: PostgreSQL ready check

### Logs

View service logs:
```bash
# All services
./deploy-aws-t4g.sh logs

# Specific service
docker-compose logs -f nexus-green
docker-compose logs -f nexus-api
docker-compose logs -f nexus-db
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on ARM64 if possible
5. Submit a pull request

## License

This project is licensed under the MIT License.