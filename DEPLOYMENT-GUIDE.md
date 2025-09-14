# NexusGreen Docker Deployment Guide

## 🚀 Quick Start (Recommended)

### Option 1: Fresh Installation
```bash
# Clone the repository
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Deploy with Docker
docker compose up -d
```

### Option 2: If you have existing installation
```bash
# Navigate to existing directory
cd NexusGreen

# Clean up any conflicts
./docker-cleanup.sh

# Pull latest changes
git pull origin main

# Deploy
docker compose up -d
```

## 🔧 Troubleshooting Network Issues

If you see network warnings like:
```
WARN[0022] a network with name nexus-green-network exists but was not created by compose.
```

**Solution:**
```bash
# Run the cleanup script
./docker-cleanup.sh

# Then redeploy
docker compose up -d
```

## 📊 Accessing the Application

- **Frontend**: http://localhost
- **API**: http://localhost:3001
- **Database**: localhost:5432 (PostgreSQL)

## 🏥 Health Checks

```bash
# Check all services
docker compose ps

# Check API health
curl http://localhost:3001/api/status

# Check frontend
curl -I http://localhost
```

## 🗄️ Database Information

- **Database**: nexusgreen
- **User**: nexususer
- **Password**: nexuspass123
- **Seed Data**: Realistic South African solar company data

## 🛠️ Development Commands

```bash
# View logs
docker compose logs -f

# Restart specific service
docker compose restart nexus-api

# Rebuild and restart
docker compose up -d --build

# Stop all services
docker compose down

# Complete cleanup
./docker-cleanup.sh
```

## 📁 Project Structure

```
NexusGreen/
├── api/                    # Node.js API backend
├── database/              # PostgreSQL schema and seed data
├── src/                   # React frontend source
├── docker-compose.yml     # Multi-container configuration
├── docker-cleanup.sh      # Network cleanup script
└── docker-install.sh      # Enhanced installation script
```

## 🔒 Security Notes

- Default passwords are for development only
- Change credentials for production deployment
- Database runs on internal Docker network
- Frontend includes security headers

## 🆘 Support

If you encounter issues:

1. Run `./docker-cleanup.sh`
2. Check `docker compose logs`
3. Verify Docker is running: `docker --version`
4. Ensure ports 80, 3001, 5432 are available

## 🎯 Production Deployment

For production deployment:

1. Update database credentials in `docker-compose.yml`
2. Configure proper SSL certificates
3. Set up reverse proxy (nginx/Apache)
4. Enable Docker restart policies
5. Set up monitoring and backups