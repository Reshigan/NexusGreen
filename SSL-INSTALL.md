# SolarNexus SSL Installation Guide

🔒 **Secure your SolarNexus deployment with automatic SSL/TLS certificates**

## Quick SSL Installation

For a fast, automated SSL setup with Let's Encrypt:

```bash
curl -o quick-ssl-install.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/quick-ssl-install.sh
chmod +x quick-ssl-install.sh
sudo ./quick-ssl-install.sh your-domain.com your-email@domain.com
```

**Example:**
```bash
sudo ./quick-ssl-install.sh solarnexus.example.com admin@example.com
```

## Full SSL Installation

For advanced configuration and customization:

```bash
curl -o install-ssl.sh https://raw.githubusercontent.com/Reshigan/SolarNexus/main/install-ssl.sh
chmod +x install-ssl.sh
sudo ./install-ssl.sh
```

## What's Included

### 🔐 SSL/TLS Features
- **Let's Encrypt certificates** - Free, trusted SSL certificates
- **Automatic renewal** - Certificates renew automatically twice daily
- **HTTP to HTTPS redirect** - All traffic automatically secured
- **Modern TLS configuration** - TLS 1.2 and 1.3 support
- **OCSP stapling** - Enhanced certificate validation

### 🛡️ Security Hardening
- **Security headers** - HSTS, CSP, X-Frame-Options, etc.
- **Rate limiting** - Protection against abuse and DDoS
- **Firewall configuration** - UFW with secure defaults
- **Fail2ban protection** - Automatic IP blocking for suspicious activity
- **Secure cipher suites** - Modern, secure encryption

### ⚡ Performance Optimization
- **HTTP/2 support** - Faster page loading
- **Gzip compression** - Reduced bandwidth usage
- **Static file caching** - Optimized asset delivery
- **Connection keep-alive** - Reduced connection overhead

## Prerequisites

### System Requirements
- **OS**: Ubuntu 18.04+ or Debian 9+
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 10GB free space
- **Network**: Public IP with ports 80 and 443 accessible

### Domain Setup
1. **Domain ownership** - You must own the domain
2. **DNS configuration** - Point A records to your server IP:
   ```
   your-domain.com     A    YOUR_SERVER_IP
   www.your-domain.com A    YOUR_SERVER_IP
   ```
3. **Propagation** - Wait for DNS changes to propagate (up to 24 hours)

## Installation Options

### Option 1: Quick Install (Recommended)
Perfect for most users who want SSL with minimal configuration:

```bash
# Download and run quick installer
curl -sSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/quick-ssl-install.sh | sudo bash -s your-domain.com your-email@domain.com
```

### Option 2: Interactive Install
For users who want to customize settings:

```bash
# Download full installer
wget https://raw.githubusercontent.com/Reshigan/SolarNexus/main/install-ssl.sh
chmod +x install-ssl.sh
sudo ./install-ssl.sh
```

### Option 3: Manual Docker Compose
For advanced users who want full control:

```bash
# Clone repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start with SSL
docker-compose -f docker-compose.ssl.yml up -d
```

## Configuration

### Environment Variables
The installer creates a `.env` file with these key settings:

```bash
# Domain Configuration
DOMAIN=your-domain.com
SSL_EMAIL=your-email@domain.com

# Security
JWT_SECRET=auto-generated-secure-key
POSTGRES_PASSWORD=auto-generated-password
REDIS_PASSWORD=auto-generated-password

# SSL Settings
SSL_ENABLED=true
CORS_ORIGIN=https://your-domain.com,https://www.your-domain.com
```

### Custom SSL Certificates
If you have your own SSL certificates:

1. Place certificates in `nginx/ssl/`:
   - `fullchain.pem` - Full certificate chain
   - `privkey.pem` - Private key

2. Update nginx configuration to use your certificates

3. Restart services:
   ```bash
   docker-compose -f docker-compose.ssl.yml restart nginx
   ```

## Management

### Service Status
Check if all services are running:
```bash
cd /home/ubuntu/SolarNexus
docker-compose -f docker-compose.ssl.yml ps
```

### View Logs
Monitor application logs:
```bash
# All services
docker-compose -f docker-compose.ssl.yml logs

# Specific service
docker-compose -f docker-compose.ssl.yml logs nginx
docker-compose -f docker-compose.ssl.yml logs backend
```

### SSL Certificate Status
Check certificate expiration:
```bash
openssl x509 -enddate -noout -in /home/ubuntu/SolarNexus/nginx/ssl/fullchain.pem
```

### Manual Certificate Renewal
Force certificate renewal:
```bash
/usr/local/bin/renew-solarnexus-ssl.sh
```

### Restart Services
Restart all services:
```bash
cd /home/ubuntu/SolarNexus
docker-compose -f docker-compose.ssl.yml restart
```

### Update Application
Update to latest version:
```bash
cd /home/ubuntu/SolarNexus
git pull origin main
docker-compose -f docker-compose.ssl.yml up -d --build
```

## Troubleshooting

### Common Issues

#### 1. Certificate Generation Failed
**Problem**: Let's Encrypt certificate generation fails

**Solutions**:
- Verify domain DNS points to your server
- Check firewall allows ports 80 and 443
- Ensure no other web server is running on port 80
- Wait for DNS propagation (up to 24 hours)

```bash
# Test DNS resolution
nslookup your-domain.com
dig your-domain.com

# Check port accessibility
curl -I http://your-domain.com
```

#### 2. Services Won't Start
**Problem**: Docker containers fail to start

**Solutions**:
- Check system resources (RAM, disk space)
- Verify Docker is running
- Check for port conflicts

```bash
# Check system resources
free -h
df -h

# Check Docker status
systemctl status docker

# Check port usage
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

#### 3. SSL Certificate Warnings
**Problem**: Browser shows SSL warnings

**Solutions**:
- Wait a few minutes for certificate propagation
- Clear browser cache
- Check certificate validity

```bash
# Test SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

#### 4. HTTP Not Redirecting to HTTPS
**Problem**: HTTP traffic not redirecting to HTTPS

**Solutions**:
- Check nginx configuration
- Restart nginx service
- Verify SSL certificates are in place

```bash
# Test redirect
curl -I http://your-domain.com

# Check nginx config
docker-compose -f docker-compose.ssl.yml exec nginx nginx -t

# Restart nginx
docker-compose -f docker-compose.ssl.yml restart nginx
```

### Log Locations
- **Application logs**: `/home/ubuntu/SolarNexus/logs/`
- **Nginx logs**: `/home/ubuntu/SolarNexus/logs/nginx/`
- **Installation log**: `/var/log/solarnexus-install.log`
- **Docker logs**: `docker-compose logs`

### Getting Help
If you encounter issues:

1. **Check logs** for error messages
2. **Verify prerequisites** are met
3. **Test connectivity** to your domain
4. **Review configuration** files

## Security Best Practices

### After Installation
1. **Change default passwords** in `.env` file
2. **Configure firewall** rules for your specific needs
3. **Set up monitoring** for certificate expiration
4. **Regular backups** of configuration and data
5. **Keep system updated** with security patches

### Monitoring
Set up monitoring for:
- SSL certificate expiration
- Service health checks
- Resource usage
- Security logs

### Backup Strategy
Regular backups should include:
- Application data (`/home/ubuntu/SolarNexus`)
- SSL certificates (`/home/ubuntu/SolarNexus/ssl`)
- Database dumps
- Configuration files

## Performance Tuning

### For High Traffic
If expecting high traffic, consider:

1. **Increase rate limits** in nginx configuration
2. **Scale backend services** with multiple containers
3. **Add load balancing** for multiple backend instances
4. **Configure CDN** for static assets
5. **Database optimization** with connection pooling

### Resource Optimization
- Monitor resource usage with `docker stats`
- Adjust container resource limits
- Optimize database queries
- Enable caching strategies

## Advanced Configuration

### Custom Nginx Configuration
Modify `nginx/conf.d/ssl.conf` for custom settings:
- Additional security headers
- Custom rate limiting rules
- Specific caching policies
- Additional proxy settings

### Database Tuning
Optimize PostgreSQL for your workload:
- Adjust connection limits
- Configure memory settings
- Set up read replicas for scaling

### Redis Configuration
Optimize Redis for caching:
- Configure memory limits
- Set up persistence options
- Implement cache eviction policies

---

## Quick Reference

### Installation Commands
```bash
# Quick SSL install
curl -sSL https://raw.githubusercontent.com/Reshigan/SolarNexus/main/quick-ssl-install.sh | sudo bash -s your-domain.com your-email@domain.com

# Full interactive install
wget https://raw.githubusercontent.com/Reshigan/SolarNexus/main/install-ssl.sh && chmod +x install-ssl.sh && sudo ./install-ssl.sh
```

### Management Commands
```bash
# Service status
docker-compose -f /home/ubuntu/SolarNexus/docker-compose.ssl.yml ps

# View logs
docker-compose -f /home/ubuntu/SolarNexus/docker-compose.ssl.yml logs

# Restart services
docker-compose -f /home/ubuntu/SolarNexus/docker-compose.ssl.yml restart

# Update application
cd /home/ubuntu/SolarNexus && git pull && docker-compose -f docker-compose.ssl.yml up -d --build
```

### SSL Commands
```bash
# Check certificate expiration
openssl x509 -enddate -noout -in /home/ubuntu/SolarNexus/nginx/ssl/fullchain.pem

# Manual renewal
/usr/local/bin/renew-solarnexus-ssl.sh

# Test SSL
curl -I https://your-domain.com
```

---

**🎉 Your SolarNexus platform is now secured with SSL/TLS!**

For additional support, please check the main [README.md](README.md) or open an issue on GitHub.