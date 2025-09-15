const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateUserRole() {
  try {
    const user = await prisma.user.update({
      where: { email: 'superadmin@nexusgreen.com' },
      data: { role: 'SUPER_ADMIN' }
    });
    console.log('Updated user:', user);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateUserRole();