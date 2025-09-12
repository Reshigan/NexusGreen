import { PrismaClient } from '@prisma/client';
import { logger } from './logger';

declare global {
  var __prisma: PrismaClient | undefined;
}

export const prisma = globalThis.__prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

if (process.env.NODE_ENV === 'development') {
  globalThis.__prisma = prisma;
}

// Test database connection
export const connectDatabase = async () => {
  try {
    await prisma.$connect();
    logger.info('✅ Database connected successfully');
  } catch (error) {
    logger.error('❌ Database connection failed', { error });
    process.exit(1);
  }
};

// Graceful shutdown
export const disconnectDatabase = async () => {
  try {
    await prisma.$disconnect();
    logger.info('Database disconnected');
  } catch (error) {
    logger.error('Error disconnecting database', { error });
  }
};