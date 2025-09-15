#!/usr/bin/env ts-node

import { PrismaClient } from '@prisma/client';
import { SouthAfricanDataService } from '../services/southAfricanDataService';

const prisma = new PrismaClient();

async function main() {
  try {
    console.log('🌍 Starting South African data seeding process...');
    
    // Seed the main data
    const result = await SouthAfricanDataService.seedSouthAfricanData();
    
    // Generate role-specific KPIs
    await SouthAfricanDataService.generateRoleKPIs();
    
    console.log('✅ South African data seeding completed successfully!');
    console.log(`📊 Created organization: ${result.organization.name}`);
    console.log(`🏗️ Created ${result.projects.length} projects`);
    console.log(`🏭 Created ${result.sites.length} sites`);
    console.log('📈 Generated 2 years of historical data');
    console.log('🎯 Generated role-specific KPIs');
    
  } catch (error) {
    console.error('❌ Error seeding South African data:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();