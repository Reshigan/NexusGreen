# NexusGreen Production Installation

## Clean Installation (Recommended for Production Issues)

If you're experiencing port conflicts, Docker issues, or want a completely fresh start:

```bash
curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/clean-install-production.sh | bash
```

This will:
- **Completely remove** existing Docker, nginx, and containers
- **Free up all ports** (80, 443, 3000, 3001, 5432)
- **Fresh install** Docker and Docker Compose
- **Clean deployment** of NexusGreen with all fixes
- **Configure firewall** and security settings
- **Install certbot** for SSL certificates

## Quick Installation (For Fresh Servers)

Run this single command on your Ubuntu 22.04 server:

```bash
curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/quick-install.sh | bash
```

This will automatically:
- Install Docker and Docker Compose
- Clone the repository with all fixes
- Deploy the application
- Configure firewall settings
- Test the deployment

## Manual Installation

If you prefer to review the script first:

```bash
# Download the installation script
wget https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/install-production.sh

# Review the script
cat install-production.sh

# Make it executable and run
chmod +x install-production.sh
./install-production.sh
```

## After Installation

1. **Configure SSL Certificate**:
   ```bash
   sudo certbot --nginx
   # Select option 1 (reinstall existing certificate)
   ```

2. **Test Your Deployment**:
   ```bash
   # Test HTTP endpoints
   curl http://your-server-ip/health
   curl http://your-server-ip/api-health
   
   # Test HTTPS endpoints (after SSL setup)
   curl https://nexus.gonxt.tech/health
   curl https://nexus.gonxt.tech/api-health
   ```

3. **Monitor Services**:
   ```bash
   # Check container status
   docker-compose ps
   
   # View logs
   docker-compose logs -f nexus-api
   docker-compose logs -f nexus-frontend
   ```

## What's Fixed

✅ **API Runtime Stability**: Increased memory limits and improved database connections  
✅ **Frontend Rendering**: Fixed API service endpoints to use nginx proxy  
✅ **SSL Configuration**: Added support for nexus.gonxt.tech domain  
✅ **Resource Optimization**: Balanced memory allocation for t4g.medium instances  

## System Requirements

- **Instance**: AWS t4g.medium (ARM64) or equivalent
- **OS**: Ubuntu 22.04 LTS
- **Memory**: 4GB RAM minimum
- **Storage**: 20GB minimum
- **Network**: Ports 80 and 443 open

## Troubleshooting

If you encounter issues:

```bash
# Run the test script
./test-deployment.sh

# Check service logs
docker-compose logs nexus-api
docker-compose logs nexus-frontend

# Restart services
docker-compose restart

# Full rebuild
docker-compose down
docker-compose up --build -d
```

## Support

- **Documentation**: See `DEPLOYMENT_FIXES.md` for detailed technical information
- **Issues**: Report problems on the GitHub repository
- **Logs**: Check `/var/log/letsencrypt/letsencrypt.log` for SSL issues