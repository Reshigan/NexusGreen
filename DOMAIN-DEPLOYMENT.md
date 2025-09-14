# 🌐 NexusGreen Domain Deployment Guide

## Domain Configuration for nexus.gonxt.tech

### 📋 Current Status
- **Domain**: nexus.gonxt.tech
- **Server IP**: 13.247.192.38
- **SSL Email**: reshigan@gonxt.tech
- **Application**: NexusGreen Solar Management Platform

### 🔧 Required Server Configuration

#### 1. DNS Configuration
Ensure your DNS A record points to your server:
```
nexus.gonxt.tech → 13.247.192.38
```

#### 2. Server Requirements
- Docker and Docker Compose installed
- Ports 80 and 443 open
- Git installed for repository cloning

#### 3. Deployment Steps

**Step 1: Clone the Repository**
```bash
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen
```

**Step 2: Run Production Deployment**
```bash
chmod +x deploy-production.sh
./deploy-production.sh
```

**Step 3: Verify Services**
```bash
# Check all containers are running
docker compose ps

# Test local access
curl http://localhost/health

# Test domain access (if DNS is configured)
curl http://nexus.gonxt.tech/health
```

### 🏥 Service Architecture

```
nexus.gonxt.tech (Port 80)
    ↓
nginx (Container: nexus-green-prod)
    ↓
┌─────────────────┬─────────────────┐
│   Frontend      │   API Proxy     │
│   React App     │   /api/* →      │
│   Static Files  │   nexus-api:3001│
└─────────────────┴─────────────────┘
                      ↓
            Node.js API (nexus-green-api)
                      ↓
            PostgreSQL DB (nexus-green-db)
```

### 🔍 Troubleshooting

#### Issue: Domain not loading
**Possible Causes:**
1. DNS not propagated yet (can take up to 48 hours)
2. Firewall blocking ports 80/443
3. Another service using port 80
4. Docker containers not running

**Solutions:**
```bash
# Check DNS propagation
nslookup nexus.gonxt.tech

# Check if port 80 is available
sudo netstat -tlnp | grep :80

# Check Docker containers
docker compose ps

# Check nginx logs
docker compose logs nexus-green
```

#### Issue: Old version showing
**Possible Causes:**
1. Browser cache
2. CDN cache (if using one)
3. Old Docker images

**Solutions:**
```bash
# Force rebuild containers
docker compose down
docker compose up -d --build --force-recreate

# Clear browser cache or try incognito mode
```

#### Issue: API not working
**Possible Causes:**
1. API container not healthy
2. Database connection issues
3. Network configuration problems

**Solutions:**
```bash
# Check API health
curl http://nexus.gonxt.tech/api/status

# Check API logs
docker compose logs nexus-api

# Check database logs
docker compose logs nexus-db
```

### 🚀 Production Checklist

- [ ] DNS A record configured (nexus.gonxt.tech → 13.247.192.38)
- [ ] Server has Docker and Docker Compose installed
- [ ] Ports 80 and 443 are open in firewall
- [ ] Repository cloned to server
- [ ] Production deployment script executed
- [ ] All containers showing as healthy
- [ ] Domain accessible via HTTP
- [ ] API endpoints responding correctly
- [ ] SSL certificate configured (optional but recommended)

### 🔒 SSL Configuration (Recommended)

For HTTPS support, consider using Let's Encrypt:

```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d nexus.gonxt.tech --email reshigan@gonxt.tech

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 📊 Monitoring Commands

```bash
# View all service logs
docker compose logs -f

# Check service health
docker compose ps

# Monitor resource usage
docker stats

# Restart specific service
docker compose restart nexus-green

# Complete restart
docker compose down && docker compose up -d
```

### 🌐 Access Points

Once deployed and DNS is configured:

- **Main Application**: http://nexus.gonxt.tech
- **API Health Check**: http://nexus.gonxt.tech/api/status
- **API Documentation**: http://nexus.gonxt.tech/api/docs (if available)

### 📞 Support

If you encounter issues:

1. Check the logs: `docker compose logs -f`
2. Verify DNS propagation
3. Ensure firewall allows HTTP/HTTPS traffic
4. Check server resources (disk space, memory)
5. Review this troubleshooting guide

### 🔄 Updates

To update the application:

```bash
cd NexusGreen
git pull origin main
docker compose down
docker compose up -d --build
```

---

**Note**: This configuration assumes you're deploying on a server with IP 13.247.192.38. Adjust the IP address and domain settings according to your actual server configuration.