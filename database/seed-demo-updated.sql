-- NexusGreen Demo Database Seed
-- Updated test data with demo credentials for production deployment
-- Version: 3.0 - Demo Ready

-- Clear existing data (for fresh deployment)
TRUNCATE TABLE maintenance, alerts, financial_data, energy_generation, installations, users, companies RESTART IDENTITY CASCADE;

-- Insert demo companies
INSERT INTO companies (id, name, registration_number, address, phone, email, website, logo_url) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'NexusGreen Energy Solutions', 'NGES-2024-001', '1250 Renewable Energy Blvd, Suite 300, San Francisco, CA 94105', '+1-415-555-0100', 'contact@nexusgreen.energy', 'https://nexusgreen.energy', '/nexus-green-logo.svg'),
('550e8400-e29b-41d4-a716-446655440001', 'Pacific Solar Ventures', 'PSV-2024-002', '890 Innovation Drive, Los Angeles, CA 90028', '+1-213-555-0200', 'info@pacificsolar.com', 'https://pacificsolar.com', '/nexus-green-logo.svg'),
('550e8400-e29b-41d4-a716-446655440002', 'Desert Sun Energy Corp', 'DSE-2024-003', '456 Solar Valley Road, Phoenix, AZ 85001', '+1-602-555-0300', 'support@desertsun.energy', 'https://desertsun.energy', '/nexus-green-logo.svg'),
('550e8400-e29b-41d4-a716-446655440003', 'Demo Solar Company', 'DEMO-2024-004', '123 Demo Street, Demo City, CA 90210', '+1-555-DEMO-123', 'demo@nexusgreen.energy', 'https://demo.nexusgreen.energy', '/nexus-green-logo.svg');

-- Insert demo users with secure password hashes
-- Password for all accounts: Demo2024!
-- Hash generated with: bcrypt.hash('Demo2024!', 12)
INSERT INTO users (id, company_id, email, password_hash, first_name, last_name, role, is_active) VALUES
-- Demo Company users (for testing)
('550e8400-e29b-41d4-a716-446655440100', '550e8400-e29b-41d4-a716-446655440003', 'admin@gonxt.tech', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Demo', 'Admin', 'super_admin', true),
('550e8400-e29b-41d4-a716-446655440101', '550e8400-e29b-41d4-a716-446655440003', 'user@gonxt.tech', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Demo', 'User', 'customer', true),
('550e8400-e29b-41d4-a716-446655440102', '550e8400-e29b-41d4-a716-446655440003', 'funder@gonxt.tech', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Demo', 'Funder', 'funder', true),
('550e8400-e29b-41d4-a716-446655440103', '550e8400-e29b-41d4-a716-446655440003', 'om@gonxt.tech', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Demo', 'OM Provider', 'om', true),

-- NexusGreen Energy Solutions users
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'admin@nexusgreen.energy', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Sarah', 'Chen', 'super_admin', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 'operations@nexusgreen.energy', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Michael', 'Rodriguez', 'customer', true),
('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440000', 'tech@nexusgreen.energy', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Emily', 'Johnson', 'om', true),

-- Pacific Solar Ventures users
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440001', 'admin@pacificsolar.com', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'David', 'Kim', 'super_admin', true),
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440001', 'manager@pacificsolar.com', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Lisa', 'Thompson', 'customer', true),

-- Desert Sun Energy Corp users
('550e8400-e29b-41d4-a716-446655440015', '550e8400-e29b-41d4-a716-446655440002', 'admin@desertsun.energy', '$2b$12$LQv3c1yqBwlVHpPjrGNDKOHYUehHKh4+3z/SoBPjk1S4gqiFq/ZG.', 'Robert', 'Martinez', 'super_admin', true);

-- Insert demo solar installations with realistic data
INSERT INTO installations (id, company_id, name, location, latitude, longitude, capacity_kw, installation_date, system_type, panel_count, inverter_type, status) VALUES
-- Demo Company installations (for testing)
('550e8400-e29b-41d4-a716-446655440200', '550e8400-e29b-41d4-a716-446655440003', 'Demo Solar Farm Alpha', 'Demo City, CA', 34.0522, -118.2437, 1500.00, '2024-01-15', 'Grid-tied Commercial', 5000, 'SMA Sunny Central 1500-EV', 'active'),
('550e8400-e29b-41d4-a716-446655440201', '550e8400-e29b-41d4-a716-446655440003', 'Demo Rooftop Installation', 'Demo Valley, CA', 34.1478, -118.1445, 850.00, '2024-03-20', 'Grid-tied Residential', 2833, 'Enphase IQ8M-72-2-US', 'active'),
('550e8400-e29b-41d4-a716-446655440202', '550e8400-e29b-41d4-a716-446655440003', 'Demo Industrial Complex', 'Demo Heights, CA', 34.0928, -118.3287, 2200.00, '2024-05-10', 'Grid-tied Industrial', 7333, 'SolarEdge SE82.8K', 'active'),

-- NexusGreen Energy Solutions installations
('550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440000', 'Bay Area Corporate Campus', 'Palo Alto, CA', 37.4419, -122.1430, 2500.00, '2023-03-15', 'Grid-tied Commercial', 8333, 'SMA Sunny Central 2500-EV', 'active'),
('550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440000', 'Fremont Manufacturing Facility', 'Fremont, CA', 37.5485, -121.9886, 1800.00, '2023-06-20', 'Grid-tied Industrial', 6000, 'Fronius Eco 25.0-3-S', 'active'),
('550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440000', 'San Jose Distribution Center', 'San Jose, CA', 37.3382, -121.8863, 3200.00, '2023-09-10', 'Grid-tied Commercial', 10667, 'SolarEdge SE82.8K', 'active'),

-- Pacific Solar Ventures installations
('550e8400-e29b-41d4-a716-446655440024', '550e8400-e29b-41d4-a716-446655440001', 'LAX Cargo Terminal Solar', 'Los Angeles, CA', 33.9425, -118.4081, 4500.00, '2023-02-28', 'Grid-tied Commercial', 15000, 'SMA Sunny Central 4600CP XT', 'active'),
('550e8400-e29b-41d4-a716-446655440025', '550e8400-e29b-41d4-a716-446655440001', 'Long Beach Port Authority', 'Long Beach, CA', 33.7701, -118.1937, 3800.00, '2023-07-15', 'Grid-tied Industrial', 12667, 'ABB PVS980-Central-2500', 'active'),

-- Desert Sun Energy Corp installations
('550e8400-e29b-41d4-a716-446655440027', '550e8400-e29b-41d4-a716-446655440002', 'Phoenix Sky Harbor Solar Farm', 'Phoenix, AZ', 33.4484, -112.0740, 5200.00, '2023-04-12', 'Utility-scale', 17333, 'SMA Sunny Central 5000CP XT', 'active'),
('550e8400-e29b-41d4-a716-446655440028', '550e8400-e29b-41d4-a716-446655440002', 'Tucson Medical Center', 'Tucson, AZ', 32.2226, -110.9747, 1600.00, '2023-08-30', 'Grid-tied Commercial', 5333, 'SolarEdge SE55K', 'active');

-- Generate realistic energy generation data for the last 90 days
DO $$
DECLARE
    installation_record RECORD;
    current_date DATE;
    hour_val INTEGER;
    base_generation DECIMAL;
    weather_factor DECIMAL;
    hour_factor DECIMAL;
    seasonal_factor DECIMAL;
    location_factor DECIMAL;
    day_of_year INTEGER;
BEGIN
    FOR installation_record IN SELECT id, capacity_kw, latitude FROM installations LOOP
        FOR i IN 0..89 LOOP
            current_date := CURRENT_DATE - INTERVAL '1 day' * i;
            day_of_year := EXTRACT(DOY FROM current_date);
            
            -- Seasonal adjustment (higher in summer, lower in winter)
            seasonal_factor := 0.8 + 0.4 * SIN(2 * PI() * (day_of_year - 80) / 365);
            
            -- Location factor (higher for southern latitudes)
            location_factor := CASE 
                WHEN installation_record.latitude > 37 THEN 0.9  -- Northern CA
                WHEN installation_record.latitude > 33 THEN 1.0  -- Southern CA
                ELSE 1.1  -- Arizona
            END;
            
            FOR hour_val IN 5..19 LOOP
                -- Realistic solar generation curve
                hour_factor := CASE 
                    WHEN hour_val = 5 THEN 0.05
                    WHEN hour_val = 6 THEN 0.15
                    WHEN hour_val = 7 THEN 0.35
                    WHEN hour_val = 8 THEN 0.55
                    WHEN hour_val = 9 THEN 0.75
                    WHEN hour_val = 10 THEN 0.90
                    WHEN hour_val = 11 THEN 0.98
                    WHEN hour_val = 12 THEN 1.00
                    WHEN hour_val = 13 THEN 0.98
                    WHEN hour_val = 14 THEN 0.90
                    WHEN hour_val = 15 THEN 0.75
                    WHEN hour_val = 16 THEN 0.55
                    WHEN hour_val = 17 THEN 0.35
                    WHEN hour_val = 18 THEN 0.15
                    WHEN hour_val = 19 THEN 0.05
                    ELSE 0.0
                END;
                
                -- Weather variability (mostly sunny with occasional clouds/rain)
                weather_factor := CASE 
                    WHEN RANDOM() < 0.05 THEN 0.1 + (RANDOM() * 0.3)  -- 5% rainy days
                    WHEN RANDOM() < 0.25 THEN 0.4 + (RANDOM() * 0.4)  -- 20% cloudy days
                    ELSE 0.8 + (RANDOM() * 0.2)  -- 75% sunny days
                END;
                
                base_generation := installation_record.capacity_kw * hour_factor * weather_factor * seasonal_factor * location_factor;
                
                INSERT INTO energy_generation (installation_id, date, hour, energy_kwh, irradiance, temperature, weather_condition)
                VALUES (
                    installation_record.id,
                    current_date,
                    hour_val,
                    GREATEST(0, base_generation + (RANDOM() - 0.5) * base_generation * 0.1), -- Add 10% noise
                    CASE 
                        WHEN weather_factor < 0.4 THEN 200 + (RANDOM() * 300)  -- Low irradiance for bad weather
                        WHEN weather_factor < 0.8 THEN 500 + (RANDOM() * 400)  -- Medium irradiance for cloudy
                        ELSE 800 + (RANDOM() * 200)  -- High irradiance for sunny
                    END,
                    CASE 
                        WHEN installation_record.latitude > 37 THEN 15 + (RANDOM() * 20)  -- Northern CA: 15-35°C
                        WHEN installation_record.latitude > 33 THEN 18 + (RANDOM() * 22)  -- Southern CA: 18-40°C
                        ELSE 20 + (RANDOM() * 25)  -- Arizona: 20-45°C
                    END,
                    CASE 
                        WHEN weather_factor < 0.4 THEN 'rainy'
                        WHEN weather_factor < 0.8 THEN 'cloudy'
                        ELSE 'sunny'
                    END
                );
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Generate realistic financial data with market rates
DO $$
DECLARE
    installation_record RECORD;
    current_date DATE;
    daily_generation DECIMAL;
    ppa_rate DECIMAL;
    grid_rate DECIMAL := 0.28; -- Average CA/AZ grid rate
BEGIN
    FOR installation_record IN SELECT id, capacity_kw FROM installations LOOP
        FOR i IN 0..89 LOOP
            current_date := CURRENT_DATE - INTERVAL '1 day' * i;
            
            -- Variable PPA rates based on installation size and date
            ppa_rate := CASE 
                WHEN installation_record.capacity_kw > 4000 THEN 0.08 + (RANDOM() * 0.02)  -- Large installations: $0.08-0.10/kWh
                WHEN installation_record.capacity_kw > 2000 THEN 0.10 + (RANDOM() * 0.02)  -- Medium installations: $0.10-0.12/kWh
                ELSE 0.12 + (RANDOM() * 0.02)  -- Small installations: $0.12-0.14/kWh
            END;
            
            -- Calculate daily generation
            SELECT COALESCE(SUM(energy_kwh), 0) INTO daily_generation
            FROM energy_generation 
            WHERE installation_id = installation_record.id AND date = current_date;
            
            INSERT INTO financial_data (installation_id, date, energy_sold_kwh, revenue, ppa_rate, savings)
            VALUES (
                installation_record.id,
                current_date,
                daily_generation * 0.95, -- 95% of generation is sold (5% for system losses)
                daily_generation * 0.95 * ppa_rate,
                ppa_rate,
                daily_generation * 0.95 * (grid_rate - ppa_rate) -- Savings vs grid electricity
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert realistic system alerts
INSERT INTO alerts (installation_id, type, severity, title, message, is_resolved, created_at) VALUES
-- Demo installation alerts
('550e8400-e29b-41d4-a716-446655440200', 'performance', 'info', 'Excellent Generation Day', 'Demo Solar Farm Alpha exceeded expected generation by 18%', false, CURRENT_TIMESTAMP - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440201', 'maintenance', 'warning', 'Scheduled Cleaning Due', 'Demo Rooftop Installation requires quarterly cleaning', false, CURRENT_TIMESTAMP - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440202', 'system', 'info', 'System Update Available', 'New monitoring firmware available for Demo Industrial Complex', false, CURRENT_TIMESTAMP - INTERVAL '2 days'),

-- Other installation alerts
('550e8400-e29b-41d4-a716-446655440020', 'maintenance', 'warning', 'Scheduled Maintenance Due', 'Quarterly maintenance inspection is due within 7 days', false, CURRENT_TIMESTAMP - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440024', 'performance', 'error', 'Inverter Fault Detected', 'String 3 inverter showing communication errors - immediate attention required', false, CURRENT_TIMESTAMP - INTERVAL '6 hours'),
('550e8400-e29b-41d4-a716-446655440027', 'weather', 'warning', 'High Wind Advisory', 'Wind speeds expected to exceed 45 mph in the next 24 hours', false, CURRENT_TIMESTAMP - INTERVAL '3 hours');

-- Insert comprehensive maintenance records
INSERT INTO maintenance (installation_id, type, description, scheduled_date, completed_date, status, cost, technician, created_at, updated_at) VALUES
-- Demo installation maintenance
('550e8400-e29b-41d4-a716-446655440200', 'Preventive', 'Quarterly system inspection and performance optimization', CURRENT_DATE + INTERVAL '7 days', NULL, 'scheduled', 2500.00, 'Demo Solar Services', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440201', 'Preventive', 'Panel cleaning and electrical connection check', CURRENT_DATE + INTERVAL '3 days', NULL, 'scheduled', 800.00, 'Demo Maintenance Team', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440202', 'Corrective', 'Inverter firmware update and system recalibration', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE - INTERVAL '5 days', 'completed', 1200.00, 'Demo Technical Services', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),

-- Other installation maintenance
('550e8400-e29b-41d4-a716-446655440020', 'Preventive', 'Quarterly system inspection, panel cleaning, and electrical testing', CURRENT_DATE + INTERVAL '5 days', NULL, 'scheduled', 3500.00, 'Advanced Solar Services - Team A', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440024', 'Corrective', 'Replace faulty string inverter and update firmware', CURRENT_DATE + INTERVAL '2 days', NULL, 'urgent', 4200.00, 'Pacific Solar Tech - Emergency Team', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440027', 'Preventive', 'Annual comprehensive system audit and performance optimization', CURRENT_DATE + INTERVAL '14 days', NULL, 'scheduled', 8500.00, 'Desert Sun Maintenance - Senior Team', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Create summary views for better performance
CREATE OR REPLACE VIEW installation_summary AS
SELECT 
    i.id,
    i.name,
    i.location,
    i.capacity_kw,
    i.status,
    c.name as company_name,
    COALESCE(SUM(eg.energy_kwh), 0) as total_generation_today,
    COALESCE(AVG(eg.energy_kwh), 0) as avg_hourly_generation_today,
    COALESCE(SUM(fd.revenue), 0) as total_revenue_today
FROM installations i
LEFT JOIN companies c ON i.company_id = c.id
LEFT JOIN energy_generation eg ON i.id = eg.installation_id AND eg.date = CURRENT_DATE
LEFT JOIN financial_data fd ON i.id = fd.installation_id AND fd.date = CURRENT_DATE
GROUP BY i.id, i.name, i.location, i.capacity_kw, i.status, c.name;

-- Create performance analytics view
CREATE OR REPLACE VIEW performance_analytics AS
SELECT 
    i.id as installation_id,
    i.name as installation_name,
    i.capacity_kw,
    DATE_TRUNC('month', eg.date) as month,
    SUM(eg.energy_kwh) as monthly_generation,
    AVG(eg.energy_kwh) as avg_hourly_generation,
    SUM(fd.revenue) as monthly_revenue,
    AVG(fd.ppa_rate) as avg_ppa_rate,
    SUM(fd.savings) as monthly_savings
FROM installations i
LEFT JOIN energy_generation eg ON i.id = eg.installation_id
LEFT JOIN financial_data fd ON i.id = fd.installation_id AND fd.date = eg.date
WHERE eg.date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY i.id, i.name, i.capacity_kw, DATE_TRUNC('month', eg.date)
ORDER BY i.id, month DESC;

-- Insert demo data summary
INSERT INTO alerts (installation_id, type, severity, title, message, is_resolved, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440200', 'system', 'info', 'Demo Data Loaded Successfully', 'NexusGreen demo environment is ready with comprehensive test data including 11 solar installations, 4 companies, and 90 days of realistic generation data.', true, CURRENT_TIMESTAMP);

-- Final data verification
DO $$
DECLARE
    company_count INTEGER;
    user_count INTEGER;
    installation_count INTEGER;
    generation_records INTEGER;
    financial_records INTEGER;
BEGIN
    SELECT COUNT(*) INTO company_count FROM companies;
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO installation_count FROM installations;
    SELECT COUNT(*) INTO generation_records FROM energy_generation;
    SELECT COUNT(*) INTO financial_records FROM financial_data;
    
    RAISE NOTICE 'Demo Data Summary:';
    RAISE NOTICE '- Companies: %', company_count;
    RAISE NOTICE '- Users: %', user_count;
    RAISE NOTICE '- Installations: %', installation_count;
    RAISE NOTICE '- Generation Records: %', generation_records;
    RAISE NOTICE '- Financial Records: %', financial_records;
    RAISE NOTICE 'Demo environment ready for testing!';
END $$;