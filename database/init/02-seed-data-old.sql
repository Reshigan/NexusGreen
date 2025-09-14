-- Nexus Green Seed Data
-- Demo company and realistic solar energy data

-- Insert demo company
INSERT INTO companies (id, name, registration_number, address, phone, email, website, logo_url) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'SolarTech Solutions (Pty) Ltd', '2023/123456/07', 
 '123 Solar Street, Green Point, Cape Town, 8005, South Africa', 
 '+27 21 555 0123', 'info@solartech.co.za', 'https://solartech.co.za',
 'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?w=200&h=200&fit=crop&crop=center');

-- Insert demo user (password: admin123)
INSERT INTO users (id, company_id, email, password_hash, first_name, last_name, role) VALUES 
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 
 'admin@solartech.co.za', '$2b$10$rOzJqQqQqQqQqQqQqQqQqOzJqQqQqQqQqQqQqQqQqOzJqQqQqQqQqQ', 
 'John', 'Smith', 'admin');

-- Insert solar installations
INSERT INTO installations (id, company_id, name, location, latitude, longitude, capacity_kw, installation_date, system_type, panel_count, inverter_type, status) VALUES 
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 
 'Cape Town Head Office', 'Green Point, Cape Town', -33.9249, 18.4241, 250.0, '2023-03-15', 'Grid-tied', 625, 'SMA Sunny Tripower', 'active'),

('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 
 'Stellenbosch Winery', 'Stellenbosch Wine Route', -33.9321, 18.8602, 500.0, '2023-06-20', 'Hybrid', 1250, 'Fronius Primo', 'active'),

('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440000', 
 'Paarl Industrial Park', 'Paarl Industrial Area', -33.7369, 18.9584, 750.0, '2023-09-10', 'Grid-tied', 1875, 'Huawei SUN2000', 'active');

-- Generate energy generation data for the last 30 days
DO $$
DECLARE
    installation_record RECORD;
    current_date DATE;
    hour_val INTEGER;
    base_generation DECIMAL;
    weather_factor DECIMAL;
    hour_factor DECIMAL;
    final_generation DECIMAL;
    weather_conditions TEXT[] := ARRAY['sunny', 'partly_cloudy', 'cloudy', 'overcast'];
    weather_condition TEXT;
    temp_val DECIMAL;
    irradiance_val DECIMAL;
BEGIN
    -- Loop through installations
    FOR installation_record IN SELECT id, capacity_kw FROM installations LOOP
        -- Loop through last 30 days
        FOR i IN 0..29 LOOP
            current_date := CURRENT_DATE - i;
            
            -- Loop through hours 6-18 (daylight hours)
            FOR hour_val IN 6..18 LOOP
                -- Base generation based on capacity and hour
                base_generation := installation_record.capacity_kw * 0.8; -- 80% efficiency
                
                -- Hour factor (solar curve)
                CASE 
                    WHEN hour_val IN (6, 7, 17, 18) THEN hour_factor := 0.2;
                    WHEN hour_val IN (8, 9, 16) THEN hour_factor := 0.6;
                    WHEN hour_val IN (10, 11, 14, 15) THEN hour_factor := 0.9;
                    WHEN hour_val IN (12, 13) THEN hour_factor := 1.0;
                    ELSE hour_factor := 0.1;
                END CASE;
                
                -- Weather factor (random)
                weather_factor := 0.7 + (RANDOM() * 0.3); -- 70-100%
                weather_condition := weather_conditions[1 + floor(random() * 4)];
                
                -- Adjust for weather
                CASE weather_condition
                    WHEN 'sunny' THEN weather_factor := weather_factor * 1.0;
                    WHEN 'partly_cloudy' THEN weather_factor := weather_factor * 0.8;
                    WHEN 'cloudy' THEN weather_factor := weather_factor * 0.5;
                    WHEN 'overcast' THEN weather_factor := weather_factor * 0.3;
                END CASE;
                
                final_generation := base_generation * hour_factor * weather_factor;
                
                -- Temperature (15-35°C)
                temp_val := 15 + (RANDOM() * 20);
                
                -- Irradiance (0-1200 W/m²)
                irradiance_val := hour_factor * weather_factor * 1200;
                
                INSERT INTO energy_generation (installation_id, date, hour, energy_kwh, irradiance, temperature, weather_condition)
                VALUES (installation_record.id, current_date, hour_val, final_generation, irradiance_val, temp_val, weather_condition);
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Generate financial data for the last 30 days
DO $$
DECLARE
    installation_record RECORD;
    current_date DATE;
    daily_energy DECIMAL;
    ppa_rate_val DECIMAL := 1.85; -- R1.85 per kWh
    daily_revenue DECIMAL;
    daily_savings DECIMAL;
BEGIN
    FOR installation_record IN SELECT id FROM installations LOOP
        FOR i IN 0..29 LOOP
            current_date := CURRENT_DATE - i;
            
            -- Calculate daily energy from hourly data
            SELECT COALESCE(SUM(energy_kwh), 0) INTO daily_energy
            FROM energy_generation 
            WHERE installation_id = installation_record.id AND date = current_date;
            
            daily_revenue := daily_energy * ppa_rate_val;
            daily_savings := daily_energy * (ppa_rate_val * 0.7); -- 30% savings vs grid
            
            INSERT INTO financial_data (installation_id, date, energy_sold_kwh, revenue, ppa_rate, savings)
            VALUES (installation_record.id, current_date, daily_energy, daily_revenue, ppa_rate_val, daily_savings);
        END LOOP;
    END LOOP;
END $$;

-- Insert sample alerts
INSERT INTO alerts (installation_id, type, severity, title, message, is_resolved) VALUES 
('550e8400-e29b-41d4-a716-446655440010', 'maintenance', 'warning', 'Scheduled Maintenance Due', 'Annual maintenance check is due for Cape Town Head Office installation.', false),
('550e8400-e29b-41d4-a716-446655440011', 'performance', 'info', 'High Performance Day', 'Stellenbosch Winery achieved 98% of expected generation today.', true),
('550e8400-e29b-41d4-a716-446655440012', 'weather', 'info', 'Weather Alert', 'Strong winds expected. Monitor system performance.', false);

-- Insert maintenance records
INSERT INTO maintenance (installation_id, type, description, scheduled_date, completed_date, cost, technician, status) VALUES 
('550e8400-e29b-41d4-a716-446655440010', 'Preventive', 'Annual system inspection and cleaning', '2024-03-15', '2024-03-15', 2500.00, 'Mike Johnson', 'completed'),
('550e8400-e29b-41d4-a716-446655440011', 'Corrective', 'Replace faulty inverter string', '2024-02-20', '2024-02-22', 4500.00, 'Sarah Williams', 'completed'),
('550e8400-e29b-41d4-a716-446655440012', 'Preventive', 'Quarterly performance check', '2024-09-30', NULL, 1800.00, 'David Brown', 'scheduled');