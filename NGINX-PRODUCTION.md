# 🌐 Nginx Production Configuration

## 🚨 **Port Conflict Resolution**

The Docker nginx container has been disabled to avoid port conflicts with the system nginx service. This is the recommended production approach.

## ✅ **Current Configuration**

- **System Nginx:** Running on ports 80/443 with SSL
- **Docker Services:** Running on internal ports only
- **SSL Certificate:** Managed by Let's Encrypt via system nginx
- **Reverse Proxy:** System nginx proxies to Docker containers

## 🔧 **Service Ports**

| Service | Docker Port | System Access |
|---------|-------------|---------------|
| Frontend | 3000:8080 | via nginx proxy |
| Backend | 5000:5000 | via nginx proxy |
| PostgreSQL | 5432:5432 | internal only |
| Redis | 6379:6379 | internal only |

## 🌐 **Access URLs**

- **Application:** https://nexus.gonxt.tech
- **API:** https://nexus.gonxt.tech/api/
- **Health Check:** https://nexus.gonxt.tech/health

## 🛠️ **Management Commands**

```bash
# Check system nginx status
sudo systemctl status nginx

# Restart system nginx
sudo systemctl restart nginx

# Check nginx configuration
sudo nginx -t

# View nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Restart Docker services only
cd /opt/solarnexus
sudo docker compose restart

# Check Docker service status
sudo docker compose ps
```

## 🔄 **If You Need Docker Nginx**

If you prefer to use the Docker nginx container instead:

1. Stop system nginx:
```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
```

2. Enable Docker nginx in docker-compose.yml:
```bash
# Uncomment the nginx service section
sudo nano docker-compose.yml
```

3. Restart services:
```bash
sudo docker compose up -d
```

## 📋 **Production Benefits**

- ✅ No port conflicts
- ✅ System nginx handles SSL certificates
- ✅ Better security isolation
- ✅ Easier SSL certificate management
- ✅ Standard production deployment pattern