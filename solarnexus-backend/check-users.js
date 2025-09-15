const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkUsers() {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true,
        organizationId: true,
        projectId: true
      }
    });
    
    console.log('Users in database:');
    console.log(JSON.stringify(users, null, 2));
    
    // Check if super admin exists
    const superAdmin = users.find(u => u.role === 'SUPER_ADMIN');
    if (superAdmin) {
      console.log('\nSuper admin found:', superAdmin.email);
    } else {
      console.log('\nNo super admin found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();