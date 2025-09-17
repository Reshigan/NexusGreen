-- Demo seed data for NexusGreen Solar Platform
-- Contains one demo user for each of the 4 user profiles

-- Insert demo company
INSERT INTO companies (id, name, registration_number, address, phone, email, website, logo_url) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'NexusGreen Demo Corp', 'NGC-2024-001', '123 Solar Street, Green Valley, CA 90210', '+1-555-SOLAR-01', 'info@nexusgreen.demo', 'https://nexusgreen.demo', '/nexus-green-logo.svg');

-- Insert 4 demo users with different roles
-- Password for all users: Demo2024! (hashed with bcrypt)
INSERT INTO users (id, company_id, email, password_hash, first_name, last_name, role, permissions, is_active) VALUES
-- Super Admin
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 'admin@nexusgreen.demo', '$2b$10$8K1p/a0drtIEaYKTty6aou6BcQQUrkFHPfOcf5aq2i4/6b7n3PDUO', 'Super', 'Admin', 'super_admin', '{"all_access": true, "manage_users": true, "manage_companies": true, "view_all_data": true, "system_config": true}', true),

-- Customer
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', 'customer@nexusgreen.demo', '$2b$10$8K1p/a0drtIEaYKTty6aou6BcQQUrkFHPfOcf5aq2i4/6b7n3PDUO', 'John', 'Customer', 'customer', '{"view_own_installations": true, "view_reports": true, "manage_profile": true}', true),

-- Funder/Investor
('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440000', 'funder@nexusgreen.demo', '$2b$10$8K1p/a0drtIEaYKTty6aou6BcQQUrkFHPfOcf5aq2i4/6b7n3PDUO', 'Sarah', 'Investor', 'funder', '{"view_financial_data": true, "view_roi_reports": true, "view_portfolio": true, "export_reports": true}', true),

-- Operations & Maintenance
('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440000', 'om@nexusgreen.demo', '$2b$10$8K1p/a0drtIEaYKTty6aou6BcQQUrkFHPfOcf5aq2i4/6b7n3PDUO', 'Mike', 'Technician', 'om', '{"manage_maintenance": true, "view_alerts": true, "update_system_status": true, "schedule_maintenance": true}', true);

-- Insert demo solar installations
INSERT INTO installations (id, company_id, name, location, latitude, longitude, capacity_kw, installation_date, system_type, panel_count, inverter_type, status) VALUES
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'Demo Solar Farm Alpha', 'Green Valley, CA', 34.0522, -118.2437, 500.00, '2023-06-15', 'Grid-Tied', 2000, 'SolarEdge SE27.6K', 'active'),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 'Demo Rooftop Beta', 'Los Angeles, CA', 34.0522, -118.2437, 250.00, '2023-08-20', 'Grid-Tied', 1000, 'Enphase IQ8+', 'active'),
('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440000', 'Demo Commercial Gamma', 'San Diego, CA', 32.7157, -117.1611, 750.00, '2023-09-10', 'Grid-Tied', 3000, 'SMA Sunny Tripower', 'active');

-- Insert sample energy generation data for the last 30 days
INSERT INTO energy_generation (installation_id, date, hour, energy_kwh, irradiance, temperature, weather_condition)
SELECT 
    i.id,
    CURRENT_DATE - INTERVAL '1 day' * generate_series(0, 29),
    generate_series(6, 18) as hour,
    CASE 
        WHEN generate_series(6, 18) BETWEEN 10 AND 16 THEN 
            (i.capacity_kw * 0.8 * RANDOM() * 0.5) + (i.capacity_kw * 0.3)
        ELSE 
            i.capacity_kw * 0.2 * RANDOM()
    END as energy_kwh,
    CASE 
        WHEN generate_series(6, 18) BETWEEN 10 AND 16 THEN 
            800 + (RANDOM() * 200)
        ELSE 
            200 + (RANDOM() * 300)
    END as irradiance,
    20 + (RANDOM() * 15) as temperature,
    CASE 
        WHEN RANDOM() > 0.8 THEN 'Cloudy'
        WHEN RANDOM() > 0.9 THEN 'Rainy'
        ELSE 'Sunny'
    END as weather_condition
FROM installations i
WHERE i.company_id = '550e8400-e29b-41d4-a716-446655440000';

-- Insert financial data
INSERT INTO financial_data (installation_id, date, energy_sold_kwh, revenue, ppa_rate, savings)
SELECT 
    i.id,
    CURRENT_DATE - INTERVAL '1 day' * generate_series(0, 29),
    SUM(eg.energy_kwh) as energy_sold_kwh,
    SUM(eg.energy_kwh) * 0.12 as revenue,
    0.12 as ppa_rate,
    SUM(eg.energy_kwh) * 0.08 as savings
FROM installations i
JOIN energy_generation eg ON i.id = eg.installation_id
WHERE i.company_id = '550e8400-e29b-41d4-a716-446655440000'
GROUP BY i.id, eg.date;

-- Insert sample alerts
INSERT INTO alerts (installation_id, type, severity, title, message, is_resolved) VALUES
('550e8400-e29b-41d4-a716-446655440010', 'maintenance', 'warning', 'Scheduled Maintenance Due', 'Quarterly maintenance check is due for Demo Solar Farm Alpha', false),
('550e8400-e29b-41d4-a716-446655440011', 'performance', 'info', 'Performance Above Average', 'Demo Rooftop Beta is performing 5% above expected output', true),
('550e8400-e29b-41d4-a716-446655440012', 'weather', 'low', 'Weather Alert', 'High winds expected in the area. Monitor system performance.', false);

-- Insert maintenance records
INSERT INTO maintenance (installation_id, type, description, scheduled_date, completed_date, cost, technician, status) VALUES
('550e8400-e29b-41d4-a716-446655440010', 'Preventive', 'Quarterly inspection and cleaning', '2024-09-20', NULL, 500.00, 'Mike Technician', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440011', 'Corrective', 'Replace faulty inverter', '2024-09-15', '2024-09-16', 1200.00, 'Mike Technician', 'completed'),
('550e8400-e29b-41d4-a716-446655440012', 'Preventive', 'Annual system inspection', '2024-10-01', NULL, 800.00, 'Mike Technician', 'scheduled');