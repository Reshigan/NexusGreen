const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function fixPasswords() {
  try {
    const password = 'password123';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    console.log('Updating all user passwords...');
    
    const result = await prisma.user.updateMany({
      data: {
        password: hashedPassword
      }
    });
    
    console.log(`Updated ${result.count} users with password: ${password}`);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixPasswords();