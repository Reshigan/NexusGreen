# 🚨 Emergency Fix for ContainerConfig Error

## Immediate Solution

Run these commands on your server (13.244.63.26):

```bash
# 1. Pull latest fixes
cd /opt/solarnexus || cd /root || cd ~
git clone https://github.com/Reshigan/SolarNexus.git temp-fix
cd temp-fix

# 2. Run the simple fix script
sudo ./deploy/simple-fix.sh
```

## Alternative: Manual Commands

If the script doesn't work, run these commands manually:

```bash
# Stop and remove all containers
docker stop $(docker ps -q --filter "name=solarnexus") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=solarnexus") 2>/dev/null || true

# Clean Docker system
docker system prune -f

# Pull fresh images
docker pull postgres:15-alpine
docker pull redis:7-alpine

# Create volumes
docker volume create postgres_data
docker volume create redis_data

# Start PostgreSQL
docker run -d \
  --name solarnexus-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=solarnexus \
  -e POSTGRES_USER=solarnexus \
  -e POSTGRES_PASSWORD=solarnexus \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15-alpine

# Start Redis
docker run -d \
  --name solarnexus-redis \
  --restart unless-stopped \
  -v redis_data:/data \
  -p 6379:6379 \
  redis:7-alpine redis-server --appendonly yes

# Wait for services
sleep 10

# Test services
docker exec solarnexus-postgres pg_isready -U solarnexus
docker exec solarnexus-redis redis-cli ping

# Create database and basic schema
docker exec solarnexus-postgres psql -U solarnexus -c "CREATE DATABASE solarnexus;"

# Create basic tables
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

CREATE TYPE \"UserRole\" AS ENUM ('SUPER_ADMIN', 'CUSTOMER', 'FUNDER', 'OM_PROVIDER');

CREATE TABLE organizations (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    domain TEXT UNIQUE,
    settings JSONB DEFAULT '{}',
    \"isActive\" BOOLEAN DEFAULT true,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    \"firstName\" TEXT NOT NULL,
    \"lastName\" TEXT NOT NULL,
    role \"UserRole\" NOT NULL,
    \"isActive\" BOOLEAN DEFAULT true,
    \"emailVerified\" BOOLEAN DEFAULT false,
    \"organizationId\" TEXT NOT NULL,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sites (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    municipality TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    capacity DOUBLE PRECISION NOT NULL,
    \"installDate\" TIMESTAMP NOT NULL,
    \"isActive\" BOOLEAN DEFAULT true,
    \"organizationId\" TEXT NOT NULL,
    \"createdAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    \"updatedAt\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO organizations (id, name, slug, domain) 
VALUES ('org_default', 'SolarNexus Default', 'solarnexus-default', 'nexus.gonxt.tech');

INSERT INTO users (id, email, password, \"firstName\", \"lastName\", role, \"emailVerified\", \"organizationId\")
VALUES ('user_admin', 'admin@nexus.gonxt.tech', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS', 'System', 'Administrator', 'SUPER_ADMIN', true, 'org_default');
"
```

## Verification

Check that everything is working:

```bash
# Check containers
docker ps

# Test database
docker exec solarnexus-postgres psql -U solarnexus -d solarnexus -c "SELECT COUNT(*) FROM users;"

# Test Redis
docker exec solarnexus-redis redis-cli ping
```

## Start Your Backend

After the database is ready, start your backend:

```bash
# If you have a backend image built
docker run -d \
  --name solarnexus-backend \
  --link solarnexus-postgres:postgres \
  --link solarnexus-redis:redis \
  -e DATABASE_URL=postgresql://solarnexus:solarnexus@postgres:5432/solarnexus \
  -e REDIS_URL=redis://redis:6379 \
  -e NODE_ENV=production \
  -p 3000:3000 \
  solarnexus-backend:latest

# Or use Docker Compose with the compatible file
curl -o docker-compose.yml https://raw.githubusercontent.com/Reshigan/SolarNexus/main/deploy/docker-compose.compatible.yml
docker-compose up -d backend
```

## Expected Results

✅ PostgreSQL running on port 5432  
✅ Redis running on port 6379  
✅ Database 'solarnexus' created with basic schema  
✅ Admin user: admin@nexus.gonxt.tech (password: admin123)  
✅ No more ContainerConfig errors  

## If Still Having Issues

1. **Check Docker version**: `docker --version`
2. **Check Docker Compose version**: `docker-compose --version`
3. **View logs**: `docker logs solarnexus-postgres`
4. **Contact support**: Create issue at https://github.com/Reshigan/SolarNexus/issues

---

**This emergency fix bypasses Docker Compose entirely and uses direct Docker commands to avoid the ContainerConfig error.**