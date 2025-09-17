-- Comprehensive Project Seeding Script for NexusGreen
-- Johannesburg and Durban Solar Projects with Detailed Data

-- Clear existing data (be careful in production)
DELETE FROM energy_data WHERE site_id IN (SELECT id FROM sites WHERE project_id IN (SELECT id FROM projects WHERE name IN ('Johannesburg Solar Grid-Tied', 'Durban Solar Battery System')));
DELETE FROM sites WHERE project_id IN (SELECT id FROM projects WHERE name IN ('Johannesburg Solar Grid-Tied', 'Durban Solar Battery System'));
DELETE FROM projects WHERE name IN ('Johannesburg Solar Grid-Tied', 'Durban Solar Battery System');

-- Insert Johannesburg Project
INSERT INTO projects (
    id, name, description, location, capacity_kw, status, 
    installation_date, funder_id, customer_id, om_provider_id,
    created_at, updated_at
) VALUES (
    'jhb-grid-tied-001',
    'Johannesburg Solar Grid-Tied',
    'Grid-tied solar installation in Johannesburg with 100kW capacity serving commercial facility with 80kW average consumption',
    'Johannesburg, Gauteng, South Africa',
    100.0,
    'operational',
    '2022-01-15',
    (SELECT id FROM users WHERE email = 'funder@gonxt.tech' LIMIT 1),
    (SELECT id FROM users WHERE email = 'user@gonxt.tech' LIMIT 1),
    (SELECT id FROM users WHERE email = 'om@gonxt.tech' LIMIT 1),
    NOW(),
    NOW()
);

-- Insert Durban Project
INSERT INTO projects (
    id, name, description, location, capacity_kw, status, 
    installation_date, funder_id, customer_id, om_provider_id,
    created_at, updated_at
) VALUES (
    'dbn-battery-001',
    'Durban Solar Battery System',
    'Solar installation with battery storage in Durban - 200kW solar with 400kW battery capacity serving facility with 160kW consumption',
    'Durban, KwaZulu-Natal, South Africa',
    200.0,
    'operational',
    '2022-03-01',
    (SELECT id FROM users WHERE email = 'funder@gonxt.tech' LIMIT 1),
    (SELECT id FROM users WHERE email = 'user@gonxt.tech' LIMIT 1),
    (SELECT id FROM users WHERE email = 'om@gonxt.tech' LIMIT 1),
    NOW(),
    NOW()
);

-- Insert Johannesburg Site
INSERT INTO sites (
    id, project_id, name, location, latitude, longitude,
    capacity_kw, installation_date, status, site_type,
    municipal_day_rate, municipal_night_rate, unit_price_from_funder,
    average_consumption_kw, created_at, updated_at
) VALUES (
    'jhb-site-001',
    'jhb-grid-tied-001',
    'Johannesburg Commercial Solar Site',
    'Sandton, Johannesburg, Gauteng',
    -26.1076,
    28.0567,
    100.0,
    '2022-01-15',
    'active',
    'grid_tied',
    3.80,  -- R3.80 day rate
    1.20,  -- R1.20 night rate
    1.50,  -- R1.50 unit price from funder
    80.0,  -- 80kW average consumption
    NOW(),
    NOW()
);

-- Insert Durban Site
INSERT INTO sites (
    id, project_id, name, location, latitude, longitude,
    capacity_kw, installation_date, status, site_type,
    municipal_day_rate, municipal_night_rate, unit_price_from_funder,
    average_consumption_kw, battery_capacity_kwh, created_at, updated_at
) VALUES (
    'dbn-site-001',
    'dbn-battery-001',
    'Durban Industrial Solar + Battery Site',
    'Pinetown, Durban, KwaZulu-Natal',
    -29.8587,
    30.8255,
    200.0,
    '2022-03-01',
    'active',
    'battery_storage',
    3.80,  -- R3.80 day rate
    2.00,  -- R2.00 night rate
    1.50,  -- R1.50 unit price from funder
    160.0, -- 160kW average consumption
    400.0, -- 400kW battery capacity
    NOW(),
    NOW()
);

-- Generate 2 years of energy data for Johannesburg (Grid-tied)
-- This will create realistic data with seasonal variations
DO $$
DECLARE
    start_date DATE := '2022-01-15';
    end_date DATE := '2024-01-15';
    current_date DATE;
    hour_of_day INTEGER;
    base_generation DECIMAL;
    seasonal_factor DECIMAL;
    daily_variation DECIMAL;
    consumption_kw DECIMAL;
    grid_import DECIMAL;
    grid_export DECIMAL;
    month_factor DECIMAL;
BEGIN
    current_date := start_date;
    
    WHILE current_date <= end_date LOOP
        -- Calculate seasonal factor (higher in summer months)
        month_factor := CASE 
            WHEN EXTRACT(MONTH FROM current_date) IN (12, 1, 2) THEN 1.2  -- Summer
            WHEN EXTRACT(MONTH FROM current_date) IN (3, 4, 5) THEN 0.9   -- Autumn
            WHEN EXTRACT(MONTH FROM current_date) IN (6, 7, 8) THEN 0.7   -- Winter
            ELSE 1.0  -- Spring
        END;
        
        FOR hour_of_day IN 0..23 LOOP
            -- Solar generation pattern (peak around noon)
            IF hour_of_day >= 6 AND hour_of_day <= 18 THEN
                base_generation := 100.0 * SIN(PI() * (hour_of_day - 6) / 12.0) * month_factor;
                -- Add some randomness
                base_generation := base_generation * (0.8 + RANDOM() * 0.4);
            ELSE
                base_generation := 0;
            END IF;
            
            -- Consumption pattern (higher during business hours)
            IF hour_of_day >= 7 AND hour_of_day <= 17 THEN
                consumption_kw := 80.0 + (RANDOM() * 20 - 10); -- 70-90kW during business hours
            ELSIF hour_of_day >= 18 AND hour_of_day <= 22 THEN
                consumption_kw := 60.0 + (RANDOM() * 20 - 10); -- 50-70kW evening
            ELSE
                consumption_kw := 30.0 + (RANDOM() * 20 - 10); -- 20-40kW night/early morning
            END IF;
            
            -- Calculate grid import/export
            IF base_generation > consumption_kw THEN
                grid_export := base_generation - consumption_kw;
                grid_import := 0;
            ELSE
                grid_import := consumption_kw - base_generation;
                grid_export := 0;
            END IF;
            
            INSERT INTO energy_data (
                site_id, timestamp, energy_generated_kwh, energy_consumed_kwh,
                grid_import_kwh, grid_export_kwh, battery_charge_kwh, battery_discharge_kwh,
                battery_soc_percent, created_at
            ) VALUES (
                'jhb-site-001',
                current_date + (hour_of_day || ' hours')::INTERVAL,
                GREATEST(0, base_generation),
                GREATEST(0, consumption_kw),
                GREATEST(0, grid_import),
                GREATEST(0, grid_export),
                0, -- No battery
                0, -- No battery
                NULL, -- No battery
                NOW()
            );
        END LOOP;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
END $$;

-- Generate 2 years of energy data for Durban (Battery Storage)
DO $$
DECLARE
    start_date DATE := '2022-03-01';
    end_date DATE := '2024-03-01';
    current_date DATE;
    hour_of_day INTEGER;
    base_generation DECIMAL;
    consumption_kw DECIMAL;
    battery_soc DECIMAL := 50.0; -- Start at 50% SOC
    battery_charge DECIMAL := 0;
    battery_discharge DECIMAL := 0;
    grid_import DECIMAL := 0;
    grid_export DECIMAL := 0;
    net_energy DECIMAL;
    month_factor DECIMAL;
BEGIN
    current_date := start_date;
    
    WHILE current_date <= end_date LOOP
        -- Calculate seasonal factor
        month_factor := CASE 
            WHEN EXTRACT(MONTH FROM current_date) IN (12, 1, 2) THEN 1.3  -- Summer (higher in Durban)
            WHEN EXTRACT(MONTH FROM current_date) IN (3, 4, 5) THEN 1.0   -- Autumn
            WHEN EXTRACT(MONTH FROM current_date) IN (6, 7, 8) THEN 0.8   -- Winter
            ELSE 1.1  -- Spring
        END;
        
        FOR hour_of_day IN 0..23 LOOP
            -- Solar generation pattern (200kW peak)
            IF hour_of_day >= 6 AND hour_of_day <= 18 THEN
                base_generation := 200.0 * SIN(PI() * (hour_of_day - 6) / 12.0) * month_factor;
                base_generation := base_generation * (0.8 + RANDOM() * 0.4);
            ELSE
                base_generation := 0;
            END IF;
            
            -- Industrial consumption pattern (160kW average)
            IF hour_of_day >= 6 AND hour_of_day <= 18 THEN
                consumption_kw := 160.0 + (RANDOM() * 40 - 20); -- 140-180kW during operation
            ELSIF hour_of_day >= 19 AND hour_of_day <= 23 THEN
                consumption_kw := 120.0 + (RANDOM() * 30 - 15); -- 105-135kW evening
            ELSE
                consumption_kw := 80.0 + (RANDOM() * 20 - 10); -- 70-90kW night
            END IF;
            
            -- Calculate net energy (generation - consumption)
            net_energy := base_generation - consumption_kw;
            
            -- Battery and grid logic
            battery_charge := 0;
            battery_discharge := 0;
            grid_import := 0;
            grid_export := 0;
            
            IF net_energy > 0 THEN
                -- Excess generation
                IF battery_soc < 90.0 THEN
                    -- Charge battery first
                    battery_charge := LEAST(net_energy, (90.0 - battery_soc) * 400.0 / 100.0);
                    battery_soc := LEAST(90.0, battery_soc + (battery_charge * 100.0 / 400.0));
                    net_energy := net_energy - battery_charge;
                END IF;
                
                IF net_energy > 0 THEN
                    -- Export excess to grid
                    grid_export := net_energy;
                END IF;
            ELSE
                -- Energy deficit
                net_energy := ABS(net_energy);
                
                -- Use battery first (if available and not peak hours)
                IF battery_soc > 20.0 AND NOT (hour_of_day >= 17 AND hour_of_day <= 20) THEN
                    battery_discharge := LEAST(net_energy, (battery_soc - 20.0) * 400.0 / 100.0);
                    battery_soc := GREATEST(20.0, battery_soc - (battery_discharge * 100.0 / 400.0));
                    net_energy := net_energy - battery_discharge;
                END IF;
                
                IF net_energy > 0 THEN
                    -- Import from grid
                    grid_import := net_energy;
                END IF;
            END IF;
            
            INSERT INTO energy_data (
                site_id, timestamp, energy_generated_kwh, energy_consumed_kwh,
                grid_import_kwh, grid_export_kwh, battery_charge_kwh, battery_discharge_kwh,
                battery_soc_percent, created_at
            ) VALUES (
                'dbn-site-001',
                current_date + (hour_of_day || ' hours')::INTERVAL,
                GREATEST(0, base_generation),
                GREATEST(0, consumption_kw),
                GREATEST(0, grid_import),
                GREATEST(0, grid_export),
                GREATEST(0, battery_charge),
                GREATEST(0, battery_discharge),
                ROUND(battery_soc, 1),
                NOW()
            );
        END LOOP;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
END $$;

-- Update project statistics
UPDATE projects SET 
    total_energy_generated = (
        SELECT COALESCE(SUM(ed.energy_generated_kwh), 0)
        FROM energy_data ed
        JOIN sites s ON ed.site_id = s.id
        WHERE s.project_id = projects.id
    ),
    total_energy_consumed = (
        SELECT COALESCE(SUM(ed.energy_consumed_kwh), 0)
        FROM energy_data ed
        JOIN sites s ON ed.site_id = s.id
        WHERE s.project_id = projects.id
    ),
    updated_at = NOW()
WHERE id IN ('jhb-grid-tied-001', 'dbn-battery-001');

-- Create some alerts for the projects
INSERT INTO alerts (
    id, site_id, type, severity, title, description, 
    status, created_at, updated_at
) VALUES 
(
    'alert-jhb-001',
    'jhb-site-001',
    'performance',
    'medium',
    'Generation Below Expected',
    'Solar generation is 15% below expected for this time of year. Recommend panel cleaning.',
    'active',
    NOW() - INTERVAL '2 days',
    NOW()
),
(
    'alert-dbn-001',
    'dbn-site-001',
    'maintenance',
    'low',
    'Scheduled Maintenance Due',
    'Quarterly battery system maintenance is due within the next 30 days.',
    'active',
    NOW() - INTERVAL '1 day',
    NOW()
),
(
    'alert-dbn-002',
    'dbn-site-001',
    'performance',
    'high',
    'Battery Efficiency Alert',
    'Battery discharge efficiency has decreased by 8% over the past month. Investigation recommended.',
    'active',
    NOW() - INTERVAL '6 hours',
    NOW()
);

-- Insert financial data for both projects
INSERT INTO financial_data (
    id, project_id, month_year, revenue_generated, costs_incurred,
    savings_achieved, roi_percentage, created_at, updated_at
) 
SELECT 
    'fin-' || p.id || '-' || TO_CHAR(month_series, 'YYYY-MM'),
    p.id,
    month_series,
    -- Calculate revenue based on energy generated and rates
    CASE 
        WHEN p.id = 'jhb-grid-tied-001' THEN
            (SELECT COALESCE(SUM(ed.energy_generated_kwh * 1.50), 0) -- R1.50 per kWh from funder
             FROM energy_data ed 
             JOIN sites s ON ed.site_id = s.id 
             WHERE s.project_id = p.id 
             AND DATE_TRUNC('month', ed.timestamp) = month_series)
        ELSE
            (SELECT COALESCE(SUM(ed.energy_generated_kwh * 1.50), 0)
             FROM energy_data ed 
             JOIN sites s ON ed.site_id = s.id 
             WHERE s.project_id = p.id 
             AND DATE_TRUNC('month', ed.timestamp) = month_series)
    END,
    -- Operational costs (maintenance, insurance, etc.)
    CASE 
        WHEN p.id = 'jhb-grid-tied-001' THEN 2500.0 + (RANDOM() * 1000 - 500)
        ELSE 4500.0 + (RANDOM() * 1500 - 750)
    END,
    -- Savings (avoided municipal electricity costs)
    CASE 
        WHEN p.id = 'jhb-grid-tied-001' THEN
            (SELECT COALESCE(SUM(
                CASE 
                    WHEN EXTRACT(HOUR FROM ed.timestamp) BETWEEN 6 AND 18 
                    THEN ed.energy_generated_kwh * 3.80  -- Day rate
                    ELSE ed.energy_generated_kwh * 1.20  -- Night rate
                END
            ), 0)
             FROM energy_data ed 
             JOIN sites s ON ed.site_id = s.id 
             WHERE s.project_id = p.id 
             AND DATE_TRUNC('month', ed.timestamp) = month_series)
        ELSE
            (SELECT COALESCE(SUM(
                CASE 
                    WHEN EXTRACT(HOUR FROM ed.timestamp) BETWEEN 6 AND 18 
                    THEN ed.energy_generated_kwh * 3.80  -- Day rate
                    ELSE ed.energy_generated_kwh * 2.00  -- Night rate
                END
            ), 0)
             FROM energy_data ed 
             JOIN sites s ON ed.site_id = s.id 
             WHERE s.project_id = p.id 
             AND DATE_TRUNC('month', ed.timestamp) = month_series)
    END,
    -- ROI calculation (simplified)
    CASE 
        WHEN p.id = 'jhb-grid-tied-001' THEN 12.5 + (RANDOM() * 5 - 2.5)
        ELSE 15.2 + (RANDOM() * 4 - 2)
    END,
    NOW(),
    NOW()
FROM projects p
CROSS JOIN generate_series(
    DATE_TRUNC('month', '2022-01-01'::DATE),
    DATE_TRUNC('month', CURRENT_DATE),
    '1 month'::INTERVAL
) AS month_series
WHERE p.id IN ('jhb-grid-tied-001', 'dbn-battery-001')
AND month_series >= CASE 
    WHEN p.id = 'jhb-grid-tied-001' THEN '2022-01-01'::DATE
    ELSE '2022-03-01'::DATE
END;

-- Add some maintenance records
INSERT INTO maintenance_records (
    id, site_id, type, description, scheduled_date, completed_date,
    technician_name, status, cost, created_at, updated_at
) VALUES 
(
    'maint-jhb-001',
    'jhb-site-001',
    'cleaning',
    'Quarterly solar panel cleaning and inspection',
    '2024-01-15',
    '2024-01-15',
    'John Smith - Solar Tech',
    'completed',
    1200.00,
    NOW() - INTERVAL '2 days',
    NOW()
),
(
    'maint-jhb-002',
    'jhb-site-001',
    'inspection',
    'Annual electrical system inspection and testing',
    '2024-02-01',
    NULL,
    'Mike Johnson - Electrical',
    'scheduled',
    2500.00,
    NOW() - INTERVAL '1 day',
    NOW()
),
(
    'maint-dbn-001',
    'dbn-site-001',
    'battery_maintenance',
    'Battery system health check and calibration',
    '2024-01-20',
    '2024-01-20',
    'Sarah Wilson - Battery Specialist',
    'completed',
    3500.00,
    NOW() - INTERVAL '5 days',
    NOW()
),
(
    'maint-dbn-002',
    'dbn-site-001',
    'preventive',
    'Quarterly preventive maintenance - inverters and monitoring systems',
    '2024-02-15',
    NULL,
    'David Brown - Systems Tech',
    'scheduled',
    2800.00,
    NOW(),
    NOW()
);

-- Create summary view for easy reporting
CREATE OR REPLACE VIEW project_summary AS
SELECT 
    p.id,
    p.name,
    p.location,
    p.capacity_kw,
    p.status,
    p.installation_date,
    COUNT(s.id) as site_count,
    COALESCE(SUM(s.capacity_kw), 0) as total_site_capacity,
    COALESCE(AVG(s.average_consumption_kw), 0) as avg_consumption,
    -- Last 30 days performance
    COALESCE((
        SELECT SUM(ed.energy_generated_kwh)
        FROM energy_data ed
        JOIN sites s2 ON ed.site_id = s2.id
        WHERE s2.project_id = p.id
        AND ed.timestamp >= CURRENT_DATE - INTERVAL '30 days'
    ), 0) as energy_generated_30d,
    COALESCE((
        SELECT SUM(ed.energy_consumed_kwh)
        FROM energy_data ed
        JOIN sites s2 ON ed.site_id = s2.id
        WHERE s2.project_id = p.id
        AND ed.timestamp >= CURRENT_DATE - INTERVAL '30 days'
    ), 0) as energy_consumed_30d,
    -- Active alerts count
    COALESCE((
        SELECT COUNT(*)
        FROM alerts a
        JOIN sites s3 ON a.site_id = s3.id
        WHERE s3.project_id = p.id
        AND a.status = 'active'
    ), 0) as active_alerts_count
FROM projects p
LEFT JOIN sites s ON p.id = s.project_id
WHERE p.id IN ('jhb-grid-tied-001', 'dbn-battery-001')
GROUP BY p.id, p.name, p.location, p.capacity_kw, p.status, p.installation_date;

-- Grant permissions (adjust as needed for your user setup)
-- GRANT SELECT ON project_summary TO nexus_readonly;

COMMIT;

-- Display summary of created data
SELECT 'Data Seeding Complete' as status;
SELECT * FROM project_summary;
SELECT 
    'Energy Data Records' as metric,
    COUNT(*) as count
FROM energy_data ed
JOIN sites s ON ed.site_id = s.id
WHERE s.project_id IN ('jhb-grid-tied-001', 'dbn-battery-001');