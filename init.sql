-- NexusGreen Database Initialization Script

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default users with bcrypt hashed passwords
-- admin123 -> $2b$10$rOzJqQZJqQZJqQZJqQZJqOzJqQZJqQZJqQZJqQZJqQZJqQZJqQZJq
-- user123 -> $2b$10$rOzJqQZJqQZJqQZJqQZJqOzJqQZJqQZJqQZJqQZJqQZJqQZJqQZJq
INSERT INTO users (username, email, password_hash, role) VALUES
    ('admin', 'admin@nexusgreen.com', '$2b$10$rOzJqQZJqQZJqQZJqQZJqOzJqQZJqQZJqQZJqQZJqQZJqQZJqQZJq', 'admin'),
    ('user', 'user@nexusgreen.com', '$2b$10$rOzJqQZJqQZJqQZJqQZJqOzJqQZJqQZJqQZJqQZJqQZJqQZJqQZJq', 'user')
ON CONFLICT (username) DO NOTHING;

-- Create energy_data table for dashboard metrics
CREATE TABLE IF NOT EXISTS energy_data (
    id SERIAL PRIMARY KEY,
    site_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    energy_production DECIMAL(10,2),
    energy_consumption DECIMAL(10,2),
    efficiency DECIMAL(5,2),
    temperature DECIMAL(5,2),
    irradiance DECIMAL(8,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample energy data
INSERT INTO energy_data (site_id, energy_production, energy_consumption, efficiency, temperature, irradiance) VALUES
    ('SITE001', 2847.5, 2156.3, 94.9, 25.4, 850.2),
    ('SITE002', 1923.8, 1456.7, 92.1, 27.1, 823.5),
    ('SITE003', 3156.2, 2398.9, 96.2, 24.8, 892.1),
    ('SITE004', 2634.7, 1987.3, 93.8, 26.3, 867.4),
    ('SITE005', 1789.4, 1345.2, 91.5, 28.2, 798.6);

-- Create alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    site_id VARCHAR(50) NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'medium',
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL
);

-- Insert sample alerts
INSERT INTO alerts (site_id, alert_type, severity, message, status) VALUES
    ('SITE001', 'efficiency', 'low', 'Panel efficiency below threshold', 'active'),
    ('SITE003', 'maintenance', 'medium', 'Scheduled maintenance due', 'active'),
    ('SITE002', 'temperature', 'high', 'High temperature detected', 'resolved'),
    ('SITE004', 'production', 'low', 'Low energy production detected', 'active');

-- Create sites table
CREATE TABLE IF NOT EXISTS sites (
    id SERIAL PRIMARY KEY,
    site_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200),
    capacity DECIMAL(10,2),
    installation_date DATE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample sites
INSERT INTO sites (site_id, name, location, capacity, installation_date, status) VALUES
    ('SITE001', 'Downtown Solar Farm', 'Downtown Business District', 5000.00, '2023-01-15', 'active'),
    ('SITE002', 'Industrial Complex A', 'Industrial Zone North', 3500.00, '2023-03-22', 'active'),
    ('SITE003', 'Residential Hub', 'Suburban Area East', 7500.00, '2022-11-08', 'active'),
    ('SITE004', 'Commercial Center', 'Shopping District', 4200.00, '2023-05-10', 'active'),
    ('SITE005', 'University Campus', 'Education District', 2800.00, '2023-07-01', 'active');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_energy_data_site_timestamp ON energy_data(site_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_alerts_site_status ON alerts(site_id, status);
CREATE INDEX IF NOT EXISTS idx_sites_status ON sites(status);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nexusgreen;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nexusgreen;