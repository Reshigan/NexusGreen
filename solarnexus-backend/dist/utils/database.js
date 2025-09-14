"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.disconnectDatabase = exports.connectDatabase = exports.prisma = void 0;
const client_1 = require("@prisma/client");
const logger_1 = require("./logger");
exports.prisma = globalThis.__prisma || new client_1.PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});
if (process.env.NODE_ENV === 'development') {
    globalThis.__prisma = exports.prisma;
}
// Test database connection
const connectDatabase = async () => {
    try {
        await exports.prisma.$connect();
        logger_1.logger.info('✅ Database connected successfully');
    }
    catch (error) {
        logger_1.logger.error('❌ Database connection failed', { error });
        process.exit(1);
    }
};
exports.connectDatabase = connectDatabase;
// Graceful shutdown
const disconnectDatabase = async () => {
    try {
        await exports.prisma.$disconnect();
        logger_1.logger.info('Database disconnected');
    }
    catch (error) {
        logger_1.logger.error('Error disconnecting database', { error });
    }
};
exports.disconnectDatabase = disconnectDatabase;
//# sourceMappingURL=database.js.map