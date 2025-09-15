#!/bin/bash
# Seed database with 2 years of South African solar data

echo "🌱 Seeding NexusGreen Database with South African Solar Data..."

# Create the seeding SQL script
cat > /tmp/seed_nexus_green.sql << 'EOF'
-- NexusGreen Database Seeding Script
-- 2 Years of South African Solar Data for 2 Projects with 5 Sites Each

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clear existing data (in correct order to handle foreign keys)
TRUNCATE TABLE energy_data CASCADE;
TRUNCATE TABLE site_performance CASCADE;
TRUNCATE TABLE maintenance_logs CASCADE;
TRUNCATE TABLE financial_records CASCADE;
TRUNCATE TABLE sites CASCADE;
TRUNCATE TABLE projects CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE companies CASCADE;

-- Insert Companies
INSERT INTO companies (id, name, registration_number, address, contact_email, contact_phone, created_at, updated_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'SolarTech Solutions', '2024/123456/07', '123 Solar Street, Cape Town, 8001', 'admin@solartech.co.za', '+27-21-555-0001', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440002', 'GreenPower Innovations', '2024/789012/07', '456 Energy Avenue, Johannesburg, 2001', 'info@greenpower.co.za', '+27-11-555-0002', NOW(), NOW());

-- Insert Users (Super Admin, Company Admins, and Role-based Users)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, company_id, is_active, created_at, updated_at) VALUES
-- Super Admin
('550e8400-e29b-41d4-a716-446655440010', 'superadmin@nexusgreen.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'System', 'Administrator', 'super_admin', NULL, true, NOW(), NOW()),

-- SolarTech Solutions Users
('550e8400-e29b-41d4-a716-446655440011', 'admin@solartech.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'John', 'Smith', 'company_admin', '550e8400-e29b-41d4-a716-446655440001', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440012', 'customer@solartech.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'Sarah', 'Johnson', 'customer', '550e8400-e29b-41d4-a716-446655440001', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440013', 'operator@solartech.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'Mike', 'Williams', 'operator', '550e8400-e29b-41d4-a716-446655440001', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440014', 'funder@solartech.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'David', 'Brown', 'funder', '550e8400-e29b-41d4-a716-446655440001', true, NOW(), NOW()),

-- GreenPower Innovations Users
('550e8400-e29b-41d4-a716-446655440021', 'admin@greenpower.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'Lisa', 'Davis', 'company_admin', '550e8400-e29b-41d4-a716-446655440002', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440022', 'customer@greenpower.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'Emma', 'Wilson', 'customer', '550e8400-e29b-41d4-a716-446655440002', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440023', 'operator@greenpower.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'James', 'Taylor', 'operator', '550e8400-e29b-41d4-a716-446655440002', true, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440024', 'funder@greenpower.co.za', '$2b$10$rQZ8kqXvJ9X8kqXvJ9X8kOX8kqXvJ9X8kqXvJ9X8kqXvJ9X8kqXvJ9', 'Robert', 'Anderson', 'funder', '550e8400-e29b-41d4-a716-446655440002', true, NOW(), NOW());

-- Insert Projects
INSERT INTO projects (id, name, description, company_id, location, capacity_kw, installation_date, ppa_rate, municipal_rate, project_admin_id, status, created_at, updated_at) VALUES
-- SolarTech Solutions Projects
('550e8400-e29b-41d4-a716-446655440101', 'Cape Town Industrial Complex', 'Large-scale industrial solar installation across 5 manufacturing sites', '550e8400-e29b-41d4-a716-446655440001', 'Cape Town, Western Cape', 1550.0, '2022-03-15', 1.20, 2.85, '550e8400-e29b-41d4-a716-446655440011', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440102', 'Johannesburg Commercial Hub', 'Commercial solar deployment across business district', '550e8400-e29b-41d4-a716-446655440001', 'Johannesburg, Gauteng', 2450.0, '2022-06-20', 1.25, 3.15, '550e8400-e29b-41d4-a716-446655440011', 'active', NOW(), NOW()),

-- GreenPower Innovations Projects  
('550e8400-e29b-41d4-a716-446655440201', 'Durban Coastal Solar Farm', 'Coastal solar installation with marine considerations', '550e8400-e29b-41d4-a716-446655440002', 'Durban, KwaZulu-Natal', 1800.0, '2022-04-10', 1.18, 2.95, '550e8400-e29b-41d4-a716-446655440021', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440202', 'Pretoria Government Complex', 'Government building solar installations', '550e8400-e29b-41d4-a716-446655440002', 'Pretoria, Gauteng', 2200.0, '2022-08-05', 1.15, 3.05, '550e8400-e29b-41d4-a716-446655440021', 'active', NOW(), NOW());

-- Insert Sites (5 sites per project)
INSERT INTO sites (id, name, description, project_id, location, capacity_kw, panel_count, inverter_type, installation_date, status, created_at, updated_at) VALUES
-- Cape Town Industrial Complex Sites
('550e8400-e29b-41d4-a716-446655440301', 'Manufacturing Plant A', 'Main production facility with rooftop solar', '550e8400-e29b-41d4-a716-446655440101', 'Montague Gardens, Cape Town', 500.0, 1250, 'SMA Sunny Tripower', '2022-03-15', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440302', 'Warehouse Complex B', 'Large warehouse with optimal roof space', '550e8400-e29b-41d4-a716-446655440101', 'Paarden Eiland, Cape Town', 300.0, 750, 'Fronius Symo', '2022-03-22', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440303', 'Office Building C', 'Corporate headquarters with integrated solar', '550e8400-e29b-41d4-a716-446655440101', 'Century City, Cape Town', 150.0, 375, 'SolarEdge SE27.6K', '2022-04-01', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440304', 'Distribution Center D', 'Logistics hub with ground-mount solar', '550e8400-e29b-41d4-a716-446655440101', 'Brackenfell, Cape Town', 400.0, 1000, 'Huawei SUN2000', '2022-04-10', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440305', 'Research Facility E', 'R&D center with advanced monitoring', '550e8400-e29b-41d4-a716-446655440101', 'Stellenbosch, Cape Town', 200.0, 500, 'ABB PVS980', '2022-04-20', 'active', NOW(), NOW()),

-- Johannesburg Commercial Hub Sites
('550e8400-e29b-41d4-a716-446655440306', 'Shopping Mall Alpha', 'Large retail complex with parking canopies', '550e8400-e29b-41d4-a716-446655440102', 'Sandton, Johannesburg', 800.0, 2000, 'SMA Sunny Central', '2022-06-20', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440307', 'Office Tower Beta', 'High-rise building with facade integration', '550e8400-e29b-41d4-a716-446655440102', 'Rosebank, Johannesburg', 600.0, 1500, 'Fronius Eco', '2022-07-01', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440308', 'Hotel Complex Gamma', 'Hospitality facility with energy optimization', '550e8400-e29b-41d4-a716-446655440102', 'Midrand, Johannesburg', 350.0, 875, 'SolarEdge SE33.3K', '2022-07-15', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440309', 'Medical Center Delta', 'Healthcare facility with backup systems', '550e8400-e29b-41d4-a716-446655440102', 'Fourways, Johannesburg', 250.0, 625, 'Huawei SUN2000', '2022-08-01', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440310', 'Educational Campus Epsilon', 'University campus with student housing', '550e8400-e29b-41d4-a716-446655440102', 'Wits, Johannesburg', 450.0, 1125, 'ABB TRIO', '2022-08-15', 'active', NOW(), NOW()),

-- Durban Coastal Solar Farm Sites
('550e8400-e29b-41d4-a716-446655440311', 'Coastal Array North', 'Northern section with marine-grade equipment', '550e8400-e29b-41d4-a716-446655440201', 'Umhlanga, Durban', 400.0, 1000, 'SMA Sunny Tripower X', '2022-04-10', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440312', 'Coastal Array South', 'Southern section with wind resistance', '550e8400-e29b-41d4-a716-446655440201', 'Amanzimtoti, Durban', 350.0, 875, 'Fronius Primo', '2022-04-20', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440313', 'Industrial Port Complex', 'Port facility with specialized mounting', '550e8400-e29b-41d4-a716-446655440201', 'Durban Harbour', 450.0, 1125, 'SolarEdge SE25K', '2022-05-01', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440314', 'Logistics Hub East', 'Eastern logistics center', '550e8400-e29b-41d4-a716-446655440201', 'Pinetown, Durban', 300.0, 750, 'Huawei SUN2000', '2022-05-15', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440315', 'Manufacturing Zone West', 'Western manufacturing district', '550e8400-e29b-41d4-a716-446655440201', 'Chatsworth, Durban', 300.0, 750, 'ABB PVS175', '2022-06-01', 'active', NOW(), NOW()),

-- Pretoria Government Complex Sites
('550e8400-e29b-41d4-a716-446655440316', 'Government Building 1', 'Main administrative building', '550e8400-e29b-41d4-a716-446655440202', 'Pretoria CBD', 500.0, 1250, 'SMA Sunny Central', '2022-08-05', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440317', 'Government Building 2', 'Secondary administrative complex', '550e8400-e29b-41d4-a716-446655440202', 'Hatfield, Pretoria', 450.0, 1125, 'Fronius Symo Advanced', '2022-08-20', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440318', 'Public Services Center', 'Citizen services facility', '550e8400-e29b-41d4-a716-446655440202', 'Arcadia, Pretoria', 400.0, 1000, 'SolarEdge SE27.6K', '2022-09-01', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440319', 'Emergency Services Hub', 'Emergency response center', '550e8400-e29b-41d4-a716-446655440202', 'Sunnyside, Pretoria', 350.0, 875, 'Huawei SUN2000', '2022-09-15', 'active', NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440320', 'Training Facility', 'Government training center', '550e8400-e29b-41d4-a716-446655440202', 'Brooklyn, Pretoria', 500.0, 1250, 'ABB TRIO-50.0', '2022-10-01', 'active', NOW(), NOW());

-- Function to generate realistic South African solar data
CREATE OR REPLACE FUNCTION generate_sa_solar_data(
    site_id UUID,
    site_capacity DECIMAL,
    start_date DATE,
    end_date DATE
) RETURNS VOID AS $$
DECLARE
    current_date DATE := start_date;
    daily_production DECIMAL;
    daily_consumption DECIMAL;
    efficiency DECIMAL;
    irradiance DECIMAL;
    temperature DECIMAL;
    month_num INTEGER;
    day_of_year INTEGER;
    seasonal_factor DECIMAL;
    weather_factor DECIMAL;
    base_production DECIMAL;
BEGIN
    WHILE current_date <= end_date LOOP
        -- Calculate seasonal factors for South Africa (Southern Hemisphere)
        month_num := EXTRACT(MONTH FROM current_date);
        day_of_year := EXTRACT(DOY FROM current_date);
        
        -- Seasonal irradiance pattern (higher in summer: Dec-Feb, lower in winter: Jun-Aug)
        seasonal_factor := 0.8 + 0.4 * SIN((day_of_year - 172) * PI() / 182.5);
        
        -- Random weather variations
        weather_factor := 0.7 + (RANDOM() * 0.6); -- 70% to 130% of base
        
        -- Base production calculation (kWh per kW installed)
        base_production := 4.5 * seasonal_factor * weather_factor; -- SA average: 4.5 kWh/kW/day
        
        -- Calculate daily values
        daily_production := site_capacity * base_production;
        daily_consumption := daily_production * (0.85 + RANDOM() * 0.3); -- 85-115% of production
        efficiency := (85 + RANDOM() * 15)::DECIMAL; -- 85-100% efficiency
        irradiance := (3.5 + RANDOM() * 3.5) * seasonal_factor; -- 3.5-7.0 kWh/m²/day
        temperature := CASE 
            WHEN month_num IN (12, 1, 2) THEN 25 + RANDOM() * 15 -- Summer: 25-40°C
            WHEN month_num IN (6, 7, 8) THEN 10 + RANDOM() * 15 -- Winter: 10-25°C
            ELSE 15 + RANDOM() * 20 -- Autumn/Spring: 15-35°C
        END;
        
        -- Insert energy data
        INSERT INTO energy_data (
            id, site_id, timestamp, energy_produced_kwh, energy_consumed_kwh,
            grid_import_kwh, grid_export_kwh, battery_charge_kwh, battery_discharge_kwh,
            efficiency_percentage, irradiance_kwh_m2, temperature_celsius,
            created_at, updated_at
        ) VALUES (
            uuid_generate_v4(),
            site_id,
            current_date + INTERVAL '12 hours', -- Noon timestamp
            daily_production,
            daily_consumption,
            GREATEST(0, daily_consumption - daily_production),
            GREATEST(0, daily_production - daily_consumption),
            daily_production * 0.1, -- 10% to battery
            daily_consumption * 0.1, -- 10% from battery
            efficiency,
            irradiance,
            temperature,
            NOW(),
            NOW()
        );
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Generate 2 years of data for all sites
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440301'::UUID, 500.0, '2022-03-15'::DATE, '2024-03-14'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440302'::UUID, 300.0, '2022-03-22'::DATE, '2024-03-21'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440303'::UUID, 150.0, '2022-04-01'::DATE, '2024-03-31'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440304'::UUID, 400.0, '2022-04-10'::DATE, '2024-04-09'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440305'::UUID, 200.0, '2022-04-20'::DATE, '2024-04-19'::DATE
);

-- Continue for all other sites...
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440306'::UUID, 800.0, '2022-06-20'::DATE, '2024-06-19'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440307'::UUID, 600.0, '2022-07-01'::DATE, '2024-06-30'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440308'::UUID, 350.0, '2022-07-15'::DATE, '2024-07-14'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440309'::UUID, 250.0, '2022-08-01'::DATE, '2024-07-31'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440310'::UUID, 450.0, '2022-08-15'::DATE, '2024-08-14'::DATE
);

-- Durban sites
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440311'::UUID, 400.0, '2022-04-10'::DATE, '2024-04-09'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440312'::UUID, 350.0, '2022-04-20'::DATE, '2024-04-19'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440313'::UUID, 450.0, '2022-05-01'::DATE, '2024-04-30'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440314'::UUID, 300.0, '2022-05-15'::DATE, '2024-05-14'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440315'::UUID, 300.0, '2022-06-01'::DATE, '2024-05-31'::DATE
);

-- Pretoria sites
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440316'::UUID, 500.0, '2022-08-05'::DATE, '2024-08-04'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440317'::UUID, 450.0, '2022-08-20'::DATE, '2024-08-19'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440318'::UUID, 400.0, '2022-09-01'::DATE, '2024-08-31'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440319'::UUID, 350.0, '2022-09-15'::DATE, '2024-09-14'::DATE
);
SELECT generate_sa_solar_data(
    '550e8400-e29b-41d4-a716-446655440320'::UUID, 500.0, '2022-10-01'::DATE, '2024-09-30'::DATE
);

-- Insert sample financial records
INSERT INTO financial_records (id, site_id, record_date, energy_cost_saved, municipal_rate, ppa_rate, revenue_generated, maintenance_cost, roi_percentage, created_at, updated_at)
SELECT 
    uuid_generate_v4(),
    s.id,
    '2024-01-01'::DATE + (RANDOM() * 365)::INTEGER,
    (RANDOM() * 50000 + 10000)::DECIMAL(10,2), -- R10,000 - R60,000 saved
    2.85 + (RANDOM() * 0.5)::DECIMAL(4,2), -- Municipal rate R2.85-R3.35
    1.20 + (RANDOM() * 0.2)::DECIMAL(4,2), -- PPA rate R1.20-R1.40
    (RANDOM() * 80000 + 20000)::DECIMAL(10,2), -- R20,000 - R100,000 revenue
    (RANDOM() * 5000 + 1000)::DECIMAL(10,2), -- R1,000 - R6,000 maintenance
    (15 + RANDOM() * 10)::DECIMAL(5,2), -- 15-25% ROI
    NOW(),
    NOW()
FROM sites s;

-- Create summary statistics view
CREATE OR REPLACE VIEW dashboard_summary AS
SELECT 
    c.name as company_name,
    COUNT(DISTINCT p.id) as total_projects,
    COUNT(DISTINCT s.id) as total_sites,
    SUM(s.capacity_kw) as total_capacity_kw,
    AVG(ed.efficiency_percentage) as avg_efficiency,
    SUM(ed.energy_produced_kwh) as total_energy_produced,
    SUM(fr.energy_cost_saved) as total_cost_saved,
    AVG(fr.roi_percentage) as avg_roi
FROM companies c
LEFT JOIN projects p ON c.id = p.company_id
LEFT JOIN sites s ON p.id = s.project_id
LEFT JOIN energy_data ed ON s.id = ed.site_id
LEFT JOIN financial_records fr ON s.id = fr.site_id
GROUP BY c.id, c.name;

-- Display seeding results
SELECT 'Database seeding completed successfully!' as status;
SELECT 'Companies: ' || COUNT(*) as companies_count FROM companies;
SELECT 'Projects: ' || COUNT(*) as projects_count FROM projects;
SELECT 'Sites: ' || COUNT(*) as sites_count FROM sites;
SELECT 'Users: ' || COUNT(*) as users_count FROM users;
SELECT 'Energy Data Records: ' || COUNT(*) as energy_data_count FROM energy_data;
SELECT 'Financial Records: ' || COUNT(*) as financial_records_count FROM financial_records;

EOF

# Execute the seeding script
echo "Executing database seeding..."
sudo docker exec -i nexus-db psql -U nexus_user -d nexus_green < /tmp/seed_nexus_green.sql

# Verify seeding
echo -e "\n✅ Database Seeding Complete!"
echo "Verifying data..."

echo -e "\nCompanies:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT name, registration_number FROM companies;"

echo -e "\nProjects:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT name, location, capacity_kw FROM projects;"

echo -e "\nSites:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT name, location, capacity_kw FROM sites LIMIT 10;"

echo -e "\nUsers:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT email, role, first_name, last_name FROM users;"

echo -e "\nData Summary:"
sudo docker exec nexus-db psql -U nexus_user -d nexus_green -c "SELECT * FROM dashboard_summary;"

echo -e "\n🎉 South African Solar Data Seeded Successfully!"
echo "- 2 Companies with complete organizational structure"
echo "- 4 Projects across major SA cities (Cape Town, Johannesburg, Durban, Pretoria)"
echo "- 20 Sites with realistic capacity and equipment"
echo "- 2 years of daily energy production data"
echo "- Financial records with SA rates (ZAR)"
echo "- Role-based users for all access levels"

# Clean up
rm -f /tmp/seed_nexus_green.sql