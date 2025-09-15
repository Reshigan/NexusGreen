const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function checkPassword() {
  try {
    const user = await prisma.user.findUnique({
      where: { email: 'superadmin@nexusgreen.co.za' }
    });
    
    if (user) {
      console.log('User found:', user.email);
      console.log('Password hash:', user.password);
      
      // Test different passwords
      const passwords = ['password123', 'admin123', 'superadmin123', 'nexusgreen123'];
      
      for (const pwd of passwords) {
        const isValid = await bcrypt.compare(pwd, user.password);
        console.log(`Password "${pwd}": ${isValid ? 'VALID' : 'INVALID'}`);
      }
    } else {
      console.log('User not found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkPassword();