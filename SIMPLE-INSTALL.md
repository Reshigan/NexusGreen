# SolarNexus Simple Installation

Deploy SolarNexus in 3 easy steps!

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone the repository)
- 4GB+ RAM recommended

## Quick Install

### Option 1: One-Command Install (Recommended)

```bash
# Clone and install in one go
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus
./install.sh
```

### Option 2: Manual Steps

```bash
# 1. Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# 2. Copy environment template
cp .env.simple .env

# 3. Start the application
docker-compose -f docker-compose.simple.yml up -d --build
```

## Access Your Application

After installation:

- **Web Application**: http://localhost:80
- **API Endpoints**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

## Configuration

Edit the `.env` file to customize:

```bash
# Database passwords
POSTGRES_PASSWORD=your_secure_password
REDIS_PASSWORD=your_redis_password

# JWT secret (important for security!)
JWT_SECRET=your_super_secure_jwt_secret_key

# API URL (change if deploying to a server)
VITE_API_URL=http://your-server:3000
```

## Management Commands

```bash
# View logs
docker-compose -f docker-compose.simple.yml logs

# Stop application
docker-compose -f docker-compose.simple.yml down

# Restart application
docker-compose -f docker-compose.simple.yml restart

# Update application
git pull
docker-compose -f docker-compose.simple.yml up -d --build

# View running containers
docker-compose -f docker-compose.simple.yml ps
```

## Troubleshooting

### Services won't start?
```bash
# Check Docker is running
docker info

# Check logs for errors
docker-compose -f docker-compose.simple.yml logs
```

### Port conflicts?
Edit `docker-compose.simple.yml` and change the ports:
```yaml
ports:
  - "8080:80"  # Change 80 to 8080
  - "3001:3000"  # Change 3000 to 3001
```

### Need to reset everything?
```bash
# Stop and remove everything
docker-compose -f docker-compose.simple.yml down -v
docker system prune -f

# Start fresh
./install.sh
```

## Production Deployment

For production servers:

1. **Change passwords** in `.env` file
2. **Set proper API URL**: `VITE_API_URL=https://your-domain.com/api`
3. **Use HTTPS**: Set up SSL certificates
4. **Backup data**: Regular backups of PostgreSQL data

## Support

- Check logs: `docker-compose -f docker-compose.simple.yml logs`
- GitHub Issues: https://github.com/Reshigan/SolarNexus/issues
- Documentation: See other `.md` files in this repository

---

**That's it!** SolarNexus should be running at http://localhost:80 🚀