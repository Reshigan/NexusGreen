-- NexusGreen Multi-Portal Database Schema
-- Comprehensive schema for 4-portal solar energy management system

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS maintenance_records CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS performance_metrics CASCADE;
DROP TABLE IF EXISTS energy_consumption CASCADE;
DROP TABLE IF EXISTS energy_production CASCADE;
DROP TABLE IF EXISTS financial_transactions CASCADE;
DROP TABLE IF EXISTS ppa_agreements CASCADE;
DROP TABLE IF EXISTS municipal_rates CASCADE;
DROP TABLE IF EXISTS site_equipment CASCADE;
DROP TABLE IF EXISTS equipment_types CASCADE;
DROP TABLE IF EXISTS sites CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table with enhanced fields
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    company VARCHAR(255),
    title VARCHAR(100),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles with hierarchical permissions
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User roles with granular access control
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    project_id INTEGER DEFAULT NULL, -- NULL means global access
    site_id INTEGER DEFAULT NULL,    -- NULL means project-level access
    granted_by INTEGER REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, role_id, project_id, site_id)
);

-- Projects table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    project_code VARCHAR(50) UNIQUE,
    customer_id INTEGER REFERENCES users(id),
    funder_id INTEGER REFERENCES users(id),
    om_provider_id INTEGER REFERENCES users(id),
    super_admin_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'PLANNING', -- PLANNING, ACTIVE, COMPLETED, CANCELLED
    total_capacity_kw DECIMAL(10,2) DEFAULT 0,
    total_investment DECIMAL(15,2),
    expected_roi DECIMAL(5,2),
    start_date DATE,
    completion_date DATE,
    contract_terms JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sites table with comprehensive configuration
CREATE TABLE sites (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    site_code VARCHAR(50) UNIQUE,
    address TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    municipality VARCHAR(255),
    state_province VARCHAR(100),
    country VARCHAR(100) DEFAULT 'South Africa',
    postal_code VARCHAR(20),
    capacity_kw DECIMAL(10,2) NOT NULL,
    system_type VARCHAR(50) NOT NULL, -- GRID_TIED, HYBRID, OFF_GRID
    battery_capacity_kwh DECIMAL(10,2) DEFAULT 0,
    inverter_capacity_kw DECIMAL(10,2),
    panel_count INTEGER,
    installation_date DATE,
    commissioning_date DATE,
    warranty_end_date DATE,
    status VARCHAR(50) DEFAULT 'PLANNING', -- PLANNING, INSTALLING, ACTIVE, MAINTENANCE, DECOMMISSIONED
    timezone VARCHAR(50) DEFAULT 'Africa/Johannesburg',
    elevation_m INTEGER,
    tilt_angle DECIMAL(5,2),
    azimuth_angle DECIMAL(5,2),
    shading_factor DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Equipment types catalog
CREATE TABLE equipment_types (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL, -- PANEL, INVERTER, BATTERY, MONITORING, MOUNTING
    manufacturer VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    specifications JSONB NOT NULL,
    warranty_years INTEGER,
    datasheet_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category, manufacturer, model)
);

-- Site equipment inventory
CREATE TABLE site_equipment (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    equipment_type_id INTEGER REFERENCES equipment_types(id),
    serial_number VARCHAR(100),
    quantity INTEGER DEFAULT 1,
    installation_date DATE,
    warranty_start_date DATE,
    warranty_end_date DATE,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, MAINTENANCE, FAULTY, REPLACED
    maintenance_schedule VARCHAR(50), -- MONTHLY, QUARTERLY, ANNUALLY
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Municipal electricity rates
CREATE TABLE municipal_rates (
    id SERIAL PRIMARY KEY,
    municipality VARCHAR(255) NOT NULL,
    state_province VARCHAR(100),
    country VARCHAR(100) DEFAULT 'South Africa',
    rate_structure VARCHAR(50) NOT NULL, -- FLAT, TIERED, TIME_OF_USE
    rate_per_kwh DECIMAL(8,4) NOT NULL,
    peak_rate_per_kwh DECIMAL(8,4),
    off_peak_rate_per_kwh DECIMAL(8,4),
    demand_charge_per_kw DECIMAL(8,4),
    fixed_monthly_charge DECIMAL(8,2),
    escalation_rate DECIMAL(5,4), -- Annual escalation percentage
    effective_date DATE NOT NULL,
    end_date DATE,
    currency VARCHAR(3) DEFAULT 'ZAR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PPA (Power Purchase Agreement) configurations
CREATE TABLE ppa_agreements (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    agreement_number VARCHAR(100) UNIQUE,
    rate_per_kwh DECIMAL(8,4) NOT NULL,
    escalation_rate DECIMAL(5,4) DEFAULT 0, -- Annual escalation percentage
    escalation_type VARCHAR(20) DEFAULT 'COMPOUND', -- SIMPLE, COMPOUND
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    minimum_purchase_kwh DECIMAL(12,2),
    maximum_purchase_kwh DECIMAL(12,2),
    currency VARCHAR(3) DEFAULT 'ZAR',
    terms JSONB,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, TERMINATED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Financial transactions and payments
CREATE TABLE financial_transactions (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- REVENUE, EXPENSE, INVESTMENT, PAYMENT
    category VARCHAR(100), -- PPA_PAYMENT, MAINTENANCE, INSURANCE, etc.
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ZAR',
    description TEXT,
    reference_number VARCHAR(100),
    invoice_url TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Energy production data
CREATE TABLE energy_production (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL,
    energy_kwh DECIMAL(10,4) NOT NULL,
    power_kw DECIMAL(10,4),
    irradiance DECIMAL(8,2), -- W/m²
    temperature DECIMAL(5,2), -- °C
    wind_speed DECIMAL(5,2), -- m/s
    humidity DECIMAL(5,2), -- %
    weather_condition VARCHAR(50),
    inverter_efficiency DECIMAL(5,4),
    system_efficiency DECIMAL(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(site_id, timestamp)
);

-- Energy consumption and grid interaction
CREATE TABLE energy_consumption (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL,
    consumption_kwh DECIMAL(10,4) NOT NULL,
    grid_import_kwh DECIMAL(10,4) DEFAULT 0,
    grid_export_kwh DECIMAL(10,4) DEFAULT 0,
    battery_charge_kwh DECIMAL(10,4) DEFAULT 0,
    battery_discharge_kwh DECIMAL(10,4) DEFAULT 0,
    battery_soc DECIMAL(5,2), -- State of charge %
    self_consumption_kwh DECIMAL(10,4) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(site_id, timestamp)
);

-- Performance metrics and KPIs
CREATE TABLE performance_metrics (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    availability DECIMAL(5,4) DEFAULT 1.0, -- System availability %
    performance_ratio DECIMAL(5,4), -- Actual vs expected performance
    specific_yield_kwh_kw DECIMAL(8,4), -- kWh/kW daily yield
    capacity_factor DECIMAL(5,4), -- Actual vs theoretical maximum
    energy_yield_kwh DECIMAL(10,4),
    revenue_generated DECIMAL(12,2),
    savings_generated DECIMAL(12,2),
    co2_avoided_kg DECIMAL(10,2),
    system_efficiency DECIMAL(5,4),
    inverter_efficiency DECIMAL(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(site_id, date)
);

-- Alerts and notifications
CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL, -- PERFORMANCE, MAINTENANCE, FAULT, WEATHER
    severity VARCHAR(20) NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Additional alert data
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id),
    resolution_notes TEXT,
    assigned_to INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Maintenance records
CREATE TABLE maintenance_records (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    om_provider_id INTEGER REFERENCES users(id),
    maintenance_type VARCHAR(50) NOT NULL, -- PREVENTIVE, CORRECTIVE, EMERGENCY
    scheduled_date DATE,
    completed_date DATE,
    duration_hours DECIMAL(5,2),
    description TEXT NOT NULL,
    work_performed TEXT,
    parts_used JSONB,
    cost DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'ZAR',
    status VARCHAR(50) DEFAULT 'SCHEDULED', -- SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    technician_name VARCHAR(255),
    notes TEXT,
    photos JSONB, -- Array of photo URLs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_project_site ON user_roles(project_id, site_id);
CREATE INDEX idx_sites_project_id ON sites(project_id);
CREATE INDEX idx_energy_production_site_timestamp ON energy_production(site_id, timestamp);
CREATE INDEX idx_energy_consumption_site_timestamp ON energy_consumption(site_id, timestamp);
CREATE INDEX idx_performance_metrics_site_date ON performance_metrics(site_id, date);
CREATE INDEX idx_alerts_site_resolved ON alerts(site_id, is_resolved);
CREATE INDEX idx_maintenance_site_date ON maintenance_records(site_id, scheduled_date);

-- Insert default roles
INSERT INTO roles (name, display_name, description, permissions, is_system_role) VALUES
('SUPER_ADMIN', 'Super Administrator', 'Full system access and management', 
 '["system:*", "projects:*", "sites:*", "users:*", "hardware:*", "rates:*", "api:*"]', true),
('CUSTOMER', 'Customer', 'Access to own projects and sites for savings tracking', 
 '["projects:read:own", "sites:read:own", "performance:read:own", "savings:read:own"]', true),
('FUNDER', 'Funder', 'Access to funded projects for ROI tracking', 
 '["projects:read:funded", "sites:read:funded", "financial:read:funded", "roi:read:funded"]', true),
('OM_PROVIDER', 'O&M Provider', 'Access to contracted sites for maintenance and monitoring', 
 '["sites:read:contracted", "performance:read:contracted", "alerts:*:contracted", "maintenance:*:contracted"]', true);

-- Insert sample equipment types
INSERT INTO equipment_types (category, manufacturer, model, specifications, warranty_years) VALUES
('PANEL', 'Canadian Solar', 'CS3W-400P', '{"power_w": 400, "efficiency": 20.3, "voltage_v": 37.8, "current_a": 10.58}', 25),
('PANEL', 'JinkoSolar', 'JKM400M-72H', '{"power_w": 400, "efficiency": 20.4, "voltage_v": 38.1, "current_a": 10.5}', 25),
('INVERTER', 'SMA', 'STP 25000TL-30', '{"power_kw": 25, "efficiency": 98.2, "input_voltage_range": "580-1000V"}', 10),
('INVERTER', 'Fronius', 'Symo 24.0-3', '{"power_kw": 24, "efficiency": 98.1, "input_voltage_range": "580-1000V"}', 10),
('BATTERY', 'Tesla', 'Powerwall 2', '{"capacity_kwh": 13.5, "power_kw": 5, "efficiency": 90, "cycles": 5000}', 10),
('MONITORING', 'SolarEdge', 'SE1000-M2M-S1', '{"type": "Gateway", "connectivity": "Ethernet/WiFi/Cellular"}', 5);

-- Insert sample municipal rates
INSERT INTO municipal_rates (municipality, state_province, rate_per_kwh, escalation_rate, effective_date) VALUES
('City of Cape Town', 'Western Cape', 1.85, 0.08, '2024-01-01'),
('City of Johannesburg', 'Gauteng', 1.92, 0.085, '2024-01-01'),
('eThekwini Municipality', 'KwaZulu-Natal', 1.78, 0.075, '2024-01-01'),
('City of Tshwane', 'Gauteng', 1.88, 0.08, '2024-01-01');

-- Create a function to calculate current PPA rate with escalation
CREATE OR REPLACE FUNCTION calculate_current_ppa_rate(
    base_rate DECIMAL(8,4),
    escalation_rate DECIMAL(5,4),
    start_date DATE,
    escalation_type VARCHAR(20) DEFAULT 'COMPOUND'
) RETURNS DECIMAL(8,4) AS $$
DECLARE
    years_elapsed DECIMAL(10,4);
    current_rate DECIMAL(8,4);
BEGIN
    years_elapsed := EXTRACT(EPOCH FROM (CURRENT_DATE - start_date)) / (365.25 * 24 * 3600);
    
    IF escalation_type = 'COMPOUND' THEN
        current_rate := base_rate * POWER(1 + escalation_rate, years_elapsed);
    ELSE
        current_rate := base_rate * (1 + escalation_rate * years_elapsed);
    END IF;
    
    RETURN current_rate;
END;
$$ LANGUAGE plpgsql;

-- Create a function to calculate savings
CREATE OR REPLACE FUNCTION calculate_site_savings(
    p_site_id INTEGER,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    total_production_kwh DECIMAL(12,4),
    total_consumption_kwh DECIMAL(12,4),
    total_grid_export_kwh DECIMAL(12,4),
    total_self_consumption_kwh DECIMAL(12,4),
    ppa_cost DECIMAL(12,2),
    municipal_cost DECIMAL(12,2),
    total_savings DECIMAL(12,2)
) AS $$
DECLARE
    site_municipality VARCHAR(255);
    current_municipal_rate DECIMAL(8,4);
    current_ppa_rate DECIMAL(8,4);
BEGIN
    -- Get site municipality
    SELECT municipality INTO site_municipality FROM sites WHERE id = p_site_id;
    
    -- Get current municipal rate
    SELECT rate_per_kwh INTO current_municipal_rate 
    FROM municipal_rates 
    WHERE municipality = site_municipality 
    AND effective_date <= CURRENT_DATE 
    ORDER BY effective_date DESC 
    LIMIT 1;
    
    -- Get current PPA rate
    SELECT calculate_current_ppa_rate(pa.rate_per_kwh, pa.escalation_rate, pa.start_date, pa.escalation_type)
    INTO current_ppa_rate
    FROM ppa_agreements pa
    WHERE pa.site_id = p_site_id
    AND pa.status = 'ACTIVE'
    AND CURRENT_DATE BETWEEN pa.start_date AND pa.end_date
    LIMIT 1;
    
    -- Calculate totals and savings
    RETURN QUERY
    SELECT 
        COALESCE(SUM(ep.energy_kwh), 0) as total_production_kwh,
        COALESCE(SUM(ec.consumption_kwh), 0) as total_consumption_kwh,
        COALESCE(SUM(ec.grid_export_kwh), 0) as total_grid_export_kwh,
        COALESCE(SUM(ec.self_consumption_kwh), 0) as total_self_consumption_kwh,
        COALESCE(SUM(ec.self_consumption_kwh), 0) * current_ppa_rate as ppa_cost,
        COALESCE(SUM(ec.self_consumption_kwh), 0) * current_municipal_rate as municipal_cost,
        (COALESCE(SUM(ec.self_consumption_kwh), 0) * current_municipal_rate) - 
        (COALESCE(SUM(ec.self_consumption_kwh), 0) * current_ppa_rate) as total_savings
    FROM energy_production ep
    FULL OUTER JOIN energy_consumption ec ON ep.site_id = ec.site_id AND DATE(ep.timestamp) = DATE(ec.timestamp)
    WHERE COALESCE(ep.site_id, ec.site_id) = p_site_id
    AND DATE(COALESCE(ep.timestamp, ec.timestamp)) BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;