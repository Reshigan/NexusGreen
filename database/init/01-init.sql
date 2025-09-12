-- SolarNexus Database Initialization
-- This script runs when the PostgreSQL container starts for the first time

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create indexes for better performance (will be created by Prisma migrations)
-- This is just a placeholder for any custom database setup

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'SolarNexus database initialized successfully';
END $$;