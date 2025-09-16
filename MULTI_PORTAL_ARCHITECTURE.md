# NexusGreen Multi-Portal Architecture

## Overview

NexusGreen will be transformed into a comprehensive 4-portal solar energy management platform serving different stakeholder needs:

1. **Super Admin Portal** - Project deployment and system management
2. **Customer Portal** - Savings tracking and site performance
3. **Funder Portal** - Investment performance and ROI analytics
4. **O&M Provider Portal** - Performance monitoring and maintenance

## Portal Specifications

### 1. Super Admin Portal
**Role**: System administrators and project managers
**Key Features**:
- Project creation and deployment management
- Site configuration (grid-tied vs battery systems)
- Hardware inventory and tracking
- User access management (per project/site)
- Rate configuration (flat vs escalating PPA rates)
- Municipal rate management by location
- API connectivity setup for investor integrations
- System-wide analytics and reporting

**Access Level**: Full system access

### 2. Customer Portal
**Role**: Solar system owners/lessees
**Key Features**:
- Total savings dashboard
- Site-by-site performance drill-downs
- PPA rate vs municipal rate comparisons
- Energy consumption analytics (self-consumption vs grid export)
- Monthly/yearly savings reports
- Performance alerts and notifications
- Bill comparison tools
- Carbon footprint tracking

**Access Level**: Own projects/sites only

### 3. Funder Portal
**Role**: Investment partners and financiers
**Key Features**:
- Investment performance tracking
- ROI calculations and projections
- Rate analysis and yield monitoring
- Portfolio performance across multiple projects
- Risk assessment and performance metrics
- Financial reporting and analytics
- Payment tracking and revenue streams
- Market analysis tools

**Access Level**: Funded projects only

### 4. O&M Provider Portal
**Role**: Operations and maintenance companies
**Key Features**:
- Real-time performance monitoring
- Alert management and response tracking
- Maintenance scheduling and history
- System health analytics
- Performance optimization recommendations
- Fault detection and diagnostics
- Service ticket management
- Equipment lifecycle tracking

**Access Level**: Contracted sites only

## Database Schema Design

### Core Entities

#### Users & Roles
```sql
users (id, email, password_hash, first_name, last_name, phone, created_at, updated_at)
roles (id, name, description, permissions)
user_roles (user_id, role_id, project_id, site_id) -- Granular access control
```

#### Projects & Sites
```sql
projects (id, name, description, customer_id, funder_id, om_provider_id, status, created_at)
sites (id, project_id, name, address, latitude, longitude, municipality, capacity_kw, 
       system_type, battery_capacity_kwh, grid_tied, installation_date, status)
```

#### Hardware & Equipment
```sql
equipment_types (id, category, manufacturer, model, specifications)
site_equipment (id, site_id, equipment_type_id, serial_number, installation_date, 
                warranty_end, status, maintenance_schedule)
```

#### Rates & Financial
```sql
municipal_rates (id, municipality, rate_per_kwh, effective_date, escalation_rate)
ppa_agreements (id, site_id, rate_per_kwh, escalation_rate, start_date, end_date, terms)
financial_transactions (id, site_id, date, type, amount, description)
```

#### Performance & Analytics
```sql
energy_production (id, site_id, timestamp, energy_kwh, power_kw, irradiance, temperature)
energy_consumption (id, site_id, timestamp, consumption_kwh, grid_import_kwh, grid_export_kwh)
performance_metrics (id, site_id, date, availability, performance_ratio, yield_kwh_kw)
```

#### Maintenance & Alerts
```sql
maintenance_records (id, site_id, om_provider_id, date, type, description, cost, status)
alerts (id, site_id, type, severity, message, created_at, resolved_at, assigned_to)
```

## Technical Architecture

### Frontend Structure
```
src/
├── portals/
│   ├── super-admin/
│   │   ├── components/
│   │   ├── pages/
│   │   └── hooks/
│   ├── customer/
│   │   ├── components/
│   │   ├── pages/
│   │   └── hooks/
│   ├── funder/
│   │   ├── components/
│   │   ├── pages/
│   │   └── hooks/
│   └── om-provider/
│       ├── components/
│       ├── pages/
│       └── hooks/
├── shared/
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── contexts/
└── core/
    ├── auth/
    ├── api/
    └── routing/
```

### API Structure
```
api/
├── auth/
│   ├── login
│   ├── logout
│   └── permissions
├── super-admin/
│   ├── projects/
│   ├── sites/
│   ├── users/
│   └── hardware/
├── customer/
│   ├── savings/
│   ├── performance/
│   └── sites/
├── funder/
│   ├── investments/
│   ├── roi/
│   └── portfolio/
└── om-provider/
    ├── monitoring/
    ├── alerts/
    └── maintenance/
```

## Key Features Implementation

### 1. Role-Based Access Control
- JWT tokens with role and permission claims
- Granular permissions per project/site
- Dynamic route protection based on user roles
- API endpoint authorization middleware

### 2. Analytics Engine
- Real-time performance calculations
- Savings analysis (PPA vs municipal rates)
- ROI calculations for funders
- Performance benchmarking
- Predictive maintenance analytics

### 3. Rate Management System
- Location-based municipal rate lookup
- PPA rate configuration (flat/escalating)
- Automatic rate escalation calculations
- Historical rate tracking

### 4. Hardware Management
- Equipment inventory tracking
- Maintenance scheduling
- Warranty management
- Performance correlation with equipment

### 5. API Integration Framework
- RESTful APIs for investor platforms
- Webhook support for real-time updates
- Data export capabilities
- Third-party system integrations

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Database schema implementation
- Authentication system overhaul
- Basic portal routing structure
- Core API endpoints

### Phase 2: Super Admin Portal (Week 3-4)
- Project/site management
- User access control
- Hardware tracking
- Rate configuration

### Phase 3: Customer Portal (Week 5-6)
- Savings dashboard
- Performance analytics
- Site drill-downs
- Reporting tools

### Phase 4: Funder Portal (Week 7-8)
- Investment tracking
- ROI analytics
- Portfolio management
- Financial reporting

### Phase 5: O&M Portal (Week 9-10)
- Performance monitoring
- Alert management
- Maintenance tracking
- Service optimization

### Phase 6: Integration & Testing (Week 11-12)
- API integrations
- Cross-portal testing
- Performance optimization
- Security auditing

## Success Metrics

- **Super Admin**: Efficient project deployment, user management
- **Customer**: Clear savings visibility, performance insights
- **Funder**: Accurate ROI tracking, portfolio performance
- **O&M Provider**: Proactive maintenance, system optimization

This architecture will transform NexusGreen into a comprehensive solar energy management ecosystem serving all stakeholders effectively.