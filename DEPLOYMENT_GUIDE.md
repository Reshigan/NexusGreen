# SolarNexus Production Deployment Guide

## 🌟 Overview

This guide provides comprehensive instructions for deploying SolarNexus to production on `nexus.gonxt.tech` with full integration to SolaX database, weather APIs, and automated data synchronization.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Nginx     │    │   React     │    │   Node.js   │         │
│  │ (Port 80/443)│◄──►│ Frontend    │◄──►│   Backend   │         │
│  │   SSL/TLS   │    │ (Port 3000) │    │ (Port 3000) │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                                       │               │
│         ▼                                       ▼               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Domain    │    │ PostgreSQL  │    │    Redis    │         │
│  │nexus.gonxt  │    │ (Port 5432) │    │ (Port 6379) │         │
│  │   .tech     │    │  Database   │    │    Cache    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    External Integrations                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   SolaX     │    │ OpenWeather │    │   SolaX     │         │
│  │   API       │    │     API     │    │  Database   │         │
│  │(EU Cloud)   │    │ (Weather)   │    │(13.244.241.5)│        │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Deployment

### Prerequisites

1. **Server Requirements:**
   - Ubuntu 20.04+ or similar Linux distribution
   - Docker & Docker Compose installed
   - 4GB+ RAM, 2+ CPU cores
   - 20GB+ storage space
   - Domain pointing to server IP: `13.244.63.26`

2. **Access Requirements:**
   - SSH access to production server
   - Domain DNS configured for `nexus.gonxt.tech`
   - SSL certificates (or use self-signed for testing)

### One-Command Deployment

```bash
# Clone the repository
git clone https://github.com/Reshigan/PPA-Frontend.git
cd PPA-Frontend

# Run the deployment script
./deploy-production.sh
```

## 📋 Manual Deployment Steps

### 1. Environment Configuration

Copy and configure the production environment:

```bash
cp .env.production .env
```

Update the following critical settings in `.env`:

```env
# Domain Configuration
DOMAIN=nexus.gonxt.tech
SERVER_IP=13.244.63.26

# SolaX Database (External)
SOLAX_DB_HOST=13.244.241.5
SOLAX_DB_USER=dev
SOLAX_DB_PASSWORD=Developer1234#
SOLAX_DB_NAME=PPA_Reporting

# SolaX API Configuration
SOLAX_BASE_URL=https://openapi-eu.solaxcloud.com
SOLAX_BEARER_TOKEN=M99UdsIbn05jaKrsw5HmWISC6tU
SOLAX_DEVICE_TYPE=1
SOLAX_BUSINESS_TYPE=4
SOLAX_SYNC_INTERVAL_HOURS=1

# OpenWeatherMap API
OPENWEATHERMAP_API_KEY=169b86575f4e66a5dd468d26084e401f

# Email Configuration (Update with your SMTP)
EMAIL_USER=noreply@nexus.gonxt.tech
EMAIL_PASS=your-app-password

# Security (CHANGE THESE!)
JWT_SECRET=SolarNexus2024_Production_JWT_Secret_Key_Secure
POSTGRES_PASSWORD=solarnexus_secure_password_2024_prod
REDIS_PASSWORD=redis_secure_password_2024_prod
```

### 2. SSL Certificate Setup

For production, obtain proper SSL certificates:

```bash
# Option 1: Let's Encrypt (Recommended)
sudo apt install certbot
sudo certbot certonly --standalone -d nexus.gonxt.tech

# Copy certificates to ssl directory
sudo cp /etc/letsencrypt/live/nexus.gonxt.tech/fullchain.pem ssl/nexus.gonxt.tech.crt
sudo cp /etc/letsencrypt/live/nexus.gonxt.tech/privkey.pem ssl/nexus.gonxt.tech.key

# Option 2: Self-signed (Development/Testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/nexus.gonxt.tech.key \
    -out ssl/nexus.gonxt.tech.crt \
    -subj "/C=US/ST=State/L=City/O=SolarNexus/CN=nexus.gonxt.tech"
```

### 3. Database Migration

```bash
# Start database services
docker compose up -d postgres redis

# Wait for database to be ready
sleep 10

# Run migrations
docker compose exec backend npx prisma migrate deploy

# Generate Prisma client
docker compose exec backend npx prisma generate
```

### 4. Start All Services

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

## 🔧 Configuration Details

### Data Synchronization

The system automatically synchronizes data every hour from:

1. **SolaX API** - Real-time solar generation data
2. **SolaX Database** - Historical energy data from external MySQL database
3. **OpenWeatherMap** - Weather data for performance correlation
4. **Performance Calculations** - Automated KPI calculations

### API Endpoints

| Endpoint | Description | Authentication |
|----------|-------------|----------------|
| `/api/auth/*` | Authentication & user management | Public/JWT |
| `/api/analytics/*` | Analytics for all user roles | JWT Required |
| `/api/solar/*` | Solar data integration | JWT Required |
| `/api/sites/*` | Site management | JWT Required |
| `/api/organizations/*` | Organization management | JWT Required |
| `/health` | System health check | Public |

### User Roles & Permissions

1. **Customer** - View analytics, savings, site performance
2. **Funder** - Monitor generation KPIs, earnings, ROI
3. **O&M Provider** - System health, predictive maintenance
4. **Super Admin** - Full system access, user management

## 📊 Monitoring & Maintenance

### Health Checks

```bash
# Application health
curl http://nexus.gonxt.tech/health

# Container status
docker compose ps

# Resource usage
docker stats

# Application logs
docker compose logs backend --tail=100
docker compose logs frontend --tail=100
```

### Database Maintenance

```bash
# Database backup
docker compose exec postgres pg_dump -U solarnexus solarnexus > backup_$(date +%Y%m%d).sql

# Database restore
docker compose exec -T postgres psql -U solarnexus solarnexus < backup_file.sql

# View database
docker compose exec backend npx prisma studio
```

### Log Management

```bash
# View application logs
docker compose logs -f backend

# View sync service logs
docker compose exec backend tail -f /app/logs/app.log

# View nginx logs
docker compose logs nginx
```

## 🔒 Security Configuration

### Firewall Setup

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow SSH (if needed)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable
```

### SSL/TLS Configuration

The Nginx configuration includes:
- TLS 1.2 and 1.3 support
- Strong cipher suites
- HSTS headers
- Security headers (XSS, CSRF protection)

### Rate Limiting

- API endpoints: 10 requests/second
- Authentication: 1 request/second
- Burst allowance with queuing

## 🔄 Updates & Maintenance

### Application Updates

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker compose build --no-cache
docker compose up -d

# Run any new migrations
docker compose exec backend npx prisma migrate deploy
```

### Database Migrations

```bash
# Create new migration
docker compose exec backend npx prisma migrate dev --name migration_name

# Deploy to production
docker compose exec backend npx prisma migrate deploy
```

### Backup Strategy

1. **Database Backups** - Daily automated backups
2. **File Backups** - User uploads and logs
3. **Configuration Backups** - Environment and Docker configs

## 🚨 Troubleshooting

### Common Issues

1. **Frontend not loading**
   ```bash
   docker compose logs frontend
   docker compose restart frontend
   ```

2. **Backend API errors**
   ```bash
   docker compose logs backend
   # Check database connection
   docker compose exec backend npx prisma db push
   ```

3. **Database connection issues**
   ```bash
   docker compose logs postgres
   docker compose restart postgres
   ```

4. **SSL certificate issues**
   ```bash
   # Check certificate validity
   openssl x509 -in ssl/nexus.gonxt.tech.crt -text -noout
   ```

### Performance Optimization

1. **Database Indexing** - Ensure proper indexes on frequently queried fields
2. **Caching** - Redis caching for frequently accessed data
3. **CDN** - Consider CDN for static assets
4. **Monitoring** - Set up application performance monitoring

## 📈 Scaling Considerations

### Horizontal Scaling

1. **Load Balancer** - Add load balancer for multiple backend instances
2. **Database Clustering** - PostgreSQL clustering for high availability
3. **Redis Clustering** - Redis cluster for cache scaling
4. **Container Orchestration** - Consider Kubernetes for large deployments

### Vertical Scaling

1. **Resource Allocation** - Increase CPU/RAM for containers
2. **Database Optimization** - Tune PostgreSQL configuration
3. **Connection Pooling** - Implement connection pooling

## 🎯 Production Checklist

- [ ] Domain DNS configured (`nexus.gonxt.tech` → `13.244.63.26`)
- [ ] SSL certificates installed and valid
- [ ] Environment variables configured
- [ ] Database migrations completed
- [ ] All services running and healthy
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Backup strategy implemented
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] Log rotation configured
- [ ] Email notifications working
- [ ] Data synchronization active (hourly)
- [ ] SolaX database connection tested
- [ ] Weather API integration verified

## 📞 Support

For deployment issues or questions:

1. Check the logs: `docker compose logs -f`
2. Review this documentation
3. Check GitHub issues
4. Contact the development team

---

**SolarNexus** - Empowering Solar Energy Through Intelligent Analytics 🌞