# NexusGreen Test Credentials

## Test Companies & Login Credentials

The production deployment includes comprehensive seeded data with multiple test companies and realistic solar installation data.

### Test Login Credentials

**Password for all accounts**: `NexusGreen2024!`

#### NexusGreen Energy Solutions
- **Admin**: `admin@nexusgreen.energy` / `NexusGreen2024!`
  - User: Sarah Chen (Admin)
  - Full system access
- **Manager**: `operations@nexusgreen.energy` / `NexusGreen2024!`
  - User: Michael Rodriguez (Manager)
  - Operations management access
- **Technician**: `tech@nexusgreen.energy` / `NexusGreen2024!`
  - User: Emily Johnson (Technician)
  - Technical operations access

#### Pacific Solar Ventures
- **Admin**: `admin@pacificsolar.com` / `NexusGreen2024!`
  - User: David Kim (Admin)
  - Full system access
- **Manager**: `manager@pacificsolar.com` / `NexusGreen2024!`
  - User: Lisa Thompson (Manager)
  - Operations management access

#### Desert Sun Energy Corp
- **Admin**: `admin@desertsun.energy` / `NexusGreen2024!`
  - User: Robert Martinez (Admin)
  - Full system access

## Test Data Included

### Companies
1. **NexusGreen Energy Solutions** - San Francisco, CA
   - 4 solar installations (2.5MW - 3.2MW capacity)
   - Bay Area locations
   
2. **Pacific Solar Ventures** - Los Angeles, CA
   - 3 solar installations (2.2MW - 4.5MW capacity)
   - Southern California locations
   
3. **Desert Sun Energy Corp** - Phoenix, AZ
   - 3 solar installations (1.6MW - 5.2MW capacity)
   - Arizona desert locations

### Solar Installations
- **10 total installations** across 3 companies
- **Total capacity**: ~26MW combined
- **Realistic locations**: California and Arizona
- **Various system types**: Grid-tied Commercial, Industrial, Utility-scale
- **Different inverter types**: SMA, Fronius, SolarEdge, Enphase, ABB

### Generated Data
- **90 days** of realistic energy generation data
- **Hourly generation patterns** based on solar irradiance
- **Weather-influenced variations** (sunny, cloudy, etc.)
- **Seasonal adjustments** for realistic performance
- **Financial data** including revenue and cost tracking
- **Maintenance schedules** and alert systems
- **Performance analytics** and reporting data

## Quick Test Access

1. **Deploy the application**:
   ```bash
   ./install-production.sh
   ```

2. **Access the application**:
   - HTTP: `http://your-server-ip/`
   - HTTPS: `https://nexus.gonxt.tech/` (after SSL setup)

3. **Login with any test account**:
   - Email: `admin@nexusgreen.energy`
   - Password: `NexusGreen2024!`

4. **Explore features**:
   - Dashboard with real-time data
   - Installation management
   - Energy generation analytics
   - Financial reporting
   - Maintenance scheduling
   - Alert management

## API Testing

Test API endpoints with:
```bash
# Health check
curl https://nexus.gonxt.tech/api-health

# Login (get auth token)
curl -X POST https://nexus.gonxt.tech/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusgreen.energy","password":"NexusGreen2024!"}'

# Get installations (with auth token)
curl https://nexus.gonxt.tech/api/installations \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Database Access

If you need direct database access:
```bash
# Connect to PostgreSQL container
docker-compose exec nexus-db psql -U nexus_user -d nexus_green

# View companies
SELECT name, email, phone FROM companies;

# View users
SELECT email, first_name, last_name, role FROM users;

# View installations
SELECT name, location, capacity_kw, status FROM installations;
```

## Notes

- All passwords use secure bcrypt hashing
- Data includes realistic solar generation patterns
- Financial data reflects current market rates
- Maintenance schedules are set for future dates
- All timestamps use proper UTC handling
- Companies have different geographic locations for testing timezone handling