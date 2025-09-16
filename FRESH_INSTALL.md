# NexusGreen Fresh Server Installation

This guide provides scripts to completely reset your server and perform a fresh installation of NexusGreen.

## Quick Start (One-Liner)

```bash
curl -sSL https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/fresh-production-install.sh | bash
```

## Step-by-Step Installation

### Step 1: Reset Server (Optional)

If you want to completely reset your server to a fresh state:

```bash
# Download and run server reset script
wget https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/reset-server.sh
chmod +x reset-server.sh
./reset-server.sh
```

**Warning**: This will remove ALL services, databases, and configurations from your server!

### Step 2: Fresh Installation

```bash
# Download and run fresh installation script
wget https://raw.githubusercontent.com/Reshigan/NexusGreen/fix-production-deployment/fresh-production-install.sh
chmod +x fresh-production-install.sh
./fresh-production-install.sh
```

## What the Installation Script Does

1. ✅ **Updates system packages**
2. ✅ **Installs Docker and Docker Compose**
3. ✅ **Configures firewall (UFW)**
4. ✅ **Installs and configures Nginx**
5. ✅ **Installs Certbot for SSL**
6. ✅ **Clones NexusGreen repository**
7. ✅ **Configures Nginx reverse proxy**
8. ✅ **Builds and starts the application**
9. ✅ **Sets up SSL certificate automatically**
10. ✅ **Provides login credentials and usage instructions**

## Requirements

- **OS**: Ubuntu 20.04 or 22.04
- **Instance**: AWS t4g.medium (4GB RAM, ARM64) or equivalent
- **Ports**: 80 and 443 must be available
- **Domain**: A domain name pointing to your server's IP address

## After Installation

### Access Your Application
- **URL**: `https://your-domain.com`
- **Login**: `admin@nexusgreen.energy`
- **Password**: `NexusGreen2024!`

### Test Data Available
- **3 Companies** with different configurations
- **10 Solar Installations** across South Africa
- **90 Days** of realistic energy generation data
- **Financial Reports** and analytics

### Useful Commands

```bash
# View application logs
cd ~/NexusGreen && docker-compose logs -f

# Check service status
docker-compose ps

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d
```

### SSL Certificate Management

The SSL certificate is automatically obtained and configured. It will auto-renew.

Test renewal:
```bash
sudo certbot renew --dry-run
```

## Troubleshooting

### If installation fails:
1. Check the logs for specific error messages
2. Ensure your domain is pointing to the server
3. Verify ports 80 and 443 are not blocked
4. Run the reset script and try again

### Common Issues:
- **Port conflicts**: Use the reset script first
- **Domain not resolving**: Check DNS settings
- **SSL certificate fails**: Ensure domain points to server
- **Services not starting**: Check Docker logs

### Get Help:
```bash
# Check system resources
free -h
df -h

# Check Docker status
docker --version
docker-compose --version

# Check Nginx status
sudo systemctl status nginx

# View detailed logs
docker-compose logs nexus-api
docker-compose logs nexus-db
```

## Security Features

- ✅ **Firewall configured** (UFW with SSH, HTTP, HTTPS)
- ✅ **SSL/TLS encryption** (Let's Encrypt)
- ✅ **Security headers** configured in Nginx
- ✅ **Gzip compression** enabled
- ✅ **Reverse proxy** setup for security

## Performance Optimizations

- ✅ **Memory limits** configured for t4g.medium
- ✅ **Database connection pooling**
- ✅ **Nginx caching** and compression
- ✅ **Docker multi-stage builds**
- ✅ **ARM64 optimized** images

---

**Need help?** Check the logs or create an issue in the GitHub repository.