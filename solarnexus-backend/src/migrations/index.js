#!/usr/bin/env node

/**
 * SolarNexus Database Migration Runner
 * Handles database schema initialization and migrations
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Database configuration
const dbConfig = {
  connectionString: process.env.DATABASE_URL || 'postgresql://solarnexus:solarnexus@localhost:5432/solarnexus',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
};

const pool = new Pool(dbConfig);

/**
 * Execute SQL migration file
 */
async function executeMigration(filePath) {
  try {
    console.log(`📄 Executing migration: ${path.basename(filePath)}`);
    
    const sql = fs.readFileSync(filePath, 'utf8');
    await pool.query(sql);
    
    console.log(`✅ Migration completed: ${path.basename(filePath)}`);
  } catch (error) {
    console.error(`❌ Migration failed: ${path.basename(filePath)}`);
    console.error(error.message);
    throw error;
  }
}

/**
 * Check if database is accessible
 */
async function checkDatabase() {
  try {
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();
    console.log('✅ Database connection successful');
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

/**
 * Run all migrations
 */
async function runMigrations() {
  console.log('🚀 Starting SolarNexus database migrations...');
  
  // Check database connection
  const isConnected = await checkDatabase();
  if (!isConnected) {
    console.error('❌ Cannot connect to database. Exiting...');
    process.exit(1);
  }
  
  try {
    // Look for migration.sql file in the backend root
    const migrationFile = path.join(__dirname, '../../migration.sql');
    
    if (fs.existsSync(migrationFile)) {
      await executeMigration(migrationFile);
    } else {
      console.log('📄 No migration.sql file found, creating basic schema...');
      
      // Create basic schema if no migration file exists
      const basicSchema = `
        -- SolarNexus Basic Schema
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        
        -- Users table
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          role VARCHAR(50) NOT NULL DEFAULT 'customer',
          first_name VARCHAR(100),
          last_name VARCHAR(100),
          company VARCHAR(255),
          phone VARCHAR(50),
          is_active BOOLEAN DEFAULT true,
          email_verified BOOLEAN DEFAULT false,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Sites table
        CREATE TABLE IF NOT EXISTS sites (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          name VARCHAR(255) NOT NULL,
          address TEXT,
          latitude DECIMAL(10, 8),
          longitude DECIMAL(11, 8),
          capacity_kw DECIMAL(10, 2),
          installation_date DATE,
          status VARCHAR(50) DEFAULT 'active',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- User sites relationship
        CREATE TABLE IF NOT EXISTS user_sites (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
          role VARCHAR(50) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id, site_id)
        );
        
        -- Solar data table
        CREATE TABLE IF NOT EXISTS solar_data (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
          timestamp TIMESTAMP NOT NULL,
          power_generation_kw DECIMAL(10, 4),
          energy_today_kwh DECIMAL(10, 4),
          energy_total_kwh DECIMAL(12, 4),
          grid_consumption_kw DECIMAL(10, 4),
          battery_soc DECIMAL(5, 2),
          temperature DECIMAL(5, 2),
          irradiance DECIMAL(8, 2),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Create indexes for performance
        CREATE INDEX IF NOT EXISTS idx_solar_data_site_timestamp ON solar_data(site_id, timestamp);
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_user_sites_user_id ON user_sites(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_sites_site_id ON user_sites(site_id);
        
        -- Insert default admin user (password: admin123)
        INSERT INTO users (email, password_hash, role, first_name, last_name, is_active, email_verified)
        VALUES (
          'admin@nexus.gonxt.tech',
          '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VcSAg/9PS',
          'admin',
          'System',
          'Administrator',
          true,
          true
        ) ON CONFLICT (email) DO NOTHING;
        
        COMMIT;
      `;
      
      await pool.query(basicSchema);
      console.log('✅ Basic schema created successfully');
    }
    
    console.log('🎉 All migrations completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run migrations if this file is executed directly
if (require.main === module) {
  runMigrations().catch(error => {
    console.error('❌ Migration process failed:', error);
    process.exit(1);
  });
}

module.exports = { runMigrations, checkDatabase };