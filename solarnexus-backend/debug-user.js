const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function debugUser() {
  try {
    const user = await prisma.user.findUnique({
      where: { email: 'projectadmin1@nexusgreen.co.za' },
      select: {
        id: true,
        email: true,
        role: true,
        projectId: true,
        organizationId: true
      }
    });
    
    console.log('User found:', JSON.stringify(user, null, 2));
    
    if (user && user.projectId) {
      const project = await prisma.project.findUnique({
        where: { id: user.projectId },
        select: {
          id: true,
          name: true,
          slug: true
        }
      });
      console.log('Associated project:', JSON.stringify(project, null, 2));
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

debugUser();