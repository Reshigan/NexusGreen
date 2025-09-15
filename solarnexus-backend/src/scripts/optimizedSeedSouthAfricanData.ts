#!/usr/bin/env ts-node

import { PrismaClient, UserRole } from '@prisma/client';

const prisma = new PrismaClient();

export class OptimizedSouthAfricanDataService {
  // South African municipalities and their typical rates (ZAR per kWh)
  private static municipalities = [
    { name: 'City of Cape Town', province: 'Western Cape', rate: 2.85 },
    { name: 'City of Johannesburg', province: 'Gauteng', rate: 3.12 },
    { name: 'eThekwini Municipality', province: 'KwaZulu-Natal', rate: 2.95 },
    { name: 'City of Tshwane', province: 'Gauteng', rate: 3.05 },
    { name: 'Ekurhuleni Metropolitan Municipality', province: 'Gauteng', rate: 2.98 },
    { name: 'Nelson Mandela Bay Municipality', province: 'Eastern Cape', rate: 2.78 },
    { name: 'Buffalo City Metropolitan Municipality', province: 'Eastern Cape', rate: 2.72 },
    { name: 'Mangaung Metropolitan Municipality', province: 'Free State', rate: 2.65 }
  ];

  // South African site locations with realistic coordinates
  private static siteLocations = [
    { name: 'Cape Town Industrial Park', lat: -33.9249, lng: 18.4241, municipality: 'City of Cape Town' },
    { name: 'Johannesburg Business District', lat: -26.2041, lng: 28.0473, municipality: 'City of Johannesburg' },
    { name: 'Durban Manufacturing Hub', lat: -29.8587, lng: 31.0218, municipality: 'eThekwini Municipality' },
    { name: 'Pretoria Technology Center', lat: -25.7479, lng: 28.2293, municipality: 'City of Tshwane' },
    { name: 'Ekurhuleni Logistics Park', lat: -26.1367, lng: 28.2400, municipality: 'Ekurhuleni Metropolitan Municipality' },
    { name: 'Port Elizabeth Solar Farm', lat: -33.9608, lng: 25.6022, municipality: 'Nelson Mandela Bay Municipality' },
    { name: 'East London Commercial Complex', lat: -32.9795, lng: 27.8546, municipality: 'Buffalo City Metropolitan Municipality' },
    { name: 'Bloemfontein Energy Park', lat: -29.0852, lng: 26.1596, municipality: 'Mangaung Metropolitan Municipality' },
    { name: 'Stellenbosch Wine Estate', lat: -33.9321, lng: 18.8602, municipality: 'City of Cape Town' },
    { name: 'Sandton Financial District', lat: -26.1076, lng: 28.0567, municipality: 'City of Johannesburg' }
  ];

  static async clearExistingData() {
    console.log('🧹 Clearing existing data...');
    
    // Delete in correct order to avoid foreign key constraints
    await prisma.roleKPI.deleteMany({});
    await prisma.financialRecord.deleteMany({});
    await prisma.energyData.deleteMany({});
    await prisma.siteMetrics.deleteMany({});
    await prisma.user.deleteMany({});
    await prisma.site.deleteMany({});
    await prisma.project.deleteMany({});
    await prisma.license.deleteMany({});
    await prisma.municipalRate.deleteMany({});
    await prisma.organization.deleteMany({});
    
    console.log('✅ Existing data cleared');
  }

  static async seedMunicipalRates() {
    console.log('🏛️ Seeding South African municipal rates...');
    
    const municipalRates = this.municipalities.map(municipality => ({
      id: `${municipality.name}-COMMERCIAL`,
      municipality: municipality.name,
      province: municipality.province,
      rateType: 'COMMERCIAL',
      rate: municipality.rate,
      effectiveDate: new Date('2023-01-01'),
      isActive: true
    }));

    await prisma.municipalRate.createMany({
      data: municipalRates,
      skipDuplicates: true
    });
    
    console.log(`✅ Created ${municipalRates.length} municipal rates`);
  }

  static async seedSouthAfricanData() {
    console.log('🌍 Starting optimized South African data seeding...');
    
    // Clear existing data first
    await this.clearExistingData();
    
    // Seed municipal rates
    await this.seedMunicipalRates();
    
    // Create demo organization
    const organization = await prisma.organization.create({
      data: {
        name: 'NexusGreen South Africa',
        slug: 'nexus-green-sa',
        domain: 'nexusgreen.co.za',
        isActive: true
      }
    });

    // Create license for the organization
    const license = await prisma.license.create({
      data: {
        organizationId: organization.id,
        licenseType: 'ENTERPRISE',
        maxSites: 50,
        maxUsers: 100,
        features: ['ADVANCED_ANALYTICS', 'MULTI_TENANT', 'API_ACCESS'],
        isActive: true,
        expiresAt: new Date('2025-12-31')
      }
    });

    // Create projects
    const projects = await prisma.project.createMany({
      data: [
        {
          id: 'proj-renewable-energy-1',
          name: 'Western Cape Renewable Energy Initiative',
          description: 'Large-scale solar deployment across Western Cape commercial facilities',
          organizationId: organization.id,
          fundingRate: 2.45, // ZAR per kWh
          expectedROI: 12.5, // 12.5% annual ROI
          totalInvestment: 15000000, // R15 million
          isActive: true
        },
        {
          id: 'proj-renewable-energy-2',
          name: 'Gauteng Industrial Solar Program',
          description: 'Solar installations for industrial facilities in Gauteng province',
          organizationId: organization.id,
          fundingRate: 2.55, // ZAR per kWh
          expectedROI: 14.2, // 14.2% annual ROI
          totalInvestment: 22000000, // R22 million
          isActive: true
        }
      ]
    });

    // Get created projects
    const project1 = await prisma.project.findUnique({ where: { id: 'proj-renewable-energy-1' } });
    const project2 = await prisma.project.findUnique({ where: { id: 'proj-renewable-energy-2' } });

    // Create users for different roles
    const users = [
      {
        email: 'superadmin@nexusgreen.co.za',
        firstName: 'System',
        lastName: 'Administrator',
        role: 'SUPER_ADMIN' as const,
        organizationId: organization.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      },
      {
        email: 'customer@nexusgreen.co.za',
        firstName: 'Sarah',
        lastName: 'Johnson',
        role: 'CUSTOMER' as const,
        organizationId: organization.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      },
      {
        email: 'operator@nexusgreen.co.za',
        firstName: 'Michael',
        lastName: 'Smith',
        role: 'OPERATOR' as const,
        organizationId: organization.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      },
      {
        email: 'funder@nexusgreen.co.za',
        firstName: 'David',
        lastName: 'Williams',
        role: 'FUNDER' as const,
        organizationId: organization.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      },
      {
        email: 'projectadmin1@nexusgreen.co.za',
        firstName: 'Lisa',
        lastName: 'Brown',
        role: 'PROJECT_ADMIN' as const,
        organizationId: organization.id,
        projectId: project1?.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      },
      {
        email: 'projectadmin2@nexusgreen.co.za',
        firstName: 'James',
        lastName: 'Davis',
        role: 'PROJECT_ADMIN' as const,
        organizationId: organization.id,
        projectId: project2?.id,
        password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        isActive: true,
        emailVerified: true
      }
    ];

    await prisma.user.createMany({
      data: users,
      skipDuplicates: true
    });

    // Create sites (5 per project) - batch creation
    const sitesData = [];
    for (let i = 0; i < 5; i++) {
      const location = this.siteLocations[i];
      const municipality = this.municipalities.find(m => m.name === location.municipality);
      
      // Project 1 site
      sitesData.push({
        id: `site-project1-${i + 1}`,
        name: `${location.name} - Site ${i + 1}`,
        address: `${location.name}, ${municipality?.province}, South Africa`,
        municipality: location.municipality,
        latitude: location.lat + (Math.random() - 0.5) * 0.01,
        longitude: location.lng + (Math.random() - 0.5) * 0.01,
        timezone: 'Africa/Johannesburg',
        capacity: 500 + Math.random() * 1000, // 500-1500 kW
        installDate: new Date('2022-06-01'),
        municipalRate: municipality?.rate || 2.85,
        organizationId: organization.id,
        projectId: project1?.id,
        isActive: true
      });

      const location2 = this.siteLocations[i + 5];
      const municipality2 = this.municipalities.find(m => m.name === location2.municipality);
      
      // Project 2 site
      sitesData.push({
        id: `site-project2-${i + 1}`,
        name: `${location2.name} - Site ${i + 1}`,
        address: `${location2.name}, ${municipality2?.province}, South Africa`,
        municipality: location2.municipality,
        latitude: location2.lat + (Math.random() - 0.5) * 0.01,
        longitude: location2.lng + (Math.random() - 0.5) * 0.01,
        timezone: 'Africa/Johannesburg',
        capacity: 750 + Math.random() * 1250, // 750-2000 kW
        installDate: new Date('2022-08-01'),
        municipalRate: municipality2?.rate || 2.95,
        organizationId: organization.id,
        projectId: project2?.id,
        isActive: true
      });
    }

    await prisma.site.createMany({
      data: sitesData,
      skipDuplicates: true
    });

    const sites = await prisma.site.findMany({
      where: { organizationId: organization.id }
    });

    console.log(`✅ Created ${sites.length} sites`);

    // Generate optimized historical data (reduced volume for performance)
    console.log('📊 Generating optimized historical data...');
    await this.generateOptimizedHistoricalData(sites);
    
    // Generate role-specific KPIs
    await this.generateRoleKPIs(organization.id);
    
    console.log('✅ South African data seeding completed successfully!');
    console.log(`📊 Created organization: ${organization.name}`);
    console.log(`🏗️ Created 2 projects`);
    console.log(`🏭 Created ${sites.length} sites`);
    console.log('📈 Generated optimized historical data');
    console.log('🎯 Generated role-specific KPIs');
    
    return { organization, projects: [project1, project2], sites };
  }

  private static async generateOptimizedHistoricalData(sites: any[]) {
    // Generate data for last 6 months instead of 2 years for performance
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 6);
    const endDate = new Date();
    
    console.log(`Generating data from ${startDate.toDateString()} to ${endDate.toDateString()}`);
    
    // Batch data arrays
    const siteMetricsData = [];
    const energyDataBatch = [];
    const financialRecordsData = [];
    
    for (const site of sites) {
      console.log(`Processing ${site.name}...`);
      
      const currentDate = new Date(startDate);
      while (currentDate <= endDate) {
        // Generate daily metrics
        const dailyData = this.generateDailyMetrics(site, new Date(currentDate));
        
        siteMetricsData.push(dailyData.siteMetrics);
        energyDataBatch.push(...dailyData.energyData);
        
        if (dailyData.financialRecord) {
          financialRecordsData.push(dailyData.financialRecord);
        }
        
        currentDate.setDate(currentDate.getDate() + 1);
      }
    }
    
    // Batch insert all data
    console.log('💾 Batch inserting site metrics...');
    await this.batchInsert(prisma.siteMetrics, siteMetricsData, 1000);
    
    console.log('💾 Batch inserting energy data...');
    await this.batchInsert(prisma.energyData, energyDataBatch, 5000);
    
    console.log('💾 Batch inserting financial records...');
    await this.batchInsert(prisma.financialRecord, financialRecordsData, 1000);
    
    console.log('✅ Historical data generation completed');
  }

  private static async batchInsert(model: any, data: any[], batchSize: number) {
    for (let i = 0; i < data.length; i += batchSize) {
      const batch = data.slice(i, i + batchSize);
      await model.createMany({
        data: batch,
        skipDuplicates: true
      });
      console.log(`  Inserted batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(data.length / batchSize)}`);
    }
  }

  private static generateDailyMetrics(site: any, date: Date) {
    // South African solar irradiance patterns (seasonal variation)
    const month = date.getMonth() + 1;
    const isWinter = month >= 5 && month <= 8; // May to August
    const baseIrradiance = isWinter ? 4.5 : 6.8; // kWh/m²/day
    const dailyVariation = (Math.random() - 0.5) * 0.8;
    const irradiance = Math.max(0, baseIrradiance + dailyVariation);
    
    // Calculate generation based on capacity and irradiance
    const capacity = site.capacity;
    const performanceRatio = 0.75 + Math.random() * 0.15; // 75-90% PR
    const dailyGeneration = capacity * irradiance * performanceRatio / 1000; // Convert to MWh
    
    // Consumption patterns (commercial/industrial)
    const baseConsumption = capacity * 0.6; // 60% of capacity as base load
    const consumptionVariation = (Math.random() - 0.5) * 0.3;
    const dailyConsumption = baseConsumption * (1 + consumptionVariation) * 10 / 1000; // Convert to MWh
    
    // Grid interaction
    const netConsumption = dailyConsumption - dailyGeneration;
    const gridImport = Math.max(0, netConsumption);
    const gridExport = Math.max(0, -netConsumption);
    
    // Site metrics
    const siteMetrics = {
      siteId: site.id,
      date: date,
      totalGeneration: dailyGeneration,
      totalConsumption: dailyConsumption,
      totalGridImport: gridImport,
      totalGridExport: gridExport,
      averageEfficiency: performanceRatio * 100,
      capacityFactor: (dailyGeneration / (capacity * 24 / 1000)) * 100,
      availability: 95 + Math.random() * 5, // 95-100% availability
      averageTemperature: this.getSouthAfricanTemperature(month) + (Math.random() - 0.5) * 5
    };

    // Generate sample hourly energy data (reduced to 4 data points per day for performance)
    const energyData = [];
    const sampleHours = [6, 12, 18, 22]; // Morning, noon, evening, night
    
    for (const hour of sampleHours) {
      const timestamp = new Date(date);
      timestamp.setHours(hour);
      
      // Solar generation curve (bell curve during daylight)
      let solarPower = 0;
      if (hour >= 6 && hour <= 18) {
        const solarHour = hour - 12; // Center at noon
        solarPower = capacity * Math.exp(-(solarHour * solarHour) / 18) * (irradiance / 6.8);
      }
      
      // Consumption pattern (higher during business hours)
      let consumptionMultiplier = 0.3; // Base night consumption
      if (hour >= 7 && hour <= 17) {
        consumptionMultiplier = 0.8 + Math.random() * 0.4; // Business hours
      } else if (hour >= 18 && hour <= 22) {
        consumptionMultiplier = 0.5 + Math.random() * 0.3; // Evening
      }
      
      const consumptionPower = baseConsumption * consumptionMultiplier;
      const netPower = consumptionPower - solarPower;
      
      energyData.push({
        timestamp: timestamp,
        solarGeneration: solarPower / 1000, // Convert to MWh
        solarPower: solarPower,
        gridConsumption: Math.max(0, netPower) / 1000,
        gridPower: Math.max(0, netPower),
        exportedEnergy: Math.max(0, -netPower) / 1000,
        irradiance: irradiance * 1000 / 24, // Convert to W/m²
        temperature: this.getSouthAfricanTemperature(month) + (Math.random() - 0.5) * 3,
        siteId: site.id
      });
    }

    // Financial record (only create if there are savings)
    const municipalCost = dailyConsumption * site.municipalRate;
    const actualCost = gridImport * site.municipalRate;
    const savings = municipalCost - actualCost;
    
    let financialRecord = null;
    if (savings > 0) {
      financialRecord = {
        siteId: site.id,
        recordType: 'MUNICIPAL_COMPARISON',
        amount: actualCost,
        currency: 'ZAR',
        description: `Daily energy cost vs municipal rate for ${date.toDateString()}`,
        periodStart: date,
        periodEnd: date,
        municipalRate: site.municipalRate,
        savingsVsMunicipal: savings
      };
    }

    return { siteMetrics, energyData, financialRecord };
  }

  private static getSouthAfricanTemperature(month: number): number {
    // Average temperatures for South Africa by month (Celsius)
    const temperatures = [26, 26, 24, 21, 18, 16, 16, 18, 21, 23, 24, 25];
    return temperatures[month - 1];
  }

  static async generateRoleKPIs(organizationId: string) {
    console.log('🎯 Generating role-specific KPIs...');
    
    const projects = await prisma.project.findMany({
      where: { organizationId }
    });

    const sites = await prisma.site.findMany({
      where: { organizationId }
    });

    const roleKPIs: any[] = [];

    // Customer KPIs
    const totalSavings = await prisma.financialRecord.aggregate({
      where: {
        site: { organizationId },
        recordType: 'MUNICIPAL_COMPARISON'
      },
      _sum: { savingsVsMunicipal: true }
    });

    roleKPIs.push({
      role: UserRole.CUSTOMER,
      kpiName: 'Total Savings',
      kpiValue: totalSavings._sum.savingsVsMunicipal || 0,
      unit: 'ZAR',
      period: 'total',
      organizationId,
      calculatedAt: new Date()
    });

    // Operator KPIs
    const avgAvailability = await prisma.siteMetrics.aggregate({
      where: { site: { organizationId } },
      _avg: { availability: true }
    });

    roleKPIs.push({
      role: UserRole.OPERATOR,
      kpiName: 'System Availability',
      kpiValue: avgAvailability._avg.availability || 0,
      unit: '%',
      period: 'average',
      organizationId,
      calculatedAt: new Date()
    });

    // Funder KPIs
    for (const project of projects) {
      const projectSavings = await prisma.financialRecord.aggregate({
        where: {
          site: { projectId: project.id },
          recordType: 'MUNICIPAL_COMPARISON'
        },
        _sum: { savingsVsMunicipal: true }
      });

      const roi = project.totalInvestment ? 
        ((projectSavings._sum.savingsVsMunicipal || 0) / project.totalInvestment) * 100 : 0;

      roleKPIs.push({
        role: UserRole.FUNDER,
        kpiName: 'ROI',
        kpiValue: roi,
        unit: '%',
        period: 'total',
        organizationId,
        projectId: project.id,
        calculatedAt: new Date()
      });
    }

    // Super Admin KPIs
    const totalGeneration = await prisma.siteMetrics.aggregate({
      where: { site: { organizationId } },
      _sum: { totalGeneration: true }
    });

    roleKPIs.push({
      role: UserRole.SUPER_ADMIN,
      kpiName: 'Total Generation',
      kpiValue: totalGeneration._sum.totalGeneration || 0,
      unit: 'MWh',
      period: 'total',
      organizationId,
      calculatedAt: new Date()
    });

    // Project Admin KPIs
    for (const project of projects) {
      const projectGeneration = await prisma.siteMetrics.aggregate({
        where: { site: { projectId: project.id } },
        _sum: { totalGeneration: true }
      });

      roleKPIs.push({
        role: UserRole.PROJECT_ADMIN,
        kpiName: 'Project Generation',
        kpiValue: projectGeneration._sum.totalGeneration || 0,
        unit: 'MWh',
        period: 'total',
        organizationId,
        projectId: project.id,
        calculatedAt: new Date()
      });
    }

    await prisma.roleKPI.createMany({
      data: roleKPIs,
      skipDuplicates: true
    });

    console.log(`✅ Generated ${roleKPIs.length} role-specific KPIs`);
  }
}

async function main() {
  try {
    console.log('🚀 Starting optimized South African data seeding process...');
    
    const result = await OptimizedSouthAfricanDataService.seedSouthAfricanData();
    
    console.log('🎉 Optimized South African data seeding completed successfully!');
    console.log(`📊 Organization: ${result.organization.name}`);
    console.log(`🏗️ Projects: ${result.projects.length}`);
    console.log(`🏭 Sites: ${result.sites.length}`);
    console.log('📈 Historical data: 6 months of optimized data');
    console.log('🎯 Role-specific KPIs generated');
    
  } catch (error) {
    console.error('❌ Error in optimized seeding:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  main();
}