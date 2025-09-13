# 🚀 SolarNexus Quick Install Guide

## One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/CLEAN-INSTALL.sh | bash
```

## What This Does

✅ **Complete System Cleanup** - Removes all previous installations  
✅ **Docker Installation** - Installs Docker and Docker Compose if needed  
✅ **Fresh Repository Clone** - Downloads latest SolarNexus code  
✅ **Secure Configuration** - Generates random passwords and secrets  
✅ **Production Build** - Creates optimized Docker containers  
✅ **Health Monitoring** - Verifies all services are running  
✅ **Database Setup** - Initializes PostgreSQL with migrations  

## Access Your Application

After installation:
- **Frontend**: http://localhost
- **Backend API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

## Management Commands

```bash
# View service status
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Stop services
docker-compose -f docker-compose.production.yml down

# Restart services
docker-compose -f docker-compose.production.yml restart

# Update application
git pull origin main
docker-compose -f docker-compose.production.yml up -d --build
```

## Manual Installation

If you prefer to run the script manually:

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/CLEAN-INSTALL.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installation
./install.sh
```

## System Requirements

- **OS**: Ubuntu 18.04+, Debian 9+, CentOS 7+
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 20GB minimum, 50GB recommended
- **Network**: Internet connection for downloads

## Features Included

🔒 **Security**
- Non-root containers
- Secure random passwords
- Network isolation
- Security headers

📊 **Monitoring**
- Health checks
- Auto-restart on failure
- Comprehensive logging
- Resource limits

⚡ **Performance**
- Optimized Docker builds
- Image compression
- Gzip compression
- Caching strategies

🛠️ **Management**
- Easy start/stop commands
- Automated backups ready
- Update mechanisms
- Troubleshooting tools

## Troubleshooting

If installation fails:

1. **Check Docker**: `docker --version`
2. **Check logs**: `docker-compose -f docker-compose.production.yml logs`
3. **Restart services**: `docker-compose -f docker-compose.production.yml restart`
4. **Clean reinstall**: Run the install script again

## Support

- **Documentation**: Check the `/deploy/` directory for detailed guides
- **Logs**: All logs are saved in `./logs/` directory
- **Configuration**: Environment settings in `.env` file
- **Deployment Info**: Complete details in `deployment-info.txt`

---

**Ready to go solar? ☀️ Run the one-command install and get started!**