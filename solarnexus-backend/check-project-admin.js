const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkProjectAdmin() {
  try {
    // First check all users
    const allUsers = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true
      }
    });
    
    console.log('All users:', JSON.stringify(allUsers, null, 2));
    
    // Check project admin users
    const projectAdmins = await prisma.user.findMany({
      where: { role: 'PROJECT_ADMIN' },
      include: {
        organization: true,
        project: true
      }
    });
    
    console.log('Project Admin Users:', JSON.stringify(projectAdmins, null, 2));
    
    // Check projects
    const projects = await prisma.project.findMany({
      select: {
        id: true,
        name: true,
        organizationId: true
      }
    });
    
    console.log('Projects:', JSON.stringify(projects, null, 2));
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkProjectAdmin();