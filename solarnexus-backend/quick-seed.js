const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

async function quickSeed() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🌱 Quick seeding organizations and users...');
    
    // Create NexusGreen organization
    const nexusGreenOrg = await prisma.organization.upsert({
      where: { slug: 'nexusgreen-energy-solutions' },
      update: {},
      create: {
        name: 'NexusGreen Energy Solutions',
        slug: 'nexusgreen-energy-solutions',
        domain: 'nexusgreen.com',
        isActive: true
      }
    });
    
    console.log('✅ NexusGreen organization created');
    
    // Create Super Admin
    const superAdminPassword = await bcrypt.hash('SuperAdmin123!', 10);
    await prisma.user.upsert({
      where: { email: 'superadmin@nexusgreen.com' },
      update: {},
      create: {
        email: 'superadmin@nexusgreen.com',
        password: superAdminPassword,
        firstName: 'Super',
        lastName: 'Admin',
        role: 'SUPER_ADMIN',
        isActive: true,
        emailVerified: true,
        organizationId: nexusGreenOrg.id
      }
    });
    
    console.log('✅ Super Admin created');
    
    // Create Customer
    const customerPassword = await bcrypt.hash('Customer123!', 10);
    await prisma.user.upsert({
      where: { email: 'customer@nexusgreen.com' },
      update: {},
      create: {
        email: 'customer@nexusgreen.com',
        password: customerPassword,
        firstName: 'John',
        lastName: 'Customer',
        role: 'CUSTOMER',
        isActive: true,
        emailVerified: true,
        organizationId: nexusGreenOrg.id
      }
    });
    
    console.log('✅ Customer created');
    
    // Create Operator
    const operatorPassword = await bcrypt.hash('Operator123!', 10);
    await prisma.user.upsert({
      where: { email: 'operator@nexusgreen.com' },
      update: {},
      create: {
        email: 'operator@nexusgreen.com',
        password: operatorPassword,
        firstName: 'Jane',
        lastName: 'Operator',
        role: 'OPERATOR',
        isActive: true,
        emailVerified: true,
        organizationId: nexusGreenOrg.id
      }
    });
    
    console.log('✅ Operator created');
    
    // Create Funder
    const funderPassword = await bcrypt.hash('Funder123!', 10);
    await prisma.user.upsert({
      where: { email: 'funder@nexusgreen.com' },
      update: {},
      create: {
        email: 'funder@nexusgreen.com',
        password: funderPassword,
        firstName: 'Mike',
        lastName: 'Funder',
        role: 'FUNDER',
        isActive: true,
        emailVerified: true,
        organizationId: nexusGreenOrg.id
      }
    });
    
    console.log('✅ Funder created');
    console.log('🎉 Quick seeding completed!');
    
  } catch (error) {
    console.error('❌ Seeding failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

quickSeed();